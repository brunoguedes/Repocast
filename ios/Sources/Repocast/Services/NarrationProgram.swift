import AVFoundation
import Foundation

/// What actually plays when a narration package is opened: either the single
/// stitched file or the part files in order, each paired with the best
/// transcript the package can offer. Built fresh from the stored folder every
/// time (import, detail screen, play) so it always reflects what's on disk.
struct NarrationProgram: Sendable {
    struct Part: Identifiable, Sendable {
        /// File name within the package folder — the stable identity resume
        /// positions are keyed on.
        let fileName: String
        let url: URL
        let title: String
        let duration: Double
        let transcript: String

        var id: String { fileName }
    }

    let title: String
    /// `true` when this is the stitched `<base>.mp3` as one continuous track
    /// (in which case `parts` has a single element).
    let isStitched: Bool
    let parts: [Part]
    /// The TTS voice from the files' ID3 artist tag, if present.
    let voice: String?

    var totalDuration: Double { parts.reduce(0) { $0 + $1.duration } }
}

/// Assembles a `NarrationProgram` from a package folder, honouring the format's
/// degradation rules:
/// - The stitched `<base>.mp3` (an mp3 with no `_partN` suffix) wins over the
///   parts when present.
/// - Part order comes from the playlist; without a usable playlist, parts sort
///   by ID3 track number, then by numeric part suffix (part 10 after part 9).
/// - Transcript per track: the `#EXT-TRANSCRIPT:` file → the same-stem `.txt` →
///   the mp3's embedded USLT lyrics → empty. The stitched file additionally
///   falls back to the part transcripts concatenated in order.
struct NarrationProgramBuilder: Sendable {

    /// Build the program for the package folder at `directory`, or `nil` when
    /// no audio belonging to `baseName` exists there.
    func build(directory: URL, baseName: String) async -> NarrationProgram? {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return nil }

        let playlist = loadPlaylist(directory: directory, baseName: baseName)
        let title = playlist?.title ?? baseName
        let partNames = orderedPartFileNames(in: directory, names: names, baseName: baseName, playlist: playlist)

        let stitchedName = "\(baseName).mp3"
        if names.contains(stitchedName) {
            let url = directory.appendingPathComponent(stitchedName)
            let tag = ID3Tag.read(from: url)
            let transcript = stitchedTranscript(
                directory: directory, baseName: baseName, tag: tag, partNames: partNames, playlist: playlist
            )
            let part = NarrationProgram.Part(
                fileName: stitchedName,
                url: url,
                title: title,
                duration: await assetDuration(of: url) ?? 0,
                transcript: transcript
            )
            return NarrationProgram(title: title, isStitched: true, parts: [part], voice: tag?.artist)
        }

