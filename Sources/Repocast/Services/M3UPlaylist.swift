import Foundation

/// A parsed extended-M3U playlist (`<base>.m3u8` inside a narration package).
/// Pure value parsing — no file I/O — so it's trivially unit-testable; the
/// `NarrationProgramBuilder` decides what to do when entries reference files
/// that don't exist.
///
/// Recognised directives:
/// - `#PLAYLIST:<name>` — display name for the whole package.
/// - `#EXTINF:<seconds>,<title>` — next entry's duration and title. A negative
///   duration (the `-1` convention) means unknown; it's surfaced as `nil` so
///   callers read the real duration from the asset instead.
/// - `#EXT-TRANSCRIPT:<file>` — nonstandard comment linking the next entry to
///   its transcript text file.
///
/// Every other `#` line is ignored; any non-comment line is a media entry
/// (relative path). CRLF endings and a missing `#EXTM3U` header are tolerated.
struct M3UPlaylist: Sendable, Equatable {
    struct Entry: Sendable, Equatable {
        var fileName: String
        var title: String?
        /// `nil` when absent or negative (`#EXTINF:-1` = unknown).
        var durationSeconds: Double?
        var transcriptFileName: String?

        init(
            fileName: String,
            title: String? = nil,
            durationSeconds: Double? = nil,
            transcriptFileName: String? = nil
        ) {
            self.fileName = fileName
            self.title = title
            self.durationSeconds = durationSeconds
            self.transcriptFileName = transcriptFileName
        }
    }

    var title: String?
    var entries: [Entry] = []

    static func parse(_ text: String) -> M3UPlaylist {
        var playlist = M3UPlaylist()
        var pendingTitle: String?
        var pendingDuration: Double?
        var pendingTranscript: String?

        // Split on the newline character *set*: CRLF is a single Swift
        // `Character`, so splitting on "\n" would miss Windows-style endings.
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if let name = value(of: "#PLAYLIST:", in: line) {
                playlist.title = name.isEmpty ? nil : name
            } else if let info = value(of: "#EXTINF:", in: line) {
                // "<seconds>,<title>" — the title may itself contain commas.
                let comma = info.firstIndex(of: ",")
                let durationField = comma.map { String(info[..<$0]) } ?? info
                let titleField = comma.map { String(info[info.index(after: $0)...]) } ?? ""
                let seconds = Double(durationField.trimmingCharacters(in: .whitespaces))
                pendingDuration = (seconds ?? -1) >= 0 ? seconds : nil
                let title = titleField.trimmingCharacters(in: .whitespaces)
                pendingTitle = title.isEmpty ? nil : title
            } else if let file = value(of: "#EXT-TRANSCRIPT:", in: line) {
                pendingTranscript = file.isEmpty ? nil : file
            } else if line.hasPrefix("#") {
                continue
            } else {
                var fileName = line
                if fileName.hasPrefix("./") { fileName.removeFirst(2) }
                playlist.entries.append(
                    Entry(
                        fileName: fileName,
                        title: pendingTitle,
                        durationSeconds: pendingDuration,
                        transcriptFileName: pendingTranscript
                    )
                )
                pendingTitle = nil
                pendingDuration = nil
                pendingTranscript = nil
            }
        }
        return playlist
    }

    private static func value(of directive: String, in line: String) -> String? {
        guard line.hasPrefix(directive) else { return nil }
        return String(line.dropFirst(directive.count)).trimmingCharacters(in: .whitespaces)
    }
}
