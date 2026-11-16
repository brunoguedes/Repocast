# Repocast

Repocast turns a GitHub repository into audio you can play in the car or while exercising: a guided repo tour (what it is, how it's architected), per-file narrations, narration packages and playlists, with lock-screen and CarPlay controls. The free tier runs entirely on-device with Apple Intelligence and Apple speech; cloud generation with premium voices is an opt-in beta.

## Layout

```
ios/        Native iOS app — XcodeGen project.yml, Sources/, Tests/, fastlane/, appstore/
backend/    Cloud tour generation — TypeScript on AWS via SST v3
shared/     Narration manifest schema, tour prompts, classification test vectors
```

## Getting started

iOS app:

```sh
brew install xcodegen          # once, if not installed
cd ios
xcodegen generate
open Repocast.xcodeproj
```

The app builds and runs with no extra setup. Firebase Analytics stays disabled until you add a real `GoogleService-Info.plist` to `ios/Sources/Repocast/Resources/`; cloud generation stays hidden until you fill in `ios/Config/Backend.xcconfig` (see `ios/Config/Backend.xcconfig.example`).

Backend: see [backend/README.md](backend/README.md).

## Release

See [ios/RELEASING.md](ios/RELEASING.md).
