import Foundation
import SwiftData
import Testing
@testable import Repocast

/// Anchor for locating the test bundle's `Fixtures/` folder reference.
private final class FixtureLocator {}

/// The narration-package fixtures shipped in the test bundle:
/// - `proposal_v2` — full package: stitched mp3 + txt, 3 parts with txt
///   transcripts, m3u8 (including an `#EXTINF:-1`), ID3v2.3 tags with TRCK and
///   USLT lyrics that deliberately differ from the .txt files.
/// - `notes` — tags-only package: 11 parts, no m3u8 / txt / stitched file, no
///   TRCK — exercises numeric suffix ordering and the USLT fallback.
private enum Fixtures {
    static var root: URL {
        Bundle(for: FixtureLocator.self).resourceURL!.appendingPathComponent("Fixtures", isDirectory: true)
    }

    static var proposal: URL { root.appendingPathComponent("proposal_v2", isDirectory: true) }
    static var notes: URL { root.appendingPathComponent("notes", isDirectory: true) }

    /// Copy a fixture package into a fresh temp folder so a test can delete
    /// files to simulate degraded packages.
    static func temporaryCopy(of fixture: URL) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("narration-fixture-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.copyItem(at: fixture, to: destination)
        return destination
    }

    /// Rewrite the mp3 at `url` without its leading ID3 tag, so transcript
    /// fallbacks past the lyrics tag can be exercised.
    static func stripID3(at url: URL) throws {
        let data = try Data(contentsOf: url)
        guard data.count > 10, data[0] == 0x49, data[1] == 0x44, data[2] == 0x33 else { return }
        let size = Int(data[6] & 0x7F) << 21 | Int(data[7] & 0x7F) << 14
            | Int(data[8] & 0x7F) << 7 | Int(data[9] & 0x7F)
        try data.dropFirst(10 + size).write(to: url)
    }
}

// MARK: - M3U parsing

struct M3UPlaylistTests {

    @Test func parsesTitleEntriesTranscriptsAndDurations() {
        let text = """
        #EXTM3U
        #PLAYLIST:Proposal v2
        #EXTINF:233,Proposal v2 - Part 1 of 4
        #EXT-TRANSCRIPT:proposal_v2_part1.txt
        proposal_v2_part1.mp3
        #EXTINF:-1,Proposal v2 - Part 2 of 4
        proposal_v2_part2.mp3
        """
        let playlist = M3UPlaylist.parse(text)
        #expect(playlist.title == "Proposal v2")
        #expect(playlist.entries.count == 2)
        #expect(playlist.entries[0].fileName == "proposal_v2_part1.mp3")
        #expect(playlist.entries[0].title == "Proposal v2 - Part 1 of 4")
        #expect(playlist.entries[0].durationSeconds == 233)
        #expect(playlist.entries[0].transcriptFileName == "proposal_v2_part1.txt")
        // -1 means unknown → nil, and the transcript link doesn't leak forward.
        #expect(playlist.entries[1].durationSeconds == nil)
        #expect(playlist.entries[1].transcriptFileName == nil)
    }

    @Test func toleratesCRLFMissingHeaderAndUnknownComments() {
        let text = "#PLAYLIST:X\r\n#EXT-X-SOMETHING:ignored\r\n#EXTINF:5,A, with commas\r\na.mp3\r\n\r\n./b.mp3\r\n"
        let playlist = M3UPlaylist.parse(text)
        #expect(playlist.title == "X")
        #expect(playlist.entries.count == 2)
        #expect(playlist.entries[0].title == "A, with commas")
        #expect(playlist.entries[0].durationSeconds == 5)
        // A bare entry with no #EXTINF, leading ./ stripped.
        #expect(playlist.entries[1] == M3UPlaylist.Entry(fileName: "b.mp3"))
    }

    @Test func emptyAndCommentOnlyInputYieldNoEntries() {
        #expect(M3UPlaylist.parse("").entries.isEmpty)
        #expect(M3UPlaylist.parse("#EXTM3U\n#PLAYLIST:\n").entries.isEmpty)
        #expect(M3UPlaylist.parse("#PLAYLIST:\n").title == nil)
    }
}

