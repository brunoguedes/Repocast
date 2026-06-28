// Repo browser — one directory level, mirrors RepoBrowserView. Folders push a
// deeper level; files are multi-selectable; a non-empty selection shows
// "Generate (N)" which renders tracks (code → AI summary, Markdown → verbatim).
function RepoBrowser({ repo, path, depth, onPush, onBack, onGenerated }) {
  const { NavBar, Card, Button } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;
  const [selected, setSelected] = React.useState(new Set());
  const [gen, setGen] = React.useState(null); // { progress, total }

  const raw = window.RC_TREE[path] || [];
  const entries = raw.slice().sort((a, b) => {
    if ((a.type === "dir") !== (b.type === "dir")) return a.type === "dir" ? -1 : 1;
    return a.name.localeCompare(b.name);
  });

  const title = path === "" ? repo.name : path.split("/").pop();
  const toggle = (p) => setSelected((s) => { const n = new Set(s); n.has(p) ? n.delete(p) : n.add(p); return n; });

  const generate = () => {
    const total = selected.size;
    setGen({ progress: 0, total });
    let done = 0;
    const tick = () => {
      done += 1;
      setGen({ progress: done, total });
      if (done < total) setTimeout(tick, 650);
      else setTimeout(() => { setGen(null); setSelected(new Set()); onGenerated(total); }, 650);
    };
    setTimeout(tick, 500);
  };

  return (
    <div className="rc-push" style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)", position: "relative" }}>
      <NavBar title={title}
        leading={<Button variant="plain" icon="chevron-left" onClick={onBack}>{depth === 0 ? "Repos" : "Back"}</Button>}
        trailing={selected.size > 0 ? <Button variant="plain" onClick={generate} style={{ fontWeight: 600 }}>{`Generate (${selected.size})`}</Button> : null} />

      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px" }}>
        <Card variant="grouped">
          {entries.length === 0 && (
            <div style={{ padding: "16px", font: "var(--type-subheadline)", color: "var(--text-secondary)", textAlign: "center" }}>Empty folder</div>
          )}
          {entries.map((e, i) => {
            const last = i === entries.length - 1;
            const sep = last ? "none" : "inset 0 -0.5px 0 var(--separator)";
            if (e.type === "dir") {
              return (
                <div key={e.path} className="rc-tap-row" onClick={() => onPush(e.path)}
                  style={{ display: "flex", alignItems: "center", gap: 11, padding: "11px 16px", cursor: "pointer", boxShadow: sep }}>
                  <RCIcon name="folder" size={20} color="var(--tint)" />
                  <span style={{ flex: 1, minWidth: 0, font: "var(--type-body)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{e.name}</span>
                  <RCIcon name="chevron-right" size={18} color="var(--label-tertiary)" />
                </div>
              );
            }
            const md = window.RC_IS_MD(e.name);
            const on = selected.has(e.path);
            return (
              <div key={e.path} className="rc-tap-row" onClick={() => toggle(e.path)}
                style={{ display: "flex", alignItems: "center", gap: 11, padding: "11px 16px", cursor: "pointer", boxShadow: sep }}>
                <RCIcon name={on ? "circle-check-big" : "circle"} size={22} color={on ? "var(--tint)" : "var(--label-tertiary)"} />
                <RCIcon name={md ? "file-text" : "code-xml"} size={19} color="var(--text-secondary)" />
                <span style={{ flex: 1, minWidth: 0, font: "var(--type-body)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{e.name}</span>
                <span style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)" }}>{md ? "Verbatim" : "Summary"}</span>
              </div>
            );
          })}
        </Card>
        {selected.size > 0 && !gen && (
          <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)", padding: "10px 4px 0" }}>
            Code files are summarized on-device with Apple Intelligence; Markdown is read verbatim.
          </div>
        )}
      </div>

      {gen && (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "color-mix(in srgb, var(--bg) 30%, transparent)" }}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, padding: 24, borderRadius: "var(--radius-lg)", background: "var(--material-thick)", backdropFilter: "var(--blur-thick)", boxShadow: "var(--shadow-lg)" }}>
            <span className="rc-spinner" />
            <span style={{ font: "var(--type-subheadline)", color: "var(--text-primary)", fontVariantNumeric: "tabular-nums" }}>Generating {gen.progress}/{gen.total}…</span>
          </div>
        </div>
      )}
    </div>
  );
}
window.RepoBrowser = RepoBrowser;
