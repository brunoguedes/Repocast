# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Repocast turns selected files from a git repository (source code and Markdown) into audio you can play in the car or while exercising, using on-device Apple Intelligence to summarize code, convert docs to speech, generate AI playlists, and voice the latest GitHub changes like new merges and open PRs.

Native iOS app (iPhone + iPad, iOS 26+, Swift 6, SwiftUI) using **SwiftData** for local persistence. The only third-party SDK and the only network calls come from **Firebase Analytics** (added via SPM), which logs anonymous usage telemetry (screen views and custom events); see the Analytics section below.

## Build, run, test

The Xcode project is generated from [project.yml](project.yml) by [XcodeGen](https://github.com/yonaskolb/XcodeGen). Regenerate whenever files are added/removed or settings change:

```sh
xcodegen generate   # rewrites Repocast.xcodeproj
```

Any source file inside `Sources/Repocast/` or `Tests/` is picked up automatically — there's no file list to edit. Edit `project.yml` (not the generated `.xcodeproj`) for target settings, bundle IDs, SPM packages, or entitlements.

```sh
# Build
xcodebuild -project Repocast.xcodeproj -scheme Repocast \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run all tests
xcodebuild -project Repocast.xcodeproj -scheme Repocast \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

## Architecture

- **App entry** — [Sources/Repocast/RepocastApp.swift](Sources/Repocast/RepocastApp.swift) configures Firebase (`AnalyticsService.start()`) and injects the SwiftData container.
- **Persistence** — [Sources/Repocast/Models/DataStack.swift](Sources/Repocast/Models/DataStack.swift) owns the single `ModelContainer`. `@Model` types live under `Models/`. The store is local on-device; the file documents how to add private CloudKit sync.
- **Views** — SwiftUI under `Views/`. Top-level navigation is a `TabView`.
- **Services** — side-effectful work (networking, on-device ML, actors) under `Services/`.

Keep views dumb; push logic into actors/services. Strict concurrency is on — annotate shared mutable state with `@MainActor` or wrap it in an `actor`.

### The audio pipeline (the spine)

Everything in Repocast feeds one pipeline — *content → on-device AI → text-to-speech → playable track → background player*. GitHub and "latest changes" are just additional producers of content that join at the front.

```text
RepoSource ──select files──►  TrackGenerationCoordinator
                                 1. fetch text       ← GitHubClient            (Phase 3)
                                 2. narrate          ← SummarizationService    (Phase 2; verbatim passthrough today)
                                 3. render to file   ← SpeechSynthesisService  (offline TTS, Phase 1 ✅)
                                 4. persist          ← AudioTrack + AudioFileStore
                                       │
                                       ▼
                                 Playlist ──► AudioPlayerService (background + lock screen + CarPlay)
```

**Models** ([Models/](Sources/Repocast/Models)) — `AudioTrack` is the only domain model so far (the playable unit; bytes live on disk via `AudioFileStore`, the model holds metadata + filename). Enum fields are stored as raw `String` with computed accessors — drift-safe and CloudKit-ready. `Playlist` / `PlaylistItem` arrive in Phase 4. Everything goes into the `Schema([...])` in [DataStack.swift](Sources/Repocast/Models/DataStack.swift).

**Services** ([Services/](Sources/Repocast/Services)) — all protocol-backed so tests inject mocks:
- [AudioFileStore](Sources/Repocast/Services/AudioFileStore.swift) — owns `Documents/Audio/`; filename is the on-disk contract.
- [SpeechSynthesisService](Sources/Repocast/Services/SpeechSynthesisService.swift) (`SpeechSynthesizing`) — **pre-renders** each track to a `.caf` via `AVSpeechSynthesizer.write(...)` (offline, not spoken live) so the playlist supports a real queue, scrubbing, duration, and background play. The buffer callback fires on an internal queue, so the bridging `OfflineRenderer` is lock-guarded + `@unchecked Sendable`.
- [AudioPlayerService](Sources/Repocast/Services/AudioPlayerService.swift) — app-lifetime `@MainActor @Observable` player. One `AVPlayer`, `AVAudioSession(.playback, .spokenAudio)`, and `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter` wired for lock-screen / CarPlay. Plays value-type `PlayableItem` snapshots, never `AudioTrack` directly.
- [TrackGenerator](Sources/Repocast/Services/TrackGenerator.swift) — `@MainActor @Observable` orchestrator (the seed of the full `TrackGenerationCoordinator`); today: text → TTS → insert `AudioTrack`.

**Views** ([Views/](Sources/Repocast/Views)) — `ContentView` is a `TabView` (Tracks / Settings) with a persistent **mini-player** in `.safeAreaInset(edge: .bottom)` and a full **Now Playing** sheet ([PlayerViews.swift](Sources/Repocast/Views/PlayerViews.swift)). ⚠️ The `.environment(player)` must be the **outermost** modifier on the TabView so the safeAreaInset content (mini-player) inherits it — applying it before `.safeAreaInset` crashes at launch with "No Observable object of type AudioPlayerService".

**Capability:** background playback needs `UIBackgroundModes: [audio]` (set in [project.yml](project.yml) `info.properties`). No new SPM packages — `AVFoundation`, `MediaPlayer`, `FoundationModels` are system frameworks.

### Roadmap (phases)

- **Phase 1 ✅ — Audio spine.** Text → offline TTS → `AudioTrack` → background player + mini/now-playing UI. Fully on-device, no credentials.
- **Phase 2 — On-device AI.** `SummarizationService` over `FoundationModels.LanguageModelSession`; check `SystemLanguageModel.default.availability` and fall back gracefully (markdown → verbatim). Route `.summary` vs `.verbatim` in `TrackGenerator`. Code files need chunking for the context window.
- **Phase 3 🟡 — GitHub (connect + browse + import shipped; AI summary of code still pending Phase 2).** [KeychainStore](Sources/Repocast/Services/KeychainStore.swift) (token), [GitHubClient](Sources/Repocast/Services/GitHubClient.swift) + [GitHubModels](Sources/Repocast/Services/GitHubModels.swift) (stateless `Sendable` REST over `URLSession`: validate / repos / contents / file), [GitHubAccount](Sources/Repocast/Services/GitHubAccount.swift) (app-lifetime connection state, injected like the player). Auth is a **pasted fine-grained PAT** (validated against `/user`, stored in Keychain) — OAuth device-flow is the later upgrade. UI in [ReposView.swift](Sources/Repocast/Views/ReposView.swift): connect sheet, add-repo picker, recursive file browser with multi-select → `TrackGenerator`. `RepoSource` is the persisted repo ([Models/RepoSource.swift](Sources/Repocast/Models/RepoSource.swift)). Files generate **verbatim** today (great for Markdown; code stays verbatim until Phase 2 summarization lands — `AudioTrack.SourceKind.detect(path:)` already tags code vs. markdown). **This is the second network surface** (see Privacy).
- **Phase 4 — Playlists.** `Playlist` / `PlaylistItem` models, CRUD + reorder, AI-generated playlists (FoundationModels guided generation / `@Generable`).
- **Phase 5 — Latest changes.** Fetch recent merged PRs / commits → spoken changelog track → smart playlist.

### CarPlay

Audio-app CarPlay support lives in `Sources/Repocast/CarPlay/`: [CarPlaySceneDelegate](Sources/Repocast/CarPlay/CarPlaySceneDelegate.swift) (named by the Info.plist scene manifest, generated from [project.yml](project.yml)) hands the connection to [CarPlayInterface](Sources/Repocast/CarPlay/CarPlayInterface.swift), which renders Tracks / Playlists / Narrations as `CPListTemplate` tabs and starts playback on **`AudioPlayerService.shared`** — the same instance the phone UI injects via `.environment`, so both screens control one playback session. `CPNowPlayingTemplate` mirrors the existing `MPNowPlayingInfoCenter` / remote-command wiring (including narration packages' aggregate timeline and ±15 s skips). Narration start/resume mechanics are shared with the phone detail screen through [NarrationPlayback](Sources/Repocast/Services/NarrationPlayback.swift). Lists refresh on `ModelContext.didSave`.

**Signing:** Apple granted the CarPlay Audio entitlement for this account (2026-08-18), so `com.apple.developer.carplay-audio` now applies to **all builds** — [project.yml](project.yml) sets `CODE_SIGN_ENTITLEMENTS` to `Sources/Repocast/Repocast.entitlements` (a checked-in, hand-edited file) unconditionally. If automatic signing ever complains the profile lacks the capability, enable **CarPlay Audio App** on the `au.com.bclgapps.Repocast` identifier (developer.apple.com ▸ Identifiers ▸ Additional Capabilities) and rebuild. In the simulator, open the CarPlay display via Simulator ▸ I/O ▸ External Displays ▸ CarPlay. `UIApplicationSupportsMultipleScenes` is `true` (required for CarPlay + phone simultaneously); side effect: iPad gains multi-window. ⚠️ Still TODO before release: mention CarPlay in the `appstore/` copy.

### Known risks / notes

- **Voice writability:** some enhanced/personal voices may not be renderable to file via `AVSpeechSynthesizer.write`; default/compact voices are. Settings currently lists the device-language voices unfiltered — a non-renderable pick surfaces as a `TrackGenerator` `.failed`. Filter by writability when it bites.
- **Audio format:** Phase 1 writes uncompressed LPCM `.caf` (simple, large). Compress to AAC/`.m4a` when track libraries grow.
- **Simulator:** TTS rendering works in the simulator; lock-screen / CarPlay controls are best verified on a device.
- **Voice-note mic on the simulator:** recording needs the *macOS* microphone permission for Simulator.app (System Settings ▸ Privacy & Security ▸ Microphone) — without it `AVAudioRecorder.record()` hangs. Mic spin-up runs off the main actor (`MicrophoneCapture` actor behind the `AudioCapturing` protocol) so the UI never freezes either way; UI tests pass the `-fake-mic` launch argument to swap in `StubAudioCapture`. On-device speech recognition (`SFSpeechRecognizer.supportsOnDeviceRecognition`) is typically unavailable in the simulator, so notes degrade to "transcription unavailable" there — verify transcription on a device.

### Privacy

Two network surfaces now: **Firebase Analytics** (anonymous) and **GitHub** (repo contents + access token). TTS is fully on-device; AI summarization will be too. **Voice notes** record with the microphone and are transcribed by `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true` — the note audio and its text never leave the device (see [VoiceNoteRecorder](Sources/Repocast/Services/VoiceNoteRecorder.swift) / [SpeechTranscriptionService](Sources/Repocast/Services/SpeechTranscriptionService.swift); usage strings in [project.yml](project.yml)). The GitHub token lives in the **Keychain** (`KeychainStore.github`), only explicitly-connected repos are fetched, and repo data is sent **only to api.github.com** — never to our servers. Analytics events carry counts / enum raw values only, never repo text, file names, transcripts, or note contents. ⚠️ **Still TODO before release:** update `appstore/`'s privacy page + App Store data-safety copy to disclose the GitHub connection, microphone use, and speech recognition.

## Analytics (Firebase)

Firebase Analytics is the app's only third-party SDK / network dependency, added through SPM (the `Firebase` package in [project.yml](project.yml), `FirebaseAnalytics` product). Every event and parameter name is centralised in [AnalyticsService](Sources/Repocast/Services/AnalyticsService.swift) — call sites never touch the SDK directly, and that's the single file to edit to add or rename events.

`AnalyticsService.start()` runs first in the app's `init()`. It **no-ops until a real `GoogleService-Info.plist` is dropped into `Sources/Repocast/Resources/`** — so the app builds and runs without Firebase credentials. The plist is gitignored.

**Never pass user content into an analytics event** — only counts, enum raw values, and toggle states. Custom event names must stay lowercase snake_case, ≤ 40 chars, with no `firebase_` / `google_` / `ga_` prefix.

## Release

See [RELEASING.md](RELEASING.md). Fastlane drives version bumps, archives, and TestFlight uploads via an App Store Connect API key. The lanes mutate `project.yml` and re-run `xcodegen` — never hand-edit the generated `.xcodeproj`.

## App Store metadata

All App Store Connect copy and screenshots live in [appstore/](appstore/). Treat [appstore/APPSTORE.md](appstore/APPSTORE.md) as the canonical source — edit it first, then update App Store Connect.