// MARK: - ID3 tags

struct ID3TagTests {

    @Test func readsTextFramesTrackAndLyrics() {
        let tag = ID3Tag.read(from: Fixtures.proposal.appendingPathComponent("proposal_v2_part1.mp3"))
        #expect(tag?.title == "Proposal v2 - Part 1 of 3")
        #expect(tag?.album == "Proposal v2")
        #expect(tag?.artist == "Samantha (en-US)")
        #expect(tag?.trackNumber == 1)
        #expect(tag?.trackTotal == 3)
        #expect(tag?.lyrics == "Lyrics transcript for part 1.\n\nEmbedded in the tag.")
    }

    @Test func readsUTF16Lyrics() {
        let tag = ID3Tag.read(from: Fixtures.proposal.appendingPathComponent("proposal_v2.mp3"))
        #expect(tag?.lyrics == "Stitched lyrics transcript.\n\nFrom the ID3 tag — not a file.")
        #expect(tag?.trackNumber == nil)
    }

    @Test func untaggedFileYieldsNil() throws {
        let copy = try Fixtures.temporaryCopy(of: Fixtures.proposal)
        defer { try? FileManager.default.removeItem(at: copy) }
        let mp3 = copy.appendingPathComponent("proposal_v2_part1.mp3")
        try Fixtures.stripID3(at: mp3)
        #expect(ID3Tag.read(from: mp3) == nil)
    }
}

// MARK: - Part ordering

struct PartOrderingTests {

    @Test func extractsNumericPartSuffix() {
        #expect(NarrationProgramBuilder.partNumber(in: "notes_part7.mp3") == 7)
        #expect(NarrationProgramBuilder.partNumber(in: "notes_part10.mp3") == 10)
        #expect(NarrationProgramBuilder.partNumber(in: "notes.mp3") == nil)
        #expect(NarrationProgramBuilder.partNumber(in: "notes_partX.mp3") == nil)
    }

    @Test func numericSuffixSortsPartTenAfterPartNine() {
        let shuffled = (1...11).map { "notes_part\($0).mp3" }.shuffled()
        let ordered = NarrationProgramBuilder.fallbackOrder(shuffled) { _ in nil }
        #expect(ordered == (1...11).map { "notes_part\($0).mp3" })
    }

    @Test func id3TrackNumberBeatsPartSuffix() {
        // Track numbers say the file *named* part2 plays first.
        let tracks = ["a_part1.mp3": 2, "a_part2.mp3": 1]
        let ordered = NarrationProgramBuilder.fallbackOrder(["a_part1.mp3", "a_part2.mp3"]) { tracks[$0] }
        #expect(ordered == ["a_part2.mp3", "a_part1.mp3"])
    }

    @Test func conventionScanIgnoresForeignFiles() {
        let names = ["notes_part1.mp3", "notes_part2.txt", "other_part1.mp3", "notes.mp3", "notes.m3u8"]
        #expect(NarrationProgramBuilder.partFileNames(in: names, baseName: "notes") == ["notes_part1.mp3"])
    }
}

// MARK: - Program building (stitched choice + transcript fallback chain)

struct NarrationProgramBuilderTests {
    private let builder = NarrationProgramBuilder()

    @Test func fullPackagePlaysStitchedFileWithFileTranscript() async {
        let program = await builder.build(directory: Fixtures.proposal, baseName: "proposal_v2")
        #expect(program?.title == "Proposal v2")
        #expect(program?.isStitched == true)
        #expect(program?.parts.count == 1)
        #expect(program?.parts.first?.fileName == "proposal_v2.mp3")
        #expect(program?.parts.first?.transcript == "Full transcript from file.\n\nIt has two paragraphs.")
        #expect(program?.voice == "Samantha (en-US)")
        #expect((program?.totalDuration ?? 0) > 0)
    }

