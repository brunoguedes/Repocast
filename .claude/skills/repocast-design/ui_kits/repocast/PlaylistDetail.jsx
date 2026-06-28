// Playlist detail — artwork header, Play All / Shuffle, and a track list with
// an Edit mode for reorder (drag handle) + remove. Mirrors a planned
// PlaylistDetailView with .onMove / .onDelete.
function PlaylistDetail({ playlist, tracks, onBack, onPlay, onReorder, onRemove }) {
  const { NavBar, Card, Button } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;
  const [editing, setEditing] = React.useState(false);
  const [dragFrom, setDragFrom] = React.useState(null);
  const listRef = React.useRef(null);
  const ROW = 56;

  const sec = tracks.reduce((a, t) => a + t.durSec, 0);
  const min = Math.max(1, Math.round(sec / 60));

  const move = (arr, from, to) => { const a = arr.slice(); const [x] = a.splice(from, 1); a.splice(to, 0, x); return a; };

  const onMove = (e) => {
    if (dragFrom == null || !listRef.current) return;
    const top = listRef.current.getBoundingClientRect().top;
    let target = Math.floor((e.clientY - top) / ROW);
    target = Math.max(0, Math.min(tracks.length - 1, target));
    if (target !== dragFrom) { onReorder(move(tracks, dragFrom, target)); setDragFrom(target); }
  };

  return (
    <div className="rc-push" style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
      <NavBar
        title={editing ? playlist.title : ""}
        leading={<Button variant="plain" icon="chevron-left" onClick={onBack}>Playlists</Button>}
        trailing={<Button variant="plain" onClick={() => { setEditing((e) => !e); setDragFrom(null); }} style={{ fontWeight: editing ? 600 : 400 }}>{editing ? "Done" : "Edit"}</Button>} />

      <div style={{ flex: 1, overflowY: "auto", padding: "0 16px 24px" }} onPointerMove={onMove} onPointerUp={() => setDragFrom(null)}>
        {/* Header */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center", padding: "4px 0 18px" }}>
          <div style={{ width: 132, height: 132, borderRadius: "var(--radius-xl)", background: window.RC_TINT_GRAD[playlist.tint], display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "var(--shadow-md)", marginBottom: 14 }}>
            <RCIcon name={playlist.icon} size={62} color="#fff" />
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
            <span style={{ font: "var(--type-title-2)", color: "var(--text-primary)" }}>{playlist.title}</span>
            {playlist.smart && <RCIcon name="sparkles" size={17} color="var(--purple)" />}
          </div>
          <div style={{ font: "var(--type-subheadline)", color: "var(--text-secondary)", marginTop: 2 }}>
            {playlist.smart ? "Smart playlist · " : playlist.repo ? playlist.repo + " · " : ""}{tracks.length} tracks · {min} min
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
            <Button variant="filled" icon="play" onClick={() => tracks[0] && onPlay(tracks[0])}>Play All</Button>
            <Button variant="tinted" icon="shuffle" onClick={() => tracks.length && onPlay(tracks[Math.floor(Math.random() * tracks.length)])}>Shuffle</Button>
          </div>
        </div>

        {/* Tracks */}
        <Card variant="grouped">
          <div ref={listRef}>
            {tracks.map((t, i) => {
              const last = i === tracks.length - 1;
              const dragging = dragFrom === i;
              return (
                <div key={t.id}
                  className={editing ? "" : "rc-tap-row"}
                  onClick={editing ? undefined : () => onPlay(t)}
                  style={{ display: "flex", alignItems: "center", gap: 11, height: ROW, padding: "0 16px", cursor: editing ? "default" : "pointer",
                    background: dragging ? "var(--fill-tertiary)" : "transparent",
                    boxShadow: last || dragging ? "none" : "inset 0 -0.5px 0 var(--separator)",
                    borderRadius: dragging ? "var(--radius-sm)" : 0, position: "relative", zIndex: dragging ? 2 : 1 }}>
                  {editing && (
                    <button type="button" onClick={() => onRemove(t.id)} aria-label="Remove"
                      style={{ border: "none", background: "transparent", cursor: "pointer", display: "inline-flex", flex: "none", padding: 0 }}>
                      <RCIcon name="circle-minus" size={22} color="var(--red)" />
                    </button>
                  )}
                  <RCIcon name={window.RC_KIND_ICON[t.kind] || "file-text"} size={18} color="var(--text-secondary)" />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ font: "var(--type-callout)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t.title}</div>
                    <div style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t.source}</div>
                  </div>
                  {editing
                    ? <span style={{ touchAction: "none", cursor: "grab", display: "inline-flex", flex: "none", padding: "6px 2px" }}
                        onPointerDown={(e) => { e.currentTarget.setPointerCapture(e.pointerId); setDragFrom(i); }}>
                        <RCIcon name="grip-horizontal" size={20} color="var(--label-tertiary)" />
                      </span>
                    : <span style={{ font: "var(--type-subheadline)", color: "var(--text-secondary)", fontVariantNumeric: "tabular-nums", flex: "none" }}>{t.duration}</span>}
                </div>
              );
            })}
          </div>
        </Card>
      </div>
    </div>
  );
}
window.PlaylistDetail = PlaylistDetail;
