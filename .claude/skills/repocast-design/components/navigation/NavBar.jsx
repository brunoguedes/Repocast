import React from "react";

/**
 * iOS navigation bar. `title` renders inline (centered) with a frosted
 * material background and a bottom hairline; `largeTitle` renders the big
 * left-aligned title below it (the scrolled-to-top state). `leading` and
 * `trailing` host nav actions (typically `<Button variant="plain">`).
 */
export function NavBar({ title, largeTitle = false, leading, trailing, style, ...rest }) {
  return (
    <div
      style={{
        background: "var(--material-regular)",
        backdropFilter: "var(--blur-regular)",
        WebkitBackdropFilter: "var(--blur-regular)",
        boxShadow: "inset 0 -0.5px 0 var(--separator)",
        ...style,
      }}
      {...rest}
    >
      <div
        style={{
          position: "relative",
          height: 44,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 8px",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", minWidth: 44, justifyContent: "flex-start" }}>{leading}</div>
        {!largeTitle && (
          <div
            style={{
              position: "absolute",
              left: "50%",
              transform: "translateX(-50%)",
              font: "var(--type-headline)",
              color: "var(--text-primary)",
              maxWidth: "60%",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {title}
          </div>
        )}
        <div style={{ display: "flex", alignItems: "center", gap: 4, minWidth: 44, justifyContent: "flex-end" }}>{trailing}</div>
      </div>
      {largeTitle && (
        <div style={{ padding: "0 16px 8px", font: "var(--type-large-title)", letterSpacing: "var(--tracking-tight)", color: "var(--text-primary)" }}>
          {title}
        </div>
      )}
    </div>
  );
}