    @Test func stitchedTranscriptFallsBackToLyricsThenParts() async throws {
        let copy = try Fixtures.temporaryCopy(of: Fixtures.proposal)
        defer { try? FileManager.default.removeItem(at: copy) }

        // Without <base>.txt the stitched file's USLT lyrics win…
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.txt"))
        var program = await builder.build(directory: copy, baseName: "proposal_v2")
        #expect(program?.parts.first?.transcript == "Stitched lyrics transcript.\n\nFrom the ID3 tag — not a file.")

        // …and without lyrics either, the part transcripts concatenate in order.
        try Fixtures.stripID3(at: copy.appendingPathComponent("proposal_v2.mp3"))
        program = await builder.build(directory: copy, baseName: "proposal_v2")
        let expected = (1...3)
            .map { "Part \($0) transcript from file.\n\nSecond paragraph of part \($0)." }
            .joined(separator: "\n\n")
        #expect(program?.parts.first?.transcript == expected)
    }

    @Test func withoutStitchedFilePartsFollowPlaylistOrder() async throws {
        let copy = try Fixtures.temporaryCopy(of: Fixtures.proposal)
        defer { try? FileManager.default.removeItem(at: copy) }
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.mp3"))
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.txt"))

        let program = await builder.build(directory: copy, baseName: "proposal_v2")
        #expect(program?.isStitched == false)
        #expect(program?.parts.map(\.fileName) == (1...3).map { "proposal_v2_part\($0).mp3" })
        #expect(program?.parts.map(\.title) == (1...3).map { "Proposal v2 - Part \($0) of 3" })
        #expect(program?.parts[1].transcript == "Part 2 transcript from file.\n\nSecond paragraph of part 2.")
        // A part whose .txt was regenerated away falls back to its lyrics tag.
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2_part2.txt"))
        let degraded = await builder.build(directory: copy, baseName: "proposal_v2")
        #expect(degraded?.parts[1].transcript == "Lyrics transcript for part 2.\n\nEmbedded in the tag.")
    }

    @Test func explicitTranscriptLinkWinsOverSameStemFile() async throws {
        let copy = try Fixtures.temporaryCopy(of: Fixtures.proposal)
        defer { try? FileManager.default.removeItem(at: copy) }
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.mp3"))
        try "Linked transcript wins.".write(
            to: copy.appendingPathComponent("custom.txt"), atomically: true, encoding: .utf8
        )
        try """
        #EXTM3U
        #EXTINF:1,Part 1
        #EXT-TRANSCRIPT:custom.txt
        proposal_v2_part1.mp3
        """.write(to: copy.appendingPathComponent("proposal_v2.m3u8"), atomically: true, encoding: .utf8)

        let program = await builder.build(directory: copy, baseName: "proposal_v2")
        #expect(program?.parts.count == 1)
        #expect(program?.parts.first?.transcript == "Linked transcript wins.")
    }

    @Test func tagsOnlyPackageOrdersNumericallyAndUsesLyrics() async {
        // `notes` has no m3u8, no txt, no stitched file and no TRCK frames:
        // ordering must come from the numeric part suffix, transcripts from USLT.
        let program = await builder.build(directory: Fixtures.notes, baseName: "notes")
        #expect(program?.title == "notes")
        #expect(program?.isStitched == false)
        #expect(program?.parts.map(\.fileName) == (1...11).map { "notes_part\($0).mp3" })
        #expect(program?.parts[9].transcript == "Spoken notes part 10.\n\nTag paragraph 10.")
        #expect(program?.parts[4].transcript == "Spoken notes part 5.\n\nTag paragraph 5.")  // UTF-16 USLT
        #expect(program?.voice == "Karen (en-AU)")
    }

    @Test func missingPlaylistFallsBackToTagOrder() async throws {
        let copy = try Fixtures.temporaryCopy(of: Fixtures.proposal)
        defer { try? FileManager.default.removeItem(at: copy) }
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.mp3"))
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.m3u8"))

        let program = await builder.build(directory: copy, baseName: "proposal_v2")
        #expect(program?.title == "proposal_v2")  // no #PLAYLIST: to name it
        #expect(program?.parts.map(\.fileName) == (1...3).map { "proposal_v2_part\($0).mp3" })
        // Titles still come from the ID3 tags.
        #expect(program?.parts.first?.title == "Proposal v2 - Part 1 of 3")
    }

