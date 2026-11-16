import Foundation
import SwiftData

/// A GitHub repository the user has connected as a source of files to turn into
/// audio. Holds no secrets — the access token lives in the Keychain
/// (`KeychainStore.github`); this is just the coordinates the `GitHubClient`
/// needs plus a little display metadata.
@Model
final class RepoSource {
    var owner: String
    var name: String
    var defaultBranch: String
    var repoDescription: String?
    var addedAt: Date

    init(
        owner: String,
        name: String,
        defaultBranch: String = "main",
        repoDescription: String? = nil,
        addedAt: Date = .now
    ) {
        self.owner = owner
        self.name = name
        self.defaultBranch = defaultBranch
        self.repoDescription = repoDescription
        self.addedAt = addedAt
    }

    var fullName: String { "\(owner)/\(name)" }
}
