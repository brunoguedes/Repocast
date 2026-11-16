import Testing
import Foundation
@testable import Repocast

struct AudioTrackTests {

    @Test func defaultsToPendingVerbatim() {
        let track = AudioTrack(title: "Intro")
        #expect(track.title == "Intro")
        #expect(track.status == .pending)
        #expect(track.generationKind == .verbatim)
        #expect(track.sourceKind == .freeform)
    }

    @Test func enumAccessorsRoundTripThroughRawStrings() {
        let track = AudioTrack(title: "x")
        track.status = .ready
        track.sourceKind = .code
        track.generationKind = .summary
        #expect(track.status == .ready)
        #expect(track.sourceKind == .code)
        #expect(track.generationKind == .summary)
    }
}

struct GitHubDecodingTests {

    @Test func decodesRepoWithSnakeCaseAndPrivateKeyword() throws {
        let json = """
        { "id": 1, "name": "Repocast", "full_name": "octocat/Repocast",
          "owner": { "login": "octocat" }, "default_branch": "develop",
          "description": "audio from repos", "private": true }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let repo = try decoder.decode(GitHubRepo.self, from: Data(json.utf8))
        #expect(repo.fullName == "octocat/Repocast")
        #expect(repo.defaultBranch == "develop")
        #expect(repo.owner.login == "octocat")
        #expect(repo.isPrivate == true)
    }

    @Test func decodesBase64FileContent() {
        let file = GitHubFileContent(
            name: "README.md",
            path: "README.md",
            content: "SGVsbG8s\nIHdvcmxk",  // "Hello, world" with a newline like the API returns
            encoding: "base64"
        )
        #expect(file.decodedText() == "Hello, world")
    }

    @Test func detectsMarkdownVersusCodeByExtension() {
        #expect(AudioTrack.SourceKind.detect(path: "docs/README.md") == .markdown)
        #expect(AudioTrack.SourceKind.detect(path: "notes.TXT") == .markdown)
        #expect(AudioTrack.SourceKind.detect(path: "Sources/App.swift") == .code)
        #expect(AudioTrack.SourceKind.detect(path: "Makefile") == .code)
    }
}

struct SummarizationChunkTests {

    @Test func shortTextIsASingleChunk() {
        let chunks = SummarizationService.chunk("hello world", maxChars: 6000)
        #expect(chunks == ["hello world"])
    }

    @Test func longTextSplitsOnLineBoundaries() {
        let line = String(repeating: "x", count: 100)
        let text = Array(repeating: line, count: 50).joined(separator: "\n")  // ~5000 chars
        let chunks = SummarizationService.chunk(text, maxChars: 1000)
        #expect(chunks.count > 1)
        // No chunk exceeds the budget by more than one line, and reassembly is lossless.
        for chunk in chunks { #expect(chunk.count <= 1000 + line.count + 1) }
        let reassembled = chunks.joined().split(separator: "\n").count
        #expect(reassembled == 50)
    }
}

struct PlaybackTimeTests {

    @Test func formatsMinutesAndSeconds() {
        #expect(PlaybackTime.string(0) == "0:00")
        #expect(PlaybackTime.string(9) == "0:09")
        #expect(PlaybackTime.string(75) == "1:15")
    }

    @Test func clampsNonFiniteAndNegative() {
        #expect(PlaybackTime.string(-5) == "0:00")
        #expect(PlaybackTime.string(.nan) == "0:00")
        #expect(PlaybackTime.string(.infinity) == "0:00")
    }
}
