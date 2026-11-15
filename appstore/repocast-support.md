# Repocast — support

Public support copy for **https://bclgapps.com.au/repocast-support**. This is the page the App Store **Support URL** points to. App Store Connect rejects builds whose Support URL 404s, so this page must exist before submission.

---

## Contact

The fastest way to reach a human:

- **Email:** bruno@bclgapps.com.au

We aim to reply within two business days.

When reporting an issue, please include:

1. Your iPhone or iPad model and iOS version (Settings → General → About).
2. The Repocast version (Settings → General → iPhone Storage → Repocast, or the App Store listing).
3. What you were doing when the problem happened — and, for anything to do with GitHub, whether the repository is public or private and the exact error message.
4. Whether Apple Intelligence is on (Settings → Apple Intelligence & Siri). Repocast's own **Settings ▸ On-Device AI** also shows whether it can use it.

**Please never email us your GitHub token.** We'll never ask for it.

We can't see your library, your repositories or your notes — see the [privacy policy](repocast-privacy.md). The more context you can include in the email, the faster we can help.

---

## Frequently asked questions

### Do I need a GitHub account?

No. In the **Repos** tab, tap **Add Public Repo** and paste a link like `github.com/apple/swift`, or type `owner/repo`. Any public repository works without an account.

You only need a GitHub account — and a token — to browse your own repositories, including private ones.

### How do I connect my GitHub account?

1. On GitHub, create a **fine-grained personal access token** at **github.com/settings/tokens** with **read-only** access to repository contents, for the repositories you want to listen to.
2. In Repocast, go to **Settings ▸ GitHub ▸ Connect GitHub** (or tap **Connect GitHub** in the Repos tab) and paste the token.
3. Repocast checks it with GitHub, then stores it in your device's Keychain. Settings shows **Connected** with your GitHub username.

Then, in **Repos**, tap **+ ▸ From Your Repos** to pick one. Private repositories show a lock.

Your token is only ever sent to GitHub. Repocast only reads — it never changes anything in your repositories.

### My repository isn't in "From Your Repos".

That list shows the 100 most recently updated repositories your token can see. For anything older, use **Add Public Repo** and type `owner/repo` — with a token connected, that also works for private repositories the token can read. If a repository still can't be found, check that your fine-grained token includes it.

### GitHub says "rejected the token", "rate limit reached", or "not found".

- **"GitHub rejected the token"** — the token has expired, been revoked, or doesn't have read access. Create a new one and reconnect in Settings.
- **"GitHub rate limit reached"** — GitHub limits how many requests can be made without a token. Connecting a token raises that limit; otherwise, wait a while and try again.
- **"Not found on GitHub"** — check the repository name, and that your token has access to it if it's private.

### Why is code summarised but Markdown read word for word?

Reading code aloud symbol by symbol isn't useful, so for source files Repocast asks Apple Intelligence for a short spoken briefing — what the file does and its main pieces — and reads that instead. Long files are summarised in parts and joined into one narration. Markdown and plain-text files (`.md`, `.txt`, `.rst` and similar) already read well, so they're read verbatim.

For text you paste into **New Track**, you choose: **Read verbatim** or **AI summary**.

Summaries come from a small on-device model. They're good at the gist and can still miss or get a detail wrong — check the source before acting on one.

### Repocast says Apple Intelligence is unavailable — why?

Code summaries and smart playlists use Apple's Foundation Models framework, which needs an Apple Intelligence-eligible device running iOS 26 or later, with Apple Intelligence turned on and downloaded. **Settings ▸ On-Device AI** in Repocast tells you which of these is missing:

1. **"This device doesn't support Apple Intelligence"** — the device isn't eligible.
2. **"Turn on Apple Intelligence in Settings"** — go to **Settings → Apple Intelligence & Siri**.
3. **"The on-device model is still downloading"** — Apple downloads the model the first time you turn it on; give it a while on Wi-Fi.

Without Apple Intelligence, everything else still works: files are read aloud word for word, and you can build playlists by hand.

### I asked for a summary but got the whole file read out.

If the on-device model isn't available, or fails on a particular file, Repocast falls back to reading the text verbatim so you still get a track. Check **Settings ▸ On-Device AI**, then generate the file again.

### Can I change the voice or the speed?

- **Voice and speech rate** are in **Settings**. They're used when a track is generated, so they apply to new tracks — to hear an existing one in a different voice, generate it again.
- **Playback speed** (0.75× to 2×) is on the **Now Playing** screen — tap the mini-player — and applies to anything you play.

### A track failed to generate.

