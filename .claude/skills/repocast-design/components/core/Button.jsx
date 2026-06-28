import React from "react";

/**
 * Repocast / iOS-style button.
 * Variants map to Apple's button prominences: filled (.borderedProminent),
 * tinted (.bordered with tint), gray (.bordered), plain (.plain), and
 * destructive. Press feedback is an opacity dip + slight scale, like UIKit.
 */
export function Button({
  children,
  variant = "filled",
  size = "medium",
  shape = "rounded",
  icon,
  iconTrailing = false,
  fullWidth = false,
  disabled = false,
  onClick,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);

  React.useEffect(() => {
    if (icon && typeof window !== "undefined" && window.lucide) {
      window.lucide.createIcons();
    }
  }, [icon, children]);

  const sizes = {
    small: { font: "var(--type-subheadline)", pad: "6px 14px", h: 32, gap: 6, icon: 16 },
    medium: { font: "var(--type-callout)", pad: "9px 18px", h: 40, gap: 7, icon: 18 },
    large: { font: "var(--type-headline)", pad: "14px 22px", h: 50, gap: 8, icon: 20 },
  };
  const s = sizes[size] || sizes.medium;

  const palettes = {
    filled: { bg: "var(--tint)", color: "var(--text-on-tint)", pressBg: "var(--tint-pressed)" },
    tinted: { bg: "color-mix(in srgb, var(--tint) 15%, transparent)", color: "var(--tint)", pressBg: "color-mix(in srgb, var(--tint) 26%, transparent)" },
    gray: { bg: "var(--fill-tertiary)", color: "var(--text-primary)", pressBg: "var(--fill-secondary)" },
    plain: { bg: "transparent", color: "var(--tint)", pressBg: "transparent" },
    destructive: { bg: "color-mix(in srgb, var(--red) 15%, transparent)", color: "var(--red)", pressBg: "color-mix(in srgb, var(--red) 26%, transparent)" },
  };
  const p = palettes[variant] || palettes.filled;

  const base = {
    display: fullWidth ? "flex" : "inline-flex",
    width: fullWidth ? "100%" : undefined,
    alignItems: "center",
    justifyContent: "center",
    gap: `${s.gap}px`,
    font: s.font,
    fontWeight: variant === "plain" ? 400 : 600,
    minHeight: `${s.h}px`,
    padding: variant === "plain" ? "4px 4px" : s.pad,
    boxSizing: "border-box",
    border: "none",
    borderRadius: shape === "capsule" ? "var(--radius-capsule)" : "var(--radius-lg)",
    background: pressed && !disabled ? p.pressBg : p.bg,
    color: p.color,
    cursor: disabled ? "default" : "pointer",
    opacity: disabled ? 0.4 : pressed && variant === "plain" ? 0.4 : 1,
    transform: pressed && !disabled && variant !== "plain" ? "scale(0.97)" : "scale(1)",
    transition: "transform var(--duration-fast) var(--ease-out), background var(--duration-fast) var(--ease-out), opacity var(--duration-fast) var(--ease-out)",
    userSelect: "none",
    WebkitTapHighlightColor: "transparent",
    ...style,
  };

  const iconEl = icon ? (
    <i data-lucide={icon} style={{ width: s.icon, height: s.icon, flex: "none" }} />
  ) : null;

  return (
    <button
      type="button"
      disabled={disabled}
      onClick={disabled ? undefined : onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={base}
      {...rest}
    >
      {!iconTrailing && iconEl}
      {children != null && <span>{children}</span>}
      {iconTrailing && iconEl}
    </button>
  );
}
