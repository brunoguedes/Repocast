// Tracks screen — the app's home. Large-title nav bar, grouped list of tracks,
// or the ContentUnavailableView empty state when there are none.
function TracksScreen({ tracks, onPlay, onNew, playingId }) {
  const { NavBar, IconButton, Card, ListRow, Badge } = window.RepocastDesignSystem_a3bb12;
  const empty = tracks.length === 0;

  React.useEffect(() => { window.lucide && window.lucide.createIcons(); });

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
      <NavBar title="Tracks" largeTitle trailing={<IconButton icon="plus" label="New Track" onClick={onNew} />} />
      <div style={{ flex: 1, overflowY: "auto", padding: empty ? 0 : "8px 16px 16px" }}>
        {empty ? (
          <div style={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10, padding: 32, textAlign: "center" }}>
            <i data-lucide="audio-lines" style={{ width: 52, height: 52, color: "var(--label-tertiary)" }} />
            <div style={{ font: "var(--type-title-3)", color: "var(--text-primary)" }}>No Tracks Yet</div>
            <div style={{ font: "var(--type-subheadline)", color: "var(--text-secondary)", maxWidth: 260 }}>
              Tap + to turn text into audio you can play anywhere.
            </div>
          </div>
        ) : (
          <Card variant="grouped">
            {tracks.map((t, i) => {
              const b = window.RC_STATUS_BADGE[t.status];
              const isPlaying = t.id === playingId;
              return (
                <ListRow
                  key={t.id}
                  icon={isPlaying ? "audio-lines" : window.RC_KIND_ICON[t.kind]}
                  iconColor={isPlaying ? "var(--tint)" : "var(--text-secondary)"}
                  title={t.title}
                  subtitle={t.source}
                  trailing={
                    b
                      ? <Badge tint={b.tint} icon={b.icon}>{b.label}</Badge>
                      : <span style={{ font: "var(--type-subheadline)", color: "var(--text-secondary)", fontVariantNumeric: "tabular-nums" }}>{t.duration}</span>
                  }
                  accessory={t.status === "ready" ? <i data-lucide="circle-play" style={{ width: 22, height: 22, color: "var(--label-tertiary)" }} /> : null}
                  onClick={t.status === "ready" ? () => onPlay(t) : undefined}
                  last={i === tracks.length - 1}
                />
              );
            })}
          </Card>
        )}
      </div>
    </div>
  );
}
window.TracksScreen = TracksScreen;
