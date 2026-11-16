import CarPlay
import SwiftData
import UIKit

/// The CarPlay experience: a tab bar of Tracks / Playlists / Narrations lists.
/// Selecting anything starts playback on the shared player and surfaces the
/// system Now Playing template, which mirrors the existing
/// `MPNowPlayingInfoCenter` + remote-command wiring — including the narration
/// packages' single aggregate timeline and ±15 s skips. Lists rebuild whenever
/// the SwiftData store saves, so the car screen tracks the phone library live.
///
/// Section/list building is separated from the `CPInterfaceController`
/// plumbing so unit tests can exercise it against an in-memory container.
@MainActor
final class CarPlayInterface {
    private let player: AudioPlayerService
    private let recorder: VoiceNoteRecorder
    private let context: ModelContext
    private let files = AudioFileStore()
    private let narrationStore = NarrationPackageStore()
    private let resumeStore = NarrationResumeStore()
    private let builder = NarrationProgramBuilder()

    private var interfaceController: CPInterfaceController?
    private var tracksTemplate: CPListTemplate?
    private var playlistsTemplate: CPListTemplate?
    private var narrationsTemplate: CPListTemplate?
    private var saveObserver: NSObjectProtocol?

    init(
        player: AudioPlayerService = .shared,
        recorder: VoiceNoteRecorder = .shared,
        context: ModelContext = DataStack.container.mainContext
    ) {
        self.player = player
        self.recorder = recorder
        self.context = context
    }

    // MARK: Lifecycle

    func connect(_ controller: CPInterfaceController) {
        interfaceController = controller

        let tracks = makeTab(
            "Tracks", image: "waveform",
            emptyTitle: "No Tracks Yet", emptySubtitle: "Generate audio on your iPhone first."
        )
        let playlists = makeTab(
            "Playlists", image: "music.note.list",
            emptyTitle: "No Playlists", emptySubtitle: "Create playlists on your iPhone."
        )
        let narrations = makeTab(
            "Narrations", image: "headphones",
            emptyTitle: "No Narrations", emptySubtitle: "Import a narration folder on your iPhone."
        )
        tracksTemplate = tracks
        playlistsTemplate = playlists
        narrationsTemplate = narrations
        refresh()

        controller.setRootTemplate(
            CPTabBarTemplate(templates: [tracks, playlists, narrations]),
            animated: false,
            completion: nil
        )

        // Keep the car lists in step with edits made on the phone.
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }

