import AVFoundation
import MediaPlayer
import Observation

/// A value snapshot of one queued clip. Decouples the player from the SwiftData
/// `AudioTrack` (so the player is trivially unit-testable and never holds a
/// managed object).
struct PlayableItem: Identifiable, Sendable, Equatable {
    /// How the transcript is structured on the Now Playing screen.
    enum TranscriptStyle: Sendable {
        case sentences   // synthesized flow, split at sentence boundaries
        case paragraphs  // imported prose, blank-line paragraph blocks
    }

    /// Stable link back to the library content this clip came from, so a
    /// voice note recorded during playback can attach to it — and later
    /// reopen it at the noted time code. Uses the same durable string keys as
    /// resume positions (file names / package identifiers), never indices.
    /// `nil` (e.g. when playing back a note's own audio) disables recording.
    struct NoteAnchor: Sendable, Equatable {
        enum Kind: String, Sendable {
            case track      // an `AudioTrack`; `contentID` is its audioFileName
            case narration  // a `NarrationPackage`; `contentID` is its identifier
        }

        var kind: Kind
        var contentID: String
        /// For narrations, the part file this clip plays; empty for tracks.
        var itemFileName: String = ""
    }

    let id: UUID
    let title: String
    let url: URL
    let duration: Double
    /// The text that was synthesized into this clip, shown and synced on the
    /// Now Playing screen. Empty when unknown.
    var transcript: String = ""
    var transcriptStyle: TranscriptStyle = .sentences
    var noteAnchor: NoteAnchor? = nil
}

/// How the queue is presented to the listener: as independent tracks (the
/// library default) or as one continuous work — a narration package — whose
/// queued items are chapters of a single aggregate timeline.
enum QueuePresentation: Equatable, Sendable {
    case trackList
    case continuous(title: String)
}

/// The app-lifetime audio player. Owns one `AVPlayer`, configures the audio
/// session for background / lock-screen / CarPlay playback, and mirrors the
/// system Now Playing + remote-command surface so the clip keeps playing and
/// stays controllable when the screen is off.
@MainActor
@Observable
final class AudioPlayerService {
    /// The single app-lifetime player. Shared (rather than created by
    /// `ContentView`) so the CarPlay scene and the phone UI control the same
    /// playback — starting a track in the car updates the phone's mini-player
    /// and vice versa.
    static let shared = AudioPlayerService()

    private(set) var queue: [PlayableItem] = []
    private(set) var currentIndex = 0
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var presentation: QueuePresentation = .trackList

    /// Playback speed (1.0 = normal). Held across track changes.
    var playbackRate: Float = 1.0 {
        didSet { applyRate() }
    }

    /// Reports the current item index + offset within it so the caller that
    /// started playback can persist a resume position. Fired on pause, seek,
    /// track change, interruption, and every few seconds while playing.
    /// `play(items:)` clears both handlers, so set them right after starting.
    var onProgress: ((_ index: Int, _ offset: Double) -> Void)?
    /// Fired once when the queue plays through to its natural end.
    var onFinished: (() -> Void)?

    var currentItem: PlayableItem? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    var duration: Double { currentItem?.duration ?? 0 }

    var isContinuous: Bool {
        if case .continuous = presentation { return true }
        return false
    }

    // MARK: Presented timeline
    // What the transport UI and lock screen show: per-item values for a track
    // list, aggregate values across the whole queue for a continuous work.

    var displayTitle: String? {
        switch presentation {
        case .continuous(let title): title
        case .trackList: currentItem?.title
        }
    }

    var displayDuration: Double {
        isContinuous ? queue.reduce(0) { $0 + $1.duration } : duration
    }

    var displayTime: Double {
        isContinuous ? elapsedBefore(currentIndex) + min(currentTime, duration) : currentTime
    }

    private let player = AVPlayer()
    private var endObserver: NSObjectProtocol?
    private var lastProgressReport = Date.distantPast

    init() {
        configureAudioSession()
        configureRemoteCommands()
        observeInterruptions()
        addTimeObserver()
    }

    // MARK: Transport

    /// Replace the queue and start playing at `startAt` (+ `offset` seconds
    /// into it — how a narration package resumes mid-part).
    func play(
        items: [PlayableItem],
        startAt index: Int,
        offset: Double = 0,
        presentation: QueuePresentation = .trackList
    ) {
        guard !items.isEmpty else { return }
        onProgress = nil
        onFinished = nil
        self.presentation = presentation
        queue = items
        currentIndex = min(max(index, 0), items.count - 1)
        loadCurrent()
        if offset > 0 { seek(to: offset) }
        play()
        AnalyticsService.logPlaybackStarted(rate: playbackRate)
    }

