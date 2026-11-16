import Foundation

/// What kind of repository a tour is about, which decides its episodes:
/// codebases get Intro + Architecture, documents-only repos get Intro.
enum RepoClassification: String, Codable, CaseIterable, Sendable {
    case codebase, documents, mixed

    var label: String {
        switch self {
        case .codebase: "Codebase"
        case .documents: "Documents"
        case .mixed: "Mixed"
        }
    }
}

/// Classifies a repo from its file paths by the rule in
/// `shared/classification.json` (bundled), the same file the backend's
/// `classify.ts` reads. Both test suites run
/// `shared/fixtures/classification-cases.json`.
struct RepoClassifier: Sendable {
    struct Rules: Decodable, Sendable {
        let codebaseMinCodeRatio: Double
        let documentsMinDocRatio: Double
        let manifestMaxDepth: Int
        let manifests: [String]
        let codeExtensions: Set<String>
        let docExtensions: Set<String>
        let ignoredDirectories: Set<String>
        let entryPointStems: Set<String>
        let entryPointSuffixes: [String]
    }

    struct Result: Equatable, Sendable {
        let classification: RepoClassification
        let manifests: [String]
        let entryPoints: [String]
    }

    let rules: Rules

    /// The rules bundled with the app.
    static let bundled: RepoClassifier = {
        guard let url = Bundle.main.url(forResource: "classification", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = try? JSONDecoder().decode(Rules.self, from: data) else {
            fatalError("shared/classification.json is missing from the app bundle — check project.yml resources.")
        }
        return RepoClassifier(rules: rules)
    }()

    func classify(_ paths: [String]) -> Result {
        let kept = paths.filter { !isIgnored($0) }
        var code = 0
        var docs = 0
        for path in kept {
            let ext = Self.fileExtension(of: path)
            if rules.codeExtensions.contains(ext) {
                code += 1
            } else if rules.docExtensions.contains(ext) {
                docs += 1
            }
        }
        let counted = Double(code + docs)
        let manifests = kept.filter(isManifest)
        let entryPoints = kept.filter(isEntryPoint)

        var classification = RepoClassification.mixed
        if !manifests.isEmpty, counted > 0, Double(code) / counted >= rules.codebaseMinCodeRatio {
            classification = .codebase
        } else if manifests.isEmpty, counted > 0, Double(docs) / counted >= rules.documentsMinDocRatio {
            classification = .documents
        }
        return Result(classification: classification, manifests: manifests, entryPoints: entryPoints)
    }

    // MARK: Internals

    private func isIgnored(_ path: String) -> Bool {
        path.split(separator: "/").dropLast().contains { rules.ignoredDirectories.contains(String($0)) }
    }

    private func isManifest(_ path: String) -> Bool {
        guard path.filter({ $0 == "/" }).count <= rules.manifestMaxDepth else { return false }
        let name = Self.baseName(of: path)
        return rules.manifests.contains { pattern in
            pattern.hasPrefix("*") ? name.hasSuffix(pattern.dropFirst()) : name == pattern
        }
    }

    private func isEntryPoint(_ path: String) -> Bool {
        let name = Self.baseName(of: path)
        if rules.entryPointSuffixes.contains(where: name.hasSuffix) { return true }
        let ext = Self.fileExtension(of: path)
        guard rules.codeExtensions.contains(ext) else { return false }
        let stem = String(name.dropLast(ext.count + 1)).lowercased()
        return rules.entryPointStems.contains(stem)
    }

    private static func baseName(of path: String) -> String {
        path.split(separator: "/").last.map(String.init) ?? path
    }

    /// Lowercased extension, or "" when the name has none (or is a dotfile).
    private static func fileExtension(of path: String) -> String {
        let name = baseName(of: path)
        guard let dot = name.lastIndex(of: "."), dot > name.startIndex else { return "" }
        return name[name.index(after: dot)...].lowercased()
    }
}
