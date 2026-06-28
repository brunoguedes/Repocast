import SwiftUI
import SwiftData

/// Hand-build a playlist: name it and tick tracks from the library.
struct NewPlaylistView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AudioTrack.createdAt, order: .reverse) private var tracks: [AudioTrack]

    @State private var title = ""
    @State private var picked: Set<PersistentIdentifier> = []

    private var readyTracks: [AudioTrack] { tracks.filter { $0.status == .ready } }
    private var canCreate: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && !picked.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Playlist name", text: $title)
                }
                Section(picked.isEmpty ? "Add Tracks" : "\(picked.count) Selected") {
                    ForEach(readyTracks) { track in
                        Button { toggle(track) } label: {
                            HStack {
                                Image(systemName: picked.contains(track.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(picked.contains(track.persistentModelID) ? Color.accentColor : Color.secondary)
                                Text(track.title).lineLimit(1)
                                Spacer()
                                Text(PlaybackTime.string(track.durationSeconds))
                                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }.disabled(!canCreate)
                }
            }
        }
    }

    private func toggle(_ track: AudioTrack) {
        let id = track.persistentModelID
        if picked.contains(id) { picked.remove(id) } else { picked.insert(id) }
    }

    private func create() {
        let playlist = Playlist(title: title.trimmingCharacters(in: .whitespaces), detail: "Playlist", tint: "teal", kind: .manual)
        context.insert(playlist)
        // Preserve the library's display order for the chosen tracks.
        for track in readyTracks where picked.contains(track.persistentModelID) {
            playlist.append(track)
        }
        try? context.save()
        AnalyticsService.logPlaylistCreated(smart: false)
        dismiss()
    }
}
