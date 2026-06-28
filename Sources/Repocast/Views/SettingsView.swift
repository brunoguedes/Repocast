import SwiftUI
import AVFoundation

/// `@AppStorage` keys for the speech defaults, in one place so the New Track
/// sheet and Settings can't drift apart.
enum SettingsKeys {
    static let voiceIdentifier = "defaultVoiceIdentifier"
    static let speechRate = "defaultSpeechRate"
}

struct SettingsView: View {
    @Environment(GitHubAccount.self) private var account
    @AppStorage(SettingsKeys.voiceIdentifier) private var voiceIdentifier = ""
    @AppStorage(SettingsKeys.speechRate) private var speechRate = Double(AVSpeechUtteranceDefaultSpeechRate)

    @State private var showConnect = false

    /// Voices for the device's current language. (Cross-language picking and
    /// per-voice download status come later.)
    private var voices: [AVSpeechSynthesisVoice] {
        let prefix = String(AVSpeechSynthesisVoice.currentLanguageCode().prefix(2))
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(prefix) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("GitHub") {
                    if account.isConnected {
                        LabeledContent("Connected", value: "@\(account.login ?? "")")
                        Button("Disconnect", role: .destructive) { account.disconnect() }
                    } else {
                        Button("Connect GitHub") { showConnect = true }
                    }
                }

                Section("Voice") {
                    Picker("Voice", selection: $voiceIdentifier) {
                        Text("System Default").tag("")
                        ForEach(voices, id: \.identifier) { voice in
                            Text(voice.name).tag(voice.identifier)
                        }
                    }
                }

                Section("Speech Rate") {
                    Slider(
                        value: $speechRate,
                        in: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceMaximumSpeechRate)
                    ) {
                        Text("Rate")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise")
                    } maximumValueLabel: {
                        Image(systemName: "hare")
                    }
                }

                Section {
                    let summarizer = SummarizationService()
                    if summarizer.isAvailable {
                        LabeledContent("Apple Intelligence", value: "Available")
                    } else {
                        LabeledContent("Apple Intelligence", value: "Unavailable")
                        if let reason = summarizer.unavailableReason {
                            Text(reason)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("On-Device AI")
                } footer: {
                    Text("When available, code files from a repo are summarized on-device. Markdown is read verbatim.")
                }

                Section("About") {
                    LabeledContent("App", value: "Repocast")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showConnect) { ConnectGitHubView() }
        }
    }
}

#Preview {
    SettingsView()
        .environment(GitHubAccount())
}
