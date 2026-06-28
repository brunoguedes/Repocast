import React from "react";

/**
 * iOS text field / editor. `multiline` renders the tall TextEditor used by
 * the New Track sheet. Styled as a rounded fill (good standalone) — inside a
 * grouped Form, pass `variant="plain"` so it sits flush in a ListRow.
 */
export function TextField({
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
    ...style,
  };

  const props = {
    value,
    placeholder,
    disabled,
    onChange: (e) => onChange && onChange(e.target.value),
    style: shared,
    ...rest,
  };

  return multiline ? (
    <textarea rows={rows} {...props} />
  ) : (
    <input type="text" {...props} />
  );
}
