import AVFoundation
import Foundation
import SwiftData
import Testing
@testable import Repocast

/// Anchor for the test bundle, which carries shared/fixtures/classification-cases.json.
private final class TourFixtureLocator {}

// MARK: - Classification (shared vectors)

struct RepoClassifierTests {
    struct Case: Decodable {
        let name: String
        let paths: [String]
        let classification: RepoClassification
        let manifests: [String]
        let entryPoints: [String]
    }

    /// The same vectors backend/test/classify.test.ts runs.
    static let cases: [Case] = {
        let url = Bundle(for: TourFixtureLocator.self).url(forResource: "classification-cases", withExtension: "json")!
        return try! JSONDecoder().decode([Case].self, from: Data(contentsOf: url))
    }()

    @Test(arguments: cases.map(\.name))
    func matchesTheSharedVector(_ name: String) {
        let testCase = Self.cases.first { $0.name == name }!
        let result = RepoClassifier.bundled.classify(testCase.paths)
        #expect(result.classification == testCase.classification)
        #expect(result.manifests == testCase.manifests)
        #expect(result.entryPoints == testCase.entryPoints)
    }
}

// MARK: - Package naming, playlist, manifest

struct TourPackageTests {
    @Test func namesFilesLikeTheBackend() {
        let base = TourPackage.baseName(repoName: "Repocast", kind: .architecture)
        #expect(base == "Repocast_architecture")
        #expect(TourPackage.partFileName(base: base, index: 1, ext: "caf") == "Repocast_architecture_part2.caf")
        #expect(TourPackage.transcriptFileName(base: base, index: 1) == "Repocast_architecture_part2.txt")
        #expect(TourPackage.playlistTitle(repoName: "Repocast", kind: .intro) == "Repocast — Intro")
        #expect(TourPackage.baseName(repoName: "my repo!", kind: .intro) == "my_repo__intro")
    }

