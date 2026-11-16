import Foundation

/// The backend's tour API (`backend/src/api`): add a public repo, read its
/// tour, start an episode, and fetch a ready episode's files through
/// short-lived signed URLs. Requests are built by `CloudAccount`, which owns
/// the tokens.
struct CloudTourClient: Sendable {
    enum CloudTourError: LocalizedError {
        case http(status: Int, message: String?)
        case invalidResponse
        case timedOut
        case failed(String)

        var errorDescription: String? {
            switch self {
            case let .http(status, message):
                message ?? "The cloud service returned HTTP \(status)."
            case .invalidResponse:
                "Unexpected response from the cloud service."
            case .timedOut:
                "Cloud generation is taking longer than expected. Try again in a few minutes."
            case let .failed(message):
                message
            }
        }
    }

    struct RepoStatus: Decodable, Sendable {
        let repo: String
        let commit: String
        let status: String
    }

    struct Tour: Decodable, Sendable {
        struct Episode: Decodable, Sendable {
            let type: String
            let title: String
            let estimatedMinutes: Int
            let status: String
        }

        let commit: String
        let status: String
        let episodes: [Episode]?
        let error: String?
    }

    struct EpisodeStatus: Decodable, Sendable {
        struct File: Decodable, Sendable {
            let name: String
            let url: URL
        }

        let status: String
        let error: String?
        let files: [File]?
    }

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func addRepo(_ fullName: String, request: URLRequest) async throws -> RepoStatus {
        var request = request
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["fullName": fullName])
        return try await decode(request)
    }

    func tour(request: URLRequest, commit: String) async throws -> Tour {
        try await decode(Self.adding(query: ["commit": commit], to: request))
    }

    func startEpisode(commit: String, request: URLRequest) async throws -> EpisodeStatus {
        var request = request
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["commit": commit])
        return try await decode(request)
    }

    func episode(request: URLRequest, commit: String) async throws -> EpisodeStatus {
        try await decode(Self.adding(query: ["commit": commit], to: request))
    }

    /// Downloads every file of a ready episode into `directory`.
    func download(_ files: [EpisodeStatus.File], to directory: URL) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for file in files {
            // Only plain file names — never let the server write outside the folder.
            guard !file.name.contains("/"), !file.name.hasPrefix(".") else { throw CloudTourError.invalidResponse }
            let (temporary, response) = try await session.download(from: file.url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw CloudTourError.invalidResponse }
            let destination = directory.appendingPathComponent(file.name)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: temporary, to: destination)
        }
    }

    // MARK: Internals

    private func decode<T: Decodable>(_ request: URLRequest) async throws -> T {
        try JSONDecoder().decode(T.self, from: try await Self.send(request, session: session))
    }

    /// Sends `request`, returning the body of a 2xx response and throwing the
    /// server's `{error}` message otherwise.
    static func send(_ request: URLRequest, session: URLSession) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CloudTourError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw CloudTourError.http(status: http.statusCode, message: message)
        }
        return data
    }

    private static func adding(query: [String: String], to request: URLRequest) -> URLRequest {
        var request = request
        if let url = request.url {
            request.url = url.appending(queryItems: query.map { URLQueryItem(name: $0.key, value: $0.value) })
        }
        return request
    }
}
