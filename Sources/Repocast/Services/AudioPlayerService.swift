import AVFoundation
import MediaPlayer
import Observation

/// A value snapshot of one queued clip. Decouples the player from the SwiftData
/// `AudioTrack` (so the player is trivially unit-testable and never holds a
/// managed object).
struct PlayableItem: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
    let url: URL
    let duration: Double
    /// The text that was synthesized into this clip, shown and synced on the
    /// Now Playing screen. Empty when unknown.
    var transcript: String = ""
}

/// The app-lifetime audio player. Owns one `AVPlayer`, configures the audio
/// session for background / lock-screen / CarPlay playback, and mirrors the
/// system Now Playing + remote-command surface so the clip keeps playing and
/// stays controllable when the screen is off.
@MainActor
@Observable
final class AudioPlayerService {
    private(set) var queue: [PlayableItem] = []
    private(set) var currentIndex = 0
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0

    /// Playback speed (1.0 = normal). Held across track changes.
    var playbackRate: Float = 1.0 {
        didSet { applyRate() }
    }

    var currentItem: PlayableItem? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    var duration: Double { currentItem?.duration ?? 0 }

    private let player = AVPlayer()
    private var endObserver: NSObjectProtocol?

    init() {
        configureAudioSession()
        configureRemoteCommands()
        addTimeObserver()
    }

    // MARK: Transport

    /// Replace the queue and start playing at `startAt`.
    func play(items: [PlayableItem], startAt index: Int) {
        guard !items.isEmpty else { return }
        queue = items
        currentIndex = min(max(index, 0), items.count - 1)
        loadCurrent()
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
        }
    }

    func seek(to seconds: Double) {
        let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        player.seek(to: target)
        currentTime = max(0, seconds)
        updateNowPlaying()
    }

    // MARK: Internals

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
            MainActor.assumeIsolated { self?.next() }
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
            }
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
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
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return }
                self.seek(to: positionEvent.positionTime)
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let item = currentItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyPlaybackDuration: item.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0,
        ]
    }
}
