import SwiftUI

/// mm:ss formatting shared across the player surfaces.
enum PlaybackTime {
    static func string(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Compact transport for the `tabViewBottomAccessory` slot. The system supplies
/// the glass container, so this is just the content; it renders nothing when the
/// queue is empty (the accessory collapses).
struct MiniPlayerBar: View {
    @Environment(AudioPlayerService.self) private var player
    @Binding var showNowPlaying: Bool

    var body: some View {
        if let item = player.currentItem {
            Button { showNowPlaying = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.displayTitle ?? item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text("\(PlaybackTime.string(player.displayTime)) / \(PlaybackTime.string(player.displayDuration))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Spacer()
                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("mini-player")
        }
    }
}

/// Full-screen transport with scrubber, speed control, and the voice-note
/// recorder.
struct NowPlayingView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(VoiceNoteRecorder.self) private var recorder
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0

    private let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        @Bindable var player = player
        let item = player.currentItem
        let displayTime = isScrubbing ? scrubValue : player.displayTime

        VStack(spacing: 20) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text(player.displayTitle ?? "Nothing Playing")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            // For a continuous work (narration package) the timeline is one
            // aggregate span, so name the chapter we're actually inside.
            if player.isContinuous, player.queue.count > 1, let item {
                Text(item.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let item, !item.transcript.isEmpty {
                TranscriptView(
                    transcript: item.transcript,
                    style: item.transcriptStyle,
                    currentTime: player.isContinuous ? player.currentTime : displayTime,
                    duration: player.duration,
                    onSeek: { player.seek(to: $0) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                Spacer()
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 110))
                    .foregroundStyle(.tint)
                    .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                if player.isContinuous {
                    Text("No transcript for this part")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }

            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { isScrubbing ? scrubValue : player.displayTime },
                        set: { scrubValue = $0; isScrubbing = true }
                    ),
                    in: 0...max(player.displayDuration, 0.1)
                ) { editing in
                    if !editing {
                        player.seek(toDisplayTime: scrubValue)
                        isScrubbing = false
                    }
                }
                HStack {
                    Text(PlaybackTime.string(displayTime))
                    Spacer()
                    Text(PlaybackTime.string(player.displayDuration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }

            HStack(spacing: 48) {
                Button { player.previous() } label: {
                    Image(systemName: "backward.fill").font(.title)
                }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").font(.title)
                }
            }
            .buttonStyle(.plain)

            if recorder.isRecording {
                RecordingNoteBar()
            } else {
                HStack(spacing: 12) {
                    // Tapping pauses playback and records a note pinned to
                    // this moment; the transcript is filled in on-device.
                    Button {
                        Task { await recorder.start(for: player) }
                    } label: {
                        if recorder.phase == .preparing {
                            ProgressView()
                                .frame(width: 30, height: 30)
                        } else {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 30))
                        }
                    }
                    .disabled(player.currentItem?.noteAnchor == nil || recorder.phase == .preparing)
                    .accessibilityLabel("Record note")

                    Picker("Speed", selection: $player.playbackRate) {
                        ForEach(speeds, id: \.self) { speed in
                            Text(speedLabel(speed)).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if recorder.phase == .denied {
                    Text("Allow microphone access in Settings to record notes.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .presentationDragIndicator(.hidden)
    }

    private func speedLabel(_ speed: Float) -> String {
        speed == 1 ? "1×" : String(format: "%g×", speed)
    }
}

/// Replaces the speed picker while a note is being recorded: pulsing red dot,
/// elapsed time, and Cancel / Save. Playback is already paused at this point
/// (`VoiceNoteRecorder.start` pauses before the mic opens).
private struct RecordingNoteBar: View {
    @Environment(VoiceNoteRecorder.self) private var recorder
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                    Text("Recording · \(PlaybackTime.string(elapsed(at: timeline.date)))")
                        .font(.callout)
                        .monospacedDigit()
                }
            }
            Spacer()
            Button("Cancel") { recorder.cancel() }
                .buttonStyle(.bordered)
            Button("Save") { recorder.stop(into: context) }
                .buttonStyle(.borderedProminent)
        }
    }

    private func elapsed(at date: Date) -> Double {
        guard let startedAt = recorder.startedAt else { return 0 }
        return max(0, date.timeIntervalSince(startedAt))
    }
}

/// Shows the spoken transcript and follows the audio: the current block is
/// highlighted and scrolled to the center, and tapping a block seeks to it.
/// Blocks are sentences (`.sentences`, the synthesized-track default) or
/// blank-line paragraphs (`.paragraphs`, imported narration prose). Timing is
/// **proportional** to elapsed playback (weighted by characters) — neither
/// `AVSpeechSynthesizer`'s offline render nor an imported package carries
/// timestamps, so this approximates the read position rather than syncing it.
struct TranscriptView: View {
    let style: PlayableItem.TranscriptStyle
    let currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void

    private let lines: [TranscriptLine]

    init(
        transcript: String,
        style: PlayableItem.TranscriptStyle = .sentences,
        currentTime: Double,
        duration: Double,
        onSeek: @escaping (Double) -> Void
    ) {
        self.style = style
        self.currentTime = currentTime
        self.duration = duration
        self.onSeek = onSeek
        self.lines = TranscriptLine.parse(transcript, style: style)
    }

    /// Index of the latest line whose proportional start time has been reached.
    private var currentIndex: Int {
        guard duration > 0 else { return 0 }
        var index = 0
        for (i, line) in lines.enumerated() where line.startTime(duration: duration) <= currentTime {
            index = i
        }
        return index
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if style == .paragraphs {
                        // No timestamps exist in a narration package, so be
                        // honest that the follow-along is an estimate.
                        Text("Highlight follows playback approximately")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line.text)
                            .font(blockFont(highlighted: index == currentIndex))
                            .lineSpacing(style == .paragraphs ? 4 : 0)
                            .foregroundStyle(index == currentIndex ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                            .id(index)
                            .onTapGesture { onSeek(line.startTime(duration: duration)) }
                    }
                }
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentIndex) { _, index in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onAppear { proxy.scrollTo(currentIndex, anchor: .center) }
        }
    }

    private func blockFont(highlighted: Bool) -> Font {
        // Sentences read like captions; imported paragraphs read like a book.
        switch style {
        case .sentences: .title3.weight(highlighted ? .semibold : .regular)
        case .paragraphs: .body.weight(highlighted ? .medium : .regular)
        }
    }
}

/// One transcript block (a sentence or a paragraph) with its character offset,
/// used to assign a proportional playback start time.
private struct TranscriptLine {
    let text: String
    let charStart: Int
    let totalChars: Int

    func startTime(duration: Double) -> Double {
        guard totalChars > 0 else { return 0 }
        return duration * Double(charStart) / Double(totalChars)
    }

    static func parse(_ transcript: String, style: PlayableItem.TranscriptStyle) -> [TranscriptLine] {
        switch style {
        case .sentences: parseSentences(transcript)
        case .paragraphs: parseParagraphs(transcript)
        }
    }

    /// Split prose into paragraphs at blank lines, mirroring the transcript
    /// file's structure.
    private static func parseParagraphs(_ transcript: String) -> [TranscriptLine] {
        let trimmed = transcript
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let paragraphs = trimmed
            .split(separator: /\n\s*\n/)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let total = paragraphs.reduce(0) { $0 + $1.count }
        var offset = 0
        return paragraphs.map { paragraph in
            let line = TranscriptLine(text: paragraph, charStart: offset, totalChars: total)
            offset += paragraph.count
            return line
        }
    }

    /// Split text into sentence-sized lines on `.`/`!`/`?`/newline boundaries.
    private static func parseSentences(_ transcript: String) -> [TranscriptLine] {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var sentences: [String] = []
        var current = ""
        for character in trimmed {
            current.append(character)
            if character == "." || character == "!" || character == "?" || character == "\n" {
                let sentence = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty { sentences.append(sentence) }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { sentences.append(tail) }
        if sentences.isEmpty { sentences = [trimmed] }

        let total = sentences.reduce(0) { $0 + $1.count }
        var offset = 0
        return sentences.map { sentence in
            let line = TranscriptLine(text: sentence, charStart: offset, totalChars: total)
            offset += sentence.count
            return line
        }
    }
}
