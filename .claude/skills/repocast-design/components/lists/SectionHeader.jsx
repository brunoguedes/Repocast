import React from "react";

/** Grouped-list section header — small uppercase caption above a Card. */
export function SectionHeader({ children, action, style, ...rest }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "flex-end",
        justifyContent: "space-between",
        padding: "0 16px 7px",
        ...style,
      }}
      {...rest}
    >
      <span style={{ font: "var(--type-footnote)", color: "var(--text-secondary)", textTransform: "uppercase", letterSpacing: "0.4px" }}>
        {children}
      </span>
      {action}
    </div>
  );
}
