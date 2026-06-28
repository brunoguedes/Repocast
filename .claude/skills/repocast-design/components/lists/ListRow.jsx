import React from "react";

/**
 * One row in an iOS grouped list / Form. Supports a leading icon (Lucide name
 * or any node), title + optional subtitle, a trailing `value` string, and an
 * accessory (disclosure chevron, checkmark, or a custom node like a Toggle).
 * Rows divide with a hairline separator; the last row omits it. Tappable rows
 * (with `onClick`) show a system press highlight.
 */
export function ListRow({
  title,
  subtitle,
  value,
  icon,
  iconColor = "var(--tint)",
  iconBg,
  accessory,
  trailing,
  last = false,
  destructive = false,
  onClick,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const tappable = !!onClick;

  React.useEffect(() => {
    if (icon && typeof icon === "string" && typeof window !== "undefined" && window.lucide) {
      window.lucide.createIcons();
    }
  }, [icon]);

  const leading =
    icon == null ? null : typeof icon === "string" ? (
      iconBg ? (
        <span style={{ width: 29, height: 29, borderRadius: 7, background: iconBg, display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
          <i data-lucide={icon} style={{ width: 18, height: 18, color: "#fff" }} />
        </span>
      ) : (
        <i data-lucide={icon} style={{ width: 22, height: 22, color: iconColor, flex: "none" }} />
      )
    ) : (
      icon
    );

  let accessoryEl = accessory;
  if (accessory === "disclosure") {
    accessoryEl = <i data-lucide="chevron-right" style={{ width: 18, height: 18, color: "var(--label-tertiary)" }} />;
  } else if (accessory === "checkmark") {
    accessoryEl = <i data-lucide="check" style={{ width: 20, height: 20, color: "var(--tint)" }} />;
  }

  React.useEffect(() => {
    if (accessory === "disclosure" || accessory === "checkmark") {
      if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
    }
  }, [accessory]);

  return (
    <div
      onClick={onClick}
      onPointerDown={() => tappable && setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        minHeight: 44,
        padding: "9px 16px",
        background: pressed ? "var(--fill-quaternary)" : "transparent",
        cursor: tappable ? "pointer" : "default",
        boxShadow: last ? "none" : "inset 0 -0.5px 0 var(--separator)",
        transition: "background var(--duration-fast) var(--ease-out)",
        WebkitTapHighlightColor: "transparent",
        ...style,
      }}
      {...rest}
    >
      {leading}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: "var(--type-body)", color: destructive ? "var(--red)" : "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
          {title}
        </div>
        {subtitle != null && (
          <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)", marginTop: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            {subtitle}
          </div>
        )}
      </div>
      {value != null && (
        <span style={{ font: "var(--type-body)", color: "var(--text-secondary)", flex: "none", maxWidth: "55%", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
          {value}
        </span>
      )}
      {trailing}
      {accessoryEl && <span style={{ display: "inline-flex", flex: "none" }}>{accessoryEl}</span>}
    </div>
  );
}
