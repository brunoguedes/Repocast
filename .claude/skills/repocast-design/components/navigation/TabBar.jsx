import React from "react";

/**
 * iOS tab bar — frosted material bottom bar. `items` is an array of
 * { value, label, icon (Lucide name) }. The active tab is tinted; others use
 * the muted label color. Controlled via `value` + `onChange`.
 */
export function TabBar({ items = [], value, onChange, style, ...rest }) {
  React.useEffect(() => {
    if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [items]);

  return (
    <div
      style={{
        display: "flex",
        background: "var(--material-regular)",
        backdropFilter: "var(--blur-regular)",
        WebkitBackdropFilter: "var(--blur-regular)",
        boxShadow: "inset 0 0.5px 0 var(--separator)",
        padding: "8px 0 10px",
        ...style,
      }}
      {...rest}
    >
      {items.map((it) => {
        const active = it.value === value;
        return (
          <button
            key={it.value}
            type="button"
            onClick={() => onChange && onChange(it.value)}
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 3,
              border: "none",
              background: "transparent",
              color: active ? "var(--tint)" : "var(--text-secondary)",
              cursor: "pointer",
              WebkitTapHighlightColor: "transparent",
            }}
          >
            <i data-lucide={it.icon} style={{ width: 25, height: 25 }} />
            <span style={{ font: "var(--type-caption-2)", fontWeight: 500 }}>{it.label}</span>
          </button>
        );
      })}
    </div>
  );
}
