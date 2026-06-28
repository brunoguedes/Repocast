// Playlists tab — list of playlists with artwork + a Smart Playlist entry.
function PlaylistsScreen({ playlists, onOpen, onNew, onSmart }) {
  const { NavBar, Card, SectionHeader, IconButton } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
      <NavBar title="Playlists" largeTitle trailing={<IconButton icon="plus" label="New Playlist" onClick={onNew} />} />
      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px" }}>

        {/* Smart playlist entry */}
        <div className="rc-tap-row" onClick={onSmart}
          style={{ display: "flex", alignItems: "center", gap: 14, padding: 14, borderRadius: "var(--radius-lg)", cursor: "pointer",
            background: "linear-gradient(135deg, color-mix(in srgb, var(--purple) 18%, var(--surface-card)), var(--surface-card))",
            boxShadow: "inset 0 0 0 0.5px var(--separator)", marginBottom: 20 }}>
          <span style={{ width: 44, height: 44, borderRadius: "var(--radius-md)", background: "var(--RC_TINT_purple, linear-gradient(160deg, #C06BFF, #7A2BD8))", display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
            <RCIcon name="sparkles" size={24} color="#fff" />
          </span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ font: "var(--type-headline)", color: "var(--text-primary)" }}>New Smart Playlist</div>
            <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)" }}>Describe it — Apple Intelligence picks the tracks.</div>
          </div>
          <RCIcon name="chevron-right" size={18} color="var(--label-tertiary)" />
        </div>

        <SectionHeader>Your Playlists</SectionHeader>
        <Card variant="grouped">
          {playlists.map((pl, i) => {
            const { tracks, min } = window.RC_RESOLVE(pl);
            return (
              <div key={pl.id} className="rc-tap-row" onClick={() => onOpen(pl)}
                style={{ display: "flex", alignItems: "center", gap: 13, padding: "10px 16px", cursor: "pointer", boxShadow: i === playlists.length - 1 ? "none" : "inset 0 -0.5px 0 var(--separator)" }}>
                <span style={{ width: 52, height: 52, borderRadius: "var(--radius-sm)", background: window.RC_TINT_GRAD[pl.tint], display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "none", boxShadow: "var(--shadow-sm)" }}>
                  <RCIcon name={pl.icon} size={26} color="#fff" />
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <span style={{ font: "var(--type-body)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{pl.title}</span>
                    {pl.smart && <RCIcon name="sparkles" size={13} color="var(--purple)" />}
                  </div>
                  <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)", marginTop: 1 }}>{tracks.length} tracks · {min} min</div>
                </div>
                <RCIcon name="chevron-right" size={18} color="var(--label-tertiary)" />
              </div>
            );
          })}
        </Card>
      </div>
    </div>
  );
}
window.PlaylistsScreen = PlaylistsScreen;
