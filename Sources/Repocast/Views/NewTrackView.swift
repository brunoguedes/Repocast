import SwiftUI
import AVFoundation

/// Phase 1 entry point into the pipeline: paste text, generate an audio track.
/// Later phases add a repo file picker and a summary/verbatim choice that
/// actually routes through the on-device model.
struct NewTrackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage(SettingsKeys.voiceIdentifier) private var voiceIdentifier = ""
    @AppStorage(SettingsKeys.speechRate) private var speechRate = Double(AVSpeechUtteranceDefaultSpeechRate)

    @State private var title = ""
    @State private var text = ""
    @State private var useSummary = false
    @State private var generator = TrackGenerator()

    private let summarizer = SummarizationService()

    private var canGenerate: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && generator.phase != .generating
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Optional", text: $title)
                }
                Section("Text to speak") {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .font(.body)
                }
                Section {
                    if summarizer.isAvailable {
                        Picker("Mode", selection: $useSummary) {
                            Text("Read verbatim").tag(false)
                            Text("AI summary").tag(true)
                        }
                        .pickerStyle(.segmented)
                        Text(useSummary
                             ? "Summarized on-device with Apple Intelligence — nothing leaves your phone."
                             : "Reads your text aloud word for word.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(summarizer.unavailableReason ?? "AI summaries are unavailable. Text is read aloud verbatim.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Narration")
                }
                if case let .failed(message) = generator.phase {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") { Task { await generate() } }
                        .disabled(!canGenerate)
                }
            }
            .overlay {
                if generator.phase == .generating {
                    ProgressView("Generating…")
                        .padding(24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }
            }
            .interactiveDismissDisabled(generator.phase == .generating)
        }
    }

    private func generate() async {
        await generator.generate(
            title: title,
            text: text,
            kind: useSummary ? .summary : .verbatim,
            voiceIdentifier: voiceIdentifier.isEmpty ? nil : voiceIdentifier,
            rate: Float(speechRate),
            into: context
        )
        if generator.phase == .idle { dismiss() }
    }
}
