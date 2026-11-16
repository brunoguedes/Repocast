import Foundation
import Observation

/// App-lifetime GitHub connection state, injected into the environment like the
/// player. Owns the connect / disconnect flow: the token goes to the Keychain,
/// the resolved login is cached in `UserDefaults` so the UI can show "connected
/// as @login" on launch without a network round-trip.
@MainActor
@Observable
final class GitHubAccount {
    private(set) var login: String?

    var isConnected: Bool { login != nil }

    private let client: GitHubFetching
    private let keychain = KeychainStore.github
    private let loginDefaultsKey = "githubLogin"

    init(client: GitHubFetching = GitHubClient()) {
        self.client = client
        if keychain.read(account: KeychainStore.tokenAccount) != nil {
            login = UserDefaults.standard.string(forKey: loginDefaultsKey)
        }
    }

    /// Validate the token against `/user`, then persist it. Throws (without
    /// saving) if GitHub rejects it.
    func connect(token: String) async throws {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = try await client.validate(token: trimmed)
        keychain.save(trimmed, account: KeychainStore.tokenAccount)
        UserDefaults.standard.set(user.login, forKey: loginDefaultsKey)
        login = user.login
        AnalyticsService.logGitHubConnected()
    }

    func disconnect() {
        keychain.delete(account: KeychainStore.tokenAccount)
        UserDefaults.standard.removeObject(forKey: loginDefaultsKey)
        login = nil
        AnalyticsService.logGitHubDisconnected()
    }
}
