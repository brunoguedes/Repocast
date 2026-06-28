// Phase 4 — Playlists. Library of generated tracks + seeded playlists.
// Mirrors the planned Playlist / PlaylistItem models: a playlist has a title,
// an optional source (a repo it was built from), a "smart" flag (AI-generated),
// a tint, and an ordered list of tracks.

window.RC_LIBRARY = [
  { id: "t1", title: "README.md", source: "bclgapps/Repocast", kind: "markdown", duration: "3:42", durSec: 222 },
  { id: "t2", title: "AudioPlayerService.swift", source: "bclgapps/Repocast", kind: "code", duration: "12:48", durSec: 768 },
  { id: "t3", title: "TrackGenerator.swift", source: "bclgapps/Repocast", kind: "code", duration: "6:20", durSec: 380 },
  { id: "t4", title: "SpeechSynthesisService.swift", source: "bclgapps/Repocast", kind: "code", duration: "8:05", durSec: 485 },
  { id: "t5", title: "GitHubClient.swift", source: "bclgapps/Repocast", kind: "code", duration: "5:30", durSec: 330 },
  { id: "t6", title: "CLAUDE.md", source: "bclgapps/Repocast", kind: "markdown", duration: "9:14", durSec: 554 },
  { id: "t7", title: "ContentView.swift", source: "bclgapps/Repocast", kind: "code", duration: "7:02", durSec: 422 },
  { id: "t8", title: "XcodeGen README", source: "yonaskolb/XcodeGen", kind: "markdown", duration: "4:18", durSec: 258 },
  { id: "t9", title: "project.yml", source: "bclgapps/Repocast", kind: "config", duration: "2:55", durSec: 175 },
  { id: "t10", title: "Reducer.swift", source: "pointfreeco/swift-composable-architecture", kind: "code", duration: "11:10", durSec: 670 },
];

const byId = (id) => window.RC_LIBRARY.find((t) => t.id === id);

window.RC_PLAYLISTS = [
  { id: "p1", title: "Repocast", subtitle: "From bclgapps/Repocast", smart: false, repo: "bclgapps/Repocast", tint: "blue", icon: "folder-git-2", trackIds: ["t1", "t7", "t2", "t3", "t4", "t5"] },
  { id: "p2", title: "The Audio Pipeline", subtitle: "Smart playlist", smart: true, tint: "purple", icon: "sparkles", trackIds: ["t3", "t4", "t2"] },
  { id: "p3", title: "Morning Review", subtitle: "Smart playlist", smart: true, tint: "orange", icon: "sparkles", trackIds: ["t6", "t1", "t8"] },
];

window.RC_TINT_GRAD = {
  blue: "linear-gradient(160deg, #3A9BFF, #0061E0)",
  purple: "linear-gradient(160deg, #C06BFF, #7A2BD8)",
  orange: "linear-gradient(160deg, #FFB13A, #F0760A)",
  green: "linear-gradient(160deg, #4ADE7B, #18A552)",
  pink: "linear-gradient(160deg, #FF6F9C, #E6306A)",
  teal: "linear-gradient(160deg, #4ED6E6, #0E9BB5)",
};

// Resolve a playlist's tracks + total seconds.
window.RC_RESOLVE = (pl) => {
  const tracks = pl.trackIds.map(byId).filter(Boolean);
  const sec = tracks.reduce((a, t) => a + t.durSec, 0);
  return { tracks, sec, min: Math.max(1, Math.round(sec / 60)) };
};

window.RC_KIND_ICON = { code: "code-xml", markdown: "file-text", config: "file-cog", changes: "git-merge" };