        guard !partNames.isEmpty else { return nil }
        var parts: [NarrationProgram.Part] = []
        var voice: String?
        for fileName in partNames {
            let url = directory.appendingPathComponent(fileName)
            let tag = ID3Tag.read(from: url)
            let entry = playlist?.entries.first { $0.fileName == fileName }
            if voice == nil { voice = tag?.artist }
            parts.append(
                NarrationProgram.Part(
                    fileName: fileName,
                    url: url,
                    title: entry?.title ?? tag?.title ?? (fileName as NSString).deletingPathExtension,
                    duration: await assetDuration(of: url) ?? entry?.durationSeconds ?? 0,
                    transcript: partTranscript(for: fileName, in: directory, tag: tag, playlist: playlist)
                )
            )
        }
        return NarrationProgram(title: title, isStitched: false, parts: parts, voice: voice)
    }

    // MARK: Part discovery + ordering

    /// The part mp3s in playback order: the playlist's order when it lists
    /// files that exist, else the naming-convention scan sorted by ID3 track
    /// number then numeric part suffix.
    private func orderedPartFileNames(
        in directory: URL, names: [String], baseName: String, playlist: M3UPlaylist?
    ) -> [String] {
        if let playlist {
            let existing = playlist.entries.map(\.fileName).filter { names.contains($0) }
            if !existing.isEmpty { return existing }
        }
        let found = Self.partFileNames(in: names, baseName: baseName)
        return Self.fallbackOrder(found) { fileName in
            ID3Tag.read(from: directory.appendingPathComponent(fileName))?.trackNumber
        }
    }

    /// The mp3s following the `<base>_partN.mp3` naming convention.
    static func partFileNames(in names: [String], baseName: String) -> [String] {
        names.filter { name in
            let stem = (name as NSString).deletingPathExtension
            return (name as NSString).pathExtension.lowercased() == "mp3"
                && stem.hasPrefix("\(baseName)_part")
                && partNumber(in: name) != nil
        }
    }

    /// Ordering when the playlist is unusable: ID3 track number first, then
    /// numeric part suffix (so part 10 follows part 9, not part 1), then name.
    static func fallbackOrder(_ fileNames: [String], trackNumber: (String) -> Int?) -> [String] {
        fileNames
            .map { (name: $0, track: trackNumber($0) ?? Int.max, part: partNumber(in: $0) ?? Int.max) }
            .sorted {
                if $0.track != $1.track { return $0.track < $1.track }
                if $0.part != $1.part { return $0.part < $1.part }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            .map(\.name)
    }

    /// The `N` in a `<base>_partN.<ext>` file name, or `nil`.
    static func partNumber(in fileName: String) -> Int? {
        let stem = (fileName as NSString).deletingPathExtension
        guard let match = stem.firstMatch(of: /_part(\d+)$/) else { return nil }
        return Int(match.1)
    }

    // MARK: Transcripts

    /// Fallback chain for one part: explicit `#EXT-TRANSCRIPT:` file →
    /// same-stem `.txt` → embedded USLT lyrics → empty.
    private func partTranscript(
        for fileName: String, in directory: URL, tag: ID3Tag?, playlist: M3UPlaylist?
    ) -> String {
        let entry = playlist?.entries.first { $0.fileName == fileName }
        if let explicit = entry?.transcriptFileName,
           let text = textFile(named: explicit, in: directory) {
            return text
        }
        let stem = (fileName as NSString).deletingPathExtension
        if let text = textFile(named: "\(stem).txt", in: directory) {
            return text
        }
        return tag?.lyrics ?? ""
    }

    /// Fallback chain for the stitched file: `<base>.txt` → its USLT lyrics →
    /// the part transcripts concatenated in order.
    private func stitchedTranscript(
        directory: URL, baseName: String, tag: ID3Tag?, partNames: [String], playlist: M3UPlaylist?
    ) -> String {
        if let text = textFile(named: "\(baseName).txt", in: directory) {
            return text
        }
        if let lyrics = tag?.lyrics {
            return lyrics
        }
        let partTexts = partNames
            .map { name in
                partTranscript(
                    for: name, in: directory,
                    tag: ID3Tag.read(from: directory.appendingPathComponent(name)),
                    playlist: playlist
                )
            }
            .filter { !$0.isEmpty }
        return partTexts.joined(separator: "\n\n")
    }

    // MARK: Helpers

    private func loadPlaylist(directory: URL, baseName: String) -> M3UPlaylist? {
        let url = directory.appendingPathComponent("\(baseName).m3u8")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return M3UPlaylist.parse(text)
    }

    private func textFile(named name: String, in directory: URL) -> String? {
        let url = directory.appendingPathComponent(name)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The asset's real duration — preferred over `#EXTINF`, which is rounded
    /// to whole seconds (and may be `-1`), because the continuous timeline's
    /// part-boundary math needs accurate lengths.
    private func assetDuration(of url: URL) async -> Double? {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return nil }
        let seconds = duration.seconds
        return seconds.isFinite && seconds > 0 ? seconds : nil
    }
}
