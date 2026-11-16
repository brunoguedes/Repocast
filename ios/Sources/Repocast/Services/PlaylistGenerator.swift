import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device smart-playlist curation. Given the user's brief and their library,
/// Apple Intelligence picks an ordered subset of tracks and names the playlist —
/// using FoundationModels *guided generation* so the result is a typed value,
/// not free text to parse. Fully on-device; the library never leaves the phone.
///
/// Mirrors `SummarizationService`: gate on `isAvailable`, and surface a typed
/// error so the UI can fall back (e.g. offer a manual playlist) when the model
/// is unavailable.
protocol PlaylistCurating: Sendable {
    var isAvailable: Bool { get }
    func curate(brief: String, from candidates: [TrackChoice]) async throws -> SmartPlaylistPlan
}

/// A `Sendable` projection of an `AudioTrack` — just what the model is shown.
/// Keeps the (non-Sendable) SwiftData models on the main actor; the curator
/// only ever receives titles and a little context.
struct TrackChoice: Sendable {
    let title: String
    let sourceKind: String
    let durationSeconds: Double
}

/// The typed result of curation. Track choices are returned as titles and
/// re-bound to `AudioTrack`s by the caller (the model only sees text, never the
/// persistent models).
struct SmartPlaylistPlan: Sendable {
    var title: String
    var rationale: String
    /// Chosen track titles, in listening order.
    var trackTitles: [String]
}

#if canImport(FoundationModels)

/// A `@Generable` shadow of `SmartPlaylistPlan` — this is what the model fills.
@Generable
private struct GeneratedPlaylist {
    @Guide(description: "A short, human title for the playlist — 2 to 5 words, no quotes.")
    var title: String

    @Guide(description: "One sentence on why these tracks, in plain spoken English.")
    var rationale: String

    @Guide(description: "The chosen file titles in listening order. Use only titles from the provided list. Pick 3 to 8.")
    var trackTitles: [String]
}

struct PlaylistGenerator: PlaylistCurating {
    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    func curate(brief: String, from candidates: [TrackChoice]) async throws -> SmartPlaylistPlan {
        guard isAvailable else { throw PlaylistGenerationError.unavailable }

        // The model only ever sees titles + a little context — never transcripts.
        let menu = candidates.map { track in
            "- \(track.title) [\(track.sourceKind), \(Int(track.durationSeconds))s]"
        }.joined(separator: "\n")

        let instructions = """
        You build listening playlists from a developer's audio library. Choose \
        tracks that fit the user's request and order them so they flow well for \
        hands-free listening. Only choose from the provided tracks.
        """

        let prompt = """
        Request: \(brief)

        Available tracks:
        \(menu)
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt, generating: GeneratedPlaylist.self)
        let plan = response.content

        // Keep only titles that actually exist, de-duplicated, order preserved.
        let known = Set(candidates.map(\.title))
        var seen = Set<String>()
        let titles = plan.trackTitles.filter { known.contains($0) && seen.insert($0).inserted }

        return SmartPlaylistPlan(
            title: plan.title.trimmingCharacters(in: .whitespacesAndNewlines),
            rationale: plan.rationale,
            trackTitles: titles
        )
    }
}

#else

/// Compiles where FoundationModels is unavailable (e.g. some CI). Always reports
/// unavailable so callers take the manual-playlist path.
struct PlaylistGenerator: PlaylistCurating {
    var isAvailable: Bool { false }
    func curate(brief: String, from candidates: [TrackChoice]) async throws -> SmartPlaylistPlan {
        throw PlaylistGenerationError.unavailable
    }
}

#endif

enum PlaylistGenerationError: LocalizedError {
    case unavailable
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .unavailable: "On-device playlist generation isn't available right now."
        case .emptyResult: "Couldn't find tracks that fit. Try a different description."
        }
    }
}
