# App Store Connect — Repocast

Copy/paste source for the Repocast App Store Connect listing. Sections below mirror the order they appear in App Store Connect: **per-version fields first** (top of the page, change every release) followed by **App Information fields** (separate page, change rarely), then the **Pricing and Availability** page. Release-engineering material that is *not* an App Store Connect field lives in the appendix at the bottom.

Edit this file first, then mirror changes into App Store Connect — not the other way around. The count after each field heading is the App Store Connect limit, not the current length.

---

## Per-Version Page

These appear on the version detail page and need to be reviewed before each submission.

---

### Previews and Screenshots

- Screenshots only required for iOS apps. Apple uses the first 3 across the rest of your sizes/localizations.
- iPhone 6.9" Display: assets in [`screenshots-6.9/`](screenshots-6.9/)
- iPad 13" Display: assets in [`screenshots-ipad-13/`](screenshots-ipad-13/)
- App Previews (video): not produced

**Not produced yet.** Both folders are empty (`.gitkeep` only) and Repocast has no screenshot automation yet. TODO: capture the iPhone 6.9" and iPad 13" sets before the first submission — suggested shots: Tracks grouped by repo, the repo file browser with files ticked, Now Playing with the follow-along transcript, a Smart Playlist preview, the Notes tab.

---

### Promotional Text *(170 char max)*

```
Turn READMEs, docs and source code from your GitHub repos into audio for the car or a run. Apple Intelligence explains each code file, right on your iPhone.
```

*(156 chars)*

---

### Description *(4000 char max)*

```
Repocast turns your code repositories into audio you can listen to in the car, on a run, or anywhere your eyes are busy and your ears are free.

Pick files from any GitHub repository — READMEs, docs, source code — and Repocast turns them into tracks you play like a podcast. Markdown is read aloud word for word. Source code is explained, not recited: Apple Intelligence summarises each file on your iPhone into a short spoken briefing about what it does. No Repocast account. No servers of ours in the middle.

WHAT YOU GET

Repos — any public repo, or your own
Add a public repository by pasting its link or typing owner/repo — no GitHub account needed. Connect a read-only GitHub personal access token to browse your own repositories, private ones included. Open folders, tick the files you want, and tap Generate.

On-device code summaries
Each code file becomes a plain-English briefing on its main types and functions, written by Apple Intelligence through Apple's Foundation Models framework. Long files are summarised in parts and joined into one narration. It all runs on your iPhone.

Tracks — any text into audio
Paste any text and have it read verbatim, or summarised first. Tracks are rendered once with the system voice and speech rate you choose, then saved on your device — so they play offline, in the background, and from the Lock Screen.

Now Playing — follow along
The transcript scrolls with the audio and highlights where you are; tap a sentence to jump to it. Change speed from 0.75× to 2×, scrub anywhere, and skip 15 seconds either way from the Lock Screen or CarPlay. Phone calls pause playback, which picks up again when they end.

Playlists — hand-built or smart
Build playlists by hand and reorder them, or describe what you want — "a tour of the audio pipeline", "short docs under 5 minutes" — and Apple Intelligence picks and orders tracks from your library. You preview the result before saving.

Narrations — long-form audio, with a bookmark
Already have narrated audio made elsewhere? Import the folder of MP3s from Files. Repocast plays the parts as one continuous timeline with their transcripts, and picks up where you stopped.

Voice notes — catch the thought
Tap the mic while you listen. Playback pauses and Repocast records a note pinned to that exact moment, then transcribes it on your device. Later, tap the note to jump straight back to the line that sparked it.

CarPlay
Your tracks, playlists and narrations on the car's screen, driving the same player as your iPhone — with a mic button on Now Playing so you can record a note without picking up your phone.

PRIVATE BY DESIGN

• Text-to-speech, code summaries, smart playlists and voice-note transcription all run on your device.
• Repository files travel directly between your iPhone and GitHub. Repocast only ever reads from GitHub — it never writes to it.
• Your GitHub token is stored in the iOS Keychain and only ever sent to GitHub.
• Voice notes — the audio and the text — stay on your device.
• The only data that reaches us is anonymous usage analytics via Firebase Analytics: which tabs you open and which features you use, as counts. Never repository names, file contents, transcripts or notes. No advertising IDs, no tracking.

REQUIREMENTS

• iPhone or iPad running iOS 26 or later.
• An internet connection to add repositories and fetch files. Generated tracks play offline.
• An Apple Intelligence-eligible device with Apple Intelligence turned on for code summaries and smart playlists. Without it, files are read aloud word for word and you build playlists by hand.
• Microphone access for voice notes, and a device and language that support on-device speech recognition for their transcripts.
• A GitHub account only if you want to browse your own or private repositories.
```

