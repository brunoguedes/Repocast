# Repocast — privacy policy

Public privacy policy for **https://bclgapps.com.au/repocast-privacy**. This is the page the App Store **Privacy Policy URL** points to. App Store Connect requires this URL to be valid before review.

**Effective date:** 2026-11-14
**Last updated:** 2026-11-14

---

## Summary in plain English

- Repocast does not run any servers. We never see the repositories you add, the text you paste, the audio you make, or the notes you record.
- When you add a GitHub repository, your iPhone talks **directly to GitHub** to list and read its files. Nothing passes through us. Repocast only reads from GitHub; it never writes to it.
- If you connect a GitHub token, it is stored in your device's **Keychain** and only ever sent to GitHub. Public repositories need no token at all.
- Text-to-speech, AI code summaries, smart playlists and voice-note transcription all run **on your device**. The AI uses Apple Intelligence's on-device model; nothing you give it leaves your device.
- Voice notes are recorded with the microphone only when you tap the mic, saved only on your device, and transcribed on your device.
- We collect anonymous, aggregate usage analytics (which tabs you open and which features get used) through Firebase Analytics so we can understand what's worth improving. This data contains **no** repository names, file contents, transcripts or notes. No accounts, no login, no advertising identifiers.

If a privacy claim ever feels less than this, please email **bruno@bclgapps.com.au** — we want to hear about it.

---

## Who we are

Repocast is published by **BCLG Apps** (sole trader, Australia), reachable at **bruno@bclgapps.com.au**.

This policy applies to the iOS app **Repocast** (the "app") and the marketing pages at **bclgapps.com.au/repocast**, **bclgapps.com.au/repocast-support**, and this page.

---

## What data the app touches

Everything below is stored only in the app's own storage on your device:

- **Repositories you add** — the owner, name, default branch and description of each repository, so the Repos tab can list them.
- **Files you choose to turn into audio** — the text of each file is downloaded from GitHub, passed to the on-device text-to-speech engine (and, for code, to the on-device AI first), and kept as the track's transcript next to the generated audio file.
- **Text you paste** into a new track, and the audio made from it.
- **Playlists** you build or generate, and the order of their tracks.
- **Narration folders** you import from the Files app. Repocast copies the folder you pick into its own storage, so playback never depends on the original location. It remembers where you stopped in each one.
- **Voice notes** — the recording, its transcript, and which track or narration (and which moment in it) you were listening to when you made it.
- **Settings** — your chosen voice and speech rate, and, if you connected GitHub, your GitHub username, so Settings can show who you're connected as.
- **Your GitHub token**, if you add one — in the iOS Keychain, not in ordinary app storage.

Repocast does **not** sync between devices: there is no iCloud container, so your library stays on the iPhone or iPad where you made it. Like the rest of your apps' data, it is included in your device backups (iCloud Backup or a computer backup) if you have those turned on.

**CarPlay:** when you connect to CarPlay, the car's screen shows your track, playlist and narration titles and plays the audio. Nothing else is sent anywhere.

---

## How GitHub access works

Repocast reads repositories through **GitHub's public REST API** (`api.github.com`), directly from your device:

