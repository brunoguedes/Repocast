import Foundation
import SwiftData

/// One episode of a repo's guided tour (Intro, Architecture), planned by
/// `TourIndexer` before any audio exists so the repo screen can list titles
/// and estimated lengths straight away. Audio is generated lazily on tap —
/// on device (`OnDeviceTourGenerator`) or in the cloud (`CloudTourService`) —
/// and lands as a `NarrationPackage`, whose identifier is kept here.
///
/// Enum-valued fields are raw `String`s with computed accessors, like
/// `AudioTrack`.
@Model
final class TourEpisode {
    enum Kind: String, Codable, CaseIterable, Sendable {
        case intro, architecture

        var label: String {
            switch self {
            case .intro: "Intro"
            case .architecture: "Architecture"
            }
        }
    }

    /// Who made (or is making) the audio.
    enum Executor: String, Codable, CaseIterable, Sendable {
        case device, cloud
    }

    enum Status: String, Codable, CaseIterable, Sendable {
        case planned, generating, ready, failed
    }

    var title: String
    var estimatedMinutes: Int
    /// Commit the episode plan (and any generated audio) was built from.
    var commit: String
    /// Sort order within the tour.
    var position: Int
    /// The `NarrationPackage.identifier` once audio exists.
    var narrationIdentifier: String?
    var errorMessage: String?
    var repo: RepoSource?

    private var kindRaw: String
    private var executorRaw: String?
    private var statusRaw: String

    init(kind: Kind, title: String, estimatedMinutes: Int, commit: String, position: Int) {
        self.kindRaw = kind.rawValue
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.commit = commit
        self.position = position
        self.statusRaw = Status.planned.rawValue
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .intro }
        set { kindRaw = newValue.rawValue }
    }

    var executor: Executor? {
        get { executorRaw.flatMap(Executor.init(rawValue:)) }
        set { executorRaw = newValue?.rawValue }
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }
}
