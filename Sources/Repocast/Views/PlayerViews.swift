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
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text("\(PlaybackTime.string(player.currentTime)) / \(PlaybackTime.string(player.duration))")
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
        }
    }
}

/// Full-screen transport with scrubber and speed control.
struct NowPlayingView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0

    private let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        @Bindable var player = player
        let item = player.currentItem
        let displayTime = isScrubbing ? scrubValue : player.currentTime

        VStack(spacing: 20) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text(item?.title ?? "Nothing Playing")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            if let transcript = item?.transcript, !transcript.isEmpty {
                TranscriptView(
                    transcript: transcript,
                    currentTime: displayTime,
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
                Spacer()
            }

            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { isScrubbing ? scrubValue : player.currentTime },
                        set: { scrubValue = $0; isScrubbing = true }
                    ),
                    in: 0...max(player.duration, 0.1)
                ) { editing in
                    if !editing {
                        player.seek(to: scrubValue)
                        isScrubbing = false
                    }
                }
                HStack {
                    Text(PlaybackTime.string(isScrubbing ? scrubValue : player.currentTime))
                    Spacer()
                    Text(PlaybackTime.string(player.duration))
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

            Picker("Speed", selection: $player.playbackRate) {
                ForEach(speeds, id: \.self) { speed in
                    Text(speedLabel(speed)).tag(speed)
                }
            }
            .pickerStyle(.segmented)

        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .presentationDragIndicator(.hidden)
    }

    private func speedLabel(_ speed: Float) -> String {
        speed == 1 ? "1×" : String(format: "%g×", speed)
    }
}

/// Shows the spoken transcript line-by-line and follows the audio: the current
/// line is highlighted and scrolled to the center, and tapping a line seeks to
/// it. Timing is **proportional** to elapsed playback (weighted by characters) —
/// `AVSpeechSynthesizer`'s offline render emits no per-word marks, so this
/// approximates the read position rather than phoneme-syncing it.
struct TranscriptView: View {
    let currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void

    private let lines: [TranscriptLine]

    init(transcript: String, currentTime: Double, duration: Double, onSeek: @escaping (Double) -> Void) {
        self.currentTime = currentTime
        self.duration = duration
        self.onSeek = onSeek
        self.lines = TranscriptLine.parse(transcript)
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
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line.text)
                            .font(.title3.weight(index == currentIndex ? .semibold : .regular))
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
}

/// One transcript line (a sentence) with its character offset, used to assign a
/// proportional playback start time.
private struct TranscriptLine {
    let text: String
    let charStart: Int
    let totalChars: Int

    func startTime(duration: Double) -> Double {
        guard totalChars > 0 else { return 0 }
        return duration * Double(charStart) / Double(totalChars)
    }

    /// Split text into sentence-sized lines on `.`/`!`/`?`/newline boundaries.
    static func parse(_ transcript: String) -> [TranscriptLine] {
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
