// Now Playing sheet — full-screen transport: big tinted waveform, title,
// scrubber, transport controls, segmented speed picker. Mirrors NowPlayingView.
function NowPlayingSheet({ track, playing, onTogglePlay, onClose, onPrev, onNext }) {
  const { IconButton, SegmentedControl } = window.RepocastDesignSystem_a3bb12;
  const [progress, setProgress] = React.useState(0.18);
  const [speed, setSpeed] = React.useState(1);
  const dur = track ? track.durSec : 0;

  React.useEffect(() => { window.lucide && window.lucide.createIcons(); });

  // Advance the scrubber while playing (cosmetic).
  React.useEffect(() => {
    if (!playing) return;
    const id = setInterval(() => setProgress((p) => (p >= 1 ? 0 : p + (speed * 0.6) / Math.max(dur, 1))), 600);
    return () => clearInterval(id);
  }, [playing, speed, dur]);

  const fmt = (s) => { s = Math.max(0, Math.round(s)); return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`; };

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "center", padding: "10px 28px 28px", background: "var(--bg)" }}>
      <div style={{ width: 40, height: 5, borderRadius: 3, background: "var(--label-tertiary)", margin: "0 0 8px" }} onClick={onClose} />
      <div style={{ flex: 1 }} />
      <div className={playing ? "rc-pulse" : ""} style={{ width: 168, height: 168, borderRadius: "50%", background: "color-mix(in srgb, var(--tint) 14%, transparent)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 28 }}>
        <i data-lucide="audio-lines" style={{ width: 88, height: 88, color: "var(--tint)" }} />
      </div>
      <div style={{ font: "var(--type-title-2)", color: "var(--text-primary)", textAlign: "center", marginBottom: 24, maxWidth: "100%", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
        {track ? track.title : "Nothing Playing"}
      </div>

      <div style={{ width: "100%", marginBottom: 24 }}>
        <div style={{ position: "relative", height: 6, borderRadius: 3, background: "var(--fill)" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${progress * 100}%`, borderRadius: 3, background: "var(--tint)" }} />
          <div style={{ position: "absolute", top: "50%", left: `calc(${progress * 100}% - 6px)`, width: 12, height: 12, borderRadius: "50%", background: "var(--text-secondary)", transform: "translateY(-50%)" }} />
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, font: "var(--type-caption-1)", color: "var(--text-secondary)", fontVariantNumeric: "tabular-nums" }}>
          <span>{fmt(progress * dur)}</span><span>-{fmt(dur - progress * dur)}</span>
        </div>
      </div>

      <div style={{ display: "flex", alignItems: "center", gap: 36, marginBottom: 28 }}>
        <IconButton icon="skip-back" label="Previous" size="medium" onClick={onPrev} />
        <button type="button" onClick={onTogglePlay} aria-label={playing ? "Pause" : "Play"}
          style={{ width: 74, height: 74, borderRadius: "50%", border: "none", background: "color-mix(in srgb, var(--tint) 14%, transparent)", color: "var(--tint)", display: "inline-flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
          <i data-lucide={playing ? "pause" : "play"} style={{ width: 36, height: 36, fill: "currentColor" }} />
        </button>
        <IconButton icon="skip-forward" label="Next" size="medium" onClick={onNext} />
      </div>

      <div style={{ width: "100%" }}>
        <SegmentedControl value={speed} onChange={setSpeed} options={[
          { label: "0.75×", value: 0.75 }, { label: "1×", value: 1 },
          { label: "1.25×", value: 1.25 }, { label: "1.5×", value: 1.5 }, { label: "2×", value: 2 },
        ]} />
      </div>
    </div>
  );
}
window.NowPlayingSheet = NowPlayingSheet;
