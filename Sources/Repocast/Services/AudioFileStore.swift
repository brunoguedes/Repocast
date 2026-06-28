import Foundation

/// Owns the on-disk home of generated audio (`Documents/Audio/`). The rest of
/// the app stores only the *filename* in `AudioTrack.audioFileName` and resolves
/// it through here — mirroring how the photo apps keep bytes on disk and
/// metadata in the database.
struct AudioFileStore: Sendable {
    private let directory: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("Audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// A fresh, collision-free filename for a new track. `.caf` holds the LPCM
    /// the speech synthesizer emits without a transcode step.
    func makeFileName() -> String { "\(UUID().uuidString).caf" }

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
