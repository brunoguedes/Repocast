import Foundation
import SwiftData
import Testing
@testable import Repocast

struct VoiceNoteModelTests {

    @Test func defaultsToTranscribing() {
        let note = VoiceNote(contentKind: .narration, contentID: "abc", contentTitle: "Proposal v2")
        #expect(note.status == .transcribing)
        #expect(note.contentKind == .narration)
        #expect(note.displayText == "Transcribing…")
    }

    @Test func enumAccessorsRoundTripThroughRawStrings() {
        let note = VoiceNote(contentKind: .track, contentID: "x.caf", contentTitle: "x")
        note.status = .transcribed
        note.transcript = "Check the retry logic here."
        #expect(note.status == .transcribed)
        #expect(note.displayText == "Check the retry logic here.")
        note.status = .unavailable
        #expect(note.displayText.contains("unavailable"))
    }
}

struct VoiceNoteStoreTests {

    @Test func filenameRoundTripAndDelete() throws {
        let store = VoiceNoteStore()
        let fileName = store.makeFileName()
        #expect(fileName.hasSuffix(".m4a"))
        #expect(!store.exists(fileName))
        try Data("hi".utf8).write(to: store.url(for: fileName))
        #expect(store.exists(fileName))
        store.delete(fileName)
        #expect(!store.exists(fileName))
        #expect(!store.exists(""))
    }
}

// MARK: - Capturing the playback moment

@MainActor
struct VoiceNoteCaptureTests {

    private func anchoredItems() -> [PlayableItem] {
        (1...3).map { n in
            PlayableItem(
                id: UUID(),
                title: "Part \(n)",
                url: URL(fileURLWithPath: "/nonexistent/p\(n).mp3"),
                duration: 100,
                transcriptStyle: .paragraphs,
                noteAnchor: .init(kind: .narration, contentID: "pkg1", itemFileName: "p\(n).mp3")
            )
        }
    }

    @Test func capturesAnchorAndAggregateTimecode() {
        let player = AudioPlayerService()
        player.play(
            items: anchoredItems(), startAt: 1, offset: 30,
            presentation: .continuous(title: "Proposal v2")
        )
        let context = VoiceNoteRecorder.captureContext(from: player)
        #expect(context?.anchor.kind == .narration)
        #expect(context?.anchor.contentID == "pkg1")
        #expect(context?.anchor.itemFileName == "p2.mp3")
        #expect(context?.contentTitle == "Proposal v2")
        #expect(context?.itemTitle == "Part 2")
        #expect(abs((context?.timecodeSeconds ?? 0) - 130) < 0.001)  // aggregate
        #expect(abs((context?.offsetSeconds ?? 0) - 30) < 0.001)     // within part
        player.pause()
    }

    @Test func unanchoredItemYieldsNoContext() {
        let player = AudioPlayerService()
        let bare = PlayableItem(
            id: UUID(), title: "Note", url: URL(fileURLWithPath: "/nonexistent/n.m4a"), duration: 5
        )
        player.play(items: [bare], startAt: 0)
        #expect(VoiceNoteRecorder.captureContext(from: player) == nil)
        player.pause()
    }

    @Test func narrationPlaybackAnchorsEveryPart() async throws {
        // Playing a narration package must anchor each queued part so notes
        // can attach anywhere in it.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: NarrationPackage.self, VoiceNote.self, configurations: config)
        let context = ModelContext(container)
        let package = NarrationPackage(title: "Notes", baseName: "notes", identifier: "vn-\(UUID().uuidString)")
        context.insert(package)

        let fixtures = Bundle(for: VoiceNoteFixtureLocator.self).resourceURL!
            .appendingPathComponent("Fixtures/notes", isDirectory: true)
        let program = await NarrationProgramBuilder().build(directory: fixtures, baseName: "notes")
        let unwrapped = try #require(program)

        let player = AudioPlayerService()
        NarrationPlayback.start(package: package, program: unwrapped, player: player, context: context)
        #expect(player.queue.count == 11)
        let anchor = player.queue[9].noteAnchor
        #expect(anchor?.kind == .narration)
        #expect(anchor?.contentID == package.identifier)
        #expect(anchor?.itemFileName == "notes_part10.mp3")
        player.pause()
    }
}

private final class VoiceNoteFixtureLocator {}
