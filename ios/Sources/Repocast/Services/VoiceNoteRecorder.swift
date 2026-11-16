import Foundation
import Observation
import SwiftData

/// Records a voice note against whatever is playing. Shared (like the player)
/// so the phone's Now Playing screen and the CarPlay note button drive one
/// recording session and stay in sync.
///
/// Flow: `start(for:)` snapshots the playback position (content anchor +
/// time code) *before* pausing the player — pausing also persists the resume
/// position — then opens the mic via `AudioCapturing` (off the main actor;
/// mic spin-up must never freeze the UI). `stop(into:)` inserts the
/// `VoiceNote` immediately (status `.transcribing`) and kicks off on-device
/// speech recognition in the background, so the listener can resume playback
/// right away while the text fills in.
@MainActor
@Observable
final class VoiceNoteRecorder {
    static let shared = VoiceNoteRecorder()

    enum Phase: Equatable {
        case idle
        case preparing      // mic requested, hardware spinning up
        case recording
        case denied         // microphone permission refused
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    /// When the current recording began — drives the elapsed-time UI.
    private(set) var startedAt: Date?

    var isRecording: Bool { phase == .recording }

    /// The playback moment a note attaches to, captured before pausing.
    struct Context: Equatable {
        var anchor: PlayableItem.NoteAnchor
        var contentTitle: String
        var itemTitle: String
        var timecodeSeconds: Double
        var offsetSeconds: Double
    }

    private let store: VoiceNoteStore
    private let transcriber: any SpeechTranscribing
    private let capture: any AudioCapturing
    private var pending: (context: Context, fileName: String)?

    init(
        store: VoiceNoteStore = VoiceNoteStore(),
        transcriber: any SpeechTranscribing = SpeechTranscriptionService(),
        capture: (any AudioCapturing)? = nil
    ) {
        self.store = store
        self.transcriber = transcriber
        self.capture = capture ?? (
            ProcessInfo.processInfo.arguments.contains("-fake-mic")
                ? StubAudioCapture()
                : MicrophoneCapture()
        )
    }

    /// Where the note attaches: the current item's anchor plus the presented
    /// time code. `nil` when nothing anchored is playing (e.g. a note's own
    /// audio). Pure, so it's unit-testable without a microphone.
    static func captureContext(from player: AudioPlayerService) -> Context? {
        guard let item = player.currentItem, let anchor = item.noteAnchor else { return nil }
        return Context(
            anchor: anchor,
            contentTitle: player.displayTitle ?? item.title,
            itemTitle: item.title,
            timecodeSeconds: player.displayTime,
            offsetSeconds: player.currentTime
        )
    }

    /// One-tap toggle for surfaces without separate start/stop controls
    /// (the CarPlay now-playing button).
    func toggle(for player: AudioPlayerService, into context: ModelContext) {
        if isRecording {
            stop(into: context)
        } else {
            Task { await start(for: player) }
        }
    }

    /// Capture the moment, pause playback, and start recording.
    func start(for player: AudioPlayerService) async {
        guard phase == .idle || phase == .denied,
              let context = Self.captureContext(from: player) else { return }
        player.pause()  // recording always pauses the audio (and saves resume)

        let fileName = store.makeFileName()
        phase = .preparing
        do {
            try await capture.begin(writingTo: store.url(for: fileName))
            pending = (context, fileName)
            startedAt = .now
            phase = .recording
            AnalyticsService.logNoteRecordingStarted(kind: context.anchor.kind.rawValue)
        } catch AudioCaptureError.permissionDenied {
            store.delete(fileName)
            phase = .denied
        } catch {
            store.delete(fileName)
            phase = .failed(error.localizedDescription)
        }
    }

    /// Finish the recording, persist the note, and transcribe in the background.
    func stop(into modelContext: ModelContext) {
        guard isRecording, let (context, fileName) = pending else { return }
        pending = nil
        startedAt = nil
        phase = .idle

        Task {
            let duration = await capture.finish()
            let note = VoiceNote(
                contentKind: context.anchor.kind == .track ? .track : .narration,
                contentID: context.anchor.contentID,
                itemFileName: context.anchor.itemFileName,
                contentTitle: context.contentTitle,
                itemTitle: context.itemTitle,
                timecodeSeconds: context.timecodeSeconds,
                offsetSeconds: context.offsetSeconds,
                audioFileName: fileName,
                durationSeconds: duration
            )
            modelContext.insert(note)
            try? modelContext.save()
            AnalyticsService.logNoteRecorded(kind: note.contentKind.rawValue)
            await transcribe(note, in: modelContext)
        }
    }

    /// Discard the in-flight recording.
    func cancel() {
        guard isRecording else { return }
        pending = nil
        startedAt = nil
        phase = .idle
        Task { await capture.discard() }
    }

    /// Clear a `.denied` / `.failed` phase once the UI has shown it.
    func dismissError() {
        if phase != .recording && phase != .preparing { phase = .idle }
    }

    // MARK: Internals

    private func transcribe(_ note: VoiceNote, in modelContext: ModelContext) async {
        guard transcriber.isAvailable else {
            note.status = .unavailable
            try? modelContext.save()
            return
        }
        do {
            let text = try await transcriber.transcribe(fileAt: store.url(for: note.audioFileName))
            note.transcript = text.trimmingCharacters(in: .whitespacesAndNewlines)
            note.status = note.transcript.isEmpty ? .failed : .transcribed
        } catch {
            note.status = .failed
        }
        try? modelContext.save()
        AnalyticsService.logNoteTranscribed(success: note.status == .transcribed)
    }
}
