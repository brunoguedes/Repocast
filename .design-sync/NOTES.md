# design-sync notes — Repocast

## What this design system is
A **pre-built web bundle** (React component primitives + CSS-token files) that
codifies Repocast's visual language: Apple's iOS 26 system look (SF type, SF
Symbols, system colors, translucent "Liquid Glass" materials, the Podcasts
mini-player → Now Playing pattern), tinted system blue `#007AFF`. It is a
**design / prototyping reference**, not code to ship — Repocast itself is native
SwiftUI. See `INTEGRATION.md` inside the bundle.

## Phase 4 (Playlists) — pulled FROM the design project (2026-06-28)
The Claude Design project was edited there and ran **ahead** of the local
bundle: it gained a Phase 4 (Playlists) drop-in (`export/Repocast-Phase4/`) and
new `ui_kits/repocast/` prototype screens. **Direction matters:** a normal
`/design-sync` pushes local→remote and deletes remote-only files, which would
have destroyed that work — so it was NOT run. Instead:
- The 7 Phase 4 Swift files were implemented in the app (`Models/Playlist.swift`,
  `PlaylistItem.swift`, `Services/PlaylistGenerator.swift`, 4 playlist Views) +
  the 4 wiring changes from `export/Repocast-Phase4/WIRING.md` (schema, Playlists
  tab, analytics). One Swift-6 fix: `PlaylistGenerator.curate` takes a `Sendable`
  `TrackChoice` (not `[AudioTrack]`) so the SwiftData models stay on the main actor.
- The local snapshot here was refreshed to match remote (101 files).

**If the remote moves ahead again, pull — don't push.** The remote is the live,
edited copy; `/design-sync` (push) is only safe once the local bundle is the
newer one.

## Sync status (2026-06-28)
- The bundle is an **export of the existing claude.ai/design project**
  `a3bb12ac-bd33-49f4-9200-cf527a70b2db` ("Repocast Design System"); the bundle
  namespace `RepocastDesignSystem_a3bb12` ties to that project id.
- That project **already contains the full bundle** — the local export and the
  remote project have an identical 79-file set. **Nothing to upload.**

## How to (re)sync in future
- There is **no source repo / build** here, so `/design-sync`'s converter does
  not apply (this is an off-script, pre-built layout).
- If the bundle is edited locally and needs pushing, it is a direct upload of
  the bundle files to the **same** project id above (atomic path), then re-arm
  the `_ds_needs_recompile` sentinel so the app rebuilds its card index.
- Do **not** create a second "Repocast Design System" project — pin is recorded
  in `config.json`.

## Bundle layout (conforms to claude.ai/design)
- `_ds_bundle.js` (`@ds-bundle` header), `_ds_manifest.json` (18 cards, 13
  components), `styles.css` → `tokens/*.css` `@import` closure.
- `components/<group>/<Name>.{jsx,d.ts,prompt.md}` + per-group `*.card.html`
  preview cards (first line `@dsCard`).
- `guidelines/` token cards, `ui_kits/repocast/` interactive app recreation,
  `export/AppIcon.appiconset/Icon-1024.png` (the app icon), `assets/`.

## App-side follow-ups (from the bundle's INTEGRATION.md)
- App icon: `export/AppIcon.appiconset/Icon-1024.png` → drop into
  `Sources/Repocast/Resources/Assets.xcassets/AppIcon.appiconset/` (scaffold's
  AppIcon is currently empty). No `xcodegen` needed for asset-catalog content.
- Optional token bridge: mirror tokens in a `Theme.swift` (`--tint` = `#007AFF`,
  radii, type → SwiftUI text styles).
- Do **not** port the React components into Swift — SwiftUI views are the real
  implementation.
