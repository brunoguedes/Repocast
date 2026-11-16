import AuthenticationServices
import AVFoundation
import SwiftData
import SwiftUI

/// The repo's guided tour, at the top of the repo's root browser: the index's
/// summary, its classification (overridable), and one row per episode.
struct TourSection: View {
    let repo: RepoSource

    @Environment(TourService.self) private var tours
    @Environment(\.modelContext) private var context

    var body: some View {
        Section {
            if let summary = repo.tourSummary, !summary.isEmpty {
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let error = tours.indexErrors[repo.fullName] {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error).font(.callout)
                        Button("Try Again") { Task { await tours.index(repo, context: context, force: true) } }
                            .font(.callout)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                }
            } else if tours.indexing.contains(repo.fullName), repo.sortedTourEpisodes.isEmpty {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Reading the repository…").foregroundStyle(.secondary)
                }
            }
            ForEach(repo.sortedTourEpisodes) { episode in
                TourEpisodeRow(episode: episode)
            }
        } header: {
            HStack {
                Text("Tour")
                Spacer()
                if repo.guessedClassification != nil { classificationMenu }
            }
        }
    }

    private var classificationMenu: some View {
        Menu {
            Picker("Repository Type", selection: Binding(
                get: { repo.classificationOverride },
                set: { tours.setClassificationOverride($0, for: repo, context: context) }
            )) {
                Text("Automatic (\(repo.guessedClassification?.label ?? "—"))").tag(RepoClassification?.none)
                ForEach(RepoClassification.allCases, id: \.self) { classification in
                    Text(classification.label).tag(Optional(classification))
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(repo.classification?.label ?? "")
                Image(systemName: "chevron.up.chevron.down").imageScale(.small)
            }
            .font(.caption)
            .textCase(nil)
        }
        .accessibilityLabel("Repository type: \(repo.classification?.label ?? "unknown")")
    }
}

/// One tour episode: its estimated length before audio exists, progress while
/// generating, then a link to the narration once ready.
struct TourEpisodeRow: View {
    let episode: TourEpisode

    @Environment(TourService.self) private var tours
    @Environment(CloudAccount.self) private var account
    @Environment(\.modelContext) private var context
    @Query private var packages: [NarrationPackage]
    @State private var showSignIn = false

    @AppStorage(SettingsKeys.voiceIdentifier) private var voiceIdentifier = ""
    @AppStorage(SettingsKeys.speechRate) private var speechRate = Double(AVSpeechUtteranceDefaultSpeechRate)