*(3,789 chars)*

---

### What's New in This Version *(4000 char max)*

#### Version 1.0

```
Version 1.0 — Your repos, out loud.

• Add any public GitHub repository, or connect a read-only token to browse your own — private ones included.
• Markdown is read aloud word for word; source code is summarised on your iPhone by Apple Intelligence.
• Paste any text to make a track, with your choice of system voice and speech rate.
• Playlists you build by hand, or smart playlists Apple Intelligence picks from a one-line description.
• Import narration folders from Files and pick up where you left off.
• Voice notes pinned to the moment you were listening, transcribed on your device.
• Background playback, Lock Screen controls, and CarPlay.
```

---

### Keywords *(100 char max, comma-separated, no spaces after commas)*

```
developer,git,repository,readme,markdown,podcast,tts,speech,narration,summary,playlist,commute,ai
```

*(97 chars)*

Words already in the name and subtitle (Repocast, listen, code, docs) are indexed from there and deliberately left out. "GitHub" is kept out of the keywords (third-party trademark); the description names it only to say what the app connects to.

---

### Support URL

> `https://bclgapps.com.au/repocast-support`

Content source: [repocast-support.md](repocast-support.md)

---

### Marketing URL

> `https://bclgapps.com.au/repocast`

Content source: [repocast.md](repocast.md)

---

### Version

> `1.0`

Single source of truth: `MARKETING_VERSION` in [`project.yml`](../project.yml). Bump via `bundle exec fastlane set_version version:1.1`. Build number is `CURRENT_PROJECT_VERSION` in the same file.

---

### Copyright

> **© 2026 BCLG Apps**

App Store Connect accepts the leading "©" — include it.

---

### Routing App Coverage File

N/A — Repocast is not a routing app.

---

### App Clip / iMessage App

N/A — neither is shipped.

---

### Build

Uploaded via Fastlane:

```sh
bundle exec fastlane beta            # first upload: ships 1.0 (1) as-is
bundle exec fastlane release_build   # later builds: bump_build, then beta
```

`beta` exports with manual signing using the App Store provisioning profile **Repocast AppStore** (see the Submission checklist). See [`../RELEASING.md`](../RELEASING.md) for the full release flow. Text-to-speech and CarPlay (Simulator ▸ I/O ▸ External Displays ▸ CarPlay) work in the simulator, but on-device speech recognition is usually unavailable there and Lock Screen controls are best checked on hardware — exercise voice-note transcription and background playback on a physical device.

---

### Game Center

N/A.

---

### App Review Information

#### Sign-In Information

> Sign-in not required. Repocast has no accounts of its own, and public GitHub repositories can be added without one.

Leave the "Sign-in required" checkbox **unchecked**.

TODO: decide whether to give App Review a read-only, fine-grained GitHub token for a demo GitHub account so they can try the optional **Connect GitHub → From Your Repos** flow. If so, paste it into the Notes field in App Store Connect only — never into this file, which is committed.

#### Contact Information

| Field | Value |
| --- | --- |
| First name | Bruno |
| Last name | Guedes |
| Phone | +61 425 532 850 |
| Email | <bruno@bclgapps.com.au> |

#### Notes

