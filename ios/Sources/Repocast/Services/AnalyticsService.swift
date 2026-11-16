import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseCore
import FirebaseAnalytics
#endif

/// Single funnel for all product analytics. Every analytics call in the app
/// goes through this type so the Firebase dependency stays isolated behind one
/// small, intention-revealing surface — the rest of the codebase never imports
/// Firebase directly, and this is the one file to edit to add or rename events.
///
/// Reports to Firebase only once a real `GoogleService-Info.plist` is bundled
/// inside the target's `Sources/Repocast/Resources` folder. Until then every
/// call is a silent no-op, so a fresh checkout builds and runs with no Firebase
/// credentials.
///
/// Session length needs no calls here: Firebase logs `session_start` and
/// per-event `engagement_time_msec` automatically once configured.
///
/// **Never pass user content into an event** — only counts, enum raw values,
/// and toggle states. Custom event names must be lowercase snake_case,
/// ≤ 40 chars, with no `firebase_` / `google_` / `ga_` prefix.
enum AnalyticsService {

    /// Configure Firebase. Call once, as early as possible at launch.
    static func start() {
        #if canImport(FirebaseAnalytics)
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            print("[Analytics] GoogleService-Info.plist not found — analytics disabled.")
            return
        }
        FirebaseApp.configure()
        #endif
    }

    /// Whether Firebase is live this run. Useful for debug surfaces.
    static var isEnabled: Bool {
        #if canImport(FirebaseAnalytics)
        return FirebaseApp.app() != nil
        #else
        return false
        #endif
    }

    /// Log a raw event. Prefer a typed helper for anything used more than once.
    static func log(_ event: String, _ parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(event, parameters: parameters)
        #endif
    }

    /// Record a screen view — mirrors Firebase's built-in `screen_view` event
    /// so it shows up in the standard Screens report.
    static func logScreen(_ name: String) {
        #if canImport(FirebaseAnalytics)
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name
        ])
        #endif
    }
}