    init(episode: TourEpisode) {
        self.episode = episode
        let identifier = episode.narrationIdentifier ?? ""
        _packages = Query(filter: #Predicate<NarrationPackage> { $0.identifier == identifier })
    }

    private var progress: String? { tours.progress[tours.key(for: episode)] }
    private var package: NarrationPackage? { episode.status == .ready ? packages.first : nil }

    var body: some View {
        Group {
            if let package, progress == nil {
                NavigationLink {
                    NarrationPackageDetailView(package: package)
                } label: {
                    label(subtitle: readySubtitle(package))
                }
                .contextMenu { generateButtons(regenerate: true) }
            } else {
                HStack {
                    label(subtitle: pendingSubtitle)
                    Spacer()
                    if progress != nil {
                        ProgressView()
                    } else {
                        Menu {
                            generateButtons(regenerate: false)
                        } label: {
                            Text(episode.status == .failed ? "Retry" : "Generate")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) { CloudSignInView() }
    }

    private func label(subtitle: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title).lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(episode.status == .failed && progress == nil ? .red : .secondary)
                    .lineLimit(3)
            }
        } icon: {
            Image(systemName: episode.kind == .intro ? "sparkles" : "building.columns")
                .foregroundStyle(.tint)
        }
    }

    private var pendingSubtitle: String {
        if let progress { return progress }
        if episode.status == .failed, let message = episode.errorMessage { return message }
        return "\(episode.kind.label) · ~\(episode.estimatedMinutes) min"
    }

    private func readySubtitle(_ package: NarrationPackage) -> String {
        let source = episode.executor == .cloud ? "Cloud voice" : "On device"
        return "\(episode.kind.label) · \(PlaybackTime.string(package.totalDurationSeconds)) · \(source)"
    }

    @ViewBuilder
    private func generateButtons(regenerate: Bool) -> some View {
        let verb = regenerate ? "Regenerate" : "Generate"
        Button {
            start(.device)
        } label: {
            Label("\(verb) on This Device", systemImage: "iphone")
            if let reason = tours.onDeviceUnavailableReason { Text(reason) }
        }
        .disabled(!tours.canWriteOnDevice)

        if account.isConfigured {
            Button {
                if account.isSignedIn { start(.cloud) } else { showSignIn = true }
            } label: {
                Label("\(verb) with Cloud Voice", systemImage: "cloud")
                Text("~\(TourBudget.estimatedMinutes(episode.kind, executor: .cloud)) min, counts toward your monthly minutes")
            }
        }
    }

    private func start(_ executor: TourEpisode.Executor) {
        Task {
            await tours.generate(
                episode,
                executor: executor,
                account: account,
                voiceIdentifier: voiceIdentifier.isEmpty ? nil : voiceIdentifier,
                rate: Float(speechRate),
                context: context
            )
        }
    }
}

/// Explains what cloud generation sends where, then signs in with Apple
/// through the backend's Cognito hosted UI.
struct CloudSignInView: View {
    @Environment(CloudAccount.self) private var account
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.dismiss) private var dismiss
    @State private var signingIn = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Cloud voice writes longer, deeper tour episodes with a larger AI model and reads them with a premium voice.")
                } footer: {
                    Text("Beta — invite only for now.")
                }
                Section("What leaves your device") {
                    Label("The name of the public repository you generate an episode for.", systemImage: "arrow.up.circle")
                    Label("Our server reads that repository from GitHub, writes the script with Claude on Amazon Bedrock, and records it with ElevenLabs. Your GitHub token never leaves your device, and private repositories aren't supported.", systemImage: "server.rack")
                    Label("Your Apple ID email (or its private relay address), to keep track of your monthly minutes. You can delete your cloud account at any time in Settings.", systemImage: "person.crop.circle")
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        Task { await signIn() }
                    } label: {
                        HStack {
                            Spacer()
                            if signingIn { ProgressView() } else { Label("Sign in with Apple", systemImage: "apple.logo") }
                            Spacer()
                        }
                    }
                    .disabled(signingIn)
                }
            }
            .navigationTitle("Cloud Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func signIn() async {
        signingIn = true
        error = nil
        defer { signingIn = false }
        do {
            let callback = try await webAuthenticationSession.authenticate(
                using: try account.authorizeURL(),
                callbackURLScheme: BackendConfig.callbackScheme,
                preferredBrowserSession: .ephemeral
            )
            try await account.completeSignIn(callback: callback)
            dismiss()
        } catch let authError as ASWebAuthenticationSessionError where authError.code == .canceledLogin {
            // The user closed the sheet — nothing to report.
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Settings ▸ Cloud Voice: account, this month's minutes, sign out, delete.
struct CloudSettingsSection: View {
    @Environment(CloudAccount.self) private var account
    @State private var showSignIn = false
    @State private var confirmDelete = false
    @State private var error: String?

    var body: some View {
        if account.isConfigured {
            Section {
                if account.isSignedIn {
                    LabeledContent("Signed In", value: account.email ?? "Apple ID")
                    if let usage = account.usage {
                        LabeledContent(
                            "This Month",
                            value: "\(usage.minutesUsed.formatted(.number.precision(.fractionLength(0...1)))) of \(Int(usage.minutesQuota)) min"
                        )
                    }
                    Button("Sign Out") { account.signOut() }
                    Button("Delete Cloud Account", role: .destructive) { confirmDelete = true }
                } else {
                    Button("Sign In for Cloud Voice") { showSignIn = true }
                }
                if let error {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            } header: {
                Text("Cloud Voice (Beta)")
            } footer: {
                Text("Optional. Tour episodes made in the cloud use a larger AI model and a premium voice; everything else stays on your device.")
            }
            .task { await account.refreshUsage() }
            .sheet(isPresented: $showSignIn) { CloudSignInView() }
            .confirmationDialog(
                "Delete your cloud account?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        do { try await account.deleteAccount() } catch { self.error = error.localizedDescription }
                    }
                }
            } message: {
                Text("This removes your sign-in and usage records from our server. Episodes already on this device stay.")
            }
        }
    }
}
