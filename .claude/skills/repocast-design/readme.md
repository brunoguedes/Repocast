# Repocast Design System

A faithful, native **iOS 26** design system, themed for **Repocast**. Repocast turns selected files from a git repository (source code and Markdown) into audio you can play in the car or while exercising — using on-device Apple Intelligence to summarize code, convert docs to speech, generate AI playlists, and voice the latest GitHub changes like new merges and open PRs.

Repocast is a **native iOS app** (iPhone + iPad, iOS 26+, Swift 6, SwiftUI + SwiftData). It ships **no custom design language** — by design, it adopts Apple's system look wholesale: San Francisco type, SF Symbols, system colors, translucent materials ("Liquid Glass"), and the Apple Podcasts / Music **mini-player → Now Playing** transport pattern. This design system therefore codifies *Apple's iOS 26 platform conventions*, tinted with Repocast's product accent (**system blue**), so that prototypes, marketing, and App Store assets feel indistinguishable from the real app.

## Sources

This system was reverse-engineered from the Repocast iOS codebase (read-only, mounted locally):

- **Codebase:** `Repocast/` — Swift 6 / SwiftUI app. Bundle ID `au.com.bclgapps.Repocast`, © 2026 BCLGApps.
- Key files read:
  - `Sources/Repocast/Views/ContentView.swift` — `TabView` (Tracks / Settings) + persistent mini-player via `.safeAreaInset(edge: .bottom)`.
  - `Sources/Repocast/Views/PlayerViews.swift` — `MiniPlayerBar` (`.regularMaterial`) and `NowPlayingView` (scrubber, transport, segmented speed picker).
  - `Sources/Repocast/Views/NewTrackView.swift` — sheet `Form` (title field, multi-line text editor, generate).
  - `Sources/Repocast/Views/SettingsView.swift` — grouped `Form` with voice picker, speech-rate slider.
  - `Sources/Repocast/Resources/Assets.xcassets/AccentColor.colorset` — accent = `sRGB(0, 0.478, 1.0)` = **`#007AFF`** (system blue).
  - `Sources/Repocast/Models/AudioTrack.swift` — domain model (track status: pending / generating / ready / failed; source kind: code / markdown / changes / freeform).
  - `appstore/APPSTORE.md`, `appstore/repocast-support.md` — product copy & tone.
  - `CLAUDE.md`, `README.md` — architecture, the "audio pipeline" spine, roadmap.

There is **no design asset folder, logo file, or Figma** in the repo — the app icon is generated at build time (a 1024×1024 placeholder slot only). See CAVEATS at the bottom.

---

## CONTENT FUNDAMENTALS

How Repocast writes copy, derived from its UI strings and App Store / support docs.

- **Voice & tone:** plain, confident, developer-direct. No marketing fluff, no exclamation marks. The one-line product pitch is a single dense sentence: *"Repocast turns selected files from a git repository … into audio you can play in the car or while exercising."* Concrete benefits over abstractions ("play in the car or while exercising", not "stay productive").
- **Person:** addresses the user as **you** ("turn your text into audio", "Tap + to turn text into audio you can play anywhere"). Never first-person "I" or "we" in UI; "we" appears only in privacy prose ("never sent anywhere but GitHub").
- **Casing:** **Title Case for navigation titles, buttons, and section headers** (iOS convention): "New Track", "Now Playing", "Speech Rate", "On-Device AI", "Generate", "Cancel". Sentence case for body/help text and placeholders ("Optional", "On-device summarization arrives in the next phase — for now this reads your text aloud verbatim.").
- **Buttons are verbs:** "Generate", "Cancel", "New". Short and imperative.
- **Empty states are instructive:** title + one helpful sentence pointing at the next action ("No Tracks Yet" / "Tap + to turn text into audio you can play anywhere.").
- **Domain vocabulary:** *track*, *playlist*, *repo / repository*, *transcript*, *voice*, *speech rate*, *summary* vs *verbatim*, *latest changes*, *PRs / merges*. Honest about phasing — "arrives in the next phase", "Wired next phase".
- **No emoji** anywhere in product UI. Meaning is carried by SF Symbols, not emoji.
- **Numbers & time:** durations are `m:ss`, monospaced digits ("0:00", "12:48"). Speed multipliers use the multiplication sign: "1×", "1.5×", "2×".
- **Technical honesty in privacy copy:** specific and reassuring — names exactly what leaves the device (Firebase Analytics, anonymous) and what never does (repo contents, tokens → Keychain).

