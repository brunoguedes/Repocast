import SwiftData

/// The app's single SwiftData stack. Keeping the `ModelContainer` in one place
/// means `@main`, SwiftUI previews, and any future App Intent / extension all
/// share the same configured store instead of spinning up divergent ones.
///
/// This is a local on-device store. To sync across the user's devices, add a
/// private CloudKit database to the `ModelConfiguration`
/// (`cloudKitDatabase: .private("iCloud.au.com.bclgapps.Repocast")`), add the matching
/// iCloud entitlements + container in the developer portal, and make every
/// `@Model` CloudKit-safe (defaults on non-optionals, optional/to-many
/// relationships, no `@Attribute(.unique)`).
enum DataStack {
    static let container: ModelContainer = {
        let schema = Schema([AudioTrack.self, RepoSource.self, Playlist.self, PlaylistItem.self, NarrationPackage.self, VoiceNote.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
