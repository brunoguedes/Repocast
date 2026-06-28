import SwiftUI
import SwiftData

/// One playlist: artwork header, Play All / Shuffle, and the ordered tracks with
/// native reorder (`.onMove`) + remove (`.onDelete`) inside `EditMode`.
struct PlaylistDetailView: View {
    @Bindable var playlist: Playlist

    @Environment(\.modelContext) private var context
    @Environment(AudioPlayerService.self) private var player
    @State private var editMode: EditMode = .inactive

    private let files = AudioFileStore()

    private var orderedItems: [PlaylistItem] { playlist.orderedItems }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tintColor.gradient)
                        .frame(width: 132, height: 132)
                        .overlay {
                            Image(systemName: playlist.kind == .smart ? "sparkles" : "music.note.list")
                                .font(.system(size: 56)).foregroundStyle(.white)
                        }
                    Text(playlist.title).font(.title2.bold()).multilineTextAlignment(.center)
                    Text("\(playlist.tracks.count) tracks · \(PlaybackTime.string(playlist.totalDuration))")
                        .font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Button { play(shuffled: false) } label: {
                            Label("Play All", systemImage: "play.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button { play(shuffled: true) } label: {
                            Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(orderedItems) { item in
                    if let track = item.track {
                        Button { play(from: track) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: track.sourceKind == .markdown ? "doc.text" : "chevron.left.forwardslash.chevron.right")
                                    .foregroundStyle(.secondary).frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title).font(.callout).lineLimit(1)
                                    Text(track.sourcePath.isEmpty ? "Freeform" : track.sourcePath)
                                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer()
                                Text(PlaybackTime.string(track.durationSeconds))
                                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: remove)
            }
        }
        .navigationTitle(playlist.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { EditButton() }
        }
        .environment(\.editMode, $editMode)
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        var items = orderedItems
        items.move(fromOffsets: offsets, toOffset: destination)
        playlist.reorder(to: items)
        try? context.save()
    }

    private func remove(_ offsets: IndexSet) {
        let items = orderedItems
        for index in offsets {
            let item = items[index]
            playlist.items?.removeAll { $0.persistentModelID == item.persistentModelID }
            context.delete(item)
        }
        playlist.reorder(to: playlist.orderedItems)
        try? context.save()
    }

    private func play(shuffled: Bool) {
        let tracks = shuffled ? playlist.tracks.shuffled() : playlist.tracks
        play(items: tracks, startAt: 0)
    }

    private func play(from track: AudioTrack) {
        let tracks = playlist.tracks
        play(items: tracks, startAt: tracks.firstIndex { $0.persistentModelID == track.persistentModelID } ?? 0)
    }

    private func play(items tracks: [AudioTrack], startAt: Int) {
        let playable = tracks
            .filter { $0.status == .ready && files.exists($0.audioFileName) }
            .map { PlayableItem(id: UUID(), title: $0.title, url: files.url(for: $0.audioFileName), duration: $0.durationSeconds, transcript: $0.transcript) }
        guard !playable.isEmpty else { return }
        player.play(items: playable, startAt: min(startAt, playable.count - 1))
        AnalyticsService.logPlaylistPlayed(smart: playlist.kind == .smart)
    }

    private var tintColor: Color {
        switch playlist.tint {
        case "purple": .purple
        case "orange": .orange
        case "green": .green
        case "pink": .pink
        case "teal": .teal
        default: .blue
        }
    }
}
