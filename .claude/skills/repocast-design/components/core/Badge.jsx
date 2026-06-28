import React from "react";

/**
 * Small status pill. `tint` picks a system color; `style="tinted"` uses the
 * translucent treatment (colored text on light fill), `solid` is filled.
 * Used for track status (Ready / Generating / Failed) and source kind.
 */
export function Badge({ children, tint = "blue", variant = "tinted", icon, style, ...rest }) {
  React.useEffect(() => {
    if (icon && typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [icon, children]);

  const color = `var(--${tint})`;
  const isSolid = variant === "solid";

  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        font: "var(--type-caption-1)",
        fontWeight: 600,
        lineHeight: 1,
        padding: "4px 9px",
        borderRadius: "var(--radius-capsule)",
        background: isSolid ? color : `color-mix(in srgb, ${color} 16%, transparent)`,
        color: isSolid ? "#fff" : color,
        whiteSpace: "nowrap",
        ...style,
      }}
      {...rest}
    >
      {icon && <i data-lucide={icon} style={{ width: 12, height: 12 }} />}
      {children}
    </span>
  );
}
