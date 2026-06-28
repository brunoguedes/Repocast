import React from "react";

/**
 * iOS segmented control — the capsule of mutually-exclusive options used for
 * the playback-speed picker. A sliding white "thumb" highlights the selected
 * segment. Controlled via `value` (must match one option's `value`).
 */
export function SegmentedControl({ options = [], value, onChange, style, ...rest }) {
  const idx = Math.max(0, options.findIndex((o) => o.value === value));
  const n = options.length || 1;

  return (
    <div
      style={{
        position: "relative",
        display: "flex",
        background: "var(--fill-tertiary)",
        borderRadius: "9px",
        padding: 2,
        ...style,
      }}
      {...rest}
    >
      <div
        style={{
          position: "absolute",
          top: 2,
          bottom: 2,
          left: `calc(${(idx / n) * 100}% + 2px)`,
          width: `calc(${100 / n}% - 4px)`,
          background: "var(--bg-tertiary)",
          borderRadius: "7px",
          boxShadow: "0 3px 8px rgba(0,0,0,0.12), 0 1px 1px rgba(0,0,0,0.04)",
          transition: "left var(--duration-base) var(--ease-standard)",
        }}
      />
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange && onChange(o.value)}
            style={{
              position: "relative",
              flex: 1,
              border: "none",
              background: "transparent",
              font: "var(--type-subheadline)",
              fontWeight: active ? 600 : 500,
              color: "var(--text-primary)",
              padding: "6px 12px",
              cursor: "pointer",
              zIndex: 1,
              WebkitTapHighlightColor: "transparent",
            }}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
