/* @ds-bundle: {"format":3,"namespace":"RepocastDesignSystem_a3bb12","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Slider","sourcePath":"components/forms/Slider.jsx"},{"name":"TextField","sourcePath":"components/forms/TextField.jsx"},{"name":"Toggle","sourcePath":"components/forms/Toggle.jsx"},{"name":"ListRow","sourcePath":"components/lists/ListRow.jsx"},{"name":"SectionHeader","sourcePath":"components/lists/SectionHeader.jsx"},{"name":"MiniPlayer","sourcePath":"components/media/MiniPlayer.jsx"},{"name":"NavBar","sourcePath":"components/navigation/NavBar.jsx"},{"name":"TabBar","sourcePath":"components/navigation/TabBar.jsx"}],"sourceHashes":{"components/core/Badge.jsx":"a1810e6494ed","components/core/Button.jsx":"9386c16e7228","components/core/Card.jsx":"03e3c7b42a04","components/core/IconButton.jsx":"cec3a22fa099","components/forms/SegmentedControl.jsx":"8eea0e22377c","components/forms/Slider.jsx":"a978349c60bc","components/forms/TextField.jsx":"b1b59f105bf5","components/forms/Toggle.jsx":"c23f54ff2d39","components/lists/ListRow.jsx":"426d3c42d3de","components/lists/SectionHeader.jsx":"0d081625b0b9","components/media/MiniPlayer.jsx":"021bb3e4112e","components/navigation/NavBar.jsx":"e484827b9292","components/navigation/TabBar.jsx":"e42cf078afa8","ui_kits/repocast/App.jsx":"18a1fa0b00da","ui_kits/repocast/NewTrackSheet.jsx":"251c9f8d7513","ui_kits/repocast/NowPlayingSheet.jsx":"b452e31cd563","ui_kits/repocast/SettingsScreen.jsx":"7322adf7ee87","ui_kits/repocast/TracksScreen.jsx":"5ca84e41c0db","ui_kits/repocast/data.js":"7107830771dd"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.RepocastDesignSystem_a3bb12 = window.RepocastDesignSystem_a3bb12 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Small status pill. `tint` picks a system color; `style="tinted"` uses the
 * translucent treatment (colored text on light fill), `solid` is filled.
 * Used for track status (Ready / Generating / Failed) and source kind.
 */
function Badge({
  children,
  tint = "blue",
  variant = "tinted",
  icon,
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (icon && typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [icon, children]);
  const color = `var(--${tint})`;
  const isSolid = variant === "solid";
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
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
      ...style
    }
  }, rest), icon && /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: 12,
      height: 12
    }
  }), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Repocast / iOS-style button.
 * Variants map to Apple's button prominences: filled (.borderedProminent),
 * tinted (.bordered with tint), gray (.bordered), plain (.plain), and
 * destructive. Press feedback is an opacity dip + slight scale, like UIKit.
 */
function Button({
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
    small: {
      font: "var(--type-subheadline)",
      pad: "6px 14px",
      h: 32,
      gap: 6,
      icon: 16
    },
    medium: {
      font: "var(--type-callout)",
      pad: "9px 18px",
      h: 40,
      gap: 7,
      icon: 18
    },
    large: {
      font: "var(--type-headline)",
      pad: "14px 22px",
      h: 50,
      gap: 8,
      icon: 20
    }
  };
  const s = sizes[size] || sizes.medium;
  const palettes = {
    filled: {
      bg: "var(--tint)",
      color: "var(--text-on-tint)",
      pressBg: "var(--tint-pressed)"
    },
    tinted: {
      bg: "color-mix(in srgb, var(--tint) 15%, transparent)",
      color: "var(--tint)",
      pressBg: "color-mix(in srgb, var(--tint) 26%, transparent)"
    },
    gray: {
      bg: "var(--fill-tertiary)",
      color: "var(--text-primary)",
      pressBg: "var(--fill-secondary)"
    },
    plain: {
      bg: "transparent",
      color: "var(--tint)",
      pressBg: "transparent"
    },
    destructive: {
      bg: "color-mix(in srgb, var(--red) 15%, transparent)",
      color: "var(--red)",
      pressBg: "color-mix(in srgb, var(--red) 26%, transparent)"
    }
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
    ...style
  };
  const iconEl = icon ? /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: s.icon,
      height: s.icon,
      flex: "none"
    }
  }) : null;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: disabled,
    onClick: disabled ? undefined : onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: base
  }, rest), !iconTrailing && iconEl, children != null && /*#__PURE__*/React.createElement("span", null, children), iconTrailing && iconEl);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * iOS grouped container. `variant="grouped"` is the inset white card on a
 * gray grouped background (Settings/Form rows live inside it, divided by
 * hairlines). `variant="plain"` is a flat surface; `variant="elevated"` adds
 * a soft shadow for a floating tile. An optional `header`/`footer` render as
 * the small caption text above/below a grouped section.
 */
