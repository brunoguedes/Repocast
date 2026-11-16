import CryptoKit
import Foundation
import Observation
import StoreKit

/// App-lifetime cloud-generation sign-in, injected like `GitHubAccount`.
/// Cognito's hosted UI with Sign in with Apple, driven by the view's
/// `webAuthenticationSession` with PKCE — no AWS SDK. Tokens live in the
/// Keychain (`KeychainStore.cloud`); the access token is refreshed silently
/// before it expires.
///
/// Cloud voice is a TestFlight beta: App Store builds never offer it, even if
/// they were archived with a `Backend.xcconfig`, because the public privacy
/// page promises no servers for the free app.
@MainActor
@Observable
final class CloudAccount {
    struct Usage: Decodable, Equatable, Sendable {
        let month: String
        let minutesUsed: Double
        let minutesQuota: Double
    }

    enum CloudError: LocalizedError {
        case notConfigured
        case notSignedIn
        case signInFailed(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Cloud generation isn't set up in this build."
            case .notSignedIn: "Sign in to use cloud generation."
            case let .signInFailed(message): "Couldn't sign in: \(message)"
            }
        }
    }

    let config: BackendConfig?
    private(set) var email: String?
    private(set) var usage: Usage?

    var isConfigured: Bool { config != nil && isPrerelease }
    var isSignedIn: Bool { keychain.read(account: Self.refreshAccount) != nil && signedInFlag }

    /// Mirrors the Keychain so SwiftUI re-renders on sign in / out.
    private var signedInFlag: Bool
    /// Debug, Xcode or TestFlight install — resolved at launch from StoreKit.
    private var isPrerelease = false
    private var pendingVerifier: String?
    private var pendingState: String?
    private let keychain = KeychainStore.cloud
    private let session: URLSession

    private static let refreshAccount = "refresh-token"
    private static let accessAccount = "access-token"
    private static let expiryKey = "cloudAccessTokenExpiry"
    private static let emailKey = "cloudEmail"

    init(config: BackendConfig? = .current, session: URLSession = .shared) {
        self.config = config
        self.session = session
        signedInFlag = KeychainStore.cloud.read(account: Self.refreshAccount) != nil
        email = signedInFlag ? UserDefaults.standard.string(forKey: Self.emailKey) : nil
        Task { isPrerelease = await Self.isPrereleaseInstall() }
    }

    private nonisolated static func isPrereleaseInstall() async -> Bool {
        #if DEBUG
        return true
        #else
        guard let result = try? await AppTransaction.shared else { return false }
        switch result {
        case let .verified(transaction), let .unverified(transaction, _):
            return transaction.environment != .production
        }
        #endif
    }

    // MARK: Sign in

    /// The hosted-UI URL to open, straight to Sign in with Apple. Remembers the
    /// PKCE verifier for `completeSignIn`.
    func authorizeURL() throws -> URL {
        guard let config else { throw CloudError.notConfigured }
        let verifier = Self.randomURLSafe(bytes: 32)
        let state = Self.randomURLSafe(bytes: 16)
        pendingVerifier = verifier
        pendingState = state
        var components = URLComponents()
        components.scheme = "https"
        components.host = config.cognitoDomain
        components.path = "/oauth2/authorize"
        components.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: config.clientID),
            .init(name: "redirect_uri", value: BackendConfig.redirectURI),
            .init(name: "scope", value: "openid email"),
            .init(name: "identity_provider", value: "SignInWithApple"),
            .init(name: "state", value: state),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: Self.challenge(for: verifier)),
        ]
        return components.url!
    }

    /// Exchange the hosted UI's callback (`repocast://auth?code=…`) for tokens.
    func completeSignIn(callback: URL) async throws {
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if let error = items.first(where: { $0.name == "error_description" || $0.name == "error" })?.value {
            throw CloudError.signInFailed(error)
        }
        guard let code = items.first(where: { $0.name == "code" })?.value,
              items.first(where: { $0.name == "state" })?.value == pendingState,
              let verifier = pendingVerifier else {
            throw CloudError.signInFailed("The sign-in response didn't match this request.")
        }
        pendingVerifier = nil
        pendingState = nil
        try await requestTokens([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": BackendConfig.redirectURI,
            "code_verifier": verifier,
        ])
        AnalyticsService.logCloudSignedIn()
        await refreshUsage()
    }

    func signOut() {
        keychain.delete(account: Self.refreshAccount)
        keychain.delete(account: Self.accessAccount)
        UserDefaults.standard.removeObject(forKey: Self.expiryKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        signedInFlag = false
        email = nil
        usage = nil
    }

    /// Deletes the cloud account and its quota records on the server, then
    /// signs out. Generated episodes already on this device stay.
    func deleteAccount() async throws {
        var request = try await authorizedRequest(path: "/me")
        request.httpMethod = "DELETE"
        _ = try await CloudTourClient.send(request, session: session)
        signOut()
        AnalyticsService.logCloudAccountDeleted()
    }

    func refreshUsage() async {
        guard isSignedIn, let request = try? await authorizedRequest(path: "/me"),
              let data = try? await CloudTourClient.send(request, session: session) else { return }
        usage = try? JSONDecoder().decode(Usage.self, from: data)
    }

    // MARK: Tokens

    /// A request to the API with a fresh access token.
    func authorizedRequest(path: String) async throws -> URLRequest {
        guard let config else { throw CloudError.notConfigured }
        var request = URLRequest(url: config.apiBaseURL.appending(path: path))
        request.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func validAccessToken() async throws -> String {
        let expiry = UserDefaults.standard.double(forKey: Self.expiryKey)
        if let token = keychain.read(account: Self.accessAccount), Date.now.timeIntervalSince1970 < expiry - 60 {
            return token
        }
        guard let refresh = keychain.read(account: Self.refreshAccount) else { throw CloudError.notSignedIn }
        do {
            try await requestTokens(["grant_type": "refresh_token", "refresh_token": refresh])
        } catch {
            // A revoked or expired refresh token means signing in again.
            signOut()
            throw CloudError.notSignedIn
        }
        guard let token = keychain.read(account: Self.accessAccount) else { throw CloudError.notSignedIn }
        return token
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let id_token: String?
        let refresh_token: String?
        let expires_in: Double
    }

    private func requestTokens(_ fields: [String: String]) async throws {
        guard let config else { throw CloudError.notConfigured }
        var request = URLRequest(url: URL(string: "https://\(config.cognitoDomain)/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = (fields.merging(["client_id": config.clientID]) { $1 })
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = form.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").data(using: .utf8)

        let data = try await CloudTourClient.send(request, session: session)
        let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
        keychain.save(tokens.access_token, account: Self.accessAccount)
        if let refresh = tokens.refresh_token { keychain.save(refresh, account: Self.refreshAccount) }
        UserDefaults.standard.set(Date.now.timeIntervalSince1970 + tokens.expires_in, forKey: Self.expiryKey)
        if let idToken = tokens.id_token, let email = Self.claim("email", in: idToken) {
            UserDefaults.standard.set(email, forKey: Self.emailKey)
            self.email = email
        }
        signedInFlag = true
    }

    // MARK: Helpers

    nonisolated static func challenge(for verifier: String) -> String {
        base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    nonisolated static func claim(_ name: String, in jwt: String) -> String? {
        let segments = jwt.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        var payload = String(segments[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object[name] as? String
    }

    private nonisolated static func randomURLSafe(bytes count: Int) -> String {
        base64URL(Data((0..<count).map { _ in UInt8.random(in: .min ... .max) }))
    }

    private nonisolated static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