    @Test func emptyFolderYieldsNoProgram() async throws {
        let empty = FileManager.default.temporaryDirectory
            .appendingPathComponent("narration-empty-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }
        #expect(await builder.build(directory: empty, baseName: "x") == nil)
    }
}

// MARK: - Base-name detection

struct NarrationBaseNameTests {

    @Test func playlistStemWinsThenPartPrefixThenLoneMP3() {
        #expect(NarrationImporter.detectBaseName(in: ["b_part1.mp3", "a.m3u8"]) == "a")
        #expect(NarrationImporter.detectBaseName(in: ["b_part1.mp3", "b_part2.mp3", "junk.txt"]) == "b")
        #expect(NarrationImporter.detectBaseName(in: ["solo.mp3"]) == "solo")
        #expect(NarrationImporter.detectBaseName(in: ["readme.txt"]) == nil)
    }

    @Test func identifierIsStableAndPathSensitive() {
        let a = NarrationImporter.identifier(sourcePath: "/x/y", baseName: "b")
        #expect(a == NarrationImporter.identifier(sourcePath: "/x/y", baseName: "b"))
        #expect(a != NarrationImporter.identifier(sourcePath: "/x/z", baseName: "b"))
        #expect(a.count == 16)
    }
}

// MARK: - Import + re-import

@MainActor
struct NarrationImporterTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: NarrationPackage.self, configurations: config)
        return ModelContext(container)
    }

    @Test func importsThenReimportsTheSameFolderWithoutDuplicating() async throws {
        let context = try makeContext()
        let copy = try Fixtures.temporaryCopy(of: Fixtures.proposal)
        let identifier = NarrationImporter.identifier(
            sourcePath: copy.standardizedFileURL.path, baseName: "proposal_v2"
        )
        let store = NarrationPackageStore()
        defer {
            try? FileManager.default.removeItem(at: copy)
            store.delete(identifier)
        }

        let importer = NarrationImporter()
        #expect(await importer.importPackage(from: copy, into: context))
        var packages = try context.fetch(FetchDescriptor<NarrationPackage>())
        #expect(packages.count == 1)
        #expect(packages.first?.title == "Proposal v2")
        #expect(packages.first?.identifier == identifier)
        #expect(packages.first?.hasStitched == true)
        #expect(packages.first?.partCount == 3)
        #expect(packages.first?.voiceName == "Samantha (en-US)")
        #expect((packages.first?.totalDurationSeconds ?? 0) > 0)
        #expect(store.exists(identifier))

        // The source folder was regenerated without the stitched file;
        // re-importing must update the existing item, not add a second one.
        try FileManager.default.removeItem(at: copy.appendingPathComponent("proposal_v2.mp3"))
        #expect(await importer.importPackage(from: copy, into: context))
        packages = try context.fetch(FetchDescriptor<NarrationPackage>())
        #expect(packages.count == 1)
        #expect(packages.first?.hasStitched == false)
    }

    @Test func rejectsAFolderWithNoNarrationFiles() async throws {
        let context = try makeContext()
        let empty = FileManager.default.temporaryDirectory
            .appendingPathComponent("narration-reject-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }

        let importer = NarrationImporter()
        #expect(await importer.importPackage(from: empty, into: context) == false)
        if case .failed = importer.phase {} else { Issue.record("expected a failed phase") }
        #expect(try context.fetch(FetchDescriptor<NarrationPackage>()).isEmpty)
    }
}

// MARK: - Resume persistence + invalidation

struct NarrationResumeStoreTests {

    private func makeStore() -> (NarrationResumeStore, UserDefaults) {
        let suite = "narration-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (NarrationResumeStore(defaults: defaults), defaults)
    }

    @Test func savesAndRestoresPerPackage() {
        let (store, _) = makeStore()
        let position = NarrationResumeStore.Position(fileName: "a_part3.mp3", offsetSeconds: 42.5, updatedAt: .now)
        store.save(position, for: "pkg1")
        #expect(store.position(for: "pkg1") == position)
        #expect(store.position(for: "pkg2") == nil)
    }

