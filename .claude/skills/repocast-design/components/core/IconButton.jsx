import React from "react";

/**
 * Circular / square icon-only button — toolbar actions, transport controls.
 * Renders a Lucide glyph (SF Symbol substitute). `prominence="filled"` gives
 * the tinted-circle treatment (like the big play button on Now Playing).
 */
export function IconButton({
  icon,
  size = "medium",
  prominence = "plain",
  shape = "circle",
  label,
  disabled = false,
  onClick,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);

  React.useEffect(() => {
    if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [icon]);

  const sizes = { small: 32, medium: 44, large: 56 };
  const glyph = { small: 18, medium: 22, large: 28 };
  const dim = sizes[size] || sizes.medium;

  const palettes = {
    plain: { bg: "transparent", color: "var(--tint)" },
    tinted: { bg: "color-mix(in srgb, var(--tint) 15%, transparent)", color: "var(--tint)" },
    gray: { bg: "var(--fill-tertiary)", color: "var(--text-primary)" },
    filled: { bg: "var(--tint)", color: "var(--text-on-tint)" },
  };
  const p = palettes[prominence] || palettes.plain;

  return (
    <button
      type="button"
      aria-label={label}
      disabled={disabled}
      onClick={disabled ? undefined : onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        width: dim,
        height: dim,
        flex: "none",
        border: "none",
        borderRadius: shape === "circle" ? "var(--radius-capsule)" : "var(--radius-md)",
        background: p.bg,
        color: p.color,
        cursor: disabled ? "default" : "pointer",
        opacity: disabled ? 0.35 : pressed ? 0.5 : 1,
        transform: pressed && !disabled ? "scale(0.92)" : "scale(1)",
        transition: "transform var(--duration-fast) var(--ease-out), opacity var(--duration-fast) var(--ease-out)",
        WebkitTapHighlightColor: "transparent",
        ...style,
      }}
      {...rest}
    >
      <i data-lucide={icon} style={{ width: glyph[size] || glyph.medium, height: glyph[size] || glyph.medium }} />
    </button>
  );
}
