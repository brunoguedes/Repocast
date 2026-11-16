import Foundation
import SwiftData

/// A voice note the listener recorded while playing content, pinned to the
/// exact time code it was taken at. The recorded audio lives on disk under
/// `Documents/Notes/` (see `VoiceNoteStore`); the transcript is filled in
/// afterwards by on-device speech recognition (`SpeechTranscriptionService`),
/// so a note is readable even when it was captured hands-free in the car.
///
/// Content linkage follows the resume-position pattern: stable string keys
/// (a track's audio file name / a package identifier + part file name), never
/// array indices, so notes survive library edits and regenerated packages —
/// a note whose content was deleted simply loses its jump-back affordance.
@Model
final class VoiceNote {
    /// What the listener was playing when the note was taken.
    enum ContentKind: String, Codable, CaseIterable, Sendable {
        case track      // an `AudioTrack` (alone or inside a playlist queue)
        case narration  // a `NarrationPackage`
    }

    /// Transcription lifecycle.
    enum Status: String, Codable, CaseIterable, Sendable {
        case transcribing   // recognition still running in the background
        case transcribed
        case unavailable    // on-device recognition not available / not authorized
        case failed
    }

    var createdAt: Date
    /// `track`: the track's `audioFileName`; `narration`: the package identifier.
    var contentID: String
    /// For narrations, the part file that was playing; empty for tracks.
    var itemFileName: String
    /// Denormalized titles so the note stays readable after content is deleted.
    var contentTitle: String
    var itemTitle: String
    /// Position on the presented timeline (aggregate across parts for a
    /// narration package) — what the Notes list displays.
    var timecodeSeconds: Double
    /// Position within the specific item/part — what jump-back seeks to.
    var offsetSeconds: Double
    var transcript: String
    /// The recorded note audio, relative to `VoiceNoteStore`'s directory.
    var audioFileName: String
    var durationSeconds: Double

    // Raw-string backing for the enums above (drift-safe, CloudKit-ready).
    private var contentKindRaw: String
    private var statusRaw: String

    init(
        contentKind: ContentKind,
        contentID: String,
        itemFileName: String = "",
        contentTitle: String,
        itemTitle: String = "",
        timecodeSeconds: Double = 0,
        offsetSeconds: Double = 0,
        transcript: String = "",
        audioFileName: String = "",
        durationSeconds: Double = 0,
        status: Status = .transcribing,
        createdAt: Date = .now
    ) {
        self.contentKindRaw = contentKind.rawValue
        self.contentID = contentID
        self.itemFileName = itemFileName
        self.contentTitle = contentTitle
        self.itemTitle = itemTitle
        self.timecodeSeconds = timecodeSeconds
        self.offsetSeconds = offsetSeconds
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.durationSeconds = durationSeconds
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }

    var contentKind: ContentKind {
        get { ContentKind(rawValue: contentKindRaw) ?? .track }
        set { contentKindRaw = newValue.rawValue }
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .transcribing }
        set { statusRaw = newValue.rawValue }
    }

    /// What the Notes list shows for this note's body.
    var displayText: String {
        switch status {
        case .transcribed: transcript.isEmpty ? "Audio note" : transcript
        case .transcribing: "Transcribing…"
        case .unavailable: "Audio note — transcription unavailable"
        case .failed: "Audio note — transcription failed"
        }
    }
}