Some enhanced or personal voices can't be rendered to an audio file. If generation fails, pick a different voice in **Settings** (System Default is the safe choice) and try again. For files from a repository, also check your connection — Repocast has to download each file from GitHub first.

### Does Repocast work offline?

Tracks you've already generated, imported narrations and voice notes all play offline — they're stored on your device. Adding repositories and generating tracks from repository files needs an internet connection to reach GitHub. Tracks from pasted text are made entirely on your device.

### What's a narration folder, and how do I import one?

A narration folder is long-form audio someone has already narrated — for example a document rendered to MP3 elsewhere. Repocast reads folders that contain:

- numbered parts (`name_part1.mp3`, `name_part2.mp3`, …) and/or the whole narration stitched into one `name.mp3`,
- optionally a `name.m3u8` playlist that sets the order and titles,
- optionally transcripts — linked from the playlist, as a matching `.txt` file next to each MP3, or embedded in the MP3's lyrics tag.

In **Tracks**, tap **+ ▸ Import Narration Folder** and pick the folder in Files. Repocast copies it into its own storage, so it keeps playing even if the original moves. Importing the same folder again updates it in place.

### Where did I leave off in a narration?

Repocast remembers your place in every narration. Open it and tap **Resume** — it starts a few seconds before where you stopped so you can catch the thread — or **Start Over**. In CarPlay, a narration simply resumes.

### The transcript highlight is a little ahead of (or behind) the voice.

The highlight follows playback approximately: neither the speech engine nor imported narrations carry word-level timestamps, so Repocast estimates the position from how far through the audio you are. Tap any sentence to jump there.

### How do voice notes work?

While something is playing, open **Now Playing** and tap the **mic**. Playback pauses and Repocast starts recording; tap **Save** when you're done (or **Cancel**). In CarPlay, tap the mic button on Now Playing to start and tap it again to save.

The first time, iOS asks for **microphone** access; after your first note is saved, it asks for **speech recognition** so the note can be transcribed. Transcription happens entirely on your device.

Find your notes in the **Notes** tab. Tap a note to jump back to the moment you recorded it; tap the waveform button to hear the recording itself.

### My note says "transcription unavailable" or "transcription failed".

Repocast only transcribes on your device, never on a server. If your device or language doesn't support on-device speech recognition — or Speech Recognition is turned off for Repocast in **Settings → Privacy & Security → Speech Recognition** — the note is kept as audio only. The recording is always saved; play it with the waveform button.

If tapping the mic only shows "Allow microphone access in Settings to record notes", turn on **Settings → Privacy & Security → Microphone → Repocast**.

### A note says "Content Not in Library".

The track or narration that note was recorded on has since been deleted, so there's nothing to jump back to. The note and its recording are still there — tap the waveform button to play it.

### How do I use Repocast with CarPlay?

Connect your iPhone to CarPlay and open Repocast on the car's screen. You'll see **Tracks**, **Playlists** and **Narrations**; pick anything to play it. The car and your iPhone share one player, so you can start on one and control it from the other. Repocast in CarPlay is a player — add repositories, generate tracks and build playlists on your iPhone, and they appear in the car straight away.

### Does my library sync between my iPhone and iPad?

Not today. There's no iCloud sync, so each device keeps its own library of tracks, playlists, narrations and notes.

### Does my data leave my device?

Your repositories' files travel only between your device and GitHub — never through us. Text-to-speech, code summaries, smart playlists and voice-note transcription all happen on your device, and your voice notes never leave it. Your GitHub token is stored in the Keychain and only ever sent to GitHub. We run no servers and there are no Repocast accounts.

The one exception is anonymous usage analytics: the app uses Firebase Analytics to record which tabs you open and which features get used, so we can see what matters. It never includes repository names, file contents, transcripts or notes, and it isn't linked to your identity or used for advertising. See the [privacy policy](repocast-privacy.md) for the full statement.

### How do I delete my data?

There is nothing to delete on our side — we have none of it. On your device:

1. Swipe to delete individual tracks, narrations, playlists, repositories or notes.
2. To remove your GitHub token, go to **Settings ▸ GitHub ▸ Disconnect** — do this **before** deleting the app, because iOS can keep Keychain items after an app is removed. You can also revoke the token on GitHub at **github.com/settings/tokens**.
3. Delete Repocast from the Home Screen to remove everything else.

### What's next?

A spoken digest of a repository's latest changes — recent merges and pull requests — is on the roadmap. Requests are welcome; see below.

---

## Reporting a bug or requesting a feature

Email **bruno@bclgapps.com.au** with the subject `Repocast — bug` or `Repocast — request`. Please include the device/iOS information listed in the **Contact** section above.

---

© 2026 BCLG Apps.
