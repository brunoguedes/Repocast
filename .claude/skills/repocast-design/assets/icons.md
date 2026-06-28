# Iconography — SF Symbols → Lucide map

Repocast renders **SF Symbols** natively (`Image(systemName:)`). SF Symbols are an Apple system font and **cannot be embedded or CDN-hosted**, so this design system substitutes **[Lucide](https://lucide.dev)** for web recreations.

⚠️ **Substitution.** Lucide is the closest free analog (rounded, consistent stroke), but it is *not* SF Symbols — notably the iconic multi-bar `waveform`. Use the real symbols for native/production work.

## Loading Lucide (CDN)

```html
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.min.js"></script>
<i data-lucide="audio-lines"></i>
<script>lucide.createIcons();</script>
```

In React/JSX recreations, just render an `<i data-lucide="…">` and call `lucide.createIcons()` after mount. Icons inherit `currentColor` and are sized by `width`/`height` (default 24). Tint with `color: var(--tint)` or `var(--text-secondary)`.

## Symbol map (used in the Repocast codebase)

| SF Symbol | Lucide name | Used for |
| --- | --- | --- |
| `waveform` | `audio-lines` | track icon, mini-player |
| `waveform.circle.fill` | `audio-lines` (in tinted circle) | Now Playing artwork |
| `gearshape` | `settings` | Settings tab |
| `plus` | `plus` | New Track |
| `play.fill` | `play` (filled) | play |
| `pause.fill` | `pause` (filled) | pause |
| `play.circle` / `play.circle.fill` | `circle-play` | row play / big play |
| `pause.circle.fill` | `circle-pause` | big pause |
| `forward.fill` | `skip-forward` (filled) | next track |
| `backward.fill` | `skip-back` (filled) | previous track |
| `hourglass` | `hourglass` | generating / pending |
| `exclamationmark.triangle` | `triangle-alert` | failed / warning |
| `tortoise` | `turtle` | slow speech rate |
| `hare` | `rabbit` | fast speech rate |

Color: monochrome, `currentColor`. Primary/active = `var(--tint)`; muted = `var(--text-secondary)`.
