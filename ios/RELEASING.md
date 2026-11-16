# Releasing Repocast

How to cut a TestFlight build and push it for review. Local-only for now — no GitHub Actions, no `match`. See the bottom of this file for what to add when those are needed.

---

## One-time setup

### 1. Install Bundler + the gem set

Bundler ships with Homebrew Ruby, so you usually don't need `gem install bundler` — and on Homebrew you can't write to the system gem dir anyway. Configure Bundler to install gems into a project-local `vendor/bundle/` (already gitignored), then install:

```sh
bundle config set --local path 'vendor/bundle'
bundle install
```

After this, prefix every fastlane command with `bundle exec` so it picks up the project-local copy.

### 2. App Store Connect API key

Fastlane authenticates to App Store Connect via an API key — no Apple ID, no 2FA prompts.

1. Go to **App Store Connect → Users and Access → Integrations → App Store Connect API**.
2. Create a new key with the **App Manager** role (`Admin` also works).
3. Note the **Key ID** (10 chars) and the **Issuer ID** (UUID at the top of the page).
4. Download the `.p8` file. App Store Connect only lets you download it once — save it somewhere safe and back it up.
5. Move the `.p8` somewhere outside the repo (e.g. `~/.appstoreconnect/AuthKey_<KEY_ID>.p8`).

### 3. Export the env vars

Add these to your shell profile (`~/.zshrc`) or copy `fastlane/.env.example` to `fastlane/.env` (gitignored) and fill it in:

```sh
export ASC_KEY_ID="ABCDEFGHIJ"
export ASC_ISSUER_ID="11111111-2222-3333-4444-555555555555"
export ASC_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_ABCDEFGHIJ.p8"
```

Reload (`source ~/.zshrc`) or open a new terminal. The Fastfile loads `fastlane/.env` itself (and expands a leading `~` in `ASC_KEY_FILEPATH`), so there's no need to source it first.

### 4. Verify Xcode signing once

Open `Repocast.xcodeproj` in Xcode and make sure the **Repocast** target signs cleanly with **Automatic** signing under your team `XKV3A3SLX9`. The app needs the CarPlay Audio entitlement (enabled on the `au.com.bclgapps.Repocast` App ID) plus the microphone and speech-recognition usage strings — all already wired through `project.yml` and `Sources/Repocast/Repocast.entitlements`. Development builds use that automatic provisioning; the App Store export signs manually (see **Build + upload to TestFlight**).

---

## Day-to-day commands

All commands run from `ios/` (the app folder), not the repo root.

### Run tests

```sh
bundle exec fastlane tests
```

Builds + runs the `Repocast` scheme (unit + UI tests) on the iOS 26.5 iPhone 17 Pro simulator (override with `TEST_DEVICE="iPhone 17 (26.5)"`; the iOS 27 simulators fail test suites with spurious "No eligible connection available" errors). Use this before every release. Firebase Analytics stays disabled unless `Sources/Repocast/Resources/GoogleService-Info.plist` is present (gitignored) — add it before archiving a release.

### Bump the build number

```sh
bundle exec fastlane bump_build
```

Increments `CURRENT_PROJECT_VERSION` in `project.yml` by 1 and regenerates the Xcode project. Use this for every TestFlight build within the same marketing version (e.g. 1.1 (1) → 1.1 (2)).

### Set a new marketing version

```sh
bundle exec fastlane set_version version:1.2
```

Sets `MARKETING_VERSION` to the value you pass and resets `CURRENT_PROJECT_VERSION` to 1. Use this when starting work on the next release (1.1 → 1.2).

### Build + upload to TestFlight

```sh
bundle exec fastlane beta
```

Builds a Release archive of the `Repocast` scheme, signs it for the App Store, and uploads it to TestFlight. Does **not** bump the version — chain it with `bump_build` first, or use the convenience lane below.

The export signs **manually** against the "Repocast AppStore" profile with the ASC API key passed straight to xcodebuild — no Xcode sign-in needed, and no cloud-signing permission on the key. If signing breaks (new machine, expired/revoked certificate, or a capability added to an App ID), recreate the pieces with the same API key:

```sh
# 1. Distribution certificate into the login keychain (api_key_path = JSON with key_id/issuer_id/key)
bundle exec fastlane run cert api_key_path:/path/to/asc_key.json generate_apple_certs:true
# 2. Refresh the App Store profile to include it
bundle exec fastlane run sigh api_key_path:/path/to/asc_key.json \
  app_identifier:au.com.bclgapps.Repocast \
  provisioning_name:"Repocast AppStore" ignore_profiles_with_different_name:true force:true
```

Repocast hasn't shipped yet: create its app record in App Store Connect (**Apps → + → New App**, bundle ID `au.com.bclgapps.Repocast`) and run step 2 once to create the "Repocast AppStore" profile before the first `beta`.

### Capture App Store screenshots

No automated driver yet — capture by hand on the App-Store-ideal simulators, **iPhone 17 Pro Max** (6.9", 1320×2868) and **iPad Pro 13-inch (M5)** (13", 2064×2752), after setting the canonical status bar:

```sh
xcrun simctl status_bar booted override --time 9:41 \
  --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
```

Save them as `NN-<screen>.png` in `appstore/screenshots-6.9/` and `appstore/screenshots-ipad-13/`. Adding a `screenshots` lane needs a demo-data launch mode plus a UI test that calls `snapshot()` — MyHealthInsights is the template.

### Release notes ("What to Test")