function Card({
  children,
  variant = "grouped",
  header,
  footer,
  padded = false,
  style,
  ...rest
}) {
  const surfaces = {
    grouped: {
      background: "var(--surface-card)",
      boxShadow: "none"
    },
    plain: {
      background: "var(--surface)",
      boxShadow: "none"
    },
    elevated: {
      background: "var(--surface-card)",
      boxShadow: "var(--shadow-md)"
    }
  };
  const s = surfaces[variant] || surfaces.grouped;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      ...style
    }
  }, rest), header && /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-footnote)",
      color: "var(--text-secondary)",
      textTransform: "uppercase",
      letterSpacing: "0.4px",
      padding: "0 16px 7px"
    }
  }, header), /*#__PURE__*/React.createElement("div", {
    style: {
      background: s.background,
      boxShadow: s.boxShadow,
      borderRadius: "var(--radius-md)",
      overflow: "hidden",
      padding: padded ? "var(--space-5)" : 0
    }
  }, children), footer && /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-footnote)",
      color: "var(--text-secondary)",
      padding: "7px 16px 0"
    }
  }, footer));
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Circular / square icon-only button — toolbar actions, transport controls.
 * Renders a Lucide glyph (SF Symbol substitute). `prominence="filled"` gives
 * the tinted-circle treatment (like the big play button on Now Playing).
 */
