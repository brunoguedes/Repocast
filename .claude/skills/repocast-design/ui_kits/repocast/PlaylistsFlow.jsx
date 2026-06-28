// Playlists flow shell — tab root, detail navigation, New / Smart sheets, and a
// Now Playing overlay. Reorder/remove persist into the playlist's track order.
function PlaylistsFlow() {
  const [playlists, setPlaylists] = React.useState(window.RC_PLAYLISTS);
  const [activeId, setActiveId] = React.useState(null);
  const [sheet, setSheet] = React.useState(null); // "new" | "smart" | null
  const [now, setNow] = React.useState(null);
  const RCIcon = window.RCIcon;

  const active = playlists.find((p) => p.id === activeId) || null;
  const fmtNow = () => { const d = new Date(); return `${((d.getHours() + 11) % 12) + 1}:${String(d.getMinutes()).padStart(2, "0")}`; };

  const updateActive = (mut) => setPlaylists((ps) => ps.map((p) => (p.id === activeId ? mut(p) : p)));
  const reorder = (tracks) => updateActive((p) => ({ ...p, trackIds: tracks.map((t) => t.id) }));
  const remove = (id) => updateActive((p) => ({ ...p, trackIds: p.trackIds.filter((x) => x !== id) }));

  const createManual = (title, ids) => {
    setPlaylists((ps) => [{ id: "n" + Date.now(), title, subtitle: "Playlist", smart: false, tint: "teal", icon: "list-music", trackIds: ids }, ...ps]);
    setSheet(null);
  };
  const createSmart = (result) => {
    setPlaylists((ps) => [{ id: "n" + Date.now(), title: result.title, subtitle: "Smart playlist", smart: true, tint: "purple", icon: "sparkles", trackIds: result.tracks.map((t) => t.id) }, ...ps]);
    setSheet(null);
  };

  const detailTracks = active ? window.RC_RESOLVE(active).tracks : [];

  return (
    <div className="rc-phone">
      <div className="rc-statusbar">
        <span className="rc-time">{fmtNow()}</span>
        <span className="rc-status-icons">
          <RCIcon name="signal" size={17} color="var(--text-primary)" />
          <RCIcon name="wifi" size={17} color="var(--text-primary)" />
          <RCIcon name="battery-full" size={22} color="var(--text-primary)" />
        </span>
      </div>

      <div className="rc-screen">
        {active ? (
          <window.PlaylistDetail key={active.id} playlist={active} tracks={detailTracks}
            onBack={() => setActiveId(null)} onPlay={(t) => setNow(t)} onReorder={reorder} onRemove={remove} />
        ) : (
          <window.PlaylistsScreen playlists={playlists} onOpen={(p) => setActiveId(p.id)} onNew={() => setSheet("new")} onSmart={() => setSheet("smart")} />
        )}
      </div>

      {/* Sheets */}
      <div className={"rc-scrim" + (sheet ? " show" : "")} onClick={() => setSheet(null)} />
      <div className={"rc-sheet" + (sheet === "new" ? " up" : "")}>
        {sheet === "new" && <window.NewPlaylistSheet onCancel={() => setSheet(null)} onCreate={createManual} />}
      </div>
      <div className={"rc-sheet" + (sheet === "smart" ? " up" : "")}>
        {sheet === "smart" && <window.SmartPlaylistSheet onCancel={() => setSheet(null)} onSave={createSmart} />}
      </div>

      {/* Now Playing overlay */}
      <div className={"rc-scrim" + (now ? " show" : "")} onClick={() => setNow(null)} />
      <div className={"rc-sheet rc-sheet-full" + (now ? " up" : "")}>
        {now && <window.NowPlayingSheet track={now} playing={true} onTogglePlay={() => {}} onClose={() => setNow(null)} onPrev={() => {}} onNext={() => {}} />}
      </div>
    </div>
  );
}
window.PlaylistsFlow = PlaylistsFlow;
