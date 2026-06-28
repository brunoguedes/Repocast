// Repocast app shell — phone screen with status bar, tab switching, persistent
// mini-player + tab bar, and the New Track / Now Playing sheets.
function RepocastApp() {
  const { TabBar, MiniPlayer } = window.RepocastDesignSystem_a3bb12;
  const [tab, setTab] = React.useState("tracks");
  const [tracks, setTracks] = React.useState(window.RC_TRACKS);
  const [playing, setPlaying] = React.useState(false);
  const [current, setCurrent] = React.useState(null);
  const [sheet, setSheet] = React.useState(null); // "new" | "now" | null

  React.useEffect(() => { window.lucide && window.lucide.createIcons(); });

  const play = (t) => { setCurrent(t); setPlaying(true); setSheet("now"); };
  const addTrack = ({ title }) => {
    const t = { id: "n" + Date.now(), title, source: "Freeform text", kind: "freeform", status: "ready", duration: "0:48", durSec: 48 };
    setTracks((prev) => [t, ...prev]);
    setSheet(null);
  };
  const cycle = (dir) => {
    const ready = tracks.filter((t) => t.status === "ready");
    if (!current || ready.length === 0) return;
    let i = ready.findIndex((t) => t.id === current.id);
    i = (i + dir + ready.length) % ready.length;
    setCurrent(ready[i]); setPlaying(true);
  };

  const fmtNow = () => { const d = new Date(); return `${((d.getHours() + 11) % 12) + 1}:${String(d.getMinutes()).padStart(2, "0")}`; };

  return (
    <div className="rc-phone">
      {/* Status bar */}
      <div className="rc-statusbar">
        <span className="rc-time">{fmtNow()}</span>
        <span className="rc-status-icons">
          <i data-lucide="signal" style={{ width: 17, height: 17 }} />
          <i data-lucide="wifi" style={{ width: 17, height: 17 }} />
          <i data-lucide="battery-full" style={{ width: 22, height: 22 }} />
        </span>
      </div>

      {/* Active screen */}
      <div className="rc-screen">
        {tab === "tracks"
          ? <window.TracksScreen tracks={tracks} onPlay={play} onNew={() => setSheet("new")} playingId={playing ? current && current.id : null} />
          : <window.SettingsScreen
              rate={0.55} onRate={() => {}} ai={true} onAi={() => {}} />}
      </div>

      {/* Bottom chrome: mini-player + tab bar */}
      <div className="rc-bottom">
        {current && (
          <MiniPlayer title={current.title} currentTime="1:23" duration={current.duration} playing={playing}
            onTogglePlay={() => setPlaying((p) => !p)} onOpen={() => setSheet("now")} />
        )}
        <TabBar value={tab} onChange={setTab} items={[
          { value: "tracks", label: "Tracks", icon: "audio-lines" },
          { value: "settings", label: "Settings", icon: "settings" },
        ]} />
      </div>

      {/* Sheets */}
      <div className={"rc-scrim" + (sheet ? " show" : "")} onClick={() => setSheet(null)} />
      <div className={"rc-sheet" + (sheet === "new" ? " up" : "")}>
        {sheet === "new" && <window.NewTrackSheet onCancel={() => setSheet(null)} onGenerate={addTrack} />}
      </div>
      <div className={"rc-sheet rc-sheet-full" + (sheet === "now" ? " up" : "")}>
        {sheet === "now" && <window.NowPlayingSheet track={current} playing={playing}
          onTogglePlay={() => setPlaying((p) => !p)} onClose={() => setSheet(null)}
          onPrev={() => cycle(-1)} onNext={() => cycle(1)} />}
      </div>
    </div>
  );
}
window.RepocastApp = RepocastApp;
