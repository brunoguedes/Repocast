import Foundation
import SwiftData

/// An imported narration package — a folder of pre-generated TTS audio
/// (stitched file and/or numbered parts) with transcripts and an M3U playlist,
/// played like an audiobook. The folder's bytes live under
/// `Documents/Narrations/<identifier>/` (see `NarrationPackageStore`); this
/// model holds only display metadata plus the identifiers needed to resolve
/// them. The resume position is *not* stored here — it lives in
/// `NarrationResumeStore`, keyed by the same `identifier`, so the player can
/// save it every few seconds without touching a managed object.
@Model
final class NarrationPackage {
    /// Display name — the playlist's `#PLAYLIST:` value, falling back to the
    /// package's base file name.
    var title: String
    /// The common file-name stem shared by every file in the package
    /// (e.g. `proposal_v2`).
    var baseName: String
    /// Stable key: a hash of the source folder path + base name. Doubles as
    /// the stored folder's name and the resume-position key, and is what makes
    /// re-importing the same folder update this item instead of duplicating it.
    var identifier: String
    /// Path of the folder the user picked, kept for re-import matching.
    var sourcePath: String
    /// The TTS voice, read from the files' ID3 artist tag.
    var voiceName: String?
    /// Number of `_partN` audio files found (0 for a stitched-only package).
    var partCount: Int
    /// Whether the folder includes the full narration stitched into one file
    /// (played in preference to the parts).
    var hasStitched: Bool
    var totalDurationSeconds: Double
    var importedAt: Date
    var lastPlayedAt: Date?

    init(
        title: String,
        baseName: String,
        identifier: String,
        sourcePath: String = "",
        voiceName: String? = nil,
        partCount: Int = 0,
        hasStitched: Bool = false,
        totalDurationSeconds: Double = 0,
        importedAt: Date = .now,
        lastPlayedAt: Date? = nil
    ) {
        self.title = title
        self.baseName = baseName
        self.identifier = identifier
        self.sourcePath = sourcePath
        self.voiceName = voiceName
        self.partCount = partCount
        self.hasStitched = hasStitched
        self.totalDurationSeconds = totalDurationSeconds
        self.importedAt = importedAt
        self.lastPlayedAt = lastPlayedAt
    }
}
