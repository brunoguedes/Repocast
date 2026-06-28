// New Playlist sheet — title + pick tracks from the library. Mirrors a manual
// playlist create (title field + multi-select).
function NewPlaylistSheet({ onCancel, onCreate }) {
  const { NavBar, Card, SectionHeader, TextField, Button } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;
  const [title, setTitle] = React.useState("");
  const [picked, setPicked] = React.useState(new Set());
  const canCreate = title.trim().length > 0 && picked.size > 0;

  const toggle = (id) => setPicked((s) => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
      <NavBar title="New Playlist"
        leading={<Button variant="plain" onClick={onCancel}>Cancel</Button>}
        trailing={<Button variant="plain" onClick={() => onCreate(title.trim(), [...picked])} disabled={!canCreate} style={{ fontWeight: 600 }}>Create</Button>} />
      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px" }}>
        <SectionHeader>Name</SectionHeader>
        <Card variant="grouped" padded>
          <TextField variant="plain" value={title} onChange={setTitle} placeholder="Playlist name" />
        </Card>

        <div style={{ height: 18 }} />
        <SectionHeader>{picked.size === 0 ? "Add Tracks" : `${picked.size} Selected`}</SectionHeader>
        <Card variant="grouped">
          {window.RC_LIBRARY.map((t, i) => {
            const on = picked.has(t.id);
            return (
              <div key={t.id} className="rc-tap-row" onClick={() => toggle(t.id)}
                style={{ display: "flex", alignItems: "center", gap: 11, padding: "10px 16px", cursor: "pointer", boxShadow: i === window.RC_LIBRARY.length - 1 ? "none" : "inset 0 -0.5px 0 var(--separator)" }}>
                <RCIcon name={on ? "circle-check-big" : "circle"} size={22} color={on ? "var(--tint)" : "var(--label-tertiary)"} />
                <RCIcon name={window.RC_KIND_ICON[t.kind] || "file-text"} size={18} color="var(--text-secondary)" />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "var(--type-callout)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t.title}</div>
                  <div style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t.source}</div>
                </div>
                <span style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)", fontVariantNumeric: "tabular-nums" }}>{t.duration}</span>
              </div>
            );
          })}
        </Card>
      </div>
    </div>
  );
}
window.NewPlaylistSheet = NewPlaylistSheet;
