import React from "react";

/**
 * Compact transport bar that rides above the tab bar (Apple Podcasts pattern).
 * Frosted material, leading waveform glyph, title + "current / total" time,
 * and a play/pause button. Tap the bar (not the button) to open Now Playing.
 */
export function MiniPlayer({
  title = "Nothing Playing",
  currentTime = "0:00",
  duration = "0:00",
  playing = false,
  onTogglePlay,
  onOpen,
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [playing]);

  return (
    <div
      onClick={onOpen}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: "9px 14px",
        background: "var(--material-regular)",
        backdropFilter: "var(--blur-regular)",
        WebkitBackdropFilter: "var(--blur-regular)",
        boxShadow: "inset 0 0.5px 0 var(--separator)",
        cursor: onOpen ? "pointer" : "default",
        ...style,
      }}
      {...rest}
    >
      <span style={{ width: 38, height: 38, borderRadius: "var(--radius-sm)", background: "color-mix(in srgb, var(--tint) 14%, transparent)", display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <i data-lucide="audio-lines" style={{ width: 21, height: 21, color: "var(--tint)" }} />
      </span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: "var(--type-subheadline)", fontWeight: 500, color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
          {title}
        </div>
        <div style={{ font: "var(--type-caption-2)", color: "var(--text-secondary)", fontVariantNumeric: "tabular-nums", marginTop: 1 }}>
          {currentTime} / {duration}
        </div>
      </div>
      <button
        type="button"
        aria-label={playing ? "Pause" : "Play"}
        onClick={(e) => { e.stopPropagation(); onTogglePlay && onTogglePlay(); }}
        style={{ border: "none", background: "transparent", color: "var(--text-primary)", cursor: "pointer", display: "inline-flex", padding: 6, flex: "none", WebkitTapHighlightColor: "transparent" }}
      >
        <i data-lucide={playing ? "pause" : "play"} style={{ width: 24, height: 24, fill: "currentColor" }} />
      </button>
    </div>
  );
}