```
Repocast turns files from GitHub repositories, and any text the user pastes, into audio for listening in the car or while exercising. We run no servers. Text-to-speech, AI summaries, smart playlists and voice-note transcription all run on the device. The only network traffic is (1) the GitHub REST API (api.github.com), to list and read repositories the user adds, and (2) anonymous usage analytics via Firebase Analytics (see below). No sign-in is required: public repositories work without any account.

1. Repos tab (network)
• Tap Add Public Repo and enter apple/swift-argument-parser (or paste any github.com URL).
• Open it, tick README.md and Package.swift, tap Generate (2).
• Markdown is read word for word. Code files are summarised on-device by Apple Intelligence (Foundation Models) into a short spoken explanation; without Apple Intelligence they are read verbatim. Settings ▸ On-Device AI shows availability.
• Optional: Settings ▸ GitHub ▸ Connect GitHub takes a fine-grained personal access token (read-only contents). It is validated against api.github.com/user, stored in the iOS Keychain, and only ever sent to api.github.com. Repos ▸ + ▸ From Your Repos then lists the account's repositories, private ones included. The app only reads from GitHub.

2. Tracks tab
• + ▸ New Track: paste text, choose Read verbatim or AI summary, tap Generate. Audio is rendered on-device with the voice and rate set in Settings and saved locally.
• Tap a track to play. Audio continues in the background (UIBackgroundModes: audio) with Lock Screen controls. Tap the mini-player for Now Playing: follow-along transcript (tap a sentence to seek), scrubber, 0.75×–2× speed.
• + ▸ Import Narration Folder opens the Files folder picker for a folder of pre-rendered MP3s (name_partN.mp3 and/or name.mp3, optional name.m3u8 playlist and .txt transcripts). The folder is copied into the app; it plays as one timeline and resumes where the listener stopped.

3. Playlists tab
• New: name a playlist and tick tracks; Edit to reorder; Play All / Shuffle.
• New Smart Playlist: type a description (e.g. "Short docs under 5 minutes"). Apple Intelligence picks 3–8 tracks from the library and names the playlist; the user previews it before saving. The model only sees track titles, types and durations. Generate a few tracks first.

4. Voice notes (Microphone, Speech Recognition)
• While something plays, open Now Playing and tap the mic. Playback pauses and the Microphone prompt appears. Tap Save to finish.
• After the first note is saved, the Speech Recognition prompt appears. Notes are transcribed with requiresOnDeviceRecognition = true, so audio and text never leave the device. Where on-device recognition is unsupported (e.g. most simulators) the note is kept as audio only.
• Notes tab: tap a note to reopen its content at that moment; the waveform button plays the recording.

5. CarPlay (CarPlay Audio entitlement)
• Connect CarPlay (or Simulator ▸ I/O ▸ External Displays ▸ CarPlay). Tabs: Tracks, Playlists, Narrations. Choosing an item plays it on the same player as the phone and opens Now Playing, which has a mic button for voice notes (tap to start, tap again to save). Content is created on the iPhone; CarPlay plays it.

Analytics
• Firebase Analytics (the only third-party SDK, via SPM) logs screen_view for the five tabs and custom events for feature use (tracks, playback, GitHub connect, repos, playlists, narrations, CarPlay, voice notes). Parameters are counts, booleans and enum values only (e.g. summary vs verbatim, playback speed). Never repository or file names, file contents, transcripts, note audio or text, GitHub username or token. Firebase attaches its anonymous app-instance ID. App Privacy declares Usage Data (Product Interaction) and Identifiers (Device ID): not linked to identity, not used for tracking.

No accounts of our own, no ads, no in-app purchases, no tracking.
```

