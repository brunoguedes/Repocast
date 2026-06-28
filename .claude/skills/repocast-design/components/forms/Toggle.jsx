import React from "react";

/** iOS switch. Controlled via `checked` + `onChange`. */
export function Toggle({ checked = false, onChange, disabled = false, style, ...rest }) {
  const on = !!checked;
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      disabled={disabled}
      onClick={() => !disabled && onChange && onChange(!on)}
      style={{
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
        ...style,
      }}
      {...rest}
    >
      <span
        style={{
          width: 27,
          height: 27,
          borderRadius: "50%",
          background: "#fff",
          boxShadow: "0 3px 8px rgba(0,0,0,0.15), 0 1px 1px rgba(0,0,0,0.16)",
          transform: on ? "translateX(20px)" : "translateX(0)",
          transition: "transform var(--duration-base) var(--ease-standard)",
        }}
      />
    </button>
  );
}
