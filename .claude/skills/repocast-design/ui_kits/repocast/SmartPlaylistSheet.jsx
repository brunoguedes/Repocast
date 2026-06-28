// Smart Playlist sheet — describe a playlist; Apple Intelligence (FoundationModels
// guided generation) returns a title + ordered track picks + a short rationale.
function SmartPlaylistSheet({ onCancel, onSave }) {
  const { NavBar, Card, SectionHeader, TextField, Button } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;
  const [prompt, setPrompt] = React.useState("");
  const [phase, setPhase] = React.useState("compose"); // compose | curating | preview
  const [result, setResult] = React.useState(null);

  const examples = ["A tour of the audio pipeline", "Everything about GitHub auth", "Short docs under 5 minutes"];

  const curate = () => {
    if (!prompt.trim()) return;
    setPhase("curating");
    setTimeout(() => {
      // Fake "guided generation": pick a handful of library tracks + a title.
      const picks = window.RC_LIBRARY.filter((t) => /\.swift|Service|Client|Generator/.test(t.title)).slice(0, 4);
      const tracks = picks.length ? picks : window.RC_LIBRARY.slice(0, 4);
      setResult({
        title: titleFrom(prompt),
        rationale: "Picked the core pipeline files in listening order, leading with the orchestrator and ending with playback.",
        tracks,
      });
      setPhase("preview");
    }, 1500);
  };

  const titleFrom = (p) => {
    const s = p.trim().replace(/^(make|create|a|an|the)\s+/i, "");
    return s.charAt(0).toUpperCase() + s.slice(1, 40);
  };

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)", position: "relative" }}>
      <NavBar title="Smart Playlist"
        leading={<Button variant="plain" onClick={onCancel}>Cancel</Button>}
        trailing={phase === "preview"
          ? <Button variant="plain" onClick={() => onSave(result)} style={{ fontWeight: 600 }}>Save</Button>
          : <Button variant="plain" onClick={curate} disabled={!prompt.trim() || phase === "curating"} style={{ fontWeight: 600 }}>Generate</Button>} />

      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px" }}>
        {phase !== "preview" && (
          <React.Fragment>
            <SectionHeader>Describe Your Playlist</SectionHeader>
            <Card variant="grouped" padded>
              <TextField variant="plain" multiline rows={3} value={prompt} onChange={setPrompt} placeholder="e.g. A 20-minute tour of how audio gets generated" />
            </Card>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 12 }}>
              {examples.map((ex) => (
                <button key={ex} type="button" onClick={() => setPrompt(ex)}
                  style={{ border: "none", cursor: "pointer", padding: "7px 13px", borderRadius: "var(--radius-capsule)", background: "var(--fill-tertiary)", color: "var(--text-primary)", font: "var(--type-footnote)" }}>
                  {ex}
                </button>
              ))}
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 7, marginTop: 16, padding: "0 4px", font: "var(--type-footnote)", color: "var(--text-secondary)" }}>
              <RCIcon name="lock" size={13} color="var(--text-secondary)" />
              Generated on-device with Apple Intelligence. Your library never leaves your phone.
            </div>
          </React.Fragment>
        )}

        {phase === "preview" && result && (
          <React.Fragment>
            <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "4px 0 16px" }}>
              <span style={{ width: 56, height: 56, borderRadius: "var(--radius-md)", background: window.RC_TINT_GRAD.purple, display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "none", boxShadow: "var(--shadow-sm)" }}>
                <RCIcon name="sparkles" size={28} color="#fff" />
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ font: "var(--type-title-3)", color: "var(--text-primary)" }}>{result.title}</div>
                <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)" }}>{result.tracks.length} tracks · Smart playlist</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 8, alignItems: "flex-start", padding: "11px 14px", marginBottom: 16, borderRadius: "var(--radius-md)", background: "color-mix(in srgb, var(--purple) 12%, transparent)" }}>
              <RCIcon name="sparkles" size={16} color="var(--purple)" style={{ marginTop: 2 }} />
              <span style={{ font: "var(--type-footnote)", color: "var(--text-primary)" }}>{result.rationale}</span>
            </div>
            <Card variant="grouped">
              {result.tracks.map((t, i) => (
                <div key={t.id} style={{ display: "flex", alignItems: "center", gap: 11, padding: "10px 16px", boxShadow: i === result.tracks.length - 1 ? "none" : "inset 0 -0.5px 0 var(--separator)" }}>
                  <span style={{ font: "var(--type-footnote)", color: "var(--text-tertiary)", width: 16, flex: "none", textAlign: "center", fontVariantNumeric: "tabular-nums" }}>{i + 1}</span>
                  <RCIcon name={window.RC_KIND_ICON[t.kind] || "file-text"} size={18} color="var(--text-secondary)" />
                  <span style={{ flex: 1, minWidth: 0, font: "var(--type-callout)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t.title}</span>
                  <span style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)", fontVariantNumeric: "tabular-nums" }}>{t.duration}</span>
                </div>
              ))}
            </Card>
            <div style={{ marginTop: 14, display: "flex", justifyContent: "center" }}>
              <Button variant="tinted" icon="refresh-cw" onClick={() => setPhase("compose")}>Start Over</Button>
            </div>
          </React.Fragment>
        )}
      </div>

      {phase === "curating" && (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "color-mix(in srgb, var(--bg) 40%, transparent)" }}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14, padding: 28, borderRadius: "var(--radius-lg)", background: "var(--material-thick)", backdropFilter: "var(--blur-thick)", boxShadow: "var(--shadow-lg)" }}>
            <span className="rc-pulse" style={{ display: "inline-flex" }}><RCIcon name="sparkles" size={40} color="var(--purple)" /></span>
            <span style={{ font: "var(--type-subheadline)", color: "var(--text-primary)" }}>Curating your playlist…</span>
          </div>
        </div>
      )}
    </div>
  );
}
window.SmartPlaylistSheet = SmartPlaylistSheet;
