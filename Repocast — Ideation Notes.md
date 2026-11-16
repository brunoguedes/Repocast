# Repocast — Ideation Notes

## Concept

Repocast turns a GitHub repository (public or the user's own) into a playlist of audio episodes, playable in the car via CarPlay. It reads the README and main files, generates narrated episodes, and lets a developer learn or keep up with a codebase hands-free.

Two use cases, both wanted:

- **Onboarding** to an unfamiliar repo — first priority: what it is about and how it is architected.
- **Keeping up** with repos you already know (later: "what changed this week" from commits, PRs as episodes).

## Episode structure for a newly added repo

A short series rather than one long file:

1. **Intro episode** — purpose and audience, drawn from the README.
2. **Architecture episode** — built from the folder layout, entry points and dependency manifest. Told as a narrative of how data flows ("requests come in through the API layer, get validated here, then hit the database via the repository pattern"), not as a list of file names.
3. **One episode per major module.**

### Describe and critique pairs

Each module gets a pair of episodes:

- **Describe** — what the module does and how it fits.
- **Critique (optional)** — what could improve: code smells, missing tests, tangled dependencies.

Ideas: the critique unlocks after the description has been played so suggestions always have context; the critique could end with a spoken offer to save the findings as tasks or GitHub issues.

## Length and pacing

- Handmade \~30-minute test episode (ElevenLabs) felt good in the car — the tone is validated.
- Target: **15 minutes max per episode**, roughly one commute leg.
- At \~150 words per minute that is a \~2,000-word script — a hard cap for the generator. If a module overruns, split into Part 1 / Part 2 rather than compress.

## Playlist behaviour

- Chapter markers inside each episode so "skip forward" in CarPlay jumps to the next concept.
- Remember the playback position per repo so the next drive carries on where you left off.
- Prefetch the next episode while the current one plays, so there is no dead air.

## Repo classification

Not every repo is a codebase — some are documents-only. The eager index step classifies each repo before planning episodes:

- **Codebase** — source tree plus a dependency manifest. Full plan: intro, architecture, module describe/critique pairs.
- **Documents** — mostly Markdown, PDFs and text, no manifest or source tree. One episode per document or section; no architecture or critique tracks.
- **Mixed** — e.g. a docs site living beside code. Both shapes, grouped.

Classify by file-extension ratio and presence of a manifest. The user can override the guess.

## Incremental changes (keeping up)

After the first tour, each sync diffs against the last indexed commit and yields:

- A short **"what changed" episode** — commits grouped by theme, told as a story ("most of this week's work was in the payments module: a new retry path and two bug fixes"), not a changelog read aloud.
- A list of **stale module episodes** to regenerate selectively, keeping lazy generation honest.

**Cadence** is chosen by the user when adding the repo, with the app suggesting the better fit:

- **Per merged PR** — a mini-episode each; suits the user's own repos.
- **Weekly digest** — one batched episode; the sane option for large, busy public repos.

Suggestion heuristic: commit frequency and contributor count from the index step, plus whether the repo is the user's own.

## Generation strategy

- **Lazy generation**: episodes are produced on demand after a repo is added, not all up front. Keeps cost tied to actual listening.
- **Eager, cheap index** on add: file tree, README, manifest and a one-paragraph summary, so the episode list (titles, estimated durations) appears immediately even though no audio exists yet.

## Voice / TTS

- Current: native iOS, on-device only; audio generated manually via ElevenLabs.
- Options: ElevenLabs API (great voice, per-character cost, key must not ship in the app) vs. Apple on-device speech (free, offline, flatter).
- Possible hybrid: on-device voice by default, premium voices as a paid upgrade — doubles as the monetisation story.

## Backend (under discussion)

- AWS to keep costs low: Lambda, DynamoDB and S3 — a good fit for a bursty, mostly idle workload. Chain generation as steps (index → script → audio) via Step Functions or SQS so a TTS failure does not redo the model call. S3 holds scripts and audio; DynamoDB tracks repos, episodes and generation status; the app polls or gets a push when an episode is ready. ElevenLabs: the standard text-to-speech endpoint is synchronous (no polling or callbacks); chunk the script into paragraphs under \~1,000 characters, stitch the audio, cap concurrency. The Studio API is whitelist-only.

## Status against the codebase

The player half of these notes is largely built; the generation half is not started. Checked against `brunoguedes/Repocast` at commit `4506213` on 16 Nov 2026.

| Idea | In the repo today |
| --- | --- |
| Add a public repo or your own | Built: paste a URL or `owner/repo`, or connect a token to list your own, including private ones. |
| CarPlay playback | Built: Tracks, Playlists and Narrations tabs driving the same player as the phone. |
| Resume where you left off | Built for narrations only, with a 3-second rewind. Tracks and playlists do not remember position. |
| Chapter skipping | Partly: in a narration, next/previous jumps between parts. No markers inside a single file. |
| Repo tour (intro, architecture, modules) | Not built. Files are ticked by hand and each becomes one track. Nothing looks at the repo as a whole. |
| Describe and critique pairs | Not built. One code prompt, and it only describes. |
| 15-minute episodes | Not built. Code summaries are capped at about 180 words, roughly a minute. |
| Eager index, lazy generation, prefetch | Not built. Generation runs in the foreground behind a progress overlay on tapping Generate. |
| Repo classification | Per file only (code vs Markdown by extension). No repo-level call. |
| Incremental changes and cadence | Not built. A "changes" track type and prompt exist, but nothing fetches commits or PRs, and a repo stores no last-seen commit. |
| ElevenLabs and the AWS backend | Not built. Voice is Apple's on-device speech and there is no server. |

### Things to decide or fix

- **The backend changes the privacy story.** The App Store copy and privacy page promise that everything runs on device with no servers in the middle. Sending repo contents to Lambda, a cloud model and ElevenLabs means rewriting both, and private repos would need their contents or token to pass through the server.
- **Narration packages are the natural backend output.** The app already plays a folder of MP3 parts with a playlist and transcripts as one timeline, with resume, in CarPlay. If the backend emits that package, the only new app-side piece is downloading it instead of picking it from Files.
- **The docs are out of step with the code.** The README says the app voices merges and open PRs, which is not implemented. `CLAUDE.md` still lists summarisation and playlists as future phases, though both are in the code.

## Decision: free on-device, paid cloud

The driver is cost, not privacy. The free tier runs entirely on the user's device at zero cost (today's app: Apple Intelligence summaries, Apple speech). The AWS backend, cloud model and ElevenLabs voices are only for subscribed users who opt in.

