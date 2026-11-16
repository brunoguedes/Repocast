import Foundation

/// Narration package layout for tour episodes — the same names the backend
/// writes (`backend/src/lib/package.ts`), so a cloud and an on-device episode
/// differ only in their audio extension. See the root CLAUDE.md for the
/// contract. Never write a stitched `<base>.<ext>`: it would hide the parts,
/// and the parts are the episode's chapters.
enum TourPackage {
    struct Section: Sendable {
        let title: String
        let paragraphs: [String]

        var text: String { paragraphs.joined(separator: "\n\n") }
    }

    /// `Repocast_architecture`.
    static func baseName(repoName: String, kind: TourEpisode.Kind) -> String {
        let safe = repoName.replacing(/[^A-Za-z0-9._-]/, with: "_")
        return "\(safe)_\(kind.rawValue)"
    }

    /// "Repocast — Architecture".
    static func playlistTitle(repoName: String, kind: TourEpisode.Kind) -> String {
        "\(repoName) — \(kind.label)"
    }

    static func partFileName(base: String, index: Int, ext: String) -> String {
        "\(base)_part\(index + 1).\(ext)"
    }

    static func transcriptFileName(base: String, index: Int) -> String {
        "\(base)_part\(index + 1).txt"
    }

    /// Stable library identity, so regenerating an episode replaces its
    /// `NarrationPackage` instead of adding a second one.
    static func identitySource(repoFullName: String, kind: TourEpisode.Kind, executor: TourEpisode.Executor) -> String {
        "tour://\(repoFullName)/\(kind.rawValue)/\(executor.rawValue)"
    }

    /// `<base>.m3u8` with titles, rounded durations and `#EXT-TRANSCRIPT`.
    static func playlist(title: String, base: String, parts: [NarrationManifest.Part]) -> String {
        var lines = ["#EXTM3U", "#PLAYLIST:\(title)"]
        for (index, part) in parts.enumerated() {
            lines.append("#EXTINF:\(Int((part.durationSeconds ?? 0).rounded())),\(part.title)")
            lines.append("#EXT-TRANSCRIPT:\(transcriptFileName(base: base, index: index))")
            lines.append(part.file)
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

/// Word budgets per episode. The cloud figures match the backend's
/// `EPISODE_WORD_CAP`; on device the model's context window allows far less.
enum TourBudget {
    static let wordsPerMinute = 150

    static func maxWords(_ kind: TourEpisode.Kind, executor: TourEpisode.Executor) -> Int {
        switch (kind, executor) {
        case (.intro, .cloud): 900
        case (.architecture, .cloud): 2000
        case (.intro, .device): 350
        case (.architecture, .device): 500
        }
    }

    static func estimatedMinutes(_ kind: TourEpisode.Kind, executor: TourEpisode.Executor) -> Int {
        Int((Double(maxWords(kind, executor: executor)) / Double(wordsPerMinute)).rounded(.up))
    }
}