Each build's tester-facing notes live in `fastlane/release-notes/<version>-<build>.txt` (committed). `beta` uploads them as the build's TestFlight **What to Test** once the build appears on App Store Connect; with no file it uploads without notes.

```sh
bundle exec fastlane release_notes            # draft the current build's file from the commits since the last build
bundle exec fastlane testflight_notes         # (re)set What to Test for the current build from its file
bundle exec fastlane testflight_notes build:9 # …or for an earlier build of this version
```

The draft sorts `feat:` / `perf:` / `fix:` subjects into New / Improved / Fixed, drops other conventional types (docs, chore, …), and lists any non-conventional subject under Changes. "The last build" is its `<scheme>-v…` tag, or before the first tag the last commit that changed the build number. The draft is a starting point: commit subjects are written for engineers, so rewrite them as what a tester will notice before shipping. App Store Connect rejects some symbols in What to Test (✕ was refused); plain text and `•` bullets are fine.

### Beta groups

```sh
bundle exec fastlane beta_groups                       # list the groups and which already get every build
bundle exec fastlane distribute groups:<name>          # add the current build once it has processed
bundle exec fastlane distribute groups:<name> build:11
```

Groups with access to every build get each upload from App Store Connect automatically, and `distribute` skips them. Adding an **external** group waits for processing, submits the build for Beta App Review with its What to Test notes, and notifies that group's testers once Apple approves — so only add it to builds you want outside testers on. Repocast has no App Store Connect record yet, so it has no groups until the app is created there.

### Build tags

Every uploaded build is tagged `Repocast-v<version>(<build>)` at the commit it was built from (`fastlane tag_build`, run by `release_build`). The release-notes draft diffs from the latest tag reachable from `HEAD`.

### When the upload "fails" but succeeded

altool regularly prints `UPLOAD SUCCEEDED` followed by a stray `CDUploaderStateInfoResumeFilePath … file doesn't exist` line, which fastlane reports as *Error uploading ipa file*. `beta` catches exactly that error, polls App Store Connect for the build number (up to 15 min), and carries on only if the build is there; otherwise it fails as before. Never re-upload a build number that's already on App Store Connect — it's rejected.

### One-shot: bump + notes + build + upload + commit + tag

```sh
bundle exec fastlane release_build
```

Requires a clean working tree. Bumps the build, drafts its notes file if you haven't written one, archives and uploads with the notes, then commits `project.yml` + the notes, pushes, and tags the build. The commit happens only after a successful upload, so a failed archive leaves just a local bump — fix it and run `bundle exec fastlane beta`, then commit. Write `fastlane/release-notes/<version>-<next build>.txt` before running it if you want hand-written notes rather than the commit-subject draft.

---

## Recommended release flow

For a new TestFlight build of the current version:

```sh
bundle exec fastlane tests          # green?
# optional: write fastlane/release-notes/<version>-<next build>.txt
bundle exec fastlane release_build  # bump, upload with notes, commit, push, tag
```

For starting a new marketing version:

```sh
# 1. Cut a release branch (optional but recommended)
git checkout -b release/1.2

# 2. Bump the marketing version
bundle exec fastlane set_version version:1.2

# 3. Commit the version bump
git add project.yml
git commit -m "chore: bump version to 1.2 (1)"

# 4. Tests + first TestFlight build
bundle exec fastlane tests
bundle exec fastlane release_notes   # then edit fastlane/release-notes/1.2-1.txt
bundle exec fastlane beta
bundle exec fastlane tag_build

# 5. Iterate — for each subsequent TestFlight upload
bundle exec fastlane release_build
```

Once happy with a TestFlight build, finish the release in App Store Connect:

1. Open the build in App Store Connect.
2. Paste the "What's New" notes into the version's "What's New" field.
3. Update screenshots if needed (see `appstore/screenshots-*/` — captured by hand for now).
4. Submit for review.

---

## What's gitignored vs. committed

**Committed**:

- `Gemfile` — declares the fastlane dependency
- `Gemfile.lock` — pins gem versions for reproducibility
- `fastlane/Fastfile`, `fastlane/Appfile` — lane definitions and app config
- `fastlane/.env.example` — template for the ASC env vars

**Gitignored**:

- `*.p8`, `*.p12` — never commit App Store Connect keys or signing certs
- `fastlane/.env*` (except `.env.example`) — local environment with the ASC key id/path
- `fastlane/report.xml`, `fastlane/Preview.html`, `fastlane/test_output/`, `fastlane/README.md` — fastlane build artefacts
- `vendor/bundle/`, `.bundle/` — installed gems

---

## Future: when to add the missing pieces

### `match` (encrypted certs in a private repo)

Add this when you start running CI/CD on a fresh runner (e.g. GitHub Actions). `match` solves the problem of getting your distribution certificate and provisioning profile onto a machine that doesn't have your local keychain. Until then, Xcode's automatic signing handles your local builds.

### GitHub Actions

Add a `.github/workflows/release.yml` that triggers on push of a `v*` git tag:

1. Checkout
2. Install Ruby + `bundle install`
3. `bundle exec fastlane match appstore --readonly` (requires `MATCH_GIT_URL` and `MATCH_PASSWORD` secrets)
4. `bundle exec fastlane beta` (with `ASC_KEY_*` secrets)

The Fastfile is already structured to support that flow — only `match` integration and the workflow YAML need to be added.

### Submission lane

`upload_to_testflight` currently uses `skip_submission: true`, which means builds land in TestFlight as test-only. To auto-submit a build for App Store Review, add a `submit` lane that calls `deliver` / `upload_to_app_store` with the release metadata. Hold off until your release process is stable enough that automated submission feels safe.
