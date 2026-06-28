import React from "react";

/**
 * iOS grouped container. `variant="grouped"` is the inset white card on a
 * gray grouped background (Settings/Form rows live inside it, divided by
 * hairlines). `variant="plain"` is a flat surface; `variant="elevated"` adds
 * a soft shadow for a floating tile. An optional `header`/`footer` render as
 * the small caption text above/below a grouped section.
 */
export function Card({ children, variant = "grouped", header, footer, padded = false, style, ...rest }) {
  const surfaces = {
    grouped: { background: "var(--surface-card)", boxShadow: "none" },
    plain: { background: "var(--surface)", boxShadow: "none" },
    elevated: { background: "var(--surface-card)", boxShadow: "var(--shadow-md)" },
  };
  const s = surfaces[variant] || surfaces.grouped;

  return (
    <div style={{ ...style }} {...rest}>
      {header && (
        <div
          style={{
            font: "var(--type-footnote)",
            color: "var(--text-secondary)",
            textTransform: "uppercase",
            letterSpacing: "0.4px",
            padding: "0 16px 7px",
          }}
        >
          {header}
        </div>
      )}
      <div
        style={{
          background: s.background,
          boxShadow: s.boxShadow,
          borderRadius: "var(--radius-md)",
          overflow: "hidden",
          padding: padded ? "var(--space-5)" : 0,
        }}
      >
        {children}
      </div>
      {footer && (
        <div
          style={{
            font: "var(--type-footnote)",
            color: "var(--text-secondary)",
            padding: "7px 16px 0",
          }}
        >
          {footer}
        </div>
      )}
    </div>
  );
}
