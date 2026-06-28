import SwiftUI
import SwiftData

/// Describe a playlist; `PlaylistGenerator` curates it on-device. The brief and
/// the chosen tracks are previewed before saving so the user stays in control.
struct SmartPlaylistView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AudioTrack.createdAt, order: .reverse) private var tracks: [AudioTrack]

    @State private var brief = ""
    @State private var plan: SmartPlaylistPlan?
    @State private var curating = false
    @State private var error: String?

    private let generator = PlaylistGenerator()
    private let examples = ["A tour of the audio pipeline", "Everything about GitHub auth", "Short docs under 5 minutes"]

    private var readyTracks: [AudioTrack] { tracks.filter { $0.status == .ready } }
    private var plannedTracks: [AudioTrack] {
        guard let plan else { return [] }
        return plan.trackTitles.compactMap { title in readyTracks.first { $0.title == title } }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let plan {
                    Section {
                        Label(plan.rationale, systemImage: "sparkles")
                            .font(.footnote)
                    }
                    Section(plan.title) {
                        ForEach(plannedTracks) { track in
                            HStack {
                                Image(systemName: track.sourceKind == .markdown ? "doc.text" : "chevron.left.forwardslash.chevron.right")
                                    .foregroundStyle(.secondary)
                                Text(track.title).lineLimit(1)
                                Spacer()
                                Text(PlaybackTime.string(track.durationSeconds))
                                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                    }
                    Section {
                        Button("Start Over") { self.plan = nil }
                    }
                } else {
                    Section {
                        TextField("e.g. A 20-minute tour of how audio gets generated", text: $brief, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    } header: {
                        Text("Describe Your Playlist")
                    } footer: {
                        Text("Generated on-device with Apple Intelligence. Your library never leaves your phone.")
                    }
                    Section {
                        ForEach(examples, id: \.self) { ex in
                            Button(ex) { brief = ex }
                        }
                    }
                    if let error {
                        Section { Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(.red) }
                    }
                }
            }
            .navigationTitle("Smart Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if plan == nil {
                        Button("Generate") { Task { await curate() } }
                            .disabled(brief.trimmingCharacters(in: .whitespaces).isEmpty || curating)
                    } else {
                        Button("Save") { save() }.disabled(plannedTracks.isEmpty)
                    }
                }
            }
            .overlay {
                if curating {
                    ProgressView("Curating your playlist…")
                        .padding(24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }
            }
            .interactiveDismissDisabled(curating)
        }
    }

    private func curate() async {
        curating = true
        error = nil
        do {
            // Project to a Sendable value type on the main actor; the SwiftData
            // models never cross into the curator.
            let choices = readyTracks.map {
                TrackChoice(title: $0.title, sourceKind: $0.sourceKind.rawValue, durationSeconds: $0.durationSeconds)
            }
            let result = try await generator.curate(brief: brief, from: choices)
            guard !result.trackTitles.isEmpty else { throw PlaylistGenerationError.emptyResult }
            plan = result
        } catch {
            self.error = error.localizedDescription
        }
        curating = false
    }

    private func save() {
        guard let plan else { return }
        let playlist = Playlist(title: plan.title, detail: plan.rationale, tint: "purple", kind: .smart)
        context.insert(playlist)
        for track in plannedTracks { playlist.append(track) }
        try? context.save()
        AnalyticsService.logPlaylistCreated(smart: true)
        dismiss()
    }
}
