import CarPlay
import Foundation
import SwiftData
import Testing
@testable import Repocast

/// `CarPlayInterface`'s list building, exercised against an in-memory store.
/// The `CPInterfaceController` plumbing needs a real CarPlay session, but the
/// section builders are plain template construction and test fine headless.
@MainActor
struct CarPlayInterfaceTests {

    private func makeInterface() throws -> (CarPlayInterface, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: AudioTrack.self, RepoSource.self, Playlist.self, PlaylistItem.self, NarrationPackage.self,
            configurations: config
        )
        let context = ModelContext(container)
        return (CarPlayInterface(player: AudioPlayerService(), context: context), context)
    }

    @Test func trackListShowsOnlyReadyTracksGroupedByRepo() throws {
        let (interface, context) = try makeInterface()
        context.insert(AudioTrack(title: "Readme", repoFullName: "octo/repo", durationSeconds: 65, status: .ready))
        context.insert(AudioTrack(title: "Pasted note", status: .ready))
        context.insert(AudioTrack(title: "Still rendering"))  // pending — hidden
        try context.save()

        let sections = interface.trackSections()
        #expect(sections.map(\.header) == ["octo/repo", "Freeform"])
        let titles = sections.flatMap(\.items).compactMap { ($0 as? CPListItem)?.text }
        #expect(titles == ["Readme", "Pasted note"])
        let firstDetail = (sections.first?.items.first as? CPListItem)?.detailText
        #expect(firstDetail == "1:05")
    }

    @Test func playlistListShowsNewestFirstWithCounts() throws {
        let (interface, context) = try makeInterface()
        context.insert(Playlist(title: "Older", createdAt: .now.addingTimeInterval(-60)))
        context.insert(Playlist(title: "Newer", createdAt: .now))
        try context.save()

        let sections = interface.playlistSections()
        let titles = sections.flatMap(\.items).compactMap { ($0 as? CPListItem)?.text }
        #expect(titles == ["Newer", "Older"])
        #expect((sections.first?.items.first as? CPListItem)?.detailText == "0 tracks · 0:00")
    }

    @Test func narrationListShowsFormAndDuration() throws {
        let (interface, context) = try makeInterface()
        context.insert(
            NarrationPackage(
                title: "Proposal v2",
                baseName: "proposal_v2",
                identifier: "cp-\(UUID().uuidString)",  // fresh key → no stray resume state
                partCount: 3,
                totalDurationSeconds: 125
            )
        )
        try context.save()

        let item = interface.narrationSections().first?.items.first as? CPListItem
        #expect(item?.text == "Proposal v2")
        #expect(item?.detailText == "3 parts · 2:05")
    }

    @Test func emptyLibraryYieldsNoSections() throws {
        let (interface, _) = try makeInterface()
        #expect(interface.trackSections().isEmpty)
        #expect(interface.playlistSections().isEmpty)
        #expect(interface.narrationSections().isEmpty)
    }
}