        configureNowPlayingButtons()
        observeRecorder()
        AnalyticsService.logCarPlayConnected()
    }

    func disconnect() {
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
        }
        saveObserver = nil
        interfaceController = nil
        tracksTemplate = nil
        playlistsTemplate = nil
        narrationsTemplate = nil
    }

    func refresh() {
        tracksTemplate?.updateSections(trackSections())
        playlistsTemplate?.updateSections(playlistSections())
        narrationsTemplate?.updateSections(narrationSections())
    }

    // MARK: List building (internal for tests)

    /// Ready tracks grouped by repo, mirroring the Tracks tab's on-screen order.
    func trackSections() -> [CPListSection] {
        let descriptor = FetchDescriptor<AudioTrack>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let ready = ((try? context.fetch(descriptor)) ?? []).filter { $0.status == .ready }
        let groups = ready.groupedByRepo()
        return groups.map { group in
            let items = group.tracks.map { track in
                let item = CPListItem(
                    text: track.title.isEmpty ? "Untitled" : track.title,
                    detailText: PlaybackTime.string(track.durationSeconds),
                    image: UIImage(systemName: "waveform")
                )
                item.handler = { [weak self] _, completion in
                    MainActor.assumeIsolated {
                        self?.play(track: track, within: groups)
                        completion()
                    }
                }
                return item
            }
            return CPListSection(items: items, header: group.title, sectionIndexTitle: nil)
        }
    }

    func playlistSections() -> [CPListSection] {
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let playlists = (try? context.fetch(descriptor)) ?? []
        let items = playlists.map { playlist in
            let item = CPListItem(
                text: playlist.title,
                detailText: "\(playlist.tracks.count) tracks · \(PlaybackTime.string(playlist.totalDuration))",
                image: UIImage(systemName: playlist.kind == .smart ? "sparkles" : "music.note.list")
            )
            item.handler = { [weak self] _, completion in
                MainActor.assumeIsolated {
                    self?.play(playlist: playlist)
                    completion()
                }
            }
            return item
        }
        return items.isEmpty ? [] : [CPListSection(items: items)]
    }

    func narrationSections() -> [CPListSection] {
        let descriptor = FetchDescriptor<NarrationPackage>(sortBy: [SortDescriptor(\.importedAt, order: .reverse)])
        let packages = (try? context.fetch(descriptor)) ?? []
        let items = packages.map { package in
            let form = package.hasStitched ? "Single track" : "\(package.partCount) parts"
            var detail = "\(form) · \(PlaybackTime.string(package.totalDurationSeconds))"
            if resumeStore.position(for: package.identifier) != nil {
                detail += " · In progress"
            }
            let item = CPListItem(text: package.title, detailText: detail, image: UIImage(systemName: "headphones"))
            item.handler = { [weak self] _, completion in
                MainActor.assumeIsolated {
                    self?.play(package: package, completion: completion)
                }
            }
            return item
        }
        return items.isEmpty ? [] : [CPListSection(items: items)]
    }

    // MARK: Playback

    private func play(track: AudioTrack, within groups: [RepoTrackGroup]) {
        var startAt = 0
        var items: [PlayableItem] = []
        // Queue follows the grouped order, like the phone's Tracks list.
        for candidate in groups.flatMap(\.tracks)
        where candidate.status == .ready && files.exists(candidate.audioFileName) {
            if candidate.persistentModelID == track.persistentModelID {
                startAt = items.count
            }
            items.append(
                PlayableItem(
                    id: UUID(),
                    title: candidate.title,
                    url: files.url(for: candidate.audioFileName),
                    duration: candidate.durationSeconds,
                    transcript: candidate.transcript,
                    noteAnchor: .init(kind: .track, contentID: candidate.audioFileName)
                )
            )
        }
        guard !items.isEmpty else { return }
        player.play(items: items, startAt: startAt)
        showNowPlaying()
    }

    private func play(playlist: Playlist) {
        let playable = playlist.tracks
            .filter { $0.status == .ready && files.exists($0.audioFileName) }
            .map {
                PlayableItem(
                    id: UUID(),
                    title: $0.title,
                    url: files.url(for: $0.audioFileName),
                    duration: $0.durationSeconds,
                    transcript: $0.transcript,
                    noteAnchor: .init(kind: .track, contentID: $0.audioFileName)
                )
            }
        guard !playable.isEmpty else { return }
        player.play(items: playable, startAt: 0)
        AnalyticsService.logPlaylistPlayed(smart: playlist.kind == .smart)
        showNowPlaying()
    }

    /// In the car a narration resumes automatically (no Resume/Start Over
    /// prompt) — the resume position, rewind, and persistence come from the
    /// same `NarrationPlayback` the phone detail screen uses.
    private func play(package: NarrationPackage, completion: @escaping () -> Void) {
        Task { [weak self] in
            defer { completion() }
            guard let self else { return }
            let directory = narrationStore.directory(for: package.identifier)
            guard let program = await builder.build(directory: directory, baseName: package.baseName),
                  !program.parts.isEmpty else { return }
            NarrationPlayback.resumeOrStart(
                package: package, program: program,
                player: player, resumeStore: resumeStore, context: context
            )
            showNowPlaying()
        }
    }

    // MARK: Helpers

    private func makeTab(_ title: String, image: String, emptyTitle: String, emptySubtitle: String) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        template.tabTitle = title
        template.tabImage = UIImage(systemName: image)
        template.emptyViewTitleVariants = [emptyTitle]
        template.emptyViewSubtitleVariants = [emptySubtitle]
        return template
    }

    private func showNowPlaying() {
        guard let interfaceController,
              interfaceController.topTemplate !== CPNowPlayingTemplate.shared else { return }
        interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
    }

    // MARK: Voice notes

    /// The record-note button on the car's Now Playing screen. One tap pauses
    /// playback and starts recording (mic icon); the next tap saves the note
    /// (stop icon) and on-device transcription runs in the background. State
    /// is shared with the phone, so either screen can stop a recording the
    /// other started.
    private func configureNowPlayingButtons() {
        let imageName = recorder.isRecording ? "stop.circle.fill" : "mic.circle"
        guard let image = UIImage(systemName: imageName) else { return }
        let noteButton = CPNowPlayingImageButton(image: image) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.recorder.toggle(for: self.player, into: self.context)
            }
        }
        CPNowPlayingTemplate.shared.updateNowPlayingButtons([noteButton])
    }

    /// Swap the button's icon whenever the recorder starts or stops —
    /// including when the other screen toggled it.
    private func observeRecorder() {
        guard interfaceController != nil else { return }
        withObservationTracking {
            _ = recorder.isRecording
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.interfaceController != nil else { return }
                self.configureNowPlayingButtons()
                self.observeRecorder()
            }
        }
    }
}
