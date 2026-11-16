import AVFoundation
import Foundation

/// Abstracts the microphone behind the voice-note recorder, following the
/// repo's protocol-backed-service convention: tests (and UI tests on machines
/// where the Simulator lacks host mic access) inject a stand-in.
protocol AudioCapturing: Sendable {
    /// Request permission, configure the audio session, and start capturing
    /// to `url`. Throws `AudioCaptureError.permissionDenied` when the user
    /// refused microphone access.
    func begin(writingTo url: URL) async throws
    /// Stop capturing and return the captured duration in seconds.
    func finish() async -> Double
    /// Stop capturing and delete whatever was written.
    func discard() async
}

enum AudioCaptureError: Error {
    case permissionDenied
    case couldNotStart
}

/// The real microphone: `AVAudioRecorder` writing AAC. An actor so CoreAudio
/// spin-up — which can take a moment, and on simulators without host mic
/// access can hang outright — never runs on the main actor and can never
/// freeze the UI.
actor MicrophoneCapture: AudioCapturing {
    private var recorder: AVAudioRecorder?
    private var url: URL?

    func begin(writingTo url: URL) async throws {
        guard await AVAudioApplication.requestRecordPermission() else {
            throw AudioCaptureError.permissionDenied
        }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let recorder = try AVAudioRecorder(
            url: url,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ]
        )
        guard recorder.record() else {
            restorePlaybackSession()
            throw AudioCaptureError.couldNotStart
        }
        self.recorder = recorder
        self.url = url
    }

    func finish() async -> Double {
        guard let recorder else { return 0 }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        self.url = nil
        restorePlaybackSession()
        return duration
    }

    func discard() async {
        recorder?.stop()
        recorder = nil
        if let url {
            try? FileManager.default.removeItem(at: url)
        }
        url = nil
        restorePlaybackSession()
    }

    /// Put the session back the way `AudioPlayerService` configured it so
    /// resumed playback routes and behaves normally.
    private func restorePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }
}

/// UI-test stand-in (the `-fake-mic` launch argument): pretends to record —
/// wall-clock duration, a marker file — so the whole note pipeline can be
/// exercised without a working microphone.
actor StubAudioCapture: AudioCapturing {
    private var startedAt: Date?
    private var url: URL?

    func begin(writingTo url: URL) async throws {
        try Data("stub-recording".utf8).write(to: url)
        self.url = url
        startedAt = .now
    }

    func finish() async -> Double {
        defer { startedAt = nil; url = nil }
        guard let startedAt else { return 0 }
        return Date.now.timeIntervalSince(startedAt)
    }

    func discard() async {
        if let url {
            try? FileManager.default.removeItem(at: url)
        }
        startedAt = nil
        url = nil
    }
}
