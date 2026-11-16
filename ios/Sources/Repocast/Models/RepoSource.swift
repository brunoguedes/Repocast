import Foundation
import SwiftData

/// A GitHub repository the user has connected as a source of files to turn into
/// audio. Holds no secrets — the access token lives in the Keychain
/// (`KeychainStore.github`); this is just the coordinates the `GitHubClient`
/// needs plus a little display metadata, and the repo tour's index (see
/// `TourIndexer`).
@Model
final class RepoSource {
    var owner: String
    var name: String
    var defaultBranch: String
    var repoDescription: String?
    var addedAt: Date

    /// Commit the tour was last indexed at.
    var lastIndexedCommit: String?
    /// One-paragraph spoken summary from the index.
    var tourSummary: String?
    private var classificationRaw: String?
    /// The user's override of the guessed classification.
    private var classificationOverrideRaw: String?

    /// The tour's episodes. Cascade so removing a repo removes its plan (the
    /// generated narrations stay in the library).
    @Relationship(deleteRule: .cascade, inverse: \TourEpisode.repo)
    var tourEpisodes: [TourEpisode]? = []

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

    /// What the index guessed the repo is.
    var guessedClassification: RepoClassification? {
        get { classificationRaw.flatMap(RepoClassification.init(rawValue:)) }
        set { classificationRaw = newValue?.rawValue }
    }

    var classificationOverride: RepoClassification? {
        get { classificationOverrideRaw.flatMap(RepoClassification.init(rawValue:)) }
        set { classificationOverrideRaw = newValue?.rawValue }
    }

    /// The override when set, else the guess.
    var classification: RepoClassification? { classificationOverride ?? guessedClassification }

    var sortedTourEpisodes: [TourEpisode] {
        (tourEpisodes ?? []).sorted { $0.position < $1.position }
    }
}
