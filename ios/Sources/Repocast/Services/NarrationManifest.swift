import Foundation

/// `manifest.json` beside a narration package's playlist — what repo and
/// commit an episode was built from, by which executor, and what it cost.
/// Schema: `shared/narration-manifest.schema.json`. Optional: Studio exports
/// have none, and the importer ignores files it doesn't know.
struct NarrationManifest: Codable, Equatable, Sendable {
    struct Part: Codable, Equatable, Sendable {
        let file: String
        let title: String
        let transcript: String
        var durationSeconds: Double?
    }

    var schemaVersion = 1
    let repo: String
    let commit: String
    let episodeType: TourEpisode.Kind
    var module: String?
    let executor: TourEpisode.Executor
    var voice: String?
    var quotaMinutes: Double
    let generatedAt: Date
    let parts: [Part]

    static let fileName = "manifest.json"

    static func load(from directory: URL) -> NarrationManifest? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(fileName)) else { return nil }
        return try? decoder.decode(NarrationManifest.self, from: data)
    }

    func write(to directory: URL) throws {
        try Self.encoder.encode(self).write(to: directory.appendingPathComponent(Self.fileName))
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: text) ?? ISO8601DateFormatter().date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(text)"))
        }
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
}
