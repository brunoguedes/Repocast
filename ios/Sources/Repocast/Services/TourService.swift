import AVFoundation
import Foundation
import Observation
import SwiftData

/// The repo tour, end to end. App-lifetime and injected like `GitHubAccount`.
///
/// - **Index** (eager, cheap, on add): HEAD commit, file tree, README and
///   manifests → `RepoClassifier` → a one-paragraph summary → planned
///   `TourEpisode`s with titles and estimates, before any audio exists.
/// - **Generate** (lazy, on tap): on device — `TourScriptWriter` +
///   `SpeechSynthesizing` → a `.caf` narration package — or in the cloud —
///   `CloudTourClient` → a downloaded `.mp3` package. Either way the package is
///   imported through `NarrationImporter`, so episodes show up under
///   Narrations and in CarPlay like any other narration.
@MainActor
@Observable
final class TourService {
    /// Repos being indexed right now, by `fullName`.
    private(set) var indexing: Set<String> = []
    /// Last index failure per repo, by `fullName`.
    private(set) var indexErrors: [String: String] = [:]
    /// What each in-flight episode is doing, by `key(for:)`.
    private(set) var progress: [String: String] = [:]

    private let github: GitHubFetching
    private let writer: TourScriptWriting
    private let synthesizer: SpeechSynthesizing
    private let importer: NarrationImporter
    private let cloud: CloudTourClient
    private let classifier: RepoClassifier

    init(
        github: GitHubFetching = GitHubClient(),
        writer: TourScriptWriting = TourScriptWriter(),
        synthesizer: SpeechSynthesizing = SpeechSynthesisService(),
        importer: NarrationImporter = NarrationImporter(),
        cloud: CloudTourClient = CloudTourClient(),
        classifier: RepoClassifier = .bundled
    ) {
        self.github = github
        self.writer = writer
        self.synthesizer = synthesizer
        self.importer = importer
        self.cloud = cloud
        self.classifier = classifier
    }

    var canWriteOnDevice: Bool { writer.isAvailable }
    var onDeviceUnavailableReason: String? { writer.unavailableReason }

    func key(for episode: TourEpisode) -> String {
        "\(episode.repo?.fullName ?? "")/\(episode.kind.rawValue)"
    }

    // MARK: Index

    /// Index `repo` at its default branch's HEAD. Skips the work when that
    /// commit is already indexed, unless `force`.
    func index(_ repo: RepoSource, context: ModelContext, force: Bool = false) async {
        let fullName = repo.fullName
        guard !indexing.contains(fullName) else { return }
        indexing.insert(fullName)
        indexErrors[fullName] = nil
        defer { indexing.remove(fullName) }
        recoverInterrupted(repo)

        do {
            let commit = try await github.headCommit(owner: repo.owner, repo: repo.name, branch: repo.defaultBranch)
            if !force, commit == repo.lastIndexedCommit, !(repo.tourEpisodes ?? []).isEmpty { return }

            let (tree, readme) = try await treeAndReadme(owner: repo.owner, name: repo.name, commit: commit)
            let paths = tree.filePaths
            let result = classifier.classify(paths)

            var summary = Self.fallbackSummary(readme: readme, repo: repo)
            var titles = (intro: "What \(repo.name) is for", architecture: "How \(repo.name) is built")
            if writer.isAvailable {
                let material = [
                    TourMaterial.readme(readme),
                    TourMaterial.section("File tree", TourMaterial.listing(paths, limit: 150)),
                    await manifestSections(repo: repo, commit: commit, manifests: result.manifests),
                ].joined(separator: "\n")
                // The model is a nicety here — fall back to the README rather than fail the index.
                if let generated = try? await writer.summarize(
                    repo: fullName, classification: result.classification, material: material
                ) {
                    summary = generated.summary
                    titles = (generated.introTitle, generated.architectureTitle)
                }
            }

            repo.lastIndexedCommit = commit
            repo.guessedClassification = result.classification
            repo.tourSummary = summary
            replan(repo, titles: titles, commit: commit, context: context)
            try? context.save()
            AnalyticsService.logTourIndexed(classification: result.classification.rawValue, files: paths.count)
        } catch {
            indexErrors[fullName] = error.localizedDescription
            AnalyticsService.logTourIndexFailed()
        }
    }

