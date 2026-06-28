# Repocast — Phase 4 (Playlists) drop-in

Swift files that implement Phase 4 from your `CLAUDE.md` roadmap — `Playlist` /
`PlaylistItem` models, CRUD + reorder, and AI-generated **smart playlists**
(FoundationModels guided generation). They follow the codebase conventions
(raw-string enums, CloudKit-safe relationships, `AnalyticsService` funnel,
`AudioFileStore` / `AudioPlayerService` reuse).

> Mounted folder is read-only to the assistant, so these live here for you to
> copy in. Paths below are relative to the repo root.

## Files (copy into `Sources/Repocast/…`)
- `Models/Playlist.swift`
- `Models/PlaylistItem.swift`
- `Services/PlaylistGenerator.swift`
- `Views/PlaylistsView.swift`
- `Views/PlaylistDetailView.swift`
- `Views/NewPlaylistView.swift`
- `Views/SmartPlaylistView.swift`

`xcodegen` picks them up automatically (sources are globbed) — no `project.yml`
edit needed. Four small wiring changes follow.

## 1. Register the models — `Models/DataStack.swift`
```diff
- let schema = Schema([AudioTrack.self, RepoSource.self])
+ let schema = Schema([AudioTrack.self, RepoSource.self, Playlist.self, PlaylistItem.self])
```

## 2. Add the tab — `Views/ContentView.swift`
Insert a Playlists tab between Repos and Settings, and renumber:
```diff
  Tab("Repos", systemImage: "folder", value: 1) { ReposView() }
+ Tab("Playlists", systemImage: "music.note.list", value: 2) { PlaylistsView() }
- Tab("Settings", systemImage: "gearshape", value: 2) { SettingsView() }
+ Tab("Settings", systemImage: "gearshape", value: 3) { SettingsView() }
```
Update `logTabScreen` to match:
```diff
  let name = switch tab {
  case 0: "Tracks"
  case 1: "Repos"
+ case 2: "Playlists"
  default: "Settings"
  }
```
And the preview container:
```diff
- .modelContainer(for: [AudioTrack.self, RepoSource.self], inMemory: true)
+ .modelContainer(for: [AudioTrack.self, RepoSource.self, Playlist.self, PlaylistItem.self], inMemory: true)
```

## 3. Analytics — `Services/AnalyticsEvents.swift`
The views call two new helpers. Add them (lowercase snake_case, no user content):
```swift
static func logPlaylistCreated(smart: Bool) {
    log("playlist_created", ["smart": smart])
}

static func logPlaylistPlayed(smart: Bool) {
    log("playlist_played", ["smart": smart])
}
```

## 4. Nothing else
No new SPM packages, entitlements, or Info.plist keys. `PlaylistGenerator` uses
the system `FoundationModels` framework (already used by `SummarizationService`)
and is `#if canImport`-guarded so it still builds where the model is absent.

---

## Design notes / decisions
- **Ordering** is an explicit `PlaylistItem.position`, not SwiftData array order
  (which isn't guaranteed stable / CloudKit-portable). `.onMove` renumbers via
  `Playlist.reorder(to:)`.
- **`PlaylistItem` is a join**, so one track can sit in many playlists and a
  deleted track nullifies its slots (`Playlist.tracks` skips them) instead of
  corrupting the list.
- **Smart playlists** use guided generation: the model fills a `@Generable`
  `GeneratedPlaylist` (title + rationale + ordered track titles), and the app
  re-binds titles to `AudioTrack`s — the model never sees persistent models or
  transcripts. Gated on `SystemLanguageModel.default.availability`, same as
  summarization.
- **Repo playlists** (`kind == .repo`) are supported by the model but not yet
  wired into a UI action — the natural follow-up is an "Add all to a playlist"
  button in `RepoBrowserView` after generation (it already produces the tracks).

## Verify it against the prototype
`ui_kits/repocast/playlists.html` in the design system is the interactive spec
these files implement (list → detail → reorder/remove, New, and Smart curate →
preview → save).
