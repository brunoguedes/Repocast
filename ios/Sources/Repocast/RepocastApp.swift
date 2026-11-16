import SwiftUI
import SwiftData

@main
struct RepocastApp: App {

    /// The app's single SwiftData container — see `DataStack`.
    let container: ModelContainer = DataStack.container

    init() {
        // Configure Firebase as early as possible so the first screen view is
        // captured. No-ops gracefully until a real GoogleService-Info.plist is
        // bundled — see AnalyticsService.
        AnalyticsService.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
