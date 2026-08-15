import Foundation
import Speech

/// On-device speech-to-text for voice notes. Protocol-backed so tests (and
/// the recorder's unit tests) can inject a mock instead of the real engine.
protocol SpeechTranscribing: Sendable {
    /// Whether transcription can run *on this device* right now.
    var isAvailable: Bool { get }
    /// Transcribe the recorded audio file. Throws when recognition is denied,
    /// unsupported, or fails.
    func transcribe(fileAt url: URL) async throws -> String
}

/// `SFSpeechRecognizer` with `requiresOnDeviceRecognition` — audio and text
/// never leave the device (see the Privacy section in CLAUDE.md), and it works
/// offline in the car. Transcription runs from the saved file *after* the
/// recording ends, so it never competes with the mic and can finish in the
/// background while the user keeps listening.
struct SpeechTranscriptionService: SpeechTranscribing {

    var isAvailable: Bool {
        guard let recognizer = SFSpeechRecognizer() else { return false }
        return recognizer.supportsOnDeviceRecognition
    }

    func transcribe(fileAt url: URL) async throws -> String {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { throw TranscriptionError.notAuthorized }
        guard let recognizer = SFSpeechRecognizer(), recognizer.supportsOnDeviceRecognition else {
            throw TranscriptionError.onDeviceUnsupported
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true  // never send audio off-device
        request.shouldReportPartialResults = false

        // The recognizer calls back multiple times on its own queue; the guard
        // makes sure the continuation resumes exactly once.
        let resumeGuard = ResumeGuard()
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    if resumeGuard.claim() {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                } else if let error {
                    if resumeGuard.claim() {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    enum TranscriptionError: Error {
        case notAuthorized
        case onDeviceUnsupported
    }

    private final class ResumeGuard: @unchecked Sendable {
        private let lock = NSLock()
        private var resumed = false

        func claim() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if resumed { return false }
            resumed = true
            return true
        }
    }
}