---

## VISUAL FOUNDATIONS

Repocast inherits Apple's iOS 26 visual language. Specifics:

- **Color:** Apple's system palette. The product **tint is system blue** (`#007AFF` light, `#0A84FF` dark) — used for interactive accents, the active tab, the `.tint`-colored SF Symbols (waveform, play). Everything else is the neutral system gray ramp + label colors. Semantic colors: green (success/ready), red (`#FF3B30`, destructive/failed), orange (warning). Color is **functional, never decorative** — large surfaces are white / system-gray-6, not branded fills. No gradients on UI chrome.
- **Light & dark:** first-class. Light = white/`#F2F2F7` backgrounds, near-black labels. Dark = true-black (`#000`) and `#1C1C1E` elevated, white labels. Tokens flip under `prefers-color-scheme`.
- **Type:** San Francisco (SF Pro Text / SF Pro Display, optical-size-switched by the system; SF Mono for code). The iOS Dynamic Type ramp — Large Title 34, Title 28/22/20, Headline 17 semibold, Body 17, Footnote 13, Caption 12/11. Tracking is slightly tight at display sizes. Weights: regular/medium/semibold/bold.
- **Backgrounds:** flat system colors. **No background images, no full-bleed photography, no patterns, no gradients, no textures, no grain.** Grouped screens (Settings, New Track) use `#F2F2F7` (light) behind white inset cards. Depth comes from translucency, not imagery.
- **Materials / translucency / blur:** the signature move. Nav bars, tab bars, and the mini-player are **frosted `.regularMaterial`** — `backdrop-filter: saturate(180%) blur(30px)` over a ~82%-opaque base. iOS 26 "Liquid Glass" = thin, luminous, blurred layers that let content scroll behind. Use blur for any floating chrome that overlaps scrollable content.
- **Corner radii:** Apple "continuous" (squircle) curvature. Grouped list cards ~10px, buttons/tiles ~14px, prominent cards ~20px, modal sheet top corners ~38px, and **capsules** (999px) for pills and the segmented control.
- **Cards:** an inset grouped card is a white (`--surface-card`) rounded rect (radius 10) on a gray grouped background, separated by **hairline separators** (`rgba(60,60,67,0.29)`, ~0.5px) between rows — *not* by shadows or borders. Elevated/floating cards get a very soft shadow (`--shadow-md`), never a hard border.
- **Shadows:** soft, sparse, low-opacity. Used only for genuinely floating surfaces (sheets, popovers, elevated tiles). Most UI has **no shadow** — separation is by material/translucency and color.
- **Borders:** hairlines only — 0.5px separators between list rows and under bars. No 1px+ colored borders, no left-accent-border cards.
- **Hover / press states:** iOS has no hover (touch-first). **Press = brief opacity dip** (~0.4–0.6) on plain/tinted buttons, or a fill darken on filled buttons; list rows show a system-gray highlight while pressed. Some controls add a subtle scale-down (~0.96). On web recreations, treat hover like a gentle highlight and keep the press feedback.
- **Animation:** **spring-led**, never linear. Sheet presentation slides up with the standard ease `cubic-bezier(0.32,0.72,0,1)`; interactive/snappy elements use an overshoot spring. Symbol effects (e.g. `.variableColor.iterative` on the playing waveform) animate state. Durations ~0.2–0.5s. Respect `prefers-reduced-motion`.
- **Transparency & blur — when:** translucency is for **chrome that overlaps content** (bars, mini-player, sheets backdrop). Content surfaces themselves stay opaque for legibility.
- **Imagery vibe:** essentially none — Repocast is icon-and-type driven. Where artwork appears it's a large tinted SF Symbol (e.g. `waveform.circle.fill` at 120pt on Now Playing), not a photo.
- **Layout rules:** 8pt grid, 4pt half-steps. 16pt screen-edge inset (20pt for grouped content). Fixed chrome: status bar (top), nav bar (top, large or inline title), mini-player + tab bar pinned to the bottom safe area. Minimum 44pt hit targets.

