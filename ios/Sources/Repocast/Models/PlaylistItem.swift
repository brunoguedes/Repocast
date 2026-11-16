import Foundation
import SwiftData

/// One ordered slot in a `Playlist`. A thin join between a playlist and an
/// `AudioTrack` so the same track can live in several playlists at different
/// positions without duplicating its bytes or metadata.
///
/// `position` is the source of truth for order (see `Playlist.orderedItems`).
/// The `track` relationship is optional and nullify-on-delete: removing a track
/// from the library leaves a tombstone slot that `Playlist.tracks` skips, rather
/// than corrupting the playlist.
@Model
final class PlaylistItem {
    var position: Int

    @Relationship(deleteRule: .nullify)
    var track: AudioTrack?

    /// Inverse of `Playlist.items`.
    var playlist: Playlist?

    init(position: Int, track: AudioTrack? = nil) {
        self.position = position
        self.track = track
    }
}
