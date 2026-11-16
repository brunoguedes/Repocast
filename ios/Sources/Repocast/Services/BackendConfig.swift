import Foundation

/// Where the cloud-generation backend lives, read from Info.plist keys that
/// `project.yml` fills from `Config/Backend.xcconfig` (gitignored; copy
/// `Backend.xcconfig.example`). Hosts are stored without a scheme because
/// xcconfig treats `//` as a comment. All empty → cloud features stay hidden.
struct BackendConfig: Sendable, Equatable {
    let apiBaseURL: URL
    let cognitoDomain: String
    let clientID: String

    static let redirectURI = "repocast://auth"
    static let callbackScheme = "repocast"

    static let current: BackendConfig? = from(Bundle.main.infoDictionary ?? [:])

    static func from(_ info: [String: Any]) -> BackendConfig? {
        func value(_ key: String) -> String? {
            guard let raw = (info[key] as? String)?.trimmingCharacters(in: .whitespaces),
                  !raw.isEmpty, !raw.hasPrefix("$(") else { return nil }
            return raw
        }
        guard let apiHost = value("RepocastAPIHost"),
              let domain = value("RepocastCognitoDomain"),
              let clientID = value("RepocastCognitoClientID"),
              let url = URL(string: "https://\(apiHost)") else { return nil }
        return BackendConfig(apiBaseURL: url, cognitoDomain: domain, clientID: clientID)
    }
}