function IconButton({
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
  const sizes = {
    small: 32,
    medium: 44,
    large: 56
  };
  const glyph = {
    small: 18,
    medium: 22,
    large: 28
  };
  const dim = sizes[size] || sizes.medium;
  const palettes = {
    plain: {
      bg: "transparent",
      color: "var(--tint)"
    },
    tinted: {
      bg: "color-mix(in srgb, var(--tint) 15%, transparent)",
      color: "var(--tint)"
    },
    gray: {
      bg: "var(--fill-tertiary)",
      color: "var(--text-primary)"
    },
    filled: {
      bg: "var(--tint)",
      color: "var(--text-on-tint)"
    }
  };
  const p = palettes[prominence] || palettes.plain;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label,
    disabled: disabled,
    onClick: disabled ? undefined : onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
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
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: glyph[size] || glyph.medium,
      height: glyph[size] || glyph.medium
    }
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * iOS segmented control — the capsule of mutually-exclusive options used for
 * the playback-speed picker. A sliding white "thumb" highlights the selected
 * segment. Controlled via `value` (must match one option's `value`).
 */
function SegmentedControl({
  options = [],
  value,
  onChange,
  style,
  ...rest
}) {
  const idx = Math.max(0, options.findIndex(o => o.value === value));
  const n = options.length || 1;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: "relative",
      display: "flex",
      background: "var(--fill-tertiary)",
      borderRadius: "9px",
      padding: 2,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: 2,
      bottom: 2,
      left: `calc(${idx / n * 100}% + 2px)`,
      width: `calc(${100 / n}% - 4px)`,
      background: "var(--bg-tertiary)",
      borderRadius: "7px",
      boxShadow: "0 3px 8px rgba(0,0,0,0.12), 0 1px 1px rgba(0,0,0,0.04)",
      transition: "left var(--duration-base) var(--ease-standard)"
    }
  }), options.map(o => {
    const active = o.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: o.value,
      type: "button",
      onClick: () => onChange && onChange(o.value),
      style: {
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
        WebkitTapHighlightColor: "transparent"
      }
    }, o.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/forms/Slider.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * iOS slider. Continuous track with a white knob; filled portion uses the
 * tint. Optional `minIcon`/`maxIcon` (Lucide names) flank the track like the
 * tortoise/hare speech-rate slider. Controlled via `value` + `onChange`.
 */
function Slider({
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
  const setFromClientX = clientX => {
    const el = trackRef.current;
    if (!el || disabled) return;
    const rect = el.getBoundingClientRect();
    let p = (clientX - rect.left) / rect.width;
    p = Math.max(0, Math.min(1, p));
    let v = min + p * (max - min);
    if (step) v = Math.round(v / step) * step;
    onChange && onChange(v);
  };
  const trackEl = /*#__PURE__*/React.createElement("div", {
    ref: trackRef,
    onPointerDown: e => {
      if (disabled) return;
      setDragging(true);
      e.currentTarget.setPointerCapture(e.pointerId);
      setFromClientX(e.clientX);
    },
    onPointerMove: e => dragging && setFromClientX(e.clientX),
    onPointerUp: () => setDragging(false),
    style: {
      position: "relative",
      flex: 1,
      height: 28,
      display: "flex",
      alignItems: "center",
      cursor: disabled ? "default" : "pointer",
      touchAction: "none"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: 0,
      right: 0,
      height: 4,
      borderRadius: 2,
      background: "var(--fill)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: 0,
      width: `${pct * 100}%`,
      height: 4,
      borderRadius: 2,
      background: "var(--tint)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: `calc(${pct * 100}% - 14px)`,
      width: 28,
      height: 28,
      borderRadius: "50%",
      background: "#fff",
      boxShadow: "0 1px 3px rgba(0,0,0,0.18), 0 3px 8px rgba(0,0,0,0.12)",
      transform: dragging ? "scale(1.08)" : "scale(1)",
      transition: "transform var(--duration-fast) var(--ease-out)"
    }
  }));
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      opacity: disabled ? 0.5 : 1,
      ...style
    }
  }, rest), minIcon && /*#__PURE__*/React.createElement("i", {
    "data-lucide": minIcon,
    style: {
      width: 18,
      height: 18,
      color: "var(--text-secondary)",
      flex: "none"
    }
  }), trackEl, maxIcon && /*#__PURE__*/React.createElement("i", {
    "data-lucide": maxIcon,
    style: {
      width: 18,
      height: 18,
      color: "var(--text-secondary)",
      flex: "none"
    }
  }));
}
Object.assign(__ds_scope, { Slider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Slider.jsx", error: String((e && e.message) || e) }); }

// components/forms/TextField.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * iOS text field / editor. `multiline` renders the tall TextEditor used by
 * the New Track sheet. Styled as a rounded fill (good standalone) — inside a
 * grouped Form, pass `variant="plain"` so it sits flush in a ListRow.
 */
function TextField({
  value = "",
  onChange,
  placeholder,
  multiline = false,
  rows = 6,
  variant = "filled",
  disabled = false,
  style,
  ...rest
}) {
  const shared = {
    width: "100%",
    boxSizing: "border-box",
    font: "var(--type-body)",
    fontFamily: "var(--font-text)",
    color: "var(--text-primary)",
    background: variant === "plain" ? "transparent" : "var(--fill-tertiary)",
    border: "none",
    borderRadius: variant === "plain" ? 0 : "var(--radius-md)",
    padding: variant === "plain" ? 0 : "11px 14px",
    outline: "none",
    resize: "none",
    opacity: disabled ? 0.5 : 1,
    ...style
  };
  const props = {
    value,
    placeholder,
    disabled,
    onChange: e => onChange && onChange(e.target.value),
    style: shared,
    ...rest
  };
  return multiline ? /*#__PURE__*/React.createElement("textarea", _extends({
    rows: rows
  }, props)) : /*#__PURE__*/React.createElement("input", _extends({
    type: "text"
  }, props));
}
Object.assign(__ds_scope, { TextField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/TextField.jsx", error: String((e && e.message) || e) }); }

// components/forms/Toggle.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** iOS switch. Controlled via `checked` + `onChange`. */
function Toggle({
  checked = false,
  onChange,
  disabled = false,
  style,
  ...rest
}) {
  const on = !!checked;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": on,
    disabled: disabled,
    onClick: () => !disabled && onChange && onChange(!on),
    style: {
      width: 51,
      height: 31,
      flex: "none",
      borderRadius: "var(--radius-capsule)",
      border: "none",
      padding: 2,
      background: on ? "var(--green)" : "var(--fill)",
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? 0.5 : 1,
      transition: "background var(--duration-base) var(--ease-out)",
      display: "flex",
      alignItems: "center",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 27,
      height: 27,
      borderRadius: "50%",
      background: "#fff",
      boxShadow: "0 3px 8px rgba(0,0,0,0.15), 0 1px 1px rgba(0,0,0,0.16)",
      transform: on ? "translateX(20px)" : "translateX(0)",
      transition: "transform var(--duration-base) var(--ease-standard)"
    }
  }));
}
Object.assign(__ds_scope, { Toggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Toggle.jsx", error: String((e && e.message) || e) }); }

// components/lists/ListRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * One row in an iOS grouped list / Form. Supports a leading icon (Lucide name
 * or any node), title + optional subtitle, a trailing `value` string, and an
 * accessory (disclosure chevron, checkmark, or a custom node like a Toggle).
 * Rows divide with a hairline separator; the last row omits it. Tappable rows
 * (with `onClick`) show a system press highlight.
 */
function ListRow({
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
  const leading = icon == null ? null : typeof icon === "string" ? iconBg ? /*#__PURE__*/React.createElement("span", {
    style: {
      width: 29,
      height: 29,
      borderRadius: 7,
      background: iconBg,
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      flex: "none"
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: 18,
      height: 18,
      color: "#fff"
    }
  })) : /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: 22,
      height: 22,
      color: iconColor,
      flex: "none"
    }
  }) : icon;
  let accessoryEl = accessory;
  if (accessory === "disclosure") {
    accessoryEl = /*#__PURE__*/React.createElement("i", {
      "data-lucide": "chevron-right",
      style: {
        width: 18,
        height: 18,
        color: "var(--label-tertiary)"
      }
    });
  } else if (accessory === "checkmark") {
    accessoryEl = /*#__PURE__*/React.createElement("i", {
      "data-lucide": "check",
      style: {
        width: 20,
        height: 20,
        color: "var(--tint)"
      }
    });
  }
  React.useEffect(() => {
    if (accessory === "disclosure" || accessory === "checkmark") {
      if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
    }
  }, [accessory]);
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onClick,
    onPointerDown: () => tappable && setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
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
      ...style
    }
  }, rest), leading, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-body)",
      color: destructive ? "var(--red)" : "var(--text-primary)",
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap"
    }
  }, title), subtitle != null && /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-footnote)",
      color: "var(--text-secondary)",
      marginTop: 1,
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap"
    }
  }, subtitle)), value != null && /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--type-body)",
      color: "var(--text-secondary)",
      flex: "none",
      maxWidth: "55%",
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap"
    }
  }, value), trailing, accessoryEl && /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      flex: "none"
    }
  }, accessoryEl));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/lists/SectionHeader.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Grouped-list section header — small uppercase caption above a Card. */