---

## ICONOGRAPHY

- **The app is built entirely on SF Symbols** — Apple's system icon font. Symbols seen in the codebase: `waveform`, `waveform.circle.fill`, `gearshape`, `plus`, `play.circle`, `play.fill` / `pause.fill`, `play.circle.fill` / `pause.circle.fill`, `forward.fill` / `backward.fill`, `hourglass`, `exclamationmark.triangle`, `tortoise`, `hare`. They are rendered in `.tint` (system blue) for primary/active and `.secondary` (label-secondary) for muted, sized off the text styles (`.title`, `.title2`, `.title3`, `.caption`).
- **SF Symbols cannot be legally embedded or CDN-hosted.** This system therefore substitutes **[Lucide](https://lucide.dev)** (loaded from CDN) — a clean, consistent, rounded-stroke open-source set that is the closest free analog to SF Symbols' weight and feel. **⚠️ This is a substitution; real SF Symbols differ in detail (especially the iconic multi-bar `waveform`).** Production/native work should use the real SF Symbols via SwiftUI's `Image(systemName:)`. See `assets/icons.md` for the symbol → Lucide mapping.
- **No emoji** and **no Unicode-glyph icons** in product UI. The one Unicode mark used deliberately is the multiplication sign **×** for playback speeds ("1×").
- Icons are monochrome and inherit `currentColor` — tint them via the `--tint` / `--text-secondary` tokens, never hard-coded colors.

---

## INDEX — what's in this system

Root:
- `styles.css` — global entry point (consumers link this). `@import`s the four token files.
- `tokens/` — `colors.css`, `typography.css`, `spacing.css`, `elevation.css` (materials, shadows, motion).
- `readme.md` — this file.
- `SKILL.md` — Agent-Skill manifest for use in Claude Code.
- `assets/` — `icons.md` (SF Symbol → Lucide map). (No brand logo shipped — see CAVEATS.)

Foundation specimen cards (Design System tab): grouped under **Type**, **Colors**, **Spacing**, **Materials & Motion**.

Components (`components/`, namespace `window.RepocastDesignSystem_a3bb12`):
- `core/` — `Button`, `IconButton`, `Badge`, `Card`
- `forms/` — `Toggle`, `Slider`, `SegmentedControl`, `TextField`
- `lists/` — `ListRow`, `SectionHeader`
- `navigation/` — `NavBar`, `TabBar`
- `media/` — `MiniPlayer`

UI kit (`ui_kits/repocast/`): interactive recreation of the app — Tracks list, Now Playing, New Track sheet, Settings, empty state.

---

## CAVEATS

- **No SF Symbols (substituted with Lucide).** The biggest fidelity gap — the iconic `waveform` glyph in particular looks different. Use real SF Symbols for native work.
- **San Francisco font is system-only.** It renders correctly on Apple devices via the `-apple-system` stack; on other platforms it falls back to the platform UI font. No webfont is (or can be) shipped.
- **No brand logo / app icon artwork** exists in the codebase (the icon set has an empty 1024px slot). None was invented — I do not draw logos.
- The app is **early (Phase 1)**: only the audio spine + Tracks/Settings exist. The UI kit recreates what's shipped, with later-phase surfaces (GitHub repo picker, playlists) intentionally omitted.
