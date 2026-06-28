import Foundation

/// Typed Repocast analytics events. Keeping them as helpers on
/// `AnalyticsService` means the rest of the app never types a raw event string,
/// and this is the one place names live. Event names stay lowercase snake_case,
/// ≤ 40 chars, no `firebase_` / `google_` / `ga_` prefix. **Never** pass user
/// content (repo text, transcripts, titles) — only counts, enum raw values, and
/// toggle states.
extension AnalyticsService {
    static func logTrackGenerated(kind: String) {
        log("track_generated", ["generation_kind": kind])
    }

    static func logTrackGenerationFailed() {
        log("track_generation_failed")
    }

    static func logPlaybackStarted(rate: Float) {
        log("playback_started", ["rate": rate])
    }

    static func logTrackDeleted() {
        log("track_deleted")
    }

    static func logGitHubConnected() {
        log("github_connected")
    }

    static func logGitHubDisconnected() {
        log("github_disconnected")
    }

    static func logRepoAdded() {
        log("repo_added")
    }

    static func logTracksFromRepo(count: Int) {
        log("tracks_from_repo", ["count": count])
    }

    /// A summary was requested but the on-device model was unavailable/failed,
    /// so generation fell back to reading the text verbatim.
    static func logSummaryFallback() {
        log("summary_fallback_verbatim")
    }

    static func logPlaylistCreated(smart: Bool) {
        log("playlist_created", ["smart": smart])
    }

    static func logPlaylistPlayed(smart: Bool) {
        log("playlist_played", ["smart": smart])
    }
}
