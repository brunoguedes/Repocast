# Repocast backend

Cloud generation of repo-tour episodes for the opt-in beta: Claude on Amazon Bedrock writes the scripts, ElevenLabs voices them, and the result is a **narration package** in S3 that the app downloads and plays like any imported narration. TypeScript on AWS via [SST v3](https://sst.dev). All commands run from `backend/`.

```text
App ──JWT──► API Gateway ──► POST /repos ──async──► Index    (GitHub tree + README + manifests → classify → summary + episode list)
                         └─► POST …/episodes/{type} ──► EpisodeFlow (Step Functions)
                                                         Script  (Claude → sections, ≤ word cap) → S3 scripts/
                                                         Audio   (ElevenLabs per ≤1,000-char chunk → <base>_partN.mp3 + .txt + .m3u8 + manifest.json) → S3 episodes/
                         └─► GET …/episodes/{type} ──► manifest + signed URL per file
```

- **DynamoDB** (single table) holds the per-commit index, episode status and per-user monthly minutes. Layout is documented in `src/lib/db.ts`.
- **Episodes are cached per repo + commit + type** and shared by every listener; only the first request is charged.
- **Quota**: each user gets `MONTHLY_QUOTA_MINUTES` (default 60) generation minutes a month. A request reserves the estimate; the audio step settles to the real duration; a failure refunds it.
- **Auth**: Cognito user pool, Sign in with Apple via the hosted UI, PKCE from the app. Sign-up is limited to the `BetaEmails` allowlist until subscriptions exist.
- **Public repos only** in this slice: private repos are rejected, so no GitHub token ever leaves the device.
- Prompts come from `../shared/prompts` (copied into the Index and Script functions); classification from `../shared/classification.json`.

## Setup

One-time, outside this repo:

1. **Bedrock**: enable access to the Claude model in your region (default model `anthropic.claude-opus-5`; override with `BEDROCK_MODEL_ID`, region with `BEDROCK_REGION`).
2. **Sign in with Apple**: in developer.apple.com create a Services ID (return URL `https://repocast-<stage>.auth.<region>.amazoncognito.com/oauth2/idpresponse`) and a Sign in with Apple key.
3. **ElevenLabs**: an API key and the voice ID to use.
4. **GitHub**: a fine-grained token with public-repository read access only.

Then per stage:

```sh
npm install
npx sst secret set ElevenLabsApiKey …
npx sst secret set ElevenLabsVoiceId …
npx sst secret set GitHubToken …
npx sst secret set BetaEmails "you@example.com"     # comma-separated, or "*"
npx sst secret set AppleServicesId …
npx sst secret set AppleTeamId …
npx sst secret set AppleKeyId …
npx sst secret set ApplePrivateKey "$(cat AuthKey_XXXX.p8)"
npx sst dev            # or: npx sst deploy --stage production
```

The deploy prints `API_BASE_URL`, `COGNITO_DOMAIN` and `COGNITO_CLIENT_ID`; copy them into `ios/Config/Backend.xcconfig`.

## Run it locally

The pipeline lives in `src/core/tour.ts` with no AWS in it; the Lambda steps wrap it with DynamoDB and S3, and `src/local/run.ts` wraps it with the file system. Nothing is deployed — GitHub and ElevenLabs are called directly and Claude through Bedrock with your local AWS credentials:

```sh
export BEDROCK_REGION=us-east-1                 # a region where your account has Claude access
export ELEVENLABS_API_KEY=… ELEVENLABS_VOICE_ID=…  # only needed for audio
npm run tour -- brunoguedes/Repocast --no-audio   # index + scripts only; read .local/…/<type>/script.md
npm run tour -- brunoguedes/Repocast              # then record (scripts are cached, not rewritten)
npm run tour -- brunoguedes/Repocast --episode architecture --fresh
```

Output goes to `.local/<owner>__<name>/<commit>/`: `index.json`, and per episode `script.json`, a readable `script.md`, and the narration package folder — the same files the cloud puts in S3. Import that folder in the app (Tracks ▸ Import Narration Folder) to hear it in the player and CarPlay.

## Tests

```sh
npm test          # vitest: shared classification vectors, chunking, package/playlist/manifest, clients
npm run typecheck
```