function SectionHeader({
  children,
  action,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "flex",
      alignItems: "flex-end",
      justifyContent: "space-between",
      padding: "0 16px 7px",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--type-footnote)",
      color: "var(--text-secondary)",
      textTransform: "uppercase",
      letterSpacing: "0.4px"
    }
  }, children), action);
}
Object.assign(__ds_scope, { SectionHeader });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/SectionHeader.jsx", error: String((e && e.message) || e) }); }

// components/media/MiniPlayer.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Compact transport bar that rides above the tab bar (Apple Podcasts pattern).
 * Frosted material, leading waveform glyph, title + "current / total" time,
 * and a play/pause button. Tap the bar (not the button) to open Now Playing.
 */
function MiniPlayer({
  title = "Nothing Playing",
  currentTime = "0:00",
  duration = "0:00",
  playing = false,
  onTogglePlay,
  onOpen,
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [playing]);
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onOpen,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      padding: "9px 14px",
      background: "var(--material-regular)",
      backdropFilter: "var(--blur-regular)",
      WebkitBackdropFilter: "var(--blur-regular)",
      boxShadow: "inset 0 0.5px 0 var(--separator)",
      cursor: onOpen ? "pointer" : "default",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 38,
      height: 38,
      borderRadius: "var(--radius-sm)",
      background: "color-mix(in srgb, var(--tint) 14%, transparent)",
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      flex: "none"
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "audio-lines",
    style: {
      width: 21,
      height: 21,
      color: "var(--tint)"
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-subheadline)",
      fontWeight: 500,
      color: "var(--text-primary)",
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap"
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-caption-2)",
      color: "var(--text-secondary)",
      fontVariantNumeric: "tabular-nums",
      marginTop: 1
    }
  }, currentTime, " / ", duration)), /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": playing ? "Pause" : "Play",
    onClick: e => {
      e.stopPropagation();
      onTogglePlay && onTogglePlay();
    },
    style: {
      border: "none",
      background: "transparent",
      color: "var(--text-primary)",
      cursor: "pointer",
      display: "inline-flex",
      padding: 6,
      flex: "none",
      WebkitTapHighlightColor: "transparent"
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": playing ? "pause" : "play",
    style: {
      width: 24,
      height: 24,
      fill: "currentColor"
    }
  })));
}
Object.assign(__ds_scope, { MiniPlayer });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/MiniPlayer.jsx", error: String((e && e.message) || e) }); }

// components/navigation/NavBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * iOS navigation bar. `title` renders inline (centered) with a frosted
 * material background and a bottom hairline; `largeTitle` renders the big
 * left-aligned title below it (the scrolled-to-top state). `leading` and
 * `trailing` host nav actions (typically `<Button variant="plain">`).
 */
