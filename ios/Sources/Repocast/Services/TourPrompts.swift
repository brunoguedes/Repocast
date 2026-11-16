import Foundation

/// The tour prompts from `shared/prompts` (bundled as the `prompts` folder),
/// shared with the backend so both executors aim at the same episodes. Each
/// prompt is instructions only; callers append `---` and the repo material,
/// the same layout `SummarizationService` uses.
enum TourPrompts {
    enum Name: String {
        case indexSummary = "index-summary"
        case intro
        case architecture

        init(_ kind: TourEpisode.Kind) {
            switch kind {
            case .intro: self = .intro
            case .architecture: self = .architecture
            }
        }
    }

    static func load(_ name: Name, values: [String: String], bundle: Bundle = .main) -> String {
        guard let url = bundle.url(forResource: name.rawValue, withExtension: "md", subdirectory: "prompts"),
              let template = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("shared/prompts/\(name.rawValue).md is missing from the app bundle — check project.yml resources.")
        }
        return fill(template, values: values)
    }

    /// Replaces `{{key}}` placeholders; unknown keys are left as they are.
    static func fill(_ template: String, values: [String: String]) -> String {
        template.replacing(/\{\{(\w+)\}\}/) { match in
            values[String(match.1)] ?? String(match.0)
        }
    }
}
