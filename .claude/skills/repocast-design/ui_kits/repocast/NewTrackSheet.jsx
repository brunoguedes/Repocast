// New Track sheet — paste text, generate a track. Mirrors NewTrackView.swift:
// a grouped Form with a title field, a tall text editor, and a help note.
function NewTrackSheet({ onCancel, onGenerate }) {
  const { NavBar, Card, SectionHeader, TextField, Button } = window.RepocastDesignSystem_a3bb12;
  const [title, setTitle] = React.useState("");
  const [text, setText] = React.useState("");
  const [generating, setGenerating] = React.useState(false);
  const canGen = text.trim().length > 0 && !generating;

  React.useEffect(() => { window.lucide && window.lucide.createIcons(); });

  const generate = () => {
    if (!canGen) return;
    setGenerating(true);
    setTimeout(() => onGenerate({ title: title.trim() || "Untitled", text }), 900);
  };

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)", position: "relative" }}>
      <NavBar
        title="New Track"
        leading={<Button variant="plain" onClick={onCancel}>Cancel</Button>}
        trailing={<Button variant="plain" onClick={generate} disabled={!canGen} style={{ fontWeight: 600 }}>Generate</Button>}
      />
      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px", display: "flex", flexDirection: "column", gap: 18 }}>
        <div>
          <SectionHeader>Title</SectionHeader>
          <Card variant="grouped" padded><TextField variant="plain" value={title} onChange={setTitle} placeholder="Optional" /></Card>
        </div>
        <div>
          <SectionHeader>Text to Speak</SectionHeader>
          <Card variant="grouped" padded><TextField variant="plain" multiline rows={7} value={text} onChange={setText} placeholder="Paste code or Markdown…" /></Card>
        </div>
        <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)", padding: "0 4px" }}>
          On-device summarization arrives in the next phase — for now this reads your text aloud verbatim.
        </div>
      </div>
      {generating && (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "color-mix(in srgb, var(--bg) 30%, transparent)", backdropFilter: "blur(2px)" }}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, padding: 24, borderRadius: "var(--radius-lg)", background: "var(--material-thick)", backdropFilter: "var(--blur-thick)", boxShadow: "var(--shadow-lg)" }}>
            <div className="rc-spinner" />
            <span style={{ font: "var(--type-subheadline)", color: "var(--text-primary)" }}>Generating…</span>
          </div>
        </div>
      )}
    </div>
  );
}
window.NewTrackSheet = NewTrackSheet;