    @Test func clearRemovesThePosition() {
        let (store, _) = makeStore()
        store.save(.init(fileName: "a.mp3", offsetSeconds: 1, updatedAt: .now), for: "pkg")
        store.clear(for: "pkg")
        #expect(store.position(for: "pkg") == nil)
    }

    @Test func validationKeepsPositionWhoseFileStillExists() {
        let (store, _) = makeStore()
        store.save(.init(fileName: "a_part3.mp3", offsetSeconds: 42, updatedAt: .now), for: "pkg")
        let valid = store.validatedPosition(for: "pkg", among: ["a_part1.mp3", "a_part3.mp3"])
        #expect(valid?.fileName == "a_part3.mp3")
        #expect(store.position(for: "pkg") != nil)
    }

    @Test func validationDiscardsStalePositionAfterRegeneration() {
        let (store, _) = makeStore()
        store.save(.init(fileName: "a_part9.mp3", offsetSeconds: 42, updatedAt: .now), for: "pkg")
        // The folder was regenerated with fewer parts: start over, not crash.
        #expect(store.validatedPosition(for: "pkg", among: ["a_part1.mp3"]) == nil)
        #expect(store.position(for: "pkg") == nil)
    }
}

// MARK: - Continuous (aggregate) timeline

@MainActor
struct ContinuousTimelineTests {

    private func makeItems(durations: [Double]) -> [PlayableItem] {
        durations.enumerated().map { index, duration in
            PlayableItem(
                id: UUID(),
                title: "Part \(index + 1)",
                url: URL(fileURLWithPath: "/nonexistent/part\(index + 1).mp3"),
                duration: duration,
                transcript: "",
                transcriptStyle: .paragraphs
            )
        }
    }

    @Test func aggregatesDurationAndMapsSeeksAcrossParts() {
        let player = AudioPlayerService()
        player.play(items: makeItems(durations: [10, 20, 30]), startAt: 0, presentation: .continuous(title: "Pkg"))
        #expect(player.isContinuous)
        #expect(player.displayTitle == "Pkg")
        #expect(player.displayDuration == 60)

        // 35s into the aggregate timeline = 5s into the third part.
        player.seek(toDisplayTime: 35)
        #expect(player.currentIndex == 2)
        #expect(abs(player.currentTime - 5) < 0.001)
        #expect(abs(player.displayTime - 35) < 0.001)

        // Back before the first boundary.
        player.seek(toDisplayTime: 4)
        #expect(player.currentIndex == 0)
        #expect(abs(player.displayTime - 4) < 0.001)
        player.pause()
    }

    @Test func trackListPresentationKeepsPerItemTimeline() {
        let player = AudioPlayerService()
        player.play(items: makeItems(durations: [10, 20]), startAt: 1)
        #expect(!player.isContinuous)
        #expect(player.displayTitle == "Part 2")
        #expect(player.displayDuration == 20)
        player.pause()
    }

    @Test func startingWithOffsetSeeksIntoTheStartPart() {
        let player = AudioPlayerService()
        player.play(items: makeItems(durations: [10, 20, 30]), startAt: 2, offset: 7, presentation: .continuous(title: "Pkg"))
        #expect(player.currentIndex == 2)
        #expect(abs(player.currentTime - 7) < 0.001)
        #expect(abs(player.displayTime - 37) < 0.001)
        player.pause()
    }

    @Test func progressHandlerReceivesPauseAndSeekPositions() {
        let player = AudioPlayerService()
        player.play(items: makeItems(durations: [10, 20]), startAt: 0, presentation: .continuous(title: "Pkg"))

        var reports: [(Int, Double)] = []
        player.onProgress = { reports.append(($0, $1)) }
        player.seek(toDisplayTime: 15)   // part 2, 5s in
        player.pause()
        #expect(reports.contains { $0.0 == 1 && abs($0.1 - 5) < 0.001 })

        // Starting fresh playback clears the handler so a later track-list
        // queue can't overwrite this package's resume position.
        reports.removeAll()
        player.play(items: makeItems(durations: [5]), startAt: 0)
        player.pause()
        #expect(reports.isEmpty)
    }
}
