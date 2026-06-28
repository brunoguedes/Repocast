# Repocast

Repocast turns selected files from a git repository (source code and Markdown) into audio you can play in the car or while exercising, using on-device Apple Intelligence to summarize code, convert docs to speech, generate AI playlists, and voice the latest GitHub changes like new merges and open PRs.

Native iOS app (iPhone + iPad, iOS 26+, Swift 6, SwiftUI + SwiftData). Firebase Analytics for anonymous usage telemetry. Fastlane for TestFlight/App Store.

## Getting started

```sh
brew install xcodegen          # once, if not installed
xcodegen generate
open Repocast.xcodeproj
```

The project builds and runs with no extra setup. Firebase Analytics stays disabled until you add a real `GoogleService-Info.plist` to `Sources/Repocast/Resources/` (see CLAUDE.md → Analytics).

## Layout

```
Sources/Repocast/   App, Models (SwiftData), Views, Services, Resources
Tests/                 Unit (Swift Testing) + UI tests
fastlane/              Fastfile, Appfile, .env.example
appstore/              App Store Connect metadata + screenshots
project.yml            XcodeGen spec — the source of truth
```

## Release

See [RELEASING.md](RELEASING.md).
