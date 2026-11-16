import SwiftUI

/// SwiftUI bridge for the **Repocast Design System** tokens (the claude.ai/design
/// project "Repocast Design System" — see `.design-sync/`). Values mirror
/// `tokens/colors.css` and `tokens/spacing.css` from the design bundle so native
/// styling stays in lock-step with the design source of truth.
///
/// The system colors below map to SwiftUI's own system palette, which already
/// matches Apple's tokens **and adapts to light/dark automatically** — e.g.
/// `Color.blue` is systemBlue (`#007AFF` light / `#0A84FF` dark), exactly the
/// `--tint` token. Pin a literal only when you need a value SwiftUI doesn't
/// vend. See the bundle's `INTEGRATION.md` for the full cheat-sheet.
extension Color {
    /// `--tint` — the product accent. systemBlue, adaptive. Matches `AccentColor`.
    static let rcTint = Color.blue
    /// Status colors used by `AudioTrack.Status` (`--green` / `--orange` / `--red`).
    static let rcReady = Color.green
    static let rcGenerating = Color.orange
    static let rcFailed = Color.red
    /// `--icon-muted` (`--gray`) and `--separator` hairline — adaptive system values.
    static let rcIconMuted = Color(.systemGray)
    static let rcSeparator = Color(.separator)
}

/// `--radius-*` from `tokens/spacing.css`. Use with `.clipShape(.rect(cornerRadius:style: .continuous))`
/// to match Apple's squircle curvature.
enum RCRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let card: CGFloat = 10    // --radius-md — grouped list cards
    static let tile: CGFloat = 14    // --radius-lg — buttons, tiles
    static let prominent: CGFloat = 20  // --radius-xl — prominent cards
    static let sheet: CGFloat = 38   // --radius-sheet — modal sheet corners
    static let capsule: CGFloat = 999  // --radius-capsule — pills, segmented
}

/// `--space-*` from `tokens/spacing.css` — iOS 8pt grid with 4pt half-steps.
enum RCSpacing {
    static let xxs: CGFloat = 2   // --space-1
    static let xs: CGFloat = 4    // --space-2
    static let sm: CGFloat = 8    // --space-3
    static let md: CGFloat = 12   // --space-4
    static let screenInset: CGFloat = 16  // --space-5 / --inset-screen
    static let groupedInset: CGFloat = 20  // --space-6 / --inset-grouped
    static let lg: CGFloat = 24   // --space-7
    static let xl: CGFloat = 32   // --space-8
    static let hitTarget: CGFloat = 44  // --space-9 / --hit-target
}
