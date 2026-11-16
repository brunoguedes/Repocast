import Foundation

/// Owns the on-disk home of imported narration packages
/// (`Documents/Narrations/<identifier>/`). Mirrors `AudioFileStore`: the
/// `NarrationPackage` model stores only its `identifier` (the folder name) and
/// per-file names, and resolves them through here — imported bytes live in the
/// app container, so playback never depends on the source folder still being
/// reachable.
struct NarrationPackageStore: Sendable {
    private let root: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        root = documents.appendingPathComponent("Narrations", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func directory(for identifier: String) -> URL {
        root.appendingPathComponent(identifier, isDirectory: true)
    }

    func url(forFileName fileName: String, in identifier: String) -> URL {
        directory(for: identifier).appendingPathComponent(fileName)
    }

    func exists(_ identifier: String) -> Bool {
        FileManager.default.fileExists(atPath: directory(for: identifier).path)
    }

    /// Replace the package's stored folder with a copy of `folderURL` — this is
    /// what makes re-importing the same source update in place rather than
    /// accumulate duplicates.
    func replaceContents(for identifier: String, with folderURL: URL) throws {
        let destination = directory(for: identifier)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: folderURL, to: destination)
    }

    func delete(_ identifier: String) {
        guard !identifier.isEmpty else { return }
        try? FileManager.default.removeItem(at: directory(for: identifier))
    }
}
