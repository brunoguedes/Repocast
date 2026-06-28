Icon-only button for toolbar and transport actions; renders a Lucide glyph (SF Symbol substitute). Always pass `label` for accessibility.

```jsx
<IconButton icon="plus" label="New Track" onClick={add} />
<IconButton icon="skip-back" label="Previous" size="large" />
<IconButton icon="play" prominence="filled" size="large" label="Play" />
```

- **size**: `small` 32 · `medium` 44 (default hit target) · `large` 56.
- **prominence**: `plain` (tint glyph, no bg) · `tinted` · `gray` · `filled` (tinted circle).
- **shape**: `circle` (default) or `rounded`. Requires Lucide loaded on the page.
