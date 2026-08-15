import CryptoKit
import Foundation
import Observation
import SwiftData

/// Imports a narration package the user picked in the document picker:
/// validates the folder, **copies it into the app container**
/// (`NarrationPackageStore`) so playback never depends on the source staying
/// reachable, and upserts the `NarrationPackage` library item. Mirrors
/// `TrackGenerator`'s shape — a `@MainActor @Observable` orchestrator whose
/// `phase` drives the importing UI.
///
/// Identity is a hash of the source folder path + base name (not an array
/// index or bookmark), so picking the same folder again — even after its
/// contents were regenerated — updates the existing item in place.
@MainActor
@Observable
final class NarrationImporter {
    enum Phase: Equatable {
        case idle
        case importing
        case failed(String)
    }

    private(set) var phase: Phase = .idle

    private let store: NarrationPackageStore
    private let resumeStore: NarrationResumeStore
    private let builder: NarrationProgramBuilder

    init(
        store: NarrationPackageStore = NarrationPackageStore(),
        resumeStore: NarrationResumeStore = NarrationResumeStore(),
        builder: NarrationProgramBuilder = NarrationProgramBuilder()
    ) {
        self.store = store
        self.resumeStore = resumeStore
        self.builder = builder
    }

    /// Import (or re-import) the folder at `folderURL`. Returns `true` on
    /// success so callers can dismiss pickers / count results.
    @discardableResult
    func importPackage(from folderURL: URL, into context: ModelContext) async -> Bool {
        phase = .importing
        // The document picker hands out security-scoped URLs; access lasts
        // only long enough to copy the folder into the app container.
        let isScoped = folderURL.startAccessingSecurityScopedResource()
        defer { if isScoped { folderURL.stopAccessingSecurityScopedResource() } }

        do {
            let names = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            guard let baseName = Self.detectBaseName(in: names) else {
                throw ImportError.notAPackage
            }
            let sourcePath = folderURL.standardizedFileURL.path
            let identifier = Self.identifier(sourcePath: sourcePath, baseName: baseName)

            // Copy off the main actor — packages can be tens of MB.
            let store = store
            try await Task.detached(priority: .userInitiated) {
                try store.replaceContents(for: identifier, with: folderURL)
            }.value

            let directory = store.directory(for: identifier)
            guard let program = await builder.build(directory: directory, baseName: baseName),
                  !program.parts.isEmpty else {
                store.delete(identifier)
                throw ImportError.noAudio
            }

            // A regenerated folder may have dropped the file a stale resume
            // position points at; validating discards it now rather than at
            // play time.
            _ = resumeStore.validatedPosition(for: identifier, among: Set(program.parts.map(\.fileName)))

            let partCount = NarrationProgramBuilder.partFileNames(in: names, baseName: baseName).count
            upsert(
                identifier: identifier,
                title: program.title,
                baseName: baseName,
                sourcePath: sourcePath,
                voice: program.voice,
                partCount: partCount,
                hasStitched: program.isStitched,
                totalDuration: program.totalDuration,
                into: context
            )
            try? context.save()

            phase = .idle
            AnalyticsService.logNarrationImported(parts: partCount, stitched: program.isStitched)
            return true
        } catch {
            phase = .failed((error as? ImportError)?.message ?? error.localizedDescription)
            AnalyticsService.logNarrationImportFailed()
            return false
        }
    }

    /// Return the failure phase to idle once the user has seen the alert.
    func dismissFailure() {
        if case .failed = phase { phase = .idle }
    }

    // MARK: Package identity

    /// The package's base name: the playlist file's stem, else the most common
    /// `_partN` prefix, else a lone mp3's stem. `nil` when the folder holds no
    /// recognisable narration files.
    nonisolated static func detectBaseName(in names: [String]) -> String? {
        let stems = { (ext: String) in
            names.filter { ($0 as NSString).pathExtension.lowercased() == ext }
                .map { ($0 as NSString).deletingPathExtension }
                .sorted()
        }
        if let playlist = stems("m3u8").first { return playlist }

        let partBases = names.compactMap { name -> String? in
            guard (name as NSString).pathExtension.lowercased() == "mp3" else { return nil }
            let stem = (name as NSString).deletingPathExtension
            guard let match = stem.firstMatch(of: /^(.+)_part\d+$/) else { return nil }
            return String(match.1)
        }
        if let commonest = Dictionary(grouping: partBases, by: { $0 })
            .max(by: { ($0.value.count, $1.key) < ($1.value.count, $0.key) })?.key {
            return commonest
        }

        let mp3s = stems("mp3")
        return mp3s.count == 1 ? mp3s[0] : nil
    }

    nonisolated static func identifier(sourcePath: String, baseName: String) -> String {
        let digest = SHA256.hash(data: Data("\(sourcePath)\n\(baseName)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(16).lowercased()
    }

    // MARK: Internals

    private func upsert(
        identifier: String,
        title: String,
        baseName: String,
        sourcePath: String,
        voice: String?,
        partCount: Int,
        hasStitched: Bool,
        totalDuration: Double,
        into context: ModelContext
    ) {
        let descriptor = FetchDescriptor<NarrationPackage>(
            predicate: #Predicate { $0.identifier == identifier }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.title = title
            existing.baseName = baseName
            existing.sourcePath = sourcePath
            existing.voiceName = voice
            existing.partCount = partCount
            existing.hasStitched = hasStitched
            existing.totalDurationSeconds = totalDuration
            existing.importedAt = .now
        } else {
            context.insert(
                NarrationPackage(
                    title: title,
                    baseName: baseName,
                    identifier: identifier,
                    sourcePath: sourcePath,
                    voiceName: voice,
                    partCount: partCount,
                    hasStitched: hasStitched,
                    totalDurationSeconds: totalDuration
                )
            )
        }
    }

    private enum ImportError: Error {
        case notAPackage
        case noAudio

        var message: String {
            switch self {
            case .notAPackage:
                "That folder doesn't look like a narration package — no playlist or numbered audio files were found."
            case .noAudio:
                "No playable audio files were found in the package."
            }
        }
    }
}
