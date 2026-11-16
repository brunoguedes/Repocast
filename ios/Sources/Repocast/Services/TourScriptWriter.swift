import Foundation
import FoundationModels

/// What the model returns for an episode: sections become narration parts.
@Generable
struct TourScript {
    @Generable
    struct Section {
        @Guide(description: "A short spoken title of at most six words")
        let title: String
        @Guide(description: "Spoken paragraphs of two to five plain sentences each")
        let paragraphs: [String]
    }

    @Guide(description: "The episode's sections in listening order", .count(2...5))
    let sections: [Section]
}

/// What the index asks the model for.
@Generable
struct TourIndexSummary {
    @Guide(description: "One spoken paragraph of at most 80 words")
    let summary: String
    @Guide(description: "Intro episode title, at most 8 words")
    let introTitle: String
    @Guide(description: "Architecture episode title, at most 8 words")
    let architectureTitle: String
}

/// Writes tour scripts with Apple's on-device model, from the shared prompts.
/// The on-device context window is small, so long repo material is first
/// condensed chunk by chunk (`SummarizationService.chunk`, 6,000 characters)
/// into notes, and the script is written from the notes. Expected to be
/// weaker than the cloud script — that is the upgrade pitch.
protocol TourScriptWriting: Sendable {
    var isAvailable: Bool { get }
    var unavailableReason: String? { get }
    func summarize(repo: String, classification: RepoClassification, material: String) async throws -> TourIndexSummary
    func script(kind: TourEpisode.Kind, repo: String, summary: String, material: String) async throws -> [TourPackage.Section]
}

struct TourScriptWriter: TourScriptWriting {
    private static let maxCharsPerCall = 6000
    private let availability = SummarizationService()

    var isAvailable: Bool { availability.isAvailable }
    var unavailableReason: String? { availability.unavailableReason }

    func summarize(repo: String, classification: RepoClassification, material: String) async throws -> TourIndexSummary {
        guard isAvailable else { throw SummarizationService.SummarizationError.unavailable }
        let instructions = TourPrompts.load(.indexSummary, values: ["repo": repo, "classification": classification.rawValue])
        let notes = try await condense(material, focus: "what the project is, who it is for, and what it is built with")
        return try await LanguageModelSession()
            .respond(to: "\(instructions)\n\n---\n\n\(notes)", generating: TourIndexSummary.self)
            .content
    }

    func script(kind: TourEpisode.Kind, repo: String, summary: String, material: String) async throws -> [TourPackage.Section] {
        guard isAvailable else { throw SummarizationService.SummarizationError.unavailable }
        let maxWords = TourBudget.maxWords(kind, executor: .device)
        let instructions = TourPrompts.load(
            TourPrompts.Name(kind),
            values: ["repo": repo, "summary": summary, "maxWords": String(maxWords)]
        )
        let focus = switch kind {
        case .intro: "the project's purpose, audience, problem, main features and technology"
        case .architecture: "entry points, layers and components, how data and control flow between them, where state lives, and key dependencies"
        }
        let notes = try await condense(material, focus: focus)
        let script = try await LanguageModelSession()
            .respond(to: "\(instructions)\n\n---\n\n\(notes)", generating: TourScript.self)
            .content
        return script.sections
            .map { TourPackage.Section(title: $0.title, paragraphs: $0.paragraphs.filter { !$0.isEmpty }) }
            .filter { !$0.paragraphs.isEmpty }
    }

    /// Short material passes straight through; longer material becomes notes,
    /// one model call per chunk, so the final prompt fits the context window.
    private func condense(_ material: String, focus: String) async throws -> String {
        let chunks = SummarizationService.chunk(material, maxChars: Self.maxCharsPerCall)
        guard chunks.count > 1 else { return material }
        var notes: [String] = []
        for chunk in chunks.prefix(6) {
            let prompt = """
            Take brief factual notes from this part of a code repository, about \(focus). \
            Plain sentences, at most 120 words. Skip anything unrelated.

            ---

            \(chunk)
            """
            notes.append(try await LanguageModelSession().respond(to: prompt).content)
        }
        return notes.joined(separator: "\n\n")
    }
}
