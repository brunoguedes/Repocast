import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var player = AudioPlayerService()
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
            Tab("Settings", systemImage: "gearshape", value: 3) {
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
        }
        // Binding the selection and logging on appear + change is what makes the
        // Firebase Screens report fire reliably on every switch.
        .onAppear { logTabScreen(selectedTab) }
        .onChange(of: selectedTab) { _, tab in logTabScreen(tab) }
        // Outermost so the env reaches the safeAreaInset content (the
        // mini-player), which attaches above any `.environment` applied to the
        // TabView itself.
        .environment(player)
        .environment(account)
    }

    private func logTabScreen(_ tab: Int) {
        let name = switch tab {
        case 0: "Tracks"
        case 1: "Repos"
        case 2: "Playlists"
        default: "Settings"
        }
        AnalyticsService.logScreen(name)
    }
}

struct TracksView: View {
    @Environment(\.modelContext) private var context
    @Environment(AudioPlayerService.self) private var player
    @Query(sort: \AudioTrack.createdAt, order: .reverse) private var tracks: [AudioTrack]
    @State private var showNewTrack = false

    private let files = AudioFileStore()

    var body: some View {
        NavigationStack {
            List {
                ForEach(tracks) { track in
                    Button { play(from: track) } label: {
                        TrackRow(track: track)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Tracks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New", systemImage: "plus") { showNewTrack = true }
                }
            }
            .overlay {
                if tracks.isEmpty {
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
        }
    }

    private func play(from track: AudioTrack) {
        var startAt = 0
        var items: [PlayableItem] = []
        for candidate in tracks where candidate.status == .ready && files.exists(candidate.audioFileName) {
            if candidate.persistentModelID == track.persistentModelID {
                startAt = items.count
            }
            items.append(
                PlayableItem(
                    id: UUID(),
                    title: candidate.title,
                    url: files.url(for: candidate.audioFileName),
                    duration: candidate.durationSeconds,
                    transcript: candidate.transcript
                )
            )
        }
        guard !items.isEmpty else { return }
        player.play(items: items, startAt: startAt)
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            files.delete(tracks[index].audioFileName)
            context.delete(tracks[index])
            AnalyticsService.logTrackDeleted()
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
        .modelContainer(for: [AudioTrack.self, RepoSource.self, Playlist.self, PlaylistItem.self], inMemory: true)
}
