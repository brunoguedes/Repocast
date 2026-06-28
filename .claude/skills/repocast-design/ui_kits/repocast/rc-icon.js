// React-owned Lucide icon. Renders the SVG via innerHTML inside a span that
// React manages, so state-driven icon changes (checkboxes, status) never fight
// React's reconciler the way a global lucide.createIcons() DOM-swap does.
function RCIcon({ name, size = 20, color, fill, strokeWidth, style }) {
  const ref = React.useRef(null);
  React.useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.innerHTML = '<i data-lucide="' + name + '"></i>';
    try { window.lucide && window.lucide.createIcons(); } catch (e) {}
    const svg = el.querySelector("svg");
    if (svg) {
      const s = typeof size === "number" ? size + "px" : size;
      svg.style.width = s;
      svg.style.height = s;
      svg.style.display = "block";
      if (color) svg.style.color = color;
      if (fill) svg.setAttribute("fill", fill);
      if (strokeWidth) svg.setAttribute("stroke-width", strokeWidth);
    }
  }, [name, size, color, fill, strokeWidth]);
  return React.createElement("span", {
    ref,
    style: { display: "inline-flex", flex: "none", lineHeight: 0, ...style },
  });
}
window.RCIcon = RCIcon;