function NavBar({
  title,
  largeTitle = false,
  leading,
  trailing,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      background: "var(--material-regular)",
      backdropFilter: "var(--blur-regular)",
      WebkitBackdropFilter: "var(--blur-regular)",
      boxShadow: "inset 0 -0.5px 0 var(--separator)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      height: 44,
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      padding: "0 8px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      minWidth: 44,
      justifyContent: "flex-start"
    }
  }, leading), !largeTitle && /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: "50%",
      transform: "translateX(-50%)",
      font: "var(--type-headline)",
      color: "var(--text-primary)",
      maxWidth: "60%",
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap"
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 4,
      minWidth: 44,
      justifyContent: "flex-end"
    }
  }, trailing)), largeTitle && /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "0 16px 8px",
      font: "var(--type-large-title)",
      letterSpacing: "var(--tracking-tight)",
      color: "var(--text-primary)"
    }
  }, title));
}
Object.assign(__ds_scope, { NavBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/NavBar.jsx", error: String((e && e.message) || e) }); }

// components/navigation/TabBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * iOS tab bar — frosted material bottom bar. `items` is an array of
 * { value, label, icon (Lucide name) }. The active tab is tinted; others use
 * the muted label color. Controlled via `value` + `onChange`.
 */
function TabBar({
  items = [],
  value,
  onChange,
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (typeof window !== "undefined" && window.lucide) window.lucide.createIcons();
  }, [items]);
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "flex",
      background: "var(--material-regular)",
      backdropFilter: "var(--blur-regular)",
      WebkitBackdropFilter: "var(--blur-regular)",
      boxShadow: "inset 0 0.5px 0 var(--separator)",
      padding: "8px 0 10px",
      ...style
    }
  }, rest), items.map(it => {
    const active = it.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.value,
      type: "button",
      onClick: () => onChange && onChange(it.value),
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 3,
        border: "none",
        background: "transparent",
        color: active ? "var(--tint)" : "var(--text-secondary)",
        cursor: "pointer",
        WebkitTapHighlightColor: "transparent"
      }
    }, /*#__PURE__*/React.createElement("i", {
      "data-lucide": it.icon,
      style: {
        width: 25,
        height: 25
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        font: "var(--type-caption-2)",
        fontWeight: 500
      }
    }, it.label));
  }));
}
Object.assign(__ds_scope, { TabBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/TabBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/repocast/App.jsx
try { (() => {
// Repocast app shell — phone screen with status bar, tab switching, persistent
// mini-player + tab bar, and the New Track / Now Playing sheets.
function RepocastApp() {
  const {
    TabBar,
    MiniPlayer
  } = window.RepocastDesignSystem_a3bb12;
  const [tab, setTab] = React.useState("tracks");
  const [tracks, setTracks] = React.useState(window.RC_TRACKS);
  const [playing, setPlaying] = React.useState(false);
  const [current, setCurrent] = React.useState(null);
  const [sheet, setSheet] = React.useState(null); // "new" | "now" | null

  React.useEffect(() => {
    window.lucide && window.lucide.createIcons();
  });
  const play = t => {
    setCurrent(t);
    setPlaying(true);
    setSheet("now");
  };
  const addTrack = ({
    title
  }) => {
    const t = {
      id: "n" + Date.now(),
      title,
      source: "Freeform text",
      kind: "freeform",
      status: "ready",
      duration: "0:48",
      durSec: 48
    };
    setTracks(prev => [t, ...prev]);
    setSheet(null);
  };
  const cycle = dir => {
    const ready = tracks.filter(t => t.status === "ready");
    if (!current || ready.length === 0) return;
    let i = ready.findIndex(t => t.id === current.id);
    i = (i + dir + ready.length) % ready.length;
    setCurrent(ready[i]);
    setPlaying(true);
  };
  const fmtNow = () => {
    const d = new Date();
    return `${(d.getHours() + 11) % 12 + 1}:${String(d.getMinutes()).padStart(2, "0")}`;
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "rc-phone"
  }, /*#__PURE__*/React.createElement("div", {
    className: "rc-statusbar"
  }, /*#__PURE__*/React.createElement("span", {
    className: "rc-time"
  }, fmtNow()), /*#__PURE__*/React.createElement("span", {
    className: "rc-status-icons"
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "signal",
    style: {
      width: 17,
      height: 17
    }
  }), /*#__PURE__*/React.createElement("i", {
    "data-lucide": "wifi",
    style: {
      width: 17,
      height: 17
    }
  }), /*#__PURE__*/React.createElement("i", {
    "data-lucide": "battery-full",
    style: {
      width: 22,
      height: 22
    }
  }))), /*#__PURE__*/React.createElement("div", {
    className: "rc-screen"
  }, tab === "tracks" ? /*#__PURE__*/React.createElement(window.TracksScreen, {
    tracks: tracks,
    onPlay: play,
    onNew: () => setSheet("new"),
    playingId: playing ? current && current.id : null
  }) : /*#__PURE__*/React.createElement(window.SettingsScreen, {
    rate: 0.55,
    onRate: () => {},
    ai: true,
    onAi: () => {}
  })), /*#__PURE__*/React.createElement("div", {
    className: "rc-bottom"
  }, current && /*#__PURE__*/React.createElement(MiniPlayer, {
    title: current.title,
    currentTime: "1:23",
    duration: current.duration,
    playing: playing,
    onTogglePlay: () => setPlaying(p => !p),
    onOpen: () => setSheet("now")
  }), /*#__PURE__*/React.createElement(TabBar, {
    value: tab,
    onChange: setTab,
    items: [{
      value: "tracks",
      label: "Tracks",
      icon: "audio-lines"
    }, {
      value: "settings",
      label: "Settings",
      icon: "settings"
    }]
  })), /*#__PURE__*/React.createElement("div", {
    className: "rc-scrim" + (sheet ? " show" : ""),
    onClick: () => setSheet(null)
  }), /*#__PURE__*/React.createElement("div", {
    className: "rc-sheet" + (sheet === "new" ? " up" : "")
  }, sheet === "new" && /*#__PURE__*/React.createElement(window.NewTrackSheet, {
    onCancel: () => setSheet(null),
    onGenerate: addTrack
  })), /*#__PURE__*/React.createElement("div", {
    className: "rc-sheet rc-sheet-full" + (sheet === "now" ? " up" : "")
  }, sheet === "now" && /*#__PURE__*/React.createElement(window.NowPlayingSheet, {
    track: current,
    playing: playing,
    onTogglePlay: () => setPlaying(p => !p),
    onClose: () => setSheet(null),
    onPrev: () => cycle(-1),
    onNext: () => cycle(1)
  })));
}
window.RepocastApp = RepocastApp;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/repocast/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/repocast/NewTrackSheet.jsx
try { (() => {
// New Track sheet — paste text, generate a track. Mirrors NewTrackView.swift:
// a grouped Form with a title field, a tall text editor, and a help note.
function NewTrackSheet({
  onCancel,
  onGenerate
}) {
  const {
    NavBar,
    Card,
    SectionHeader,
    TextField,
    Button
  } = window.RepocastDesignSystem_a3bb12;
  const [title, setTitle] = React.useState("");
  const [text, setText] = React.useState("");
  const [generating, setGenerating] = React.useState(false);
  const canGen = text.trim().length > 0 && !generating;
  React.useEffect(() => {
    window.lucide && window.lucide.createIcons();
  });
  const generate = () => {
    if (!canGen) return;
    setGenerating(true);
    setTimeout(() => onGenerate({
      title: title.trim() || "Untitled",
      text
    }), 900);
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: "100%",
      display: "flex",
      flexDirection: "column",
      background: "var(--bg-grouped)",
      position: "relative"
    }
  }, /*#__PURE__*/React.createElement(NavBar, {
    title: "New Track",
    leading: /*#__PURE__*/React.createElement(Button, {
      variant: "plain",
      onClick: onCancel
    }, "Cancel"),
    trailing: /*#__PURE__*/React.createElement(Button, {
      variant: "plain",
      onClick: generate,
      disabled: !canGen,
      style: {
        fontWeight: 600
      }
    }, "Generate")
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: "auto",
      padding: "8px 16px 16px",
      display: "flex",
      flexDirection: "column",
      gap: 18
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(SectionHeader, null, "Title"), /*#__PURE__*/React.createElement(Card, {
    variant: "grouped",
    padded: true
  }, /*#__PURE__*/React.createElement(TextField, {
    variant: "plain",
    value: title,
    onChange: setTitle,
    placeholder: "Optional"
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(SectionHeader, null, "Text to Speak"), /*#__PURE__*/React.createElement(Card, {
    variant: "grouped",
    padded: true
  }, /*#__PURE__*/React.createElement(TextField, {
    variant: "plain",
    multiline: true,
    rows: 7,
    value: text,
    onChange: setText,
    placeholder: "Paste code or Markdown\u2026"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-footnote)",
      color: "var(--text-secondary)",
      padding: "0 4px"
    }
  }, "On-device summarization arrives in the next phase \u2014 for now this reads your text aloud verbatim.")), generating && /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      background: "color-mix(in srgb, var(--bg) 30%, transparent)",
      backdropFilter: "blur(2px)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 12,
      padding: 24,
      borderRadius: "var(--radius-lg)",
      background: "var(--material-thick)",
      backdropFilter: "var(--blur-thick)",
      boxShadow: "var(--shadow-lg)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "rc-spinner"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--type-subheadline)",
      color: "var(--text-primary)"
    }
  }, "Generating\u2026"))));
}
window.NewTrackSheet = NewTrackSheet;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/repocast/NewTrackSheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/repocast/NowPlayingSheet.jsx
try { (() => {
// Now Playing sheet — full-screen transport: big tinted waveform, title,
// scrubber, transport controls, segmented speed picker. Mirrors NowPlayingView.
function NowPlayingSheet({
  track,
  playing,
  onTogglePlay,
  onClose,
  onPrev,
  onNext
}) {
  const {
    IconButton,
    SegmentedControl
  } = window.RepocastDesignSystem_a3bb12;
  const [progress, setProgress] = React.useState(0.18);
  const [speed, setSpeed] = React.useState(1);
  const dur = track ? track.durSec : 0;
  React.useEffect(() => {
    window.lucide && window.lucide.createIcons();
  });

  // Advance the scrubber while playing (cosmetic).
  React.useEffect(() => {
    if (!playing) return;
    const id = setInterval(() => setProgress(p => p >= 1 ? 0 : p + speed * 0.6 / Math.max(dur, 1)), 600);
    return () => clearInterval(id);
  }, [playing, speed, dur]);
  const fmt = s => {
    s = Math.max(0, Math.round(s));
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: "100%",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      padding: "10px 28px 28px",
      background: "var(--bg)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 5,
      borderRadius: 3,
      background: "var(--label-tertiary)",
      margin: "0 0 8px"
    },
    onClick: onClose
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement("div", {
    className: playing ? "rc-pulse" : "",
    style: {
      width: 168,
      height: 168,
      borderRadius: "50%",
      background: "color-mix(in srgb, var(--tint) 14%, transparent)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      marginBottom: 28
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "audio-lines",
    style: {
      width: 88,
      height: 88,
      color: "var(--tint)"
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-title-2)",
      color: "var(--text-primary)",
      textAlign: "center",
      marginBottom: 24,
      maxWidth: "100%",
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap"
    }
  }, track ? track.title : "Nothing Playing"), /*#__PURE__*/React.createElement("div", {
    style: {
      width: "100%",
      marginBottom: 24
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      height: 6,
      borderRadius: 3,
      background: "var(--fill)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: 0,
      top: 0,
      bottom: 0,
      width: `${progress * 100}%`,
      borderRadius: 3,
      background: "var(--tint)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: "50%",
      left: `calc(${progress * 100}% - 6px)`,
      width: 12,
      height: 12,
      borderRadius: "50%",
      background: "var(--text-secondary)",
      transform: "translateY(-50%)"
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      marginTop: 8,
      font: "var(--type-caption-1)",
      color: "var(--text-secondary)",
      fontVariantNumeric: "tabular-nums"
    }
  }, /*#__PURE__*/React.createElement("span", null, fmt(progress * dur)), /*#__PURE__*/React.createElement("span", null, "-", fmt(dur - progress * dur)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 36,
      marginBottom: 28
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "skip-back",
    label: "Previous",
    size: "medium",
    onClick: onPrev
  }), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onTogglePlay,
    "aria-label": playing ? "Pause" : "Play",
    style: {
      width: 74,
      height: 74,
      borderRadius: "50%",
      border: "none",
      background: "color-mix(in srgb, var(--tint) 14%, transparent)",
      color: "var(--tint)",
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      cursor: "pointer"
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": playing ? "pause" : "play",
    style: {
      width: 36,
      height: 36,
      fill: "currentColor"
    }
  })), /*#__PURE__*/React.createElement(IconButton, {
    icon: "skip-forward",
    label: "Next",
    size: "medium",
    onClick: onNext
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      width: "100%"
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    value: speed,
    onChange: setSpeed,
    options: [{
      label: "0.75×",
      value: 0.75
    }, {
      label: "1×",
      value: 1
    }, {
      label: "1.25×",
      value: 1.25
    }, {
      label: "1.5×",
      value: 1.5
    }, {
      label: "2×",
      value: 2
    }]
  })));
}
window.NowPlayingSheet = NowPlayingSheet;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/repocast/NowPlayingSheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/repocast/SettingsScreen.jsx
try { (() => {
// Settings screen — grouped Form: voice, speech rate, on-device AI, about.
function SettingsScreen({
  rate,
  onRate,
  ai,
  onAi
}) {
  const {
    NavBar,
    Card,
    ListRow,
    SectionHeader,
    Slider,
    Toggle
  } = window.RepocastDesignSystem_a3bb12;
  React.useEffect(() => {
    window.lucide && window.lucide.createIcons();
  });
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: "100%",
      display: "flex",
      flexDirection: "column",
      background: "var(--bg-grouped)"
    }
  }, /*#__PURE__*/React.createElement(NavBar, {
    title: "Settings",
    largeTitle: true
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: "auto",
      padding: "8px 16px 16px",
      display: "flex",
      flexDirection: "column",
      gap: 18
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(SectionHeader, null, "Voice"), /*#__PURE__*/React.createElement(Card, {
    variant: "grouped"
  }, /*#__PURE__*/React.createElement(ListRow, {
    icon: "mic",
    iconBg: "var(--purple)",
    title: "Voice",
    value: "System Default",
    accessory: "disclosure",
    onClick: () => {}
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: "gauge",
    iconBg: "var(--blue)",
    title: "Speech Rate",
    last: true,
    trailing: /*#__PURE__*/React.createElement("div", {
      style: {
        width: 150
      }
    }, /*#__PURE__*/React.createElement(Slider, {
      value: rate,
      min: 0,
      max: 1,
      onChange: onRate,
      minIcon: "turtle",
      maxIcon: "rabbit"
    }))
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(SectionHeader, null, "On-Device AI"), /*#__PURE__*/React.createElement(Card, {
    variant: "grouped",
    footer: "Summaries are generated on-device with Apple Intelligence. Nothing is sent to a server."
  }, /*#__PURE__*/React.createElement(ListRow, {
    icon: "sparkles",
    iconBg: "var(--green)",
    title: "Apple Intelligence",
    subtitle: ai ? "Summarize code" : "Read verbatim",
    trailing: /*#__PURE__*/React.createElement(Toggle, {
      checked: ai,
      onChange: onAi
    }),
    last: true
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(SectionHeader, null, "About"), /*#__PURE__*/React.createElement(Card, {
    variant: "grouped"
  }, /*#__PURE__*/React.createElement(ListRow, {
    icon: "info",
    iconBg: "var(--gray)",
    title: "App",
    value: "Repocast"
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: "git-branch",
    iconBg: "var(--orange)",
    title: "Version",
    value: "1.0 (Phase 1)",
    last: true
  })))));
}
window.SettingsScreen = SettingsScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/repocast/SettingsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/repocast/TracksScreen.jsx
try { (() => {
// Tracks screen — the app's home. Large-title nav bar, grouped list of tracks,
// or the ContentUnavailableView empty state when there are none.
function TracksScreen({
  tracks,
  onPlay,
  onNew,
  playingId
}) {
  const {
    NavBar,
    IconButton,
    Card,
    ListRow,
    Badge
  } = window.RepocastDesignSystem_a3bb12;
  const empty = tracks.length === 0;
  React.useEffect(() => {
    window.lucide && window.lucide.createIcons();
  });
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: "100%",
      display: "flex",
      flexDirection: "column",
      background: "var(--bg-grouped)"
    }
  }, /*#__PURE__*/React.createElement(NavBar, {
    title: "Tracks",
    largeTitle: true,
    trailing: /*#__PURE__*/React.createElement(IconButton, {
      icon: "plus",
      label: "New Track",
      onClick: onNew
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: "auto",
      padding: empty ? 0 : "8px 16px 16px"
    }
  }, empty ? /*#__PURE__*/React.createElement("div", {
    style: {
      height: "100%",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      gap: 10,
      padding: 32,
      textAlign: "center"
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "audio-lines",
    style: {
      width: 52,
      height: 52,
      color: "var(--label-tertiary)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-title-3)",
      color: "var(--text-primary)"
    }
  }, "No Tracks Yet"), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--type-subheadline)",
      color: "var(--text-secondary)",
      maxWidth: 260
    }
  }, "Tap + to turn text into audio you can play anywhere.")) : /*#__PURE__*/React.createElement(Card, {
    variant: "grouped"
  }, tracks.map((t, i) => {
    const b = window.RC_STATUS_BADGE[t.status];
    const isPlaying = t.id === playingId;
    return /*#__PURE__*/React.createElement(ListRow, {
      key: t.id,
      icon: isPlaying ? "audio-lines" : window.RC_KIND_ICON[t.kind],
      iconColor: isPlaying ? "var(--tint)" : "var(--text-secondary)",
      title: t.title,
      subtitle: t.source,
      trailing: b ? /*#__PURE__*/React.createElement(Badge, {
        tint: b.tint,
        icon: b.icon
      }, b.label) : /*#__PURE__*/React.createElement("span", {
        style: {
          font: "var(--type-subheadline)",
          color: "var(--text-secondary)",
          fontVariantNumeric: "tabular-nums"
        }
      }, t.duration),
      accessory: t.status === "ready" ? /*#__PURE__*/React.createElement("i", {
        "data-lucide": "circle-play",
        style: {
          width: 22,
          height: 22,
          color: "var(--label-tertiary)"
        }
      }) : null,
      onClick: t.status === "ready" ? () => onPlay(t) : undefined,
      last: i === tracks.length - 1
    });
  }))));
}
window.TracksScreen = TracksScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/repocast/TracksScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/repocast/data.js
try { (() => {
// Sample track data for the Repocast UI kit (fake, cosmetic).
window.RC_TRACKS = [{
  id: "t1",
  title: "README.md",
  source: "repocast/README.md",
  kind: "markdown",
  status: "ready",
  duration: "3:42",
  durSec: 222
}, {
  id: "t2",
  title: "AudioPlayerService.swift",
  source: "Sources/…/AudioPlayerService.swift",
  kind: "code",
  status: "ready",
  duration: "12:48",
  durSec: 768
}, {
  id: "t3",
  title: "DataStack.swift",
  source: "Sources/…/Models/DataStack.swift",
  kind: "code",
  status: "generating",
  duration: "",
  durSec: 0
}, {
  id: "t4",
  title: "Latest changes · main",
  source: "5 merged PRs, 12 commits",
  kind: "changes",
  status: "ready",
  duration: "6:10",
  durSec: 370
}, {
  id: "t5",
  title: "Old draft",
  source: "Freeform text",
  kind: "freeform",
  status: "failed",
  duration: "",
  durSec: 0
}];
window.RC_STATUS_BADGE = {
  ready: null,
  generating: {
    tint: "orange",
    icon: "hourglass",
    label: "Generating"
  },
  failed: {
    tint: "red",
    icon: "triangle-alert",
    label: "Failed"
  },
  pending: {
    tint: "gray",
    icon: "hourglass",
    label: "Pending"
  }
};
window.RC_KIND_ICON = {
  code: "file-code",
  markdown: "file-text",
  changes: "git-merge",
  freeform: "type"
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/repocast/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Slider = __ds_scope.Slider;

__ds_ns.TextField = __ds_scope.TextField;

__ds_ns.Toggle = __ds_scope.Toggle;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.SectionHeader = __ds_scope.SectionHeader;

__ds_ns.MiniPlayer = __ds_scope.MiniPlayer;

__ds_ns.NavBar = __ds_scope.NavBar;

__ds_ns.TabBar = __ds_scope.TabBar;

})();
