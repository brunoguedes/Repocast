import Foundation
import SwiftData

/// A user-curated or AI-generated ordering of `AudioTrack`s — the unit the
/// Playlists tab lists and the player queues as a set. Tracks are referenced
/// through ordered `PlaylistItem`s (an explicit `position` rather than relying
/// on SwiftData array order, which isn't guaranteed stable across the store).
///
/// Like `AudioTrack`, the enum-valued `kind` is stored as its raw `String` with
/// a computed accessor — drift-safe, queryable, and CloudKit-ready for the
/// eventual private-sync switch documented in `DataStack`.
@Model
final class Playlist {
    /// How the playlist came to be.
    enum Kind: String, Codable, CaseIterable, Sendable {
        case manual   // hand-built by the user
        case smart    // generated on-device by `PlaylistGenerator`
        case repo     // auto-built from all tracks of one `RepoSource`
    }

    var title: String
    /// One-line subtitle: the smart-playlist rationale, the source repo, etc.
    var detail: String
    /// A system-color token name (`"blue"`, `"purple"`, …) for the artwork tint.
    var tint: String
    /// For `.repo` playlists, the `owner/name` this was built from.
    var sourceRepoFullName: String?
    var createdAt: Date

    private var kindRaw: String

    /// Ordered membership. Cascade-delete the join rows (not the tracks) when a
    /// playlist is removed; to-many + optional keeps the model CloudKit-safe.
    @Relationship(deleteRule: .cascade, inverse: \PlaylistItem.playlist)
    var items: [PlaylistItem]? = []

    init(
        title: String,
        detail: String = "",
        tint: String = "blue",
        kind: Kind = .manual,
        sourceRepoFullName: String? = nil,
        createdAt: Date = .now
    ) {
        self.title = title
        self.detail = detail
        self.tint = tint
        self.kindRaw = kind.rawValue
        self.sourceRepoFullName = sourceRepoFullName
        self.createdAt = createdAt
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .manual }
        set { kindRaw = newValue.rawValue }
    }

    /// Items sorted by their stored position.
    var orderedItems: [PlaylistItem] {
        (items ?? []).sorted { $0.position < $1.position }
    }

    /// The playable tracks, in order (skips items whose track was deleted).
    var tracks: [AudioTrack] {
        orderedItems.compactMap(\.track)
    }

    var totalDuration: Double {
        tracks.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Append a track as the next position.
    func append(_ track: AudioTrack) {
        let next = (items ?? []).map(\.position).max().map { $0 + 1 } ?? 0
        let item = PlaylistItem(position: next, track: track)
        item.playlist = self
        items = (items ?? []) + [item]
    }

    /// Renumber `position` to match the supplied order (call after a move).
    func reorder(to ordered: [PlaylistItem]) {
        for (index, item) in ordered.enumerated() { item.position = index }
    }
}