- The current App Store listing and privacy page stay true for free users; cloud generation is disclosed at subscription time.
- Paid usage is metered by a **monthly quota of generation minutes**, not a repo cap, so ElevenLabs' per-character cost can never exceed the subscription.
- The repo tour logic (index, intro, architecture, modules) is written once and runs on Apple Intelligence for free users and on a larger model for paid: same plan, different executor and voice.

## Decision: output contract is the narration package

The backend emits exactly what `NarrationImporter` already accepts: a folder with a base name, numbered `<base>_partN.mp3` files, a `.txt` transcript per part, and a `<base>.m3u8` playlist carrying titles and order. The Studio exports in `Tests/Fixtures/` are already in this shape.

Added, backwards-compatibly: a `manifest.json` beside the playlist with the repo and commit it was built from, the episode type, the module it covers, and the quota minutes it cost. The importer ignores unknown files, so old packages still load.

App-side work is one download step: fetch a zip from a signed S3 URL, unzip into the narrations store, call the existing importer. Lazy generation follows: the episode list comes from the index, each row downloads on tap. Episodes appear under Narrations, not Tracks.

## Decision: first slice

A two-episode tour, intro then architecture, for one public repo. No modules, no critique, no incremental changes. First test repo: Repocast itself.

Lambda chain of three steps:

1. **Index** — shallow-clone; read the README, file tree and manifest; classify codebase vs docs; write a one-paragraph summary and the episode list to DynamoDB.
2. **Script** — one model call per episode under the 2,000-word cap, output as paragraphs.
3. **Audio** — ElevenLabs per paragraph, stitched into parts, packaged with the manifest, zipped to S3.

The test: is the architecture episode, built only from the tree, manifests and entry points, actually good? It is the one thing a per-file approach cannot produce, and the whole case for the backend.

On-device, the same two episodes run through Apple Intelligence with the existing 6,000-character chunking. Expected to be weaker; that is the upgrade pitch.
