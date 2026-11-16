# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Repocast turns a GitHub repository into audio you can play in the car or while exercising: a guided **repo tour** (intro, architecture) plus per-file tracks, narration packages and playlists, played through a background player with lock-screen and CarPlay controls. Product thinking lives in [Repocast — Ideation Notes.md](Repocast%20—%20Ideation%20Notes.md).

**Free tier is fully on-device** (Apple Intelligence + Apple speech). **Cloud generation** (Claude on Amazon Bedrock + ElevenLabs voices, on AWS) is an opt-in beta for signed-in users. Cost, not privacy, is the reason for the split.

## Repo map

| Folder | What | Run commands from | Guidance |
| --- | --- | --- | --- |
| [ios/](ios/) | Native iOS app (Swift 6, SwiftUI, SwiftData, XcodeGen, fastlane, App Store copy) | `ios/` | [ios/CLAUDE.md](ios/CLAUDE.md), [ios/RELEASING.md](ios/RELEASING.md) |
| [backend/](backend/) | Cloud tour generation (TypeScript, SST v3 on AWS: API Gateway + Cognito, Lambda, Step Functions, DynamoDB, S3) | `backend/` | [backend/README.md](backend/README.md) |
| [shared/](shared/) | The contract both executors honour: narration `manifest.json` schema, tour prompts, classification test vectors | — | below |

Launch Claude Code from the repo root (project memory and `.mcp.json` are keyed to it).

## The shared contract

Both executors — on-device (`ios/`) and cloud (`backend/`) — produce the **same narration package**, which the app's `NarrationImporter` already plays as one timeline with resume and CarPlay:

```text
<base>.m3u8          #PLAYLIST title, #EXTINF:<sec>,<part title>, #EXT-TRANSCRIPT:<part>.txt
<base>_partN.<ext>   one part per script section (mp3 from the cloud, caf on device)
<base>_partN.txt     transcript per part
manifest.json        shared/narration-manifest.schema.json — repo, commit, episode type, executor, quota minutes
```

- Never emit a stitched `<base>.<ext>` for a tour episode — it would hide the parts, and the parts are the chapter markers.
- Prompts in [shared/prompts/](shared/prompts/) are bundled into the app and imported by the backend. Change a prompt there, not in code.
- Repo classification (codebase / documents / mixed) is implemented twice (Swift `RepoClassifier`, TS `classify.ts`); both test suites run [shared/fixtures/classification-cases.json](shared/fixtures/classification-cases.json). Change the rule → update the vectors → both suites must pass.

## Privacy

- Free tier: repo data goes only to api.github.com; scripts and audio are made on the device.
- Cloud beta: the app sends the **public** repo's name to our API; the backend fetches it from GitHub, scripts it with Claude on Bedrock and voices it with ElevenLabs. Private repos are rejected in this slice — no GitHub token ever leaves the device.
- Analytics events carry counts and enum raw values only, never repo text, file names or transcripts.
- Keep `ios/appstore/repocast-privacy.md` and the App Privacy answers in sync with any change to either surface.
