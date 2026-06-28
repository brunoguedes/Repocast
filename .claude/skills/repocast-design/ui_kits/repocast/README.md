# Repocast UI Kit

Interactive, high-fidelity recreation of the **Repocast** iOS app (Phase 1) — built entirely from this design system's components and tokens.

Open `index.html`. It runs as a 390×844 iPhone screen:

- **Tracks** — large-title screen with a grouped list of generated tracks, each showing its source-kind icon, path, and status (Ready / Generating / Failed). Tap a *Ready* track to play it.
- **Now Playing** — full-screen sheet: big tinted waveform, scrubber, transport controls, and the segmented playback-speed picker. Auto-advances the scrubber while playing.
- **New Track** — sheet with a title field and a tall text editor; **Generate** shows the progress overlay then adds a track and returns to the list.
- **Settings** — grouped Form: voice picker, speech-rate slider (tortoise/hare), an Apple-Intelligence toggle, and About rows.
- Persistent **mini-player** + **tab bar** ride the bottom safe area on every tab (Apple Podcasts pattern).

## Files
- `index.html` — phone shell, status bar, sheet animations, mount.
- `App.jsx` — app state machine (tab, tracks, playback, sheets).
- `TracksScreen.jsx`, `NowPlayingSheet.jsx`, `NewTrackSheet.jsx`, `SettingsScreen.jsx` — the surfaces.
- `data.js` — sample track data (cosmetic).

## Fidelity notes
This recreates only what ships today (Phase 1). The GitHub repo file-tree picker, AI summaries, and playlists (Phases 2–5) are **intentionally omitted** — they don't exist in the codebase yet. Icons are **Lucide** substitutes for SF Symbols (see `../../assets/icons.md`).
