import SwiftUI
import SwiftData

/// Playlists tab: list playlists, build one by hand, or generate a smart one
/// on-device. Mirrors the Tracks/Repos tabs' structure and the system grouped
/// look. Composes the existing player + file store rather than re-implementing.
struct PlaylistsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Playlist.createdAt, order: .reverse) private var playlists: [Playlist]

    @State private var showNew = false
    @State private var showSmart = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showSmart = true } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New Smart Playlist").font(.headline)
                                Text("Describe it — Apple Intelligence picks the tracks.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "sparkles").foregroundStyle(.purple)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Your Playlists") {
                    ForEach(playlists) { playlist in
                        NavigationLink {
                            PlaylistDetailView(playlist: playlist)
                        } label: {
                            PlaylistRow(playlist: playlist)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New", systemImage: "plus") { showNew = true }
                }
            }
            .overlay {
                if playlists.isEmpty {
                    ContentUnavailableView(
                        "No Playlists",
                        systemImage: "music.note.list",
                        description: Text("Create a playlist or generate a smart one from your library.")
                    )
                }
            }
            .sheet(isPresented: $showNew) { NewPlaylistView() }
            .sheet(isPresented: $showSmart) { SmartPlaylistView() }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(playlists[index]) }
    }
}

private struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tintColor.gradient)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: playlist.kind == .smart ? "sparkles" : "music.note.list")
                        .font(.title3).foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title).font(.body).lineLimit(1)
                Text("\(playlist.tracks.count) tracks · \(PlaybackTime.string(playlist.totalDuration))")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
