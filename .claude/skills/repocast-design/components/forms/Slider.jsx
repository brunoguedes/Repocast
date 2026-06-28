import React from "react";

/**
 * iOS slider. Continuous track with a white knob; filled portion uses the
 * tint. Optional `minIcon`/`maxIcon` (Lucide names) flank the track like the
 * tortoise/hare speech-rate slider. Controlled via `value` + `onChange`.
 */
export function Slider({
  value = 0,
  min = 0,
  max = 1,
  step,
  onChange,
  minIcon,
  maxIcon,
  disabled = false,
  style,
  ...rest
}) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);
  const pct = Math.max(0, Math.min(1, (value - min) / (max - min || 1)));

  React.useEffect(() => {
    if ((minIcon || maxIcon) && typeof window !== "undefined" && window.lucide) {
      window.lucide.createIcons();
    }
  }, [minIcon, maxIcon]);

  const setFromClientX = (clientX) => {
    const el = trackRef.current;
    if (!el || disabled) return;
    const rect = el.getBoundingClientRect();
    let p = (clientX - rect.left) / rect.width;
    p = Math.max(0, Math.min(1, p));
    let v = min + p * (max - min);
    if (step) v = Math.round(v / step) * step;
    onChange && onChange(v);
  };

  const trackEl = (
    <div
      ref={trackRef}
      onPointerDown={(e) => {
        if (disabled) return;
        setDragging(true);
        e.currentTarget.setPointerCapture(e.pointerId);
        setFromClientX(e.clientX);
      }}
      onPointerMove={(e) => dragging && setFromClientX(e.clientX)}
      onPointerUp={() => setDragging(false)}
      style={{
        position: "relative",
        flex: 1,
        height: 28,
        display: "flex",
        alignItems: "center",
        cursor: disabled ? "default" : "pointer",
        touchAction: "none",
      }}
    >
      <div style={{ position: "absolute", left: 0, right: 0, height: 4, borderRadius: 2, background: "var(--fill)" }} />
      <div style={{ position: "absolute", left: 0, width: `${pct * 100}%`, height: 4, borderRadius: 2, background: "var(--tint)" }} />
      <div
        style={{
          position: "absolute",
          left: `calc(${pct * 100}% - 14px)`,
          width: 28,
          height: 28,
          borderRadius: "50%",
          background: "#fff",
          boxShadow: "0 1px 3px rgba(0,0,0,0.18), 0 3px 8px rgba(0,0,0,0.12)",
          transform: dragging ? "scale(1.08)" : "scale(1)",
          transition: "transform var(--duration-fast) var(--ease-out)",
        }}
      />
    </div>
  );

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, opacity: disabled ? 0.5 : 1, ...style }} {...rest}>
      {minIcon && <i data-lucide={minIcon} style={{ width: 18, height: 18, color: "var(--text-secondary)", flex: "none" }} />}
      {trackEl}
      {maxIcon && <i data-lucide={maxIcon} style={{ width: 18, height: 18, color: "var(--text-secondary)", flex: "none" }} />}
    </div>
  );
}
