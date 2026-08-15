import SwiftData
import SwiftUI

/// Library row for an imported narration package (Tracks tab, Narrations
/// section). Matches `TrackRow`'s icon + title + subtitle shape.
struct NarrationPackageRow: View {
    let package: NarrationPackage

    private let resumeStore = NarrationResumeStore()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "headphones")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(package.title.isEmpty ? "Untitled" : package.title)
                    .font(.body)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        let form = package.hasStitched ? "Single track" : "\(package.partCount) parts"
        var text = "\(form) · \(PlaybackTime.string(package.totalDurationSeconds))"
        if resumeStore.position(for: package.identifier) != nil {
            text += " · In progress"
        }
        return text
    }
}

/// One narration package: artwork header, Resume / Play (+ Start Over once a
/// resume position exists), and the parts with their transcript availability.
/// Mirrors `PlaylistDetailView`'s layout. The program (what actually plays) is
/// rebuilt from the stored folder on every appearance, so it always reflects
/// what's on disk.
struct NarrationPackageDetailView: View {
    let package: NarrationPackage

    @Environment(\.modelContext) private var context
    @Environment(AudioPlayerService.self) private var player
    @State private var program: NarrationProgram?
    @State private var loadFailed = false

    private let store = NarrationPackageStore()
    private let resumeStore = NarrationResumeStore()
    private let builder = NarrationProgramBuilder()

    /// The saved position, validated against the files that actually exist.
    private var resumePosition: NarrationResumeStore.Position? {
        guard let program else { return nil }
        return resumeStore.validatedPosition(
            for: package.identifier,
            among: Set(program.parts.map(\.fileName))
        )
    }

    var body: some View {
        List {
            Section {
                header
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section(package.hasStitched ? "Audio" : "Parts") {
                if let program {
                    ForEach(Array(program.parts.enumerated()), id: \.element.id) { index, part in
                        Button { play(fromPart: index) } label: {
                            partRow(index: index, part: part)
                        }
                        .buttonStyle(.plain)
                    }
                } else if loadFailed {
                    Label("The package's audio files are missing. Re-import the folder to restore them.",
                          systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Reading package…").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(package.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.indigo.gradient)
                .frame(width: 132, height: 132)
                .overlay {
                    Image(systemName: "headphones")
                        .font(.system(size: 56)).foregroundStyle(.white)
                }
            Text(package.title).font(.title2.bold()).multilineTextAlignment(.center)
            Text(headerSubtitle)
                .font(.subheadline).foregroundStyle(.secondary)
            if let voice = package.voiceName {
                Text("Narrated by \(voice)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            transportButtons
                .padding(.top, 4)
        }
    }

    private var headerSubtitle: String {
        let form = package.hasStitched ? "Single track" : "\(package.partCount) parts"
        return "\(form) · \(PlaybackTime.string(package.totalDurationSeconds))"
    }

    @ViewBuilder
    private var transportButtons: some View {
        if let resumePosition, let program {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button { resume() } label: {
                        Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Button { startOver() } label: {
                        Label("Start Over", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                Text("Resumes at \(PlaybackTime.string(aggregateTime(of: resumePosition, in: program)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } else {
            Button { startOver() } label: {
                Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(program == nil)
        }
    }

    private func partRow(index: Int, part: NarrationProgram.Part) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(part.title).font(.callout).lineLimit(1)
                if part.transcript.isEmpty {
                    Text("No transcript").font(.caption).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(PlaybackTime.string(part.duration))
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
    }

    // MARK: Playback
    // The actual start/resume mechanics live in `NarrationPlayback`, shared
    // with the CarPlay scene.

    private func resume() {
        guard let program else { return }
        NarrationPlayback.resumeOrStart(
            package: package, program: program,
            player: player, resumeStore: resumeStore, context: context
        )
    }

    private func startOver() {
        resumeStore.clear(for: package.identifier)
        play(fromPart: 0)
    }

    private func play(fromPart index: Int) {
        guard let program else { return }
        NarrationPlayback.start(
            package: package, program: program, fromPart: index,
            player: player, resumeStore: resumeStore, context: context
        )
    }

    private func load() async {
        let directory = store.directory(for: package.identifier)
        program = await builder.build(directory: directory, baseName: package.baseName)
        loadFailed = program == nil
    }

    /// Where the saved position falls on the aggregate timeline, for display.
    private func aggregateTime(of position: NarrationResumeStore.Position, in program: NarrationProgram) -> Double {
        var elapsed: Double = 0
        for part in program.parts {
            if part.fileName == position.fileName {
                return elapsed + position.offsetSeconds
            }
            elapsed += part.duration
        }
        return position.offsetSeconds
    }
}
