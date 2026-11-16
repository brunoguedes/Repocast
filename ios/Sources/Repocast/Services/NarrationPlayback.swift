import Foundation
import SwiftData

/// Starts narration-package playback on the player — the one place that knows
/// how a package becomes a continuous queue with resume persistence. Shared by
/// the SwiftUI detail screen and the CarPlay list so resume, rewind, and
/// position saving behave identically on every screen.
@MainActor
enum NarrationPlayback {
    /// Rewind applied when resuming so the listener regains context.
    static let resumeRewind: Double = 3

    /// Resume at the validated saved position (with rewind), or start from the
    /// beginning when there is none / it went stale. Returns whether it resumed.
    @discardableResult
    static func resumeOrStart(
        package: NarrationPackage,
        program: NarrationProgram,
        player: AudioPlayerService,
        resumeStore: NarrationResumeStore = NarrationResumeStore(),
        context: ModelContext
    ) -> Bool {
        if let position = resumeStore.validatedPosition(
            for: package.identifier, among: Set(program.parts.map(\.fileName))
        ),
           let index = program.parts.firstIndex(where: { $0.fileName == position.fileName }) {
            start(
                package: package, program: program,
                fromPart: index, offset: max(0, position.offsetSeconds - resumeRewind), resumed: true,
                player: player, resumeStore: resumeStore, context: context
            )
            return true
        }
        start(package: package, program: program, player: player, resumeStore: resumeStore, context: context)
        return false
    }

    /// Play the package as one continuous work starting `offset` seconds into
    /// part `index`, and wire up resume-position persistence.
    static func start(
        package: NarrationPackage,
        program: NarrationProgram,
        fromPart index: Int = 0,
        offset: Double = 0,
        resumed: Bool = false,
        player: AudioPlayerService,
        resumeStore: NarrationResumeStore = NarrationResumeStore(),
        context: ModelContext
    ) {
        let items = program.parts.map { part in
            PlayableItem(
                id: UUID(),
                title: part.title,
                url: part.url,
                duration: part.duration,
                transcript: part.transcript,
                transcriptStyle: .paragraphs,
                noteAnchor: .init(
                    kind: .narration, contentID: package.identifier, itemFileName: part.fileName
                )
            )
        }
        guard !items.isEmpty else { return }
        player.play(
            items: items,
            startAt: index,
            offset: offset,
            presentation: .continuous(title: package.title)
        )

        // Persist the resume position keyed by the package's stable identifier;
        // the player fires this on pause, seek, part change, interruption, and
        // every few seconds while playing. Finishing clears it.
        let identifier = package.identifier
        let fileNames = program.parts.map(\.fileName)
        player.onProgress = { index, offset in
            guard fileNames.indices.contains(index) else { return }
            resumeStore.save(
                .init(fileName: fileNames[index], offsetSeconds: offset, updatedAt: .now),
                for: identifier
            )
        }
        player.onFinished = {
            resumeStore.clear(for: identifier)
            AnalyticsService.logNarrationFinished()
        }

        package.lastPlayedAt = .now
        try? context.save()
        AnalyticsService.logNarrationPlayed(resumed: resumed, stitched: program.isStitched)
    }
}