    /// Apply the user's classification override (or clear it) and replan.
    func setClassificationOverride(_ classification: RepoClassification?, for repo: RepoSource, context: ModelContext) {
        repo.classificationOverride = classification
        if let classification { AnalyticsService.logTourClassificationOverridden(classification: classification.rawValue) }
        replan(repo, titles: nil, commit: repo.lastIndexedCommit, context: context)
        try? context.save()
    }

    /// Bring the planned episodes in line with the classification:
    /// documents-only repos get an intro, everything else intro + architecture.
    /// Ready and in-flight episodes are never removed.
    private func replan(
        _ repo: RepoSource,
        titles: (intro: String, architecture: String)?,
        commit: String?,
        context: ModelContext
    ) {
        let wanted: [TourEpisode.Kind] = repo.classification == .documents ? [.intro] : [.intro, .architecture]
        for episode in repo.tourEpisodes ?? [] where !wanted.contains(episode.kind) {
            if episode.status == .planned || episode.status == .failed { context.delete(episode) }
        }
        for (position, kind) in wanted.enumerated() {
            let title = switch kind {
            case .intro: titles?.intro ?? "What \(repo.name) is for"
            case .architecture: titles?.architecture ?? "How \(repo.name) is built"
            }
            if let existing = repo.tourEpisodes?.first(where: { $0.kind == kind }) {
                if titles != nil { existing.title = title }
                existing.position = position
                if let commit, existing.status != .ready, existing.status != .generating { existing.commit = commit }
            } else {
                let episode = TourEpisode(
                    kind: kind,
                    title: title,
                    estimatedMinutes: TourBudget.estimatedMinutes(kind, executor: .device),
                    commit: commit ?? "",
                    position: position
                )
                context.insert(episode)
                episode.repo = repo
            }
        }
    }

    /// An episode left `generating` by a previous launch can't still be running.
    private func recoverInterrupted(_ repo: RepoSource) {
        for episode in repo.tourEpisodes ?? [] where episode.status == .generating && progress[key(for: episode)] == nil {
            episode.status = episode.narrationIdentifier == nil ? .planned : .ready
        }
    }

    // MARK: Generate

    private enum Stage: String {
        case fetch, script, audio, download, importing = "import"
    }

    private struct StageError: Error {
        let stage: Stage
        let underlying: Error
    }