- **Public repositories** can be added by link or `owner/repo` without any account or token.
- **Your own repositories** — including private ones — can be listed once you connect a **personal access token** you create on GitHub. We recommend a fine-grained token with read-only access to repository contents. Repocast checks the token with GitHub, then stores it in your device's Keychain.
- If a token is saved, it is sent **only to GitHub**, with every request Repocast makes there (this also raises GitHub's rate limit for public repositories). It is never sent to us, to Firebase, or to anyone else.
- Repocast only ever **reads** — it lists repositories, folders and files, and downloads the text of the files you select. It never creates, edits, comments on or deletes anything on GitHub.
- GitHub sees these requests the way it sees any app or browser using its API. Its handling of them is covered by GitHub's own privacy statement, between you and GitHub.

To stop all of this: **Settings ▸ GitHub ▸ Disconnect** deletes the token from the Keychain and forgets your username. You can also revoke the token itself on GitHub at any time (**github.com/settings/tokens**).

---

## What data the app does not collect

- We run no servers of our own. Apart from requests to GitHub (described above) and the anonymous Firebase Analytics usage data (described in "Usage analytics" below), no data is sent off your device.
- **Your repositories, files, transcripts and generated audio never reach us.** They move only between your device and GitHub, and are stored only on your device.
- **Your voice notes never leave your device at all** — not the recording, not the transcript (see "Voice notes and speech recognition" below).
- **Your GitHub token never reaches us.** It is stored in the Keychain and only ever sent to GitHub.
- We do not collect or transmit your name, email, phone number, location, contacts, photos, or advertising identifiers.
- The only third-party SDK in the app is **Firebase Analytics** (Google), used solely for the anonymous usage analytics described below. The rest of the app uses only Apple frameworks: SwiftUI, SwiftData, AVFoundation, MediaPlayer, Speech, Foundation Models, CarPlay, and Security (for the Keychain).

---

## Usage analytics

The app uses **Firebase Analytics** (a Google service) to collect anonymous, aggregate information about how the app is used. This helps us understand which features people find valuable and where to focus.

- **What is collected:** which of the five tabs (Tracks, Repos, Playlists, Notes, Settings) you open, and events when you use a feature — for example generating, playing or deleting a track; connecting or disconnecting GitHub; adding a repository; creating or playing a playlist; importing, playing or finishing a narration; connecting to CarPlay; and recording, transcribing, opening or deleting a voice note. For these events we record only counts and simple states — for example whether a track was summarised or read verbatim, the playback speed, whether a playlist was a smart one, how many parts a narration has, or whether a transcription succeeded. Firebase also records when a session starts and how long the app is in use.
- **What is never collected:** repository or file names, file contents, the text you paste, transcripts, playlist names or descriptions, your voice notes or their text, your GitHub username, or your GitHub token. The analytics events carry only the categories listed above.
- **Identifiers:** Firebase attaches an anonymous, app-specific instance identifier so events from the same install can be grouped. This is not the advertising identifier (IDFA), and we do not use it to track you across other apps or websites.
- **No tracking / no ads:** we do not use this data for advertising, we do not share it with data brokers, and we do not link it to your identity. There are no third-party advertising SDKs in the app.
- **Where it goes:** these anonymous events are sent to Google's Firebase servers over an encrypted connection and are subject to Google's handling of Firebase Analytics data. We see only aggregate reports.

This, and your own requests to GitHub, is the only data the app transmits.

---

## Apple Intelligence and on-device AI

Repocast uses **Apple Intelligence** through Apple's **Foundation Models** framework — Apple's on-device language model — in two places:

- **Code summaries.** When you turn a source-code file into a track (or choose "AI summary" for pasted text), the text is given to the on-device model, which writes a short spoken explanation. Long files are summarised in parts and then combined.
- **Smart playlists.** When you describe a playlist, the model is shown your description and your tracks' **titles, types and durations** — never their transcripts — and picks and orders tracks from that list.

In both cases the model runs entirely on your device. The prompt and the generated text are not sent to Apple, to us, or to anyone else. Summaries are saved on your device as the track's transcript.

This is only available on Apple Intelligence-eligible devices running iOS 26 or later, with Apple Intelligence turned on. Elsewhere, files are read aloud word for word and smart playlists are unavailable.

---

## Voice notes and speech recognition

While you listen, you can record a voice note pinned to the moment you were at.

- The **microphone** is used only after you tap the mic button and grant microphone permission, and only until you save or cancel the note. Recording pauses playback first.
- Notes are saved **only** in the app's local storage on your device.
- Transcription uses Apple's Speech framework with **on-device recognition required**, so the recording is never sent to Apple's servers or anyone else to be transcribed. The app asks for Speech Recognition permission the first time it transcribes a note. If your device or language doesn't support on-device recognition, the note is kept as audio only — Repocast never falls back to server-based recognition.
- To delete a note, swipe it away in the **Notes** tab. That deletes the recording and its transcript.

---

## Children

Repocast is not directed at children under 13. We do not knowingly collect data from anyone, including children.

---

## Changes to this policy

If we change this policy we will update the "Last updated" date at the top of this page and post the new version at the same URL. If we ever introduce a feature that involves transmitting data off the device beyond what is described here, we will update this policy **before** the feature ships and call out the change clearly in the App Store "What's New" notes for that release.

---

## Your rights

You can:

- Disconnect GitHub at any time: **Settings ▸ GitHub ▸ Disconnect** in Repocast, which deletes the token from the Keychain. You can also revoke the token on GitHub at **github.com/settings/tokens**.
- Revoke microphone access at any time: **Settings → Privacy & Security → Microphone → Repocast**.
- Revoke speech recognition access at any time: **Settings → Privacy & Security → Speech Recognition → Repocast**.
- Delete individual tracks, narrations, playlists, repositories and voice notes by swiping them away in the app.
- Delete the app to remove your library, audio, narrations and notes from the device. iOS can keep Keychain items after an app is deleted, so if you connected GitHub, tap **Disconnect** first (or revoke the token on GitHub) to be sure the token is gone.
- Email **bruno@bclgapps.com.au** with any question or concern about this policy.

We hold no account for you and none of your content. The only data we receive is the anonymous, aggregate usage analytics described above, which is not linked to your identity — so there is no personal record for us to export or delete. You can stop all analytics collection at any time by deleting the app.

---

## Jurisdiction

BCLG Apps is based in Australia. Australian privacy law (the Privacy Act 1988 (Cth) and the Australian Privacy Principles) applies to our handling of personal information. Because the app does not collect personal information, most of the obligations are not triggered, but we are committed to operating consistently with their spirit.

If you are in the European Union or the United Kingdom, the GDPR and UK GDPR may apply to your use of the app. We do not receive your content or any data linked to your identity. The anonymous usage analytics described above are processed by Google's Firebase service, which may store them outside your country.

---

## Contact

**bruno@bclgapps.com.au**

© 2026 BCLG Apps.
