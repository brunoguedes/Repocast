import Foundation
import SwiftData

/// One generated, playable audio item — the unit the player queues and the
/// library lists. The audio bytes themselves live on disk under
/// `Documents/Audio/` (see `AudioFileStore`); this model holds only metadata
/// plus the filename, which is the on-disk contract.
///
/// Enum-valued fields are stored as their raw `String` (with computed
/// accessors) rather than as `enum` columns: it survives schema drift, stays
/// queryable, and keeps the model CloudKit-safe for the eventual sync switch.
@Model
final class AudioTrack {
    /// Where the spoken text came from.
    enum SourceKind: String, Codable, CaseIterable, Sendable {
        case code, markdown, changes, freeform
    }

    /// How the text was produced from the source.
    enum GenerationKind: String, Codable, CaseIterable, Sendable {
        case summary   // on-device AI summary (Phase 2)
        case verbatim  // read the source text as-is
    }

    /// Generation lifecycle.
    enum Status: String, Codable, CaseIterable, Sendable {
        case pending, generating, ready, failed
    }

    var title: String
    /// `owner/name` of the repo this track was generated from (`nil` for
    /// freeform text). Stored as a string — like `Playlist.sourceRepoFullName` —
    /// to stay drift-safe and CloudKit-ready without a hard relationship.
    var repoFullName: String?
    /// Path of the originating file within its repo (empty for freeform text).
    var sourcePath: String
    var transcript: String
    /// Filename only, relative to `AudioFileStore`'s directory.
    var audioFileName: String
    var durationSeconds: Double
    var voiceIdentifier: String?
    var createdAt: Date

    // Raw-string backing for the enums above.
    private var sourceKindRaw: String
    private var generationKindRaw: String
    private var statusRaw: String

    /// Playlist slots that reference this track. Declaring the inverse here is
    /// what makes `PlaylistItem.track`'s `.nullify` rule actually fire: without a
    /// registered inverse, deleting a track leaves dangling references on its
    /// `PlaylistItem`s, which crash the playlist view when dereferenced. With it,
    /// deleting a track nullifies those slots into the tombstones `Playlist.tracks`
    /// skips. Optional to-many keeps the model CloudKit-safe.
    @Relationship(deleteRule: .nullify, inverse: \PlaylistItem.track)
    var playlistItems: [PlaylistItem]? = []

    init(
        title: String,
        repoFullName: String? = nil,
        sourcePath: String = "",
        sourceKind: SourceKind = .freeform,
        generationKind: GenerationKind = .verbatim,
        transcript: String = "",
        audioFileName: String = "",
        durationSeconds: Double = 0,
        voiceIdentifier: String? = nil,
        status: Status = .pending,
        createdAt: Date = .now
    ) {
        self.title = title
        self.repoFullName = repoFullName
        self.sourcePath = sourcePath
        self.sourceKindRaw = sourceKind.rawValue
        self.generationKindRaw = generationKind.rawValue
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.durationSeconds = durationSeconds
        self.voiceIdentifier = voiceIdentifier
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }

    var sourceKind: SourceKind {
        get { SourceKind(rawValue: sourceKindRaw) ?? .freeform }
        set { sourceKindRaw = newValue.rawValue }
    }

    var generationKind: GenerationKind {
        get { GenerationKind(rawValue: generationKindRaw) ?? .verbatim }
        set { generationKindRaw = newValue.rawValue }
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}

/// A run of tracks that share an originating repo, for grouped display in the
/// library and the playlist editor.
struct RepoTrackGroup: Identifiable {
    /// `repoFullName` for a repo group, or `""` for the freeform/no-repo group.
    let id: String
    /// Header text: the repo's `owner/name`, or "Freeform".
    let title: String
    let tracks: [AudioTrack]
}

extension Array where Element == AudioTrack {
    /// Group tracks by their originating repo. Repo groups come first
    /// (alphabetical, case-insensitive); freeform tracks land in a trailing
    /// "Freeform" group. The relative order of tracks within each group is
    /// preserved from the receiver.
    func groupedByRepo() -> [RepoTrackGroup] {
        Dictionary(grouping: self) { $0.repoFullName ?? "" }
            .map { key, value in
                RepoTrackGroup(id: key, title: key.isEmpty ? "Freeform" : key, tracks: value)
            }
            .sorted { lhs, rhs in
                // Freeform always sorts last; otherwise alphabetical by repo.
                if lhs.id.isEmpty != rhs.id.isEmpty { return rhs.id.isEmpty }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }
}
