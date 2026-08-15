import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    /// The shared app-lifetime player — the CarPlay scene drives the same
    /// instance, so both screens stay in sync.
    private let player = AudioPlayerService.shared
    /// Same deal for the voice-note recorder: one session shared with CarPlay.
    private let recorder = VoiceNoteRecorder.shared
    @State private var account = GitHubAccount()
    @State private var selectedTab = 0
    @State private var showNowPlaying = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Tracks", systemImage: "waveform", value: 0) {
                TracksView()
            }
            Tab("Repos", systemImage: "folder", value: 1) {
                ReposView()
            }
            Tab("Playlists", systemImage: "music.note.list", value: 2) {
                PlaylistsView()
            }
            Tab("Notes", systemImage: "mic", value: 3) {
                NotesView()
            }
            Tab("Settings", systemImage: "gearshape", value: 4) {
                SettingsView()
            }
        }
        // iOS 26's native slot for a mini-player: it floats just ABOVE the
        // Liquid-Glass tab bar (Apple Music pattern). Only attached while a
        // track is loaded — otherwise the accessory shows an empty glass pill.
        .miniPlayerAccessory(present: player.currentItem != nil, showNowPlaying: $showNowPlaying)
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
                .environment(player)
                .environment(recorder)
        }
        // Binding the selection and logging on appear + change is what makes the
        // Firebase Screens report fire reliably on every switch.
        .onAppear { logTabScreen(selectedTab) }
        .onChange(of: selectedTab) { _, tab in logTabScreen(tab) }
        // Flush the resume position when the app leaves the foreground so a
        // termination while backgrounded loses nothing.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive { player.saveProgressNow() }
        }
        // Outermost so the env reaches the safeAreaInset content (the
        // mini-player), which attaches above any `.environment` applied to the
        // TabView itself.
        .environment(player)
        .environment(recorder)
        .environment(account)
    }

    private func logTabScreen(_ tab: Int) {
        let name = switch tab {
        case 0: "Tracks"
        case 1: "Repos"
        case 2: "Playlists"
        case 3: "Notes"
        default: "Settings"
        }
        AnalyticsService.logScreen(name)
    }
}

struct TracksView: View {
    @Environment(\.modelContext) private var context
    @Environment(AudioPlayerService.self) private var player
    @Query(sort: \AudioTrack.createdAt, order: .reverse) private var tracks: [AudioTrack]
    @Query(sort: \NarrationPackage.importedAt, order: .reverse) private var narrations: [NarrationPackage]
    @State private var showNewTrack = false
    @State private var showImportNarration = false
    @State private var importer = NarrationImporter()

    private let files = AudioFileStore()
    private let narrationStore = NarrationPackageStore()
    private let resumeStore = NarrationResumeStore()

    /// Tracks grouped by their originating repo (freeform tracks trail last).
    private var groups: [RepoTrackGroup] { tracks.groupedByRepo() }

    private var importFailureMessage: String? {
        if case let .failed(message) = importer.phase { message } else { nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if !narrations.isEmpty || importer.phase == .importing {
                    Section("Narrations") {
                        ForEach(narrations) { package in
                            NavigationLink {
                                NarrationPackageDetailView(package: package)
                            } label: {
                                NarrationPackageRow(package: package)
                            }
                        }
                        .onDelete(perform: deleteNarrations)
                        if importer.phase == .importing {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Importing…").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                ForEach(groups) { group in
                    Section(group.title) {
                        ForEach(group.tracks) { track in
                            Button { play(from: track) } label: {
                                TrackRow(track: track)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { delete(in: group, offsets: $0) }
                    }
                }
            }
            .navigationTitle("Tracks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New Track", systemImage: "waveform") { showNewTrack = true }
                        Button("Import Narration Folder", systemImage: "folder.badge.plus") {
                            showImportNarration = true
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if tracks.isEmpty && narrations.isEmpty {
                    ContentUnavailableView(
                        "No Tracks Yet",
                        systemImage: "waveform",
                        description: Text("Tap + to turn text into audio you can play anywhere.")
                    )
                }
            }
            .sheet(isPresented: $showNewTrack) {
                NewTrackView()
            }
            .fileImporter(isPresented: $showImportNarration, allowedContentTypes: [.folder]) { result in
                if case let .success(url) = result {
                    Task { await importer.importPackage(from: url, into: context) }
                }
            }
            .alert(
                "Couldn't Import Narration",
                isPresented: Binding(
                    get: { importFailureMessage != nil },
                    set: { if !$0 { importer.dismissFailure() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importFailureMessage ?? "")
            }
        }
    }

    private func play(from track: AudioTrack) {
        var startAt = 0
        var items: [PlayableItem] = []
        // Queue follows the on-screen (grouped) order so playback continues the
        // way the list reads.
        for candidate in groups.flatMap(\.tracks) where candidate.status == .ready && files.exists(candidate.audioFileName) {
            if candidate.persistentModelID == track.persistentModelID {
                startAt = items.count
            }
            items.append(
                PlayableItem(
                    id: UUID(),
                    title: candidate.title,
                    url: files.url(for: candidate.audioFileName),
                    duration: candidate.durationSeconds,
                    transcript: candidate.transcript,
                    noteAnchor: .init(kind: .track, contentID: candidate.audioFileName)
                )
            )
        }
        guard !items.isEmpty else { return }
        player.play(items: items, startAt: startAt)
    }

    private func delete(in group: RepoTrackGroup, offsets: IndexSet) {
        for index in offsets {
            let track = group.tracks[index]
            files.delete(track.audioFileName)
            context.delete(track)
            AnalyticsService.logTrackDeleted()
        }
    }

    private func deleteNarrations(_ offsets: IndexSet) {
        for index in offsets {
            let package = narrations[index]
            narrationStore.delete(package.identifier)
            resumeStore.clear(for: package.identifier)
            context.delete(package)
            AnalyticsService.logNarrationDeleted()
        }
    }
}

private struct TrackRow: View {
    let track: AudioTrack

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title.isEmpty ? "Untitled" : track.title)
                    .font(.body)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "play.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var icon: String {
        switch track.status {
        case .ready: "waveform"
        case .generating, .pending: "hourglass"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var subtitle: String {
        track.durationSeconds > 0
            ? PlaybackTime.string(track.durationSeconds)
            : track.status.rawValue.capitalized
    }
}

private extension View {
    /// Attach the mini-player accessory only when `present`. Conditionally
    /// applying the modifier is what hides the empty glass pill when no track is
    /// loaded (an always-on `tabViewBottomAccessory` with empty content still
    /// renders its container).
    @ViewBuilder
    func miniPlayerAccessory(present: Bool, showNowPlaying: Binding<Bool>) -> some View {
        if present {
            tabViewBottomAccessory { MiniPlayerBar(showNowPlaying: showNowPlaying) }
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [AudioTrack.self, RepoSource.self, Playlist.self, PlaylistItem.self, NarrationPackage.self, VoiceNote.self],
            inMemory: true
        )
}