    /// Generate `episode`'s audio and import it as a narration package.
    func generate(
        _ episode: TourEpisode,
        executor: TourEpisode.Executor,
        account: CloudAccount,
        voiceIdentifier: String?,
        rate: Float,
        context: ModelContext
    ) async {
        guard let repo = episode.repo else { return }
        let key = key(for: episode)
        guard progress[key] == nil else { return }
        progress[key] = "Starting…"
        episode.status = .generating
        episode.errorMessage = nil
        try? context.save()
        defer { progress[key] = nil }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("tour-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            switch executor {
            case .device:
                try await renderOnDevice(episode, repo: repo, into: directory, voiceIdentifier: voiceIdentifier, rate: rate, key: key)
            case .cloud:
                try await fetchFromCloud(episode, repo: repo, into: directory, account: account, key: key)
            }

            progress[key] = "Adding to your library…"
            guard let identifier = await importer.importLocalPackage(
                at: directory,
                identitySource: TourPackage.identitySource(repoFullName: repo.fullName, kind: episode.kind, executor: executor),
                into: context
            ) else {
                let message = if case let .failed(text) = importer.phase { text } else { "Import failed." }
                importer.dismissFailure()
                throw StageError(stage: .importing, underlying: CloudTourClient.CloudTourError.failed(message))
            }

            episode.narrationIdentifier = identifier
            episode.executor = executor
            episode.status = .ready
            try? context.save()
            let minutes = (NarrationManifest.load(from: directory)?.parts.compactMap(\.durationSeconds).reduce(0, +) ?? 0) / 60
            AnalyticsService.logTourEpisodeGenerated(type: episode.kind.rawValue, executor: executor.rawValue, minutes: Int(minutes.rounded()))
            if executor == .cloud { await account.refreshUsage() }
        } catch {
            let stageError = error as? StageError
            episode.status = .failed
            episode.errorMessage = (stageError?.underlying ?? error).localizedDescription
            try? context.save()
            AnalyticsService.logTourEpisodeFailed(
                type: episode.kind.rawValue, executor: executor.rawValue, stage: (stageError?.stage ?? .fetch).rawValue
            )
        }
    }

    private func renderOnDevice(
        _ episode: TourEpisode, repo: RepoSource, into directory: URL, voiceIdentifier: String?, rate: Float, key: String
    ) async throws {
        progress[key] = "Reading the repository…"
        let commit = repo.lastIndexedCommit ?? episode.commit
        let material: String
        do {
            material = try await episodeMaterial(episode.kind, repo: repo, commit: commit)
        } catch {
            throw StageError(stage: .fetch, underlying: error)
        }

        progress[key] = "Writing the script…"
        let sections: [TourPackage.Section]
        do {
            sections = try await writer.script(
                kind: episode.kind, repo: repo.fullName, summary: repo.tourSummary ?? "", material: material
            )
            guard !sections.isEmpty else { throw CloudTourClient.CloudTourError.failed("The script came back empty.") }
        } catch {
            throw StageError(stage: .script, underlying: error)
        }

        let base = TourPackage.baseName(repoName: repo.name, kind: episode.kind)
        var parts: [NarrationManifest.Part] = []
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for (index, section) in sections.enumerated() {
                progress[key] = "Recording part \(index + 1) of \(sections.count)…"
                let file = TourPackage.partFileName(base: base, index: index, ext: "caf")
                let transcript = TourPackage.transcriptFileName(base: base, index: index)
                let duration = try await synthesizer.render(
                    text: section.text, voiceIdentifier: voiceIdentifier, rate: rate, pitch: 1.0,
                    to: directory.appendingPathComponent(file)
                )
                try section.text.write(to: directory.appendingPathComponent(transcript), atomically: true, encoding: .utf8)
                parts.append(.init(file: file, title: section.title, transcript: transcript, durationSeconds: duration))
            }
            let title = TourPackage.playlistTitle(repoName: repo.name, kind: episode.kind)
            try TourPackage.playlist(title: title, base: base, parts: parts)
                .write(to: directory.appendingPathComponent("\(base).m3u8"), atomically: true, encoding: .utf8)
            try NarrationManifest(
                repo: repo.fullName,
                commit: commit,
                episodeType: episode.kind,
                executor: .device,
                voice: voiceIdentifier.flatMap { AVSpeechSynthesisVoice(identifier: $0)?.name },
                quotaMinutes: 0,
                generatedAt: .now,
                parts: parts
            ).write(to: directory)
        } catch {
            throw StageError(stage: .audio, underlying: error)
        }
    }

    private func fetchFromCloud(
        _ episode: TourEpisode, repo: RepoSource, into directory: URL, account: CloudAccount, key: String
    ) async throws {
        let episodePath = "/repos/\(repo.owner)/\(repo.name)/episodes/\(episode.kind.rawValue)"
        let ready: CloudTourClient.EpisodeStatus
        do {
            progress[key] = "Preparing the cloud tour…"
            let added = try await cloud.addRepo(repo.fullName, request: try await account.authorizedRequest(path: "/repos"))
            let tour = try await poll(every: .seconds(3), timeout: .seconds(180)) { [cloud] in
                let tour = try await cloud.tour(
                    request: try await account.authorizedRequest(path: "/repos/\(repo.owner)/\(repo.name)/tour"),
                    commit: added.commit
                )
                if tour.status == "failed" { throw CloudTourClient.CloudTourError.failed(tour.error ?? "Indexing failed.") }
                return tour.status == "ready" ? tour : nil
            }
            guard tour.episodes?.contains(where: { $0.type == episode.kind.rawValue }) == true else {
                throw CloudTourClient.CloudTourError.failed("The cloud tour has no \(episode.kind.label.lowercased()) episode for this repository.")
            }

            _ = try await cloud.startEpisode(commit: added.commit, request: try await account.authorizedRequest(path: episodePath))
            ready = try await poll(every: .seconds(5), timeout: .seconds(25 * 60)) { [cloud] in
                let status = try await cloud.episode(request: try await account.authorizedRequest(path: episodePath), commit: added.commit)
                switch status.status {
                case "ready": return status
                case "failed": throw CloudTourClient.CloudTourError.failed(status.error ?? "Cloud generation failed.")
                case "scripting": self.progress[key] = "Writing the script in the cloud…"
                case "rendering": self.progress[key] = "Recording in the cloud…"
                default: self.progress[key] = "Queued in the cloud…"
                }
                return nil
            }
        } catch {
            throw StageError(stage: .script, underlying: error)
        }

        do {
            progress[key] = "Downloading…"
            try await cloud.download(ready.files ?? [], to: directory)
        } catch {
            throw StageError(stage: .download, underlying: error)
        }
    }

    /// Calls `check` until it returns a value, sleeping `interval` between
    /// tries; throws `.timedOut` after `timeout`.
    private func poll<T>(every interval: Duration, timeout: Duration, _ check: () async throws -> T?) async throws -> T {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if let value = try await check() { return value }
            try await Task.sleep(for: interval)
        }
        throw CloudTourClient.CloudTourError.timedOut
    }

    // MARK: Material

    private func episodeMaterial(_ kind: TourEpisode.Kind, repo: RepoSource, commit: String) async throws -> String {
        let (tree, readme) = try await treeAndReadme(owner: repo.owner, name: repo.name, commit: commit)
        let result = classifier.classify(tree.filePaths)
        let manifests = await manifestSections(repo: repo, commit: commit, manifests: result.manifests)
        switch kind {
        case .intro:
            return [TourMaterial.readme(readme), manifests].joined(separator: "\n")
        case .architecture:
            // On device there's no model call to pick key files; entry points
            // found by the shared rule stand in for them.
            var keyFiles: [String] = []
            for path in result.entryPoints.prefix(6) {
                if let text = try? await github.fileText(owner: repo.owner, repo: repo.name, path: path, ref: commit) {
                    keyFiles.append(TourMaterial.section(path, TourMaterial.clip(text, 4000)))
                }
            }
            return [
                TourMaterial.section("File tree", TourMaterial.listing(tree.filePaths, limit: 300)),
                manifests,
                keyFiles.joined(separator: "\n"),
                TourMaterial.readme(readme),
            ].joined(separator: "\n")
        }
    }

    /// Fetches the tree and README in parallel. Takes plain strings so nothing
    /// non-`Sendable` crosses into the child tasks.
    private func treeAndReadme(owner: String, name: String, commit: String) async throws -> (GitHubTree, String?) {
        async let tree = github.tree(owner: owner, repo: name, sha: commit)
        async let readme = github.readme(owner: owner, repo: name, ref: commit)
        return try await (tree, readme)
    }

    private func manifestSections(repo: RepoSource, commit: String, manifests: [String]) async -> String {
        var sections: [String] = []
        for path in manifests.prefix(3) {
            if let text = try? await github.fileText(owner: repo.owner, repo: repo.name, path: path, ref: commit) {
                sections.append(TourMaterial.section(path, TourMaterial.clip(text, 3000)))
            }
        }
        return sections.joined(separator: "\n")
    }

    /// Without Apple Intelligence: the README's first prose paragraph.
    static func fallbackSummary(readme: String?, repo: RepoSource) -> String {
        let paragraph = readme?
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { paragraph in
                guard let first = paragraph.first else { return false }
                return first.isLetter && !paragraph.hasPrefix("<")
            }
        return paragraph?.replacing(/[*_`#>\[\]]/, with: "") ?? repo.repoDescription ?? repo.fullName
    }
}

/// How repo text is laid out for the model — the same `## title` sections the
/// backend uses (`backend/src/lib/material.ts`).
enum TourMaterial {
    static func section(_ title: String, _ body: String) -> String {
        "## \(title)\n\n\(body.trimmingCharacters(in: .whitespacesAndNewlines))\n"
    }

    static func readme(_ text: String?) -> String {
        section("README", text.map { clip($0, 8000) } ?? "(This repository has no README.)")
    }

    static func clip(_ text: String, _ max: Int) -> String {
        text.count > max ? String(text.prefix(max)) + "\n… (truncated)" : text
    }

    static func listing(_ paths: [String], limit: Int) -> String {
        let shown = paths.prefix(limit).joined(separator: "\n")
        return paths.count > limit ? "\(shown)\n… and \(paths.count - limit) more files" : shown
    }
}
