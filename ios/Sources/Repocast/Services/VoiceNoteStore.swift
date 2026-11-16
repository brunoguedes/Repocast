import Foundation

/// Owns the on-disk home of recorded voice notes (`Documents/Notes/`).
/// Mirrors `AudioFileStore`: `VoiceNote.audioFileName` stores only the file
/// name and resolves it through here.
struct VoiceNoteStore: Sendable {
    private let directory: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("Notes", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// A fresh, collision-free filename for a new note. `.m4a` because the
    /// recorder writes AAC — small files, and speech recognition reads it fine.
    func makeFileName() -> String { "\(UUID().uuidString).m4a" }

    func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    func exists(_ fileName: String) -> Bool {
        guard !fileName.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: url(for: fileName).path)
    }

    func delete(_ fileName: String) {
        guard !fileName.isEmpty else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