    /// Byte-for-byte what backend/test/package.test.ts expects, bar the extension.
    @Test func writesThePlaylistTheImporterReads() {
        let base = "Repocast_architecture"
        let parts = (0..<2).map { index in
            NarrationManifest.Part(
                file: TourPackage.partFileName(base: base, index: index, ext: "mp3"),
                title: "Section \(index + 1)",
                transcript: TourPackage.transcriptFileName(base: base, index: index),
                durationSeconds: 61.4
            )
        }
        let text = TourPackage.playlist(title: "Repocast — Architecture", base: base, parts: parts)
        #expect(text == """
        #EXTM3U
        #PLAYLIST:Repocast — Architecture
        #EXTINF:61,Section 1
        #EXT-TRANSCRIPT:Repocast_architecture_part1.txt
        Repocast_architecture_part1.mp3
        #EXTINF:61,Section 2
        #EXT-TRANSCRIPT:Repocast_architecture_part2.txt
        Repocast_architecture_part2.mp3

        """)

        let parsed = M3UPlaylist.parse(text)
        #expect(parsed.title == "Repocast — Architecture")
        #expect(parsed.entries.map(\.fileName) == parts.map(\.file))
        #expect(parsed.entries.first?.transcriptFileName == "Repocast_architecture_part1.txt")
    }

    @Test func decodesTheBackendsManifest() throws {
        let json = """
        {
          "schemaVersion": 1,
          "repo": "brunoguedes/Repocast",
          "commit": "5220ca1d0f3a5c2b6c8e9f0a1b2c3d4e5f607182",
          "episodeType": "architecture",
          "module": null,
          "executor": "cloud",
          "voice": "ElevenLabs",
          "quotaMinutes": 12.4,
          "generatedAt": "2026-11-16T07:30:12.345Z",
          "parts": [{ "file": "Repocast_architecture_part1.mp3", "title": "Entry points", "transcript": "Repocast_architecture_part1.txt", "durationSeconds": 95.2 }],
          "somethingNew": true
        }
        """
        let manifest = try NarrationManifest.decoder.decode(NarrationManifest.self, from: Data(json.utf8))
        #expect(manifest.episodeType == .architecture)
        #expect(manifest.executor == .cloud)
        #expect(manifest.quotaMinutes == 12.4)
        #expect(manifest.parts.first?.durationSeconds == 95.2)

        let roundTripped = try NarrationManifest.decoder.decode(
            NarrationManifest.self, from: NarrationManifest.encoder.encode(manifest)
        )
        #expect(roundTripped.repo == manifest.repo)
        #expect(roundTripped.parts == manifest.parts)
    }
}

// MARK: - On-device packages through the importer

@MainActor
struct TourPackageImportTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: NarrationPackage.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    /// A short silent `.caf`, the format `SpeechSynthesisService` writes.
    private func writeSilentCAF(to url: URL, seconds: Double = 0.5) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22_050, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(seconds * format.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        try file.write(from: buffer)
    }

    private func makeEpisodeFolder(sections: [String]) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("tour-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let base = TourPackage.baseName(repoName: "Repocast", kind: .architecture)
        var parts: [NarrationManifest.Part] = []
        for (index, title) in sections.enumerated() {
            let file = TourPackage.partFileName(base: base, index: index, ext: "caf")
            let transcript = TourPackage.transcriptFileName(base: base, index: index)
            try writeSilentCAF(to: directory.appendingPathComponent(file))
            try "About \(title).".write(to: directory.appendingPathComponent(transcript), atomically: true, encoding: .utf8)
            parts.append(.init(file: file, title: title, transcript: transcript, durationSeconds: 0.5))
        }
        try TourPackage.playlist(title: "Repocast — Architecture", base: base, parts: parts)
            .write(to: directory.appendingPathComponent("\(base).m3u8"), atomically: true, encoding: .utf8)
        try NarrationManifest(
            repo: "brunoguedes/Repocast", commit: String(repeating: "a", count: 40), episodeType: .architecture,
            executor: .device, voice: "Samantha", quotaMinutes: 0, generatedAt: .now, parts: parts
        ).write(to: directory)
        return directory
    }

    @Test func importsCAFPartsAsChaptersAndReplacesOnRegenerate() async throws {
        let context = try makeContext()
        let identity = TourPackage.identitySource(repoFullName: "brunoguedes/Repocast", kind: .architecture, executor: .device)
        let first = try makeEpisodeFolder(sections: ["Entry points", "Data flow", "Persistence"])
        let importer = NarrationImporter()
        let identifier = try #require(await importer.importLocalPackage(at: first, identitySource: identity, into: context))
        defer { NarrationPackageStore().delete(identifier) }

        var packages = try context.fetch(FetchDescriptor<NarrationPackage>())
        #expect(packages.count == 1)
        #expect(packages.first?.title == "Repocast — Architecture")
        #expect(packages.first?.partCount == 3)
        #expect(packages.first?.hasStitched == false)
        #expect(packages.first?.voiceName == "Samantha")

        let program = try #require(await NarrationProgramBuilder().build(
            directory: NarrationPackageStore().directory(for: identifier), baseName: "Repocast_architecture"
        ))
        #expect(program.parts.map(\.title) == ["Entry points", "Data flow", "Persistence"])
        #expect(program.parts.first?.transcript == "About Entry points.")

        // Regenerating writes a new temp folder; the stable identity keeps one library item.
        let second = try makeEpisodeFolder(sections: ["Overview", "Layers"])
        #expect(await importer.importLocalPackage(at: second, identitySource: identity, into: context) == identifier)
        packages = try context.fetch(FetchDescriptor<NarrationPackage>())
        #expect(packages.count == 1)
        #expect(packages.first?.partCount == 2)
        try? FileManager.default.removeItem(at: first)
        try? FileManager.default.removeItem(at: second)
    }

    @Test func detectsCAFBaseNamesWithoutAPlaylist() {
        #expect(NarrationImporter.detectBaseName(in: ["x_part1.caf", "x_part2.caf", "x_part1.txt"]) == "x")
        #expect(NarrationImporter.detectBaseName(in: ["solo.m4a"]) == "solo")
        #expect(NarrationProgramBuilder.partFileNames(in: ["x_part1.caf", "x_part1.wav"], baseName: "x") == ["x_part1.caf"])
    }
}

// MARK: - Prompts, config, auth helpers

struct TourPromptTests {
    @Test func fillsKnownPlaceholdersAndKeepsUnknownOnes() {
        #expect(TourPrompts.fill("{{repo}} in {{maxWords}} {{other}}", values: ["repo": "o/r", "maxWords": "500"])
            == "o/r in 500 {{other}}")
    }

    @Test func bundlesEverySharedPrompt() {
        let values = ["repo": "o/r", "classification": "codebase", "maxWords": "500", "summary": "S"]
        for name in [TourPrompts.Name.indexSummary, .intro, .architecture] {
            #expect(!TourPrompts.load(name, values: values).contains("{{"))
        }
    }
}

struct BackendConfigTests {
    @Test func staysHiddenUntilFilledIn() {
        #expect(BackendConfig.from([:]) == nil)
        #expect(BackendConfig.from([
            "RepocastAPIHost": "", "RepocastCognitoDomain": "", "RepocastCognitoClientID": "",
        ]) == nil)
        #expect(BackendConfig.from([
            "RepocastAPIHost": "$(REPOCAST_API_HOST)", "RepocastCognitoDomain": "d", "RepocastCognitoClientID": "c",
        ]) == nil)
    }

    @Test func readsHostsWithoutAScheme() throws {
        let config = try #require(BackendConfig.from([
            "RepocastAPIHost": "abc.execute-api.ap-southeast-2.amazonaws.com",
            "RepocastCognitoDomain": "repocast-dev.auth.ap-southeast-2.amazoncognito.com",
            "RepocastCognitoClientID": "client123",
        ]))
        #expect(config.apiBaseURL.absoluteString == "https://abc.execute-api.ap-southeast-2.amazonaws.com")
        #expect(config.clientID == "client123")
    }
}

@MainActor
struct CloudAccountTests {
    /// base64url(SHA-256(verifier)) without padding, checked against
    /// `printf %s <verifier> | openssl dgst -sha256 -binary | base64`.
    @Test func derivesThePKCEChallenge() {
        #expect(CloudAccount.challenge(for: "dBjftJeZ4CVP-mJ92K9qkuwjZ0yJ3U7dKoGr2pg9jlw")
            == "PFUy1HIGbHEZYWoENJprFHkmQTvEZW4KnXuVpleRW2g")
    }

    @Test func readsAClaimFromAJWT() {
        let payload = Data(#"{"email":"a@b.co","sub":"x"}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        #expect(CloudAccount.claim("email", in: "header.\(payload).sig") == "a@b.co")
        #expect(CloudAccount.claim("email", in: "garbage") == nil)
    }

    @Test func buildsAnAppleOnlyPKCEAuthorizeURL() throws {
        let account = CloudAccount(config: BackendConfig(
            apiBaseURL: URL(string: "https://api.example.com")!, cognitoDomain: "auth.example.com", clientID: "client123"
        ))
        let url = try account.authorizeURL()
        let items = Dictionary(uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
            .map { ($0.name, $0.value ?? "") })
        #expect(url.host == "auth.example.com")
        #expect(items["identity_provider"] == "SignInWithApple")
        #expect(items["code_challenge_method"] == "S256")
        #expect(items["redirect_uri"] == "repocast://auth")
        #expect(items["client_id"] == "client123")
    }
}

// MARK: - Index → plan

private struct StubGitHub: GitHubFetching {
    var paths: [String]
    var readmeText: String?

    func validate(token: String) async throws -> GitHubUser { throw GitHubError.invalidResponse }
    func repositories() async throws -> [GitHubRepo] { [] }
    func repository(owner: String, repo: String) async throws -> GitHubRepo { throw GitHubError.invalidResponse }
    func contents(owner: String, repo: String, path: String, ref: String?) async throws -> [GitHubContentEntry] { [] }
    func fileText(owner: String, repo: String, path: String, ref: String?) async throws -> String { "" }
    func headCommit(owner: String, repo: String, branch: String) async throws -> String { String(repeating: "b", count: 40) }
    func tree(owner: String, repo: String, sha: String) async throws -> GitHubTree {
        GitHubTree(tree: paths.map { .init(path: $0, type: "blob", size: 1) }, truncated: false)
    }
    func readme(owner: String, repo: String, ref: String?) async throws -> String? { readmeText }
}

/// Apple Intelligence off — exercises the README fallbacks.
private struct UnavailableWriter: TourScriptWriting {
    var isAvailable: Bool { false }
    var unavailableReason: String? { "Off" }
    func summarize(repo: String, classification: RepoClassification, material: String) async throws -> TourIndexSummary {
        throw SummarizationService.SummarizationError.unavailable
    }
    func script(kind: TourEpisode.Kind, repo: String, summary: String, material: String) async throws -> [TourPackage.Section] {
        throw SummarizationService.SummarizationError.unavailable
    }
}

@MainActor
struct TourIndexTests {
    @Test func plansIntroAndArchitectureThenFollowsTheOverride() async throws {
        let container = try ModelContainer(
            for: RepoSource.self, TourEpisode.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let repo = RepoSource(owner: "brunoguedes", name: "Repocast")
        context.insert(repo)

        let tours = TourService(
            github: StubGitHub(
                paths: ["ios/project.yml", "ios/Sources/RepocastApp.swift", "ios/Sources/Player.swift", "README.md"],
                readmeText: "# Repocast\n\n![badge](x)\n\nRepocast turns a repository into audio.\n\nMore."
            ),
            writer: UnavailableWriter()
        )
        await tours.index(repo, context: context)

        #expect(tours.indexErrors.isEmpty)
        #expect(repo.lastIndexedCommit == String(repeating: "b", count: 40))
        #expect(repo.guessedClassification == .codebase)
        #expect(repo.tourSummary == "Repocast turns a repository into audio.")
        #expect(repo.sortedTourEpisodes.map(\.kind) == [.intro, .architecture])
        #expect(repo.sortedTourEpisodes.allSatisfy { $0.status == .planned })

        tours.setClassificationOverride(.documents, for: repo, context: context)
        #expect(repo.classification == .documents)
        #expect(repo.sortedTourEpisodes.map(\.kind) == [.intro])

        tours.setClassificationOverride(nil, for: repo, context: context)
        #expect(repo.sortedTourEpisodes.map(\.kind) == [.intro, .architecture])
    }
}
