# Integrating the Repocast Design System

Two things to integrate: the **app icon** (a real change to your Xcode project) and the **design system** (a design/prototyping reference, since Repocast is native SwiftUI — not a web app). There's also an optional **token bridge** to keep your SwiftUI styling in lock-step with the design tokens.

---

## 1. App icon → Xcode (concrete)

The generated icon is the modern single-size universal format Xcode 16 / iOS 26 expect.

**Option A — drag into Xcode (simplest):**
1. Download the `AppIcon.appiconset` card (or grab `export/AppIcon.appiconset/Icon-1024.png`).
2. In Xcode, open `Assets.xcassets` → select `AppIcon`.
3. Drag `Icon-1024.png` onto the single 1024×1024 "All Sizes" well.
4. Build & run — the icon appears on the home screen.

**Option B — replace the folder on disk:**
1. Copy `export/AppIcon.appiconset/Icon-1024.png` + `Contents.json` into
   `Sources/Repocast/Resources/Assets.xcassets/AppIcon.appiconset/`
   (overwrite the existing `Contents.json`).
2. `xcodegen generate` is **not** needed — asset-catalog contents aren't in `project.yml`.
3. Clean build folder (⇧⌘K) if the old empty icon is cached, then build.

> The asset is full-bleed with no transparency and no pre-applied corner radius — iOS applies the rounded-rect mask itself. Correct by design.

---

## 2. Use the design system for design work

The design system is **HTML/React + CSS tokens** — it's your source of truth for *how Repocast should look*, not Swift code you drop in. Use it to:

- **Prototype new screens** (Phase 2–5: repo file-tree picker, playlists, spoken changelog) as click-through HTML before writing SwiftUI — faster to iterate, easy to share.
- **Produce assets**: App Store screenshots, marketing pages, the support/privacy pages referenced in `appstore/`.
- **Stay consistent**: the `readme.md` codifies the content voice, color/type/spacing foundations, and iconography rules.

### As a Claude Skill (recommended)
Download this whole project. It already contains a `SKILL.md` at the root, so it works as an Agent Skill in Claude Code:
1. Download the project (or just this folder).
2. Drop it into your Claude Code skills directory (e.g. `.claude/skills/repocast-design/`).
3. Invoke it — Claude reads `readme.md` + the components and designs in-brand.

---

## 3. Bridge tokens into SwiftUI (optional, keeps native ↔ design in sync)

Your app already matches the core token: `AccentColor` is `#007AFF`, which is `--tint`. To pull the rest of the palette into SwiftUI, mirror the tokens in a small `Theme` file. Example:

```swift
import SwiftUI

extension Color {
    // Mirrors tokens/colors.css — system colors are also available as
    // Color.blue etc., but pin them if you want exact parity.
    static let rcTint        = Color(red: 0.00, green: 0.478, blue: 1.0) // #007AFF
    static let rcReady       = Color.green      // #34C759
    static let rcGenerating  = Color.orange     // #FF9500
    static let rcFailed      = Color.red        // #FF3B30
}

enum RCRadius {           // tokens/spacing.css
    static let card: CGFloat = 10
    static let tile: CGFloat = 14
    static let sheet: CGFloat = 38
}
```

You're mostly there already: the app leans on system colors, SF type, SF Symbols, and `.regularMaterial` — which is exactly what the design system codifies. The token files are the canonical values if you ever need to pin one.

### Token → SwiftUI cheat-sheet
- `--tint` → `Color.accentColor` / `.tint(...)`
- `--type-*` → SwiftUI text styles (`.largeTitle`, `.title2`, `.headline`, `.body`, `.footnote`, `.caption`)
- `--material-regular` + `--blur-regular` → `.background(.regularMaterial)`
- `--radius-card/tile/sheet` → `.clipShape(.rect(cornerRadius:))` (use `.continuous` style)
- Icons (Lucide names in the kit) → real **SF Symbols** via `Image(systemName:)` — see `assets/icons.md` for the reverse map.

---

## What NOT to copy into the app
The React components in `components/` and the `ui_kits/` recreation are **web prototyping aids** — don't port them into Swift. Your SwiftUI views (`ContentView`, `PlayerViews`, etc.) are the real implementation; the kit just lets you design and preview faster.