*(3,906 chars — App Store Connect's Notes limit is 4,000)*

#### Attachment

None. TODO: decide whether to hand App Review a sample narration package so they can exercise **Import Narration Folder** without making one. [`../Tests/Fixtures/proposal_v2/`](../Tests/Fixtures/proposal_v2/) is a minimal valid package (three parts, a stitched file, `.txt` transcripts, an `.m3u8` playlist); the reviewer would need to save it to Files first.

---

### App Store Version Release

Recommended:

> ☑️ **Manually release this version**

Reason: gives time to spot-check the live listing — and that the marketing, support and privacy pages are up — before users see it. Switch to "Automatically release this version" once the release process is stable.

---

### Phased Release for App Store Automatic Updates

N/A for 1.0 — phased release only applies to updates delivered through automatic updates, and there are no existing users yet.

From 1.1 onward, recommended:

> ☑️ **Release update over 7-day period using phased release**

Reason: limits blast radius if a regression slips through. Can be paused or accelerated to 100% from App Store Connect at any time.

---

### Reset iOS App Store Summary Rating

N/A for 1.0 — first release, there is no rating to reset.

From 1.1 onward, recommended:

> ☑️ **Keep existing rating**

Only reset the rating after a major redesign or quality issue that you want to wipe the slate on.

---

## App Information Page

These live on the **App Information** page (top-level, not per-version) and only need to change when one of the values genuinely needs updating.

---

### Name

> Repocast

---

### Subtitle *(30 char max)*

> Listen to your code and docs

*(28 chars)*

---

### Bundle ID, SKU, Language

- **Bundle ID:** `au.com.bclgapps.Repocast`
- **SKU:** `repocast-ios-001` — TODO: confirm. The SKU is fixed when the app record is created; if the record already exists in App Store Connect, copy its SKU here instead.
- **Primary language:** English (Australia)

---

### Privacy Policy URL

> `https://bclgapps.com.au/repocast-privacy`

Content source: [repocast-privacy.md](repocast-privacy.md). Required by App Store Connect before submission.

---

### Categories

- **Primary:** Productivity
- **Secondary:** Developer Tools

(`LSApplicationCategoryType` in [project.yml](../project.yml) is `public.app-category.productivity`, which matches Productivity as primary. If Developer Tools is ever promoted to primary, change it to `public.app-category.developer-tools` to keep the two in step.)

---

### Age Rating

> 4+

- **Unrestricted Web Access:** No — there is no browser or web view. The app reads text files from GitHub repositories the user chooses, through GitHub's API, and turns them into audio.
- **User-Generated Content:** No — nothing is shared between users; every library is private to its device.
- **Medical/Treatment Information:** None
- **Gambling, Contests, etc.:** No

---

### App Privacy

Repocast uses Firebase Analytics, so the answers are **not** "Data Not Collected" across the board. Declare:

**Data collected (via Firebase Analytics):**

- **Usage Data → Product Interaction** — Collected. *Not* linked to the user's identity. *Not* used for tracking. Firebase logs `screen_view` events for the five tabs and the custom events in [`AnalyticsEvents.swift`](../Sources/Repocast/Services/AnalyticsEvents.swift) (counts, booleans and enum raw values only).
- **Identifiers → Device ID** — Collected. *Not* linked to identity. *Not* used for tracking. This is Firebase's anonymous app-instance/installation ID; it is not the IDFA (there is no App Tracking Transparency prompt and no `NSUserTrackingUsageDescription`) and is not used to track across apps or websites.
- In App Store Connect's tracking question, answer **No** — none of the collected data is used to track users across apps/websites owned by other companies (Firebase Analytics here is first-party product analytics only, no ad attribution, no IDFA).
- TODO: before submitting, re-read Google's "Firebase data disclosure for Apple's App Store" page for the Analytics SDK version in use, and keep these answers consistent with MyHealthInsights, which declares the same two types.

**Data NOT collected (everything else):**

- **Repository contents and the GitHub token** — the app talks to `api.github.com` directly from the device, on the user's behalf, with the user's own optional token. That data goes to GitHub (a service the user has their own relationship with) to serve each request; it never reaches us or a partner of ours, so it is not "collected" in Apple's sense. The token is stored in the iOS Keychain; fetched files, their transcripts and the generated audio are stored only in the app's local storage.
- **Audio data (voice notes)** — recorded with the microphone and saved only in the app's local storage. Transcription uses `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`, so neither the audio nor the text leaves the device.
- **Other user content** — pasted text, playlists, imported narration folders and the on-device AI output are stored only on the device. There is no iCloud/CloudKit sync (the entitlements file holds only `com.apple.developer.carplay-audio`).
- The Apple Intelligence summaries and smart playlists are generated locally via Foundation Models; the prompts and responses never leave the device.
- No name, email, phone number, location, contacts, photos, or advertising identifiers are collected.

---

### Other fields (Routing App Coverage, Game Center, App Sandbox)

Not applicable.

- **Content Rights** (App Information page): **Yes**, the app accesses third-party content — files from GitHub repositories that the user chooses to add. Repocast doesn't bundle or redistribute any of it; it reads it on the user's behalf.

---

## Pricing and Availability Page

- **Price tier:** Free — TODO: confirm. (There is no StoreKit code, so nothing is sold in-app.)
- **In-app purchases:** None at launch
- **Territories:** All App Store regions. Code summaries and smart playlists need Apple Intelligence, but the app degrades gracefully where it is unavailable — files are read verbatim and playlists are built by hand.

---

## Appendix — Release engineering (not App Store Connect fields)

This material is specific to building and shipping Repocast and does not map to an App Store Connect text field. Kept here so the release process is documented alongside the listing copy.

---

### Export compliance / encryption

The app uses only **exempt** encryption. Its network calls — the GitHub REST API
over `URLSession` and Firebase Analytics telemetry — go over standard HTTPS/TLS
provided by the OS and Google's SDK; the GitHub token is stored with the system
Keychain. `CryptoKit` is imported in exactly one place
([NarrationImporter.swift](../Sources/Repocast/Services/NarrationImporter.swift)),
to compute a SHA-256 hash that names imported narration folders — hashing, not
encryption. The app implements no proprietary cryptography. Under the US export
rules this falls within the standard exemptions, so the Info.plist key
`ITSAppUsesNonExemptEncryption = NO` is set via [project.yml](../project.yml)
(`info.properties` → `ITSAppUsesNonExemptEncryption: false`), and App Store Connect
**will skip the encryption questionnaire on every submission**.

If a future feature ever introduces non-exempt encryption (e.g. a custom cipher,
or encrypting exported audio with our own scheme), update this section before
flipping the key.

---

### Version & build source of truth

Source of truth is [project.yml](../project.yml), under `settings.base`:

- **Marketing version:** `1.0` (`MARKETING_VERSION`)
- **Build:** `1` (`CURRENT_PROJECT_VERSION`)

Bump before each TestFlight / production submission after the first, then `xcodegen generate` and archive (Fastlane's `bump_build` / `set_version` lanes do this for you). For the very first upload, run `beta` rather than `release_build` — `release_build` bumps to build 2 before uploading.

There is no `aps-environment` to flip before archiving: Repocast uses neither CloudKit nor push notifications.

---

### Submission checklist

- [ ] `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` correct in [project.yml](../project.yml) (`1.0` / `1` for the first submission)
- [ ] `xcodegen generate` run; clean build succeeds
- [ ] Unit + UI tests green: `bundle exec fastlane tests`
- [ ] App ID `au.com.bclgapps.Repocast` has the **CarPlay Audio App** capability enabled (developer.apple.com ▸ Identifiers ▸ Additional Capabilities) — [Repocast.entitlements](../Sources/Repocast/Repocast.entitlements) carries `com.apple.developer.carplay-audio` on every build, so signing fails without it
- [ ] App Store provisioning profile named **Repocast AppStore** exists (App Store distribution, App ID `au.com.bclgapps.Repocast`, team `XKV3A3SLX9`), was generated *after* CarPlay Audio was enabled so it carries the CarPlay entitlement, and is installed on the build Mac along with an **Apple Distribution** certificate — `bundle exec fastlane beta` exports with manual signing using exactly that profile name. Create or refresh it with `bundle exec fastlane run sigh provisioning_name:"Repocast AppStore"` whenever the distribution certificate or an App ID capability changes
- [ ] `GoogleService-Info.plist` is present in [`Sources/Repocast/Resources/`](../Sources/Repocast/Resources/) (it is gitignored, so a fresh checkout won't have it). Without it `AnalyticsService.start()` silently no-ops — the app still works, but the App Privacy answers above would over-declare. Confirm events fire in Firebase DebugView on a test device
- [ ] TODO: decide on an app-level `PrivacyInfo.xcprivacy`. The target has none (the Firebase packages ship their own), but the app's own code uses `UserDefaults` — a required-reason API (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`). If App Store Connect emails ITMS-91053 after upload, add one
- [ ] Manual smoke test on a **physical iPhone with Apple Intelligence on**: add a public repo, generate a Markdown file (verbatim) and a code file (summary), play with the screen locked, change speed, tap transcript sentences
- [ ] Connect GitHub with a fine-grained read-only token — **From Your Repos** lists private repos (lock icon); **Disconnect** clears the connection
- [ ] Smoke test with Apple Intelligence **off** (or on an ineligible device): Settings ▸ On-Device AI shows the reason, code files fall back to verbatim, Smart Playlist shows its "isn't available" error
- [ ] **Smart Playlist** end-to-end: describe → preview → Save → Play All
- [ ] **Import Narration Folder** from Files (e.g. a copy of `Tests/Fixtures/proposal_v2/`), play, leave mid-part, reopen — Resume lands about 3 s before where you stopped
- [ ] **Voice note** on a physical device: Microphone prompt on first tap, Speech Recognition prompt after the first save, transcript appears, tapping the note jumps back to the moment
- [ ] **CarPlay** (simulator or a car): Tracks / Playlists / Narrations tabs populate, playback starts from each, the mic button on Now Playing records and saves a note
- [ ] Manual smoke test on **iPad** (multiple scenes are enabled for CarPlay, so iPad gains multi-window — check two windows share one player sensibly)
- [ ] **App Privacy answers** in App Store Connect match the **App Privacy** section above (Usage Data (Product Interaction) and Identifiers (Device ID) Collected, Not Linked, Not Used for Tracking; tracking question **No**; everything else "Data Not Collected")
- [ ] **Age rating** questionnaire answered as in **Age Rating** above; **Content Rights** answered Yes
- [ ] Marketing page live at `bclgapps.com.au/repocast`, matching [repocast.md](repocast.md)
- [ ] Support page live at `bclgapps.com.au/repocast-support`, matching [repocast-support.md](repocast-support.md) — App Store Connect rejects a Support URL that 404s
- [ ] Privacy policy live at `bclgapps.com.au/repocast-privacy`, matching [repocast-privacy.md](repocast-privacy.md)
- [ ] Screenshots produced in `screenshots-6.9/`, `screenshots-ipad-13/` (TODO above — no automation yet)
- [ ] App Review demo-token decision made (see **Sign-In Information**)
- [ ] Archive uploaded; processed build attached to the version; What's New text matches above
