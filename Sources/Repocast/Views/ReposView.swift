import SwiftUI
import SwiftData
import AVFoundation

/// Repos tab: connect GitHub, add repositories, browse their files, and turn a
/// selection into audio tracks.
struct ReposView: View {
    @Environment(GitHubAccount.self) private var account
    @Environment(\.modelContext) private var context
    @Query(sort: \RepoSource.addedAt, order: .reverse) private var repos: [RepoSource]

    @State private var showConnect = false
    @State private var showAddRepo = false

    var body: some View {
        NavigationStack {
            Group {
                if !account.isConnected {
                    ContentUnavailableView {
                        Label("Connect GitHub", systemImage: "folder.badge.plus")
                    } description: {
                        Text("Add a GitHub token to browse your repositories and turn files into audio.")
                    } actions: {
                        Button("Connect GitHub") { showConnect = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else if repos.isEmpty {
                    ContentUnavailableView {
                        Label("No Repositories", systemImage: "folder")
                    } description: {
                        Text("Add a repository to start selecting files.")
                    } actions: {
                        Button("Add Repository") { showAddRepo = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(repos) { repo in
                            NavigationLink {
                                RepoBrowserView(repo: repo, path: "")
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(repo.fullName).font(.body)
                                    if let description = repo.repoDescription, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Repos")
            .toolbar {
                if account.isConnected {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add", systemImage: "plus") { showAddRepo = true }
                    }
                }
            }
            .sheet(isPresented: $showConnect) { ConnectGitHubView() }
            .sheet(isPresented: $showAddRepo) { AddRepoView() }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(repos[index]) }
    }
}

/// Paste-a-token connect flow. The token is validated against `/user` before it
/// is saved to the Keychain.
struct ConnectGitHubView: View {
    @Environment(GitHubAccount.self) private var account
    @Environment(\.dismiss) private var dismiss

    @State private var token = ""
    @State private var connecting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Personal access token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("GitHub Token")
                } footer: {
                    Text("Create a fine-grained token at github.com/settings/tokens with read-only access to repository contents. It's kept in your device Keychain and only ever sent to GitHub.")
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Connect GitHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") { Task { await connect() } }
                        .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || connecting)
                }
            }
            .overlay {
                if connecting {
                    ProgressView("Connecting…")
                        .padding(24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }
            }
            .interactiveDismissDisabled(connecting)
        }
    }

    private func connect() async {
        connecting = true
        error = nil
        do {
            try await account.connect(token: token)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        connecting = false
    }
}

/// Lists the connected account's repositories so the user can add one.
struct AddRepoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var repos: [GitHubRepo] = []
    @State private var loading = true
    @State private var error: String?

    private let client = GitHubClient()

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading repositories…")
                } else if let error {
                    ContentUnavailableView(
                        "Couldn't Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List(repos) { repo in
                        Button { add(repo) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(repo.fullName)
                                    if repo.isPrivate {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if let description = repo.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        error = nil
        do {
            repos = try await client.repositories()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func add(_ repo: GitHubRepo) {
        context.insert(
            RepoSource(
                owner: repo.owner.login,
                name: repo.name,
                defaultBranch: repo.defaultBranch,
                repoDescription: repo.description
            )
        )
        AnalyticsService.logRepoAdded()
        dismiss()
    }
}

/// Browses one directory level of a repo. Folders push another browser; files
/// are multi-selectable and the selection generates audio tracks.
struct RepoBrowserView: View {
    let repo: RepoSource
    let path: String

    @Environment(\.modelContext) private var context

    @State private var entries: [GitHubContentEntry] = []
    @State private var loading = true
    @State private var error: String?
    @State private var selected: Set<String> = []
    @State private var generating = false
    @State private var progress = 0
    @State private var total = 0
    @State private var generator = TrackGenerator()

    @AppStorage(SettingsKeys.voiceIdentifier) private var voiceIdentifier = ""
    @AppStorage(SettingsKeys.speechRate) private var speechRate = Double(AVSpeechUtteranceDefaultSpeechRate)

    private let client = GitHubClient()
    private let summarizer = SummarizationService()

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let error {
                ContentUnavailableView(
                    "Couldn't Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                List {
                    ForEach(sortedEntries) { entry in
                        if entry.isDirectory {
                            NavigationLink {
                                RepoBrowserView(repo: repo, path: entry.path)
                            } label: {
                                Label(entry.name, systemImage: "folder")
                            }
                        } else {
                            Button { toggle(entry) } label: {
                                HStack {
                                    Image(systemName: selected.contains(entry.path) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected.contains(entry.path) ? Color.accentColor : Color.secondary)
                                    Label(entry.name, systemImage: icon(for: entry))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle(path.isEmpty ? repo.name : lastComponent(path))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !selected.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate (\(selected.count))") { Task { await generate() } }
                        .disabled(generating)
                }
            }
        }
        .overlay {
            if generating {
                ProgressView("Generating \(progress)/\(total)…")
                    .padding(24)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
            }
        }
        .task { await load() }
    }

    private var sortedEntries: [GitHubContentEntry] {
        entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func icon(for entry: GitHubContentEntry) -> String {
        AudioTrack.SourceKind.detect(path: entry.path) == .markdown
            ? "doc.text"
            : "chevron.left.forwardslash.chevron.right"
    }

    private func toggle(_ entry: GitHubContentEntry) {
        if selected.contains(entry.path) {
            selected.remove(entry.path)
        } else {
            selected.insert(entry.path)
        }
    }

    private func lastComponent(_ path: String) -> String {
        path.split(separator: "/").last.map(String.init) ?? path
    }

    private func load() async {
        loading = true
        error = nil
        do {
            entries = try await client.contents(owner: repo.owner, repo: repo.name, path: path, ref: repo.defaultBranch)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func generate() async {
        let paths = sortedEntries.filter { selected.contains($0.path) }.map(\.path)
        guard !paths.isEmpty else { return }

        generating = true
        total = paths.count
        progress = 0
        var made = 0

        for filePath in paths {
            do {
                let text = try await client.fileText(owner: repo.owner, repo: repo.name, path: filePath, ref: repo.defaultBranch)
                let detected = AudioTrack.SourceKind.detect(path: filePath)
                // Code is worth summarizing (reading it aloud verbatim is useless);
                // Markdown reads well verbatim. Fall back to verbatim if AI is off.
                let kind: AudioTrack.GenerationKind =
                    (detected == .code && summarizer.isAvailable) ? .summary : .verbatim
                let ok = await generator.generate(
                    title: lastComponent(filePath),
                    text: text,
                    kind: kind,
                    sourcePath: filePath,
                    sourceKind: detected,
                    voiceIdentifier: voiceIdentifier.isEmpty ? nil : voiceIdentifier,
                    rate: Float(speechRate),
                    into: context
                )
                if ok { made += 1 }
            } catch {
                // Skip a file that failed to fetch/render; keep the batch going.
            }
            progress += 1
        }

        if made > 0 { AnalyticsService.logTracksFromRepo(count: made) }
        generating = false
        selected.removeAll()
    }
}