    func play() {
        guard currentItem != nil else { return }
        player.rate = playbackRate
        isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlaying()
        reportProgress()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func next() {
        guard currentIndex + 1 < queue.count else {
            pause()
            seek(to: duration)
            return
        }
        currentIndex += 1
        loadCurrent()
        play()
        reportProgress()
    }

    func previous() {
        // Standard player behavior: restart the current clip unless we're near
        // its start, in which case step back a track.
        if currentTime > 3 || currentIndex == 0 {
            seek(to: 0)
        } else {
            currentIndex -= 1
            loadCurrent()
            play()
            reportProgress()
        }
    }

    /// Seek within the current item.
    func seek(to seconds: Double) {
        let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        player.seek(to: target)
        currentTime = max(0, seconds)
        updateNowPlaying()
        reportProgress()
    }

    /// Seek on the presented timeline — for a continuous work this maps the
    /// aggregate position to (part, offset) and hops parts as needed, so one
    /// scrubber spans the whole package.
    func seek(toDisplayTime seconds: Double) {
        guard isContinuous else {
            seek(to: seconds)
            return
        }
        var remaining = max(0, min(seconds, displayDuration))
        var index = 0
        while index < queue.count - 1, remaining >= queue[index].duration {
            remaining -= queue[index].duration
            index += 1
        }
        if index != currentIndex {
            currentIndex = index
            loadCurrent()
        }
        seek(to: remaining)
        if isPlaying { play() }
    }

    func skipForward(_ seconds: Double = 15) {
        seek(toDisplayTime: displayTime + seconds)
    }

    func skipBackward(_ seconds: Double = 15) {
        seek(toDisplayTime: displayTime - seconds)
    }

    /// Flush the current position to `onProgress` — called when the app
    /// backgrounds so a subsequent termination loses nothing.
    func saveProgressNow() {
        reportProgress()
    }

    // MARK: Internals

    private func elapsedBefore(_ index: Int) -> Double {
        queue.prefix(index).reduce(0) { $0 + $1.duration }
    }

    private func reportProgress() {
        lastProgressReport = .now
        onProgress?(currentIndex, currentTime)
    }

    /// The current item played through to its end: advance, or wrap up the
    /// queue (a finished narration clears its saved resume position via
    /// `onFinished`).
    private func handleItemEnded() {
        if currentIndex + 1 < queue.count {
            currentIndex += 1
            loadCurrent()
            play()
            reportProgress()
        } else {
            pause()
            currentTime = duration
            updateNowPlaying()
            onFinished?()
        }
    }

    private func loadCurrent() {
        guard let item = currentItem else { return }
        let playerItem = AVPlayerItem(url: item.url)
        playerItem.audioTimePitchAlgorithm = .timeDomain  // keep voice natural when sped up

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleItemEnded() }
        }

        player.replaceCurrentItem(with: playerItem)
        currentTime = 0
    }

    private func applyRate() {
        if isPlaying { player.rate = playbackRate }
        updateNowPlaying()
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self else { return }
                let seconds = time.seconds
                self.currentTime = seconds.isFinite ? seconds : 0
                self.updateNowPlaying()
                // Keep the persisted resume position a few seconds fresh so a
                // crash mid-playback loses almost nothing.
                if self.isPlaying, Date.now.timeIntervalSince(self.lastProgressReport) >= 5 {
                    self.reportProgress()
                }
            }
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    /// Pause (saving position) when a call or other audio interrupts, and
    /// resume only when the system says the interruption ended cleanly.
    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            let typeRaw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            MainActor.assumeIsolated {
                guard let self, let typeRaw, let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
                switch type {
                case .began:
                    if self.isPlaying { self.pause() }
                case .ended:
                    if AVAudioSession.InterruptionOptions(rawValue: optionsRaw ?? 0).contains(.shouldResume) {
                        self.play()
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.togglePlayPause() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.previous() }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.skipForward() }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.skipBackward() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return }
                self.seek(toDisplayTime: positionEvent.positionTime)
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let item = currentItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        // The lock screen mirrors the presented timeline: for a continuous
        // work that's the part title over the package name with aggregate
        // elapsed/total, so scrubbing there spans the whole package too.
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyPlaybackDuration: displayDuration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: displayTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0,
        ]
        if case .continuous(let title) = presentation {
            info[MPMediaItemPropertyAlbumTitle] = title
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
