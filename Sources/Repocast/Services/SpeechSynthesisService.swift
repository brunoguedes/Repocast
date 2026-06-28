import AVFoundation

/// Renders text to an audio file on disk (offline TTS), rather than speaking it
/// live. Pre-rendering is what makes a real "play in the car" playlist possible:
/// each track has a stable duration, can be queued, scrubbed, and played in the
/// background without the synthesizer running.
protocol SpeechSynthesizing: Sendable {
    /// Synthesize `text` into an audio file at `url`. Returns the clip duration
    /// in seconds. Throws if nothing could be written (e.g. a non-renderable
    /// voice, or empty text).
    func render(
        text: String,
        voiceIdentifier: String?,
        rate: Float,
        pitch: Float,
        to url: URL
    ) async throws -> TimeInterval
}

struct SpeechSynthesisService: SpeechSynthesizing {
    enum SynthesisError: Error { case producedNoAudio }

    func render(
        text: String,
        voiceIdentifier: String?,
        rate: Float,
        pitch: Float,
        to url: URL
    ) async throws -> TimeInterval {
        let utterance = AVSpeechUtterance(string: text)
        if let id = voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: id) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }
        utterance.rate = rate
        utterance.pitchMultiplier = pitch

        // The synthesizer's buffer callback fires on an internal queue, so the
        // bridging state is lock-guarded and the whole renderer is treated as
        // `@unchecked Sendable`. The renderer is kept alive across the `await`
        // by the local binding below.
        let renderer = OfflineRenderer()
        return try await renderer.run(utterance: utterance, to: url)
    }
}

private final class OfflineRenderer: @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private let lock = NSLock()
    private var audioFile: AVAudioFile?
    private var continuation: CheckedContinuation<TimeInterval, Error>?
    private var didFinish = false

    func run(utterance: AVSpeechUtterance, to url: URL) async throws -> TimeInterval {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.continuation = continuation
            lock.unlock()

            synthesizer.write(utterance) { [weak self] buffer in
                self?.handle(buffer, writingTo: url)
            }
        }
    }

    private func handle(_ buffer: AVAudioBuffer, writingTo url: URL) {
        guard let pcm = buffer as? AVAudioPCMBuffer else { return }

        lock.lock()
        defer { lock.unlock() }
        guard !didFinish else { return }

        // An empty buffer signals the end of synthesis.
        if pcm.frameLength == 0 {
            if let file = audioFile {
                let duration = Double(file.length) / file.fileFormat.sampleRate
                finish(.success(duration))
            } else {
                finish(.failure(SpeechSynthesisService.SynthesisError.producedNoAudio))
            }
            return
        }

        do {
            if audioFile == nil {
                audioFile = try AVAudioFile(forWriting: url, settings: pcm.format.settings)
            }
            try audioFile?.write(from: pcm)
        } catch {
            finish(.failure(error))
        }
    }

    /// Resume the continuation exactly once. Must be called with `lock` held.
    private func finish(_ result: Result<TimeInterval, Error>) {
        guard !didFinish, let continuation else { return }
        didFinish = true
        self.continuation = nil
        audioFile = nil  // flush + close the file
        continuation.resume(with: result)
    }
}
