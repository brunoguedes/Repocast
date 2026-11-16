import Foundation
import SwiftData

/// Orchestrates the (Phase 1) pipeline: text → offline TTS → file on disk →
/// persisted `AudioTrack`. This is the seed of the full
/// `TrackGenerationCoordinator` described in CLAUDE.md; later phases insert a
/// GitHub fetch (source text) and an on-device summarization step ahead of the
/// synthesizer. For now it reads the supplied text verbatim.
@MainActor
@Observable
final class TrackGenerator {
    enum Phase: Equatable {
        case idle
        case generating
        case failed(String)
    }

    private(set) var phase: Phase = .idle

    private let synthesizer: SpeechSynthesizing
    private let summarizer: Summarizing
    private let files: AudioFileStore

    init(
        synthesizer: SpeechSynthesizing = SpeechSynthesisService(),
        summarizer: Summarizing = SummarizationService(),
        files: AudioFileStore = AudioFileStore()
    ) {
        self.synthesizer = synthesizer
        self.summarizer = summarizer
        self.files = files
    }

    /// Generate one track. `repoFullName` / `sourcePath` / `sourceKind` record
    /// where the text came from (a repo file vs. pasted freeform text). Returns
    /// `true` on success so batch callers (e.g. the repo file browser) can count
    /// results.
    @discardableResult
    func generate(
        title: String,
        text: String,
        kind: AudioTrack.GenerationKind,
        repoFullName: String? = nil,
        sourcePath: String = "",
        sourceKind: AudioTrack.SourceKind = .freeform,
        voiceIdentifier: String?,
        rate: Float,
        into context: ModelContext
    ) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        phase = .generating
        let fileName = files.makeFileName()
        let url = files.url(for: fileName)

        do {
            // Route `.summary` through the on-device model; fall back to reading
            // the text verbatim if the model is unavailable or errors, so the
            // user always gets audio. `usedKind` reflects what actually happened.
            var narration = trimmed
            var usedKind = kind
            if kind == .summary {
                if summarizer.isAvailable {
                    do {
                        narration = try await summarizer.narrate(trimmed, kind: sourceKind)
                    } catch {
                        narration = trimmed
                        usedKind = .verbatim
                        AnalyticsService.logSummaryFallback()
                    }
                } else {
                    usedKind = .verbatim
                    AnalyticsService.logSummaryFallback()
                }
            }
            let duration = try await synthesizer.render(
                text: narration,
                voiceIdentifier: voiceIdentifier,
                rate: rate,
                pitch: 1.0,
                to: url
            )

            let track = AudioTrack(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title,
                repoFullName: repoFullName,
                sourcePath: sourcePath,
                sourceKind: sourceKind,
                generationKind: usedKind,
                transcript: narration,
                audioFileName: fileName,
                durationSeconds: duration,
                voiceIdentifier: voiceIdentifier,
                status: .ready
            )
            context.insert(track)
            try? context.save()

            phase = .idle
            AnalyticsService.logTrackGenerated(kind: usedKind.rawValue)
            return true
        } catch {
            files.delete(fileName)
            phase = .failed(error.localizedDescription)
            AnalyticsService.logTrackGenerationFailed()
            return false
        }
    }
}
