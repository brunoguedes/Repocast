import Foundation

/// Read-only GitHub REST access. Stateless and `Sendable`: the auth token is
/// read from the Keychain per call (or passed explicitly when validating a
/// not-yet-saved token). Tests inject a mock conforming to `GitHubFetching`.
protocol GitHubFetching: Sendable {
    /// Validate a candidate token and return the authenticated user.
    func validate(token: String) async throws -> GitHubUser
    /// Repositories the saved token can see (first page, most-recently updated).
    func repositories() async throws -> [GitHubRepo]
    /// Directory listing at `path` ("" = repo root).
    func contents(owner: String, repo: String, path: String, ref: String?) async throws -> [GitHubContentEntry]
    /// UTF-8 text of a single file.
    func fileText(owner: String, repo: String, path: String, ref: String?) async throws -> String
}

enum GitHubError: LocalizedError {
    case notAuthenticated
    case badURL
    case invalidResponse
    case http(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "Not connected to GitHub. Add a token in Settings."
        case .badURL:
            "Couldn't build the GitHub request URL."
        case .invalidResponse:
            "Unexpected response from GitHub."
        case let .http(status, message):
            switch status {
            case 401: "GitHub rejected the token. Check it has read access and hasn't expired."
            case 403: message ?? "GitHub rate limit reached. Try again later."
            case 404: "Not found on GitHub — check the repository and your token's access."
            default: message ?? "GitHub request failed (HTTP \(status))."
            }
        }
    }
}

struct GitHubClient: GitHubFetching {
    var keychain: KeychainStore = .github

    private let base = URL(string: "https://api.github.com")!

    func validate(token: String) async throws -> GitHubUser {
        try await get("/user", token: token)
    }

    func repositories() async throws -> [GitHubRepo] {
        try await get("/user/repos?per_page=100&sort=updated", token: requireToken())
    }

    func contents(owner: String, repo: String, path: String, ref: String?) async throws -> [GitHubContentEntry] {
        try await get(contentsEndpoint(owner: owner, repo: repo, path: path, ref: ref), token: requireToken())
    }

    func fileText(owner: String, repo: String, path: String, ref: String?) async throws -> String {
        let file: GitHubFileContent = try await get(
            contentsEndpoint(owner: owner, repo: repo, path: path, ref: ref),
            token: requireToken()
        )
        return file.decodedText() ?? ""
    }

    // MARK: Internals

    private func requireToken() throws -> String {
        guard let token = keychain.read(account: KeychainStore.tokenAccount) else {
            throw GitHubError.notAuthenticated
        }
        return token
    }

    private func contentsEndpoint(owner: String, repo: String, path: String, ref: String?) -> String {
        let encodedPath = path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        var endpoint = "/repos/\(owner)/\(repo)/contents/\(encodedPath)"
        if let ref, let encodedRef = ref.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "?ref=\(encodedRef)"
        }
        return endpoint
    }

    private func get<T: Decodable>(_ endpoint: String, token: String) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: base) else { throw GitHubError.badURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Repocast", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = try? JSONDecoder().decode(GitHubErrorMessage.self, from: data).message
            throw GitHubError.http(status: http.statusCode, message: message)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
