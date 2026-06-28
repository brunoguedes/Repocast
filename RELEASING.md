# Releasing Repocast

How to cut a TestFlight build. Local-only for now — no GitHub Actions, no `match`.

## One-time setup

### 1. Install Bundler + the gem set

```sh
bundle config set --local path 'vendor/bundle'
bundle install
```

Prefix every fastlane command with `bundle exec` so it uses the project-local copy.

### 2. App Store Connect API key

1. **App Store Connect -> Users and Access -> Integrations -> App Store Connect API**.
2. Create a key with the **App Manager** role.
3. Note the **Key ID** (10 chars) and **Issuer ID** (UUID at the top).
4. Download the `.p8` (once only) and move it outside the repo, e.g. `~/.appstoreconnect/AuthKey_<KEY_ID>.p8`.

### 3. Export the env vars

Copy `fastlane/.env.example` to `fastlane/.env` (gitignored) and fill it in:

```sh
ASC_KEY_ID="ABCDEFGHIJ"
ASC_ISSUER_ID="11111111-2222-3333-4444-555555555555"
ASC_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_ABCDEFGHIJ.p8"
```

### 4. Verify signing once

Open `Repocast.xcodeproj` and confirm the **Repocast** target signs cleanly with **Automatic** signing under team `XKV3A3SLX9`.

## Day-to-day commands

```sh
bundle exec fastlane tests           # run unit + UI tests
bundle exec fastlane bump_build      # CURRENT_PROJECT_VERSION += 1, regenerate
bundle exec fastlane set_version version:1.2   # new marketing version, build -> 1
bundle exec fastlane beta            # build Release + upload to TestFlight
bundle exec fastlane release_build   # bump_build + beta (most common)
```

All lanes mutate `project.yml` and re-run `xcodegen` — never hand-edit the generated `.xcodeproj`.
