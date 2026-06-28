// Sample track data for the Repocast UI kit (fake, cosmetic).
window.RC_TRACKS = [
  { id: "t1", title: "README.md", source: "repocast/README.md", kind: "markdown", status: "ready", duration: "3:42", durSec: 222 },
  { id: "t2", title: "AudioPlayerService.swift", source: "Sources/…/AudioPlayerService.swift", kind: "code", status: "ready", duration: "12:48", durSec: 768 },
  { id: "t3", title: "DataStack.swift", source: "Sources/…/Models/DataStack.swift", kind: "code", status: "generating", duration: "", durSec: 0 },
  { id: "t4", title: "Latest changes · main", source: "5 merged PRs, 12 commits", kind: "changes", status: "ready", duration: "6:10", durSec: 370 },
  { id: "t5", title: "Old draft", source: "Freeform text", kind: "freeform", status: "failed", duration: "", durSec: 0 },
];

window.RC_STATUS_BADGE = { ready: null, generating: { tint: "orange", icon: "hourglass", label: "Generating" }, failed: { tint: "red", icon: "triangle-alert", label: "Failed" }, pending: { tint: "gray", icon: "hourglass", label: "Pending" } };
window.RC_KIND_ICON = { code: "file-code", markdown: "file-text", changes: "git-merge", freeform: "type" };
