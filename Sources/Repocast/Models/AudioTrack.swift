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

    init(
        title: String,
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
