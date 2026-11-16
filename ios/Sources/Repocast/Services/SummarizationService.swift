import Foundation
import FoundationModels

/// Turns source text into a short, spoken-friendly narration using Apple's
/// on-device model (`FoundationModels`). Everything stays on device. When the
/// model isn't available (ineligible hardware, Apple Intelligence off, or the
/// model still downloading) `narrate` throws `.unavailable` and the caller falls
/// back to reading the text verbatim — see `TrackGenerator`.
protocol Summarizing: Sendable {
    /// Whether the on-device model can be used right now.
    var isAvailable: Bool { get }
    /// A human-readable reason the model is unavailable, or `nil` when available.
    var unavailableReason: String? { get }
    /// Produce TTS-ready narration for `text`. Throws if the model is unavailable.
    func narrate(_ text: String, kind: AudioTrack.SourceKind) async throws -> String
}

struct SummarizationService: Summarizing {
    enum SummarizationError: LocalizedError {
        case unavailable
        var errorDescription: String? {
            "On-device summarization isn't available right now."
        }
    }

    /// Roughly how many characters of source to send per model call. Code files
    /// easily exceed the context window, so longer input is summarized in chunks
    /// and the chunk summaries are combined in a final pass.
    private static let maxCharsPerCall = 6000

    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings to enable AI summaries."
        case .unavailable(.modelNotReady):
            return "The on-device model is still downloading. Try again shortly."
        case .unavailable:
            return "On-device summarization is unavailable."
        }
    }

    func narrate(_ text: String, kind: AudioTrack.SourceKind) async throws -> String {
        guard isAvailable else { throw SummarizationError.unavailable }

        let chunks = Self.chunk(text, maxChars: Self.maxCharsPerCall)
        var summaries: [String] = []
        summaries.reserveCapacity(chunks.count)
        for chunk in chunks {
            summaries.append(try await summarize(chunk, kind: kind, combining: false))
        }

        guard summaries.count > 1 else { return summaries.first ?? "" }

        // Combine the per-chunk summaries into one cohesive narration.
        let joined = summaries.enumerated()
            .map { "Part \($0.offset + 1): \($0.element)" }
            .joined(separator: "\n\n")
        return try await summarize(joined, kind: kind, combining: true)
    }

    // MARK: - Internals

    private func summarize(_ text: String, kind: AudioTrack.SourceKind, combining: Bool) async throws -> String {
        let session = LanguageModelSession()
        let prompt = "\(Self.instructions(for: kind, combining: combining))\n\n---\n\n\(text)"
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func instructions(for kind: AudioTrack.SourceKind, combining: Bool) -> String {
        if combining {
            return """
            Combine these partial summaries into one cohesive spoken briefing. \
            Remove repetition. Plain spoken English only — no markdown, headings, \
            bullet points, or symbols.
            """
        }
        switch kind {
        case .code:
            return """
            You are turning a source code file into a short audio briefing for a \
            developer listening hands-free while driving or exercising. Explain in \
            plain spoken English what this file does — its main types, functions, \
            and anything notable. Do not read code aloud. No markdown, symbols, or \
            bullet points. Short, natural sentences. Keep it under about 180 words.
            """
        case .changes:
            return """
            You are narrating recent changes to a code repository for a developer \
            listening hands-free. Summarize what changed and why it matters in plain \
            spoken English. No code, no markdown, no symbols. Keep it concise.
            """
        case .markdown, .freeform:
            return """
            You are turning a document into a short audio briefing for someone \
            listening hands-free. Summarize the key points in plain spoken English \
            suitable for text-to-speech. No markdown, headings, bullet points, or \
            symbols — just natural sentences. Keep it concise.
            """
        }
    }

    /// Split text into chunks no larger than `maxChars`, breaking on line
    /// boundaries so a chunk never splits mid-line.
    static func chunk(_ text: String, maxChars: Int) -> [String] {
        guard text.count > maxChars else { return [text] }
        var chunks: [String] = []
        var current = ""
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if !current.isEmpty, current.count + line.count + 1 > maxChars {
                chunks.append(current)
                current = ""
            }
            current += line + "\n"
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chunks.append(current)
        }
        return chunks.isEmpty ? [text] : chunks
    }
}
