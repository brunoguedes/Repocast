import SwiftData
import SwiftUI

/// Notes tab: every voice note, newest first. Tapping a note reopens its
/// content at the noted time code (the same jump the note was pinned with);
/// the trailing waveform button plays the raw recording instead — useful when
/// transcription was unavailable. Notes whose content has since been deleted
/// stay readable but lose the jump.
struct NotesView: View {
    @Environment(\.modelContext) private var context
    @Environment(AudioPlayerService.self) private var player
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    @State private var showMissingContent = false

    private let files = AudioFileStore()
    private let noteStore = VoiceNoteStore()
    private let narrationStore = NarrationPackageStore()
    private let builder = NarrationProgramBuilder()

    var body: some View {
        NavigationStack {
            List {
                ForEach(notes) { note in
                    Button { jump(to: note) } label: {
                        NoteRow(note: note) { playRecording(of: note) }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Notes")
            .overlay {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "mic",
                        description: Text("While listening, tap the mic on the player — or in CarPlay — to record a note at that moment.")
                    )
                }
            }
            .alert("Content Not in Library", isPresented: $showMissingContent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The audio this note was taken on has been deleted. You can still play the note itself.")
            }
        }
    }

    // MARK: Actions

    /// Reopen the noted content at the note's time code.
    private func jump(to note: VoiceNote) {
        switch note.contentKind {
        case .track:
            jumpToTrack(note)
        case .narration:
            jumpToNarration(note)
        }
    }

    private func jumpToTrack(_ note: VoiceNote) {
        let contentID = note.contentID
        let descriptor = FetchDescriptor<AudioTrack>(
            predicate: #Predicate { $0.audioFileName == contentID }
        )
        guard let track = try? context.fetch(descriptor).first, files.exists(track.audioFileName) else {
            showMissingContent = true
            return
        }
        let item = PlayableItem(
            id: UUID(),
            title: track.title,
            url: files.url(for: track.audioFileName),
            duration: track.durationSeconds,
            transcript: track.transcript,
            noteAnchor: .init(kind: .track, contentID: track.audioFileName)
        )
        player.play(items: [item], startAt: 0, offset: note.offsetSeconds)
        AnalyticsService.logNoteJumped(kind: note.contentKind.rawValue)
    }

    private func jumpToNarration(_ note: VoiceNote) {
        let contentID = note.contentID
        let descriptor = FetchDescriptor<NarrationPackage>(
            predicate: #Predicate { $0.identifier == contentID }
        )
        guard let package = try? context.fetch(descriptor).first else {
            showMissingContent = true
            return
        }
        Task {
            let directory = narrationStore.directory(for: package.identifier)
            guard let program = await builder.build(directory: directory, baseName: package.baseName),
                  let index = program.parts.firstIndex(where: { $0.fileName == note.itemFileName }) else {
                showMissingContent = true
                return
            }
            NarrationPlayback.start(
                package: package, program: program,
                fromPart: index, offset: note.offsetSeconds,
                player: player, context: context
            )
            AnalyticsService.logNoteJumped(kind: note.contentKind.rawValue)
        }
    }

    /// Play the note's own recording (a one-item queue; no note-on-note).
    private func playRecording(of note: VoiceNote) {
        guard noteStore.exists(note.audioFileName) else { return }
        let item = PlayableItem(
            id: UUID(),
            title: "Note — \(note.contentTitle)",
            url: noteStore.url(for: note.audioFileName),
            duration: note.durationSeconds,
            transcript: note.status == .transcribed ? note.transcript : "",
            transcriptStyle: .paragraphs
        )
        player.play(items: [item], startAt: 0)
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            let note = notes[index]
            noteStore.delete(note.audioFileName)
            context.delete(note)
            AnalyticsService.logNoteDeleted()
        }
    }
}

private struct NoteRow: View {
    let note: VoiceNote
    let onPlayRecording: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.displayText)
                    .font(.body)
                    .foregroundStyle(note.status == .transcribed ? .primary : .secondary)
                    .lineLimit(3)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onPlayRecording) {
                Image(systemName: "waveform.circle")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play note recording")
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        var parts = [note.contentTitle]
        if !note.itemTitle.isEmpty, note.itemTitle != note.contentTitle {
            parts.append(note.itemTitle)
        }
        parts.append("at \(PlaybackTime.string(note.timecodeSeconds))")
        parts.append(note.createdAt.formatted(date: .abbreviated, time: .shortened))
        return parts.joined(separator: " · ")
    }
}
