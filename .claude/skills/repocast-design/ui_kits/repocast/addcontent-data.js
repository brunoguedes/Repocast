// Repos flow — data mirrors the real GitHub layer (GitHubModels.swift,
// RepoSource.swift, ReposView.swift). Repos to add, and a directory tree
// browsed one level at a time (GitHub Contents API), keyed by path.

// GitHubRepo list shown in AddRepoView (the connected account's repositories).
window.RC_GH_REPOS = [
  { id: "g1", fullName: "bclgapps/Repocast", owner: "bclgapps", name: "Repocast", priv: true, description: "Turn repo files into audio you can play anywhere." },
  { id: "g2", fullName: "bclgapps/repocast-landing", owner: "bclgapps", name: "repocast-landing", priv: true, description: "Marketing site." },
  { id: "g3", fullName: "yonaskolb/XcodeGen", owner: "yonaskolb", name: "XcodeGen", priv: false, description: "Generate your Xcode project from a spec file." },
  { id: "g4", fullName: "pointfreeco/swift-composable-architecture", owner: "pointfreeco", name: "swift-composable-architecture", priv: false, description: "A library for building applications in a consistent, understandable way." },
];

// detect(): markdown if extension is doc-ish, else code — matches
// AudioTrack.SourceKind.detect(path:) in GitHubModels.swift.
window.RC_IS_MD = (name) => /\.(md|markdown|mdx|txt|rst)$/i.test(name);

// Directory tree keyed by path. "" is the repo root. Each entry: name, path,
// type ("dir" | "file"), size (files only).
window.RC_TREE = {
  "": [
    { name: "Sources", path: "Sources", type: "dir" },
    { name: "Tests", path: "Tests", type: "dir" },
    { name: "fastlane", path: "fastlane", type: "dir" },
    { name: "README.md", path: "README.md", type: "file", size: "1.2 KB" },
    { name: "CLAUDE.md", path: "CLAUDE.md", type: "file", size: "8.9 KB" },
    { name: "RELEASING.md", path: "RELEASING.md", type: "file", size: "2.1 KB" },
    { name: "project.yml", path: "project.yml", type: "file", size: "3.0 KB" },
  ],
  "Sources": [{ name: "Repocast", path: "Sources/Repocast", type: "dir" }],
  "Sources/Repocast": [
    { name: "App", path: "Sources/Repocast/App", type: "dir" },
    { name: "Models", path: "Sources/Repocast/Models", type: "dir" },
    { name: "Services", path: "Sources/Repocast/Services", type: "dir" },
    { name: "Views", path: "Sources/Repocast/Views", type: "dir" },
    { name: "Resources", path: "Sources/Repocast/Resources", type: "dir" },
    { name: "RepocastApp.swift", path: "Sources/Repocast/RepocastApp.swift", type: "file", size: "1.4 KB" },
    { name: "Info.plist", path: "Sources/Repocast/Info.plist", type: "file", size: "0.6 KB" },
  ],
  "Sources/Repocast/Models": [
    { name: "AudioTrack.swift", path: "Sources/Repocast/Models/AudioTrack.swift", type: "file", size: "2.9 KB" },
    { name: "DataStack.swift", path: "Sources/Repocast/Models/DataStack.swift", type: "file", size: "1.8 KB" },
    { name: "RepoSource.swift", path: "Sources/Repocast/Models/RepoSource.swift", type: "file", size: "1.1 KB" },
  ],
  "Sources/Repocast/Views": [
    { name: "ContentView.swift", path: "Sources/Repocast/Views/ContentView.swift", type: "file", size: "5.0 KB" },
    { name: "ReposView.swift", path: "Sources/Repocast/Views/ReposView.swift", type: "file", size: "14 KB" },
    { name: "NewTrackView.swift", path: "Sources/Repocast/Views/NewTrackView.swift", type: "file", size: "3.0 KB" },
    { name: "SettingsView.swift", path: "Sources/Repocast/Views/SettingsView.swift", type: "file", size: "2.2 KB" },
    { name: "PlayerViews.swift", path: "Sources/Repocast/Views/PlayerViews.swift", type: "file", size: "4.9 KB" },
  ],
  "Sources/Repocast/Services": [
    { name: "GitHubClient.swift", path: "Sources/Repocast/Services/GitHubClient.swift", type: "file", size: "3.4 KB" },
    { name: "GitHubAccount.swift", path: "Sources/Repocast/Services/GitHubAccount.swift", type: "file", size: "1.6 KB" },
    { name: "TrackGenerator.swift", path: "Sources/Repocast/Services/TrackGenerator.swift", type: "file", size: "3.8 KB" },
    { name: "SummarizationService.swift", path: "Sources/Repocast/Services/SummarizationService.swift", type: "file", size: "4.2 KB" },
    { name: "AudioPlayerService.swift", path: "Sources/Repocast/Services/AudioPlayerService.swift", type: "file", size: "5.1 KB" },
  ],
  "Sources/Repocast/App": [],
  "Sources/Repocast/Resources": [{ name: "Assets.xcassets", path: "Sources/Repocast/Resources/Assets.xcassets", type: "dir" }],
  "Sources/Repocast/Resources/Assets.xcassets": [],
  "Tests": [{ name: "RepocastTests", path: "Tests/RepocastTests", type: "dir" }],
  "Tests/RepocastTests": [{ name: "AudioTrackTests.swift", path: "Tests/RepocastTests/AudioTrackTests.swift", type: "file", size: "2.0 KB" }],
  "fastlane": [{ name: "Fastfile", path: "fastlane/Fastfile", type: "file", size: "1.0 KB" }],
};
