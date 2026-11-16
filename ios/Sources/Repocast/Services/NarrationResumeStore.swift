import Foundation

/// Persists per-package playback position so a narration resumes where the
/// listener stopped. Keyed by the package's stable `identifier` (not an array
/// index) and stored in `UserDefaults` rather than SwiftData: it's written
/// every few seconds during playback via the player's progress callback, and
/// the player deliberately never touches managed objects (see `PlayableItem`).
struct NarrationResumeStore {
    struct Position: Codable, Sendable, Equatable {
        /// File name (within the package folder) of the track that was playing.
        var fileName: String
        var offsetSeconds: Double
        var updatedAt: Date
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func position(for identifier: String) -> Position? {
        guard let data = defaults.data(forKey: key(identifier)) else { return nil }
        return try? JSONDecoder().decode(Position.self, from: data)
    }

    func save(_ position: Position, for identifier: String) {
        guard let data = try? JSONEncoder().encode(position) else { return }
        defaults.set(data, forKey: key(identifier))
    }

    func clear(for identifier: String) {
        defaults.removeObject(forKey: key(identifier))
    }

    /// The saved position, but only if its file is still part of the package —
    /// a regenerated folder invalidates the stale position (which is discarded
    /// here) so playback starts from the beginning instead of crashing.
    func validatedPosition(for identifier: String, among fileNames: Set<String>) -> Position? {
        guard let position = position(for: identifier) else { return nil }
        guard fileNames.contains(position.fileName) else {
            clear(for: identifier)
            return nil
        }
        return position
    }

    private func key(_ identifier: String) -> String {
        "narration.resume.\(identifier)"
    }
}
