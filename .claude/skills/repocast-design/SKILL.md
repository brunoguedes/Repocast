---
name: repocast-design
description: Use this skill to generate well-branded interfaces and assets for Repocast, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.
If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.
If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

## What Repocast is
A native iOS 26 app (Swift 6 / SwiftUI) that turns selected files from a git repo into audio — on-device AI summaries, text-to-speech, AI playlists, and spoken GitHub changes. It uses **no custom design language**: it adopts Apple's iOS 26 system look (San Francisco type, SF Symbols, system colors, translucent materials / "Liquid Glass", the Apple Podcasts mini-player → Now Playing pattern), tinted with the product accent **system blue (`#007AFF`)**.

## Key files
- `readme.md` — the full design guide: CONTENT FUNDAMENTALS, VISUAL FOUNDATIONS, ICONOGRAPHY, and an index.
- `styles.css` — the one stylesheet to link; `@import`s all tokens in `tokens/`.
- `tokens/` — colors, typography, spacing, elevation (materials/shadows/motion) as CSS custom properties.
- `assets/icons.md` — SF Symbol → Lucide substitution map (icons are loaded from the Lucide CDN; real SF Symbols differ).
- `components/` — React UI primitives (Button, IconButton, Badge, Card, Toggle, Slider, SegmentedControl, TextField, ListRow, SectionHeader, NavBar, TabBar, MiniPlayer). Each has a `.d.ts` contract and `.prompt.md` usage note.
- `ui_kits/repocast/` — interactive recreation of the app (Tracks, Now Playing, New Track, Settings).

## Rules of thumb
- Tint = system blue, used only for interactive accents and active state. Everything else is the neutral gray ramp + label colors. No gradients on chrome, no background imagery, no emoji.
- Support light **and** dark — tokens flip under `prefers-color-scheme`.
- Translucent frosted materials for chrome that overlaps content (bars, mini-player, sheets); opaque surfaces for content. Hairline separators, not borders. Soft shadows only for floating surfaces.
- Title Case for titles/buttons/section headers; sentence case for help text. Buttons are short verbs. Address the user as "you".
- Use Lucide for icons (SF Symbol substitute) and flag the substitution; prefer real SF Symbols for native work.
