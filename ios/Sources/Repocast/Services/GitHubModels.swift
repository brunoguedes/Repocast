import Foundation

/// Decodable DTOs for the GitHub REST API. These are wire types, not persisted
/// models — `RepoSource` is the persisted shape. All snake_case JSON keys are
/// mapped by `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`, except
/// `private`, which is a Swift keyword (handled with `CodingKeys`).
struct GitHubUser: Decodable, Sendable, Identifiable {
    let id: Int
    let login: String
    let name: String?
    let avatarUrl: String?
}

struct GitHubRepo: Decodable, Sendable, Identifiable {
    struct Owner: Decodable, Sendable { let login: String }

    let id: Int
    let name: String
    let fullName: String
    let owner: Owner
    let defaultBranch: String
    let description: String?
    let isPrivate: Bool

    // The decoder runs `.convertFromSnakeCase`, so JSON `full_name` /
    // `default_branch` already arrive as `fullName` / `defaultBranch`. Only
    // `private` needs an override (it's a Swift keyword and has no underscore).
    private enum CodingKeys: String, CodingKey {
        case id, name, owner, description, fullName, defaultBranch
        case isPrivate = "private"
    }
}

/// One entry in a repository directory listing (Contents API, array form).
struct GitHubContentEntry: Decodable, Sendable, Identifiable {
    let name: String
    let path: String
    let sha: String
    let size: Int?
    /// "file" or "dir".
    let type: String

    var id: String { path }
    var isDirectory: Bool { type == "dir" }
}

/// A single file from the Contents API (object form) — `content` is base64.
struct GitHubFileContent: Decodable, Sendable {
    let name: String
    let path: String
    let content: String?
    let encoding: String?

    func decodedText() -> String? {
        guard let content, encoding == "base64" else { return content }
        let stripped = content.replacingOccurrences(of: "\n", with: "")
        guard let data = Data(base64Encoded: stripped) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

struct GitHubErrorMessage: Decodable, Sendable { let message: String }

extension AudioTrack.SourceKind {
    /// Classify a repo file by extension so the pipeline can pick the right
    /// narration treatment (Markdown reads beautifully verbatim; code will get
    /// AI summarization once Phase 2 lands).
    static func detect(path: String) -> AudioTrack.SourceKind {
        let lower = path.lowercased()
        let markdownish = [".md", ".markdown", ".mdx", ".txt", ".rst"]
        return markdownish.contains(where: lower.hasSuffix) ? .markdown : .code
    }
}
