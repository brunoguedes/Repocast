Repocast/iOS button — use for any tappable action; pick the variant by prominence (`filled` primary, `tinted`/`gray` secondary, `plain` for nav-bar text actions, `destructive` for delete).

```jsx
<Button variant="filled" size="large" fullWidth onClick={generate}>Generate</Button>
<Button variant="plain" onClick={cancel}>Cancel</Button>
<Button variant="tinted" icon="circle-play">Play All</Button>
<Button variant="destructive" icon="trash-2">Delete</Button>
```

- **variant**: `filled` (system-blue, white text) · `tinted` (translucent tint) · `gray` (neutral fill) · `plain` (text-only, used in nav bars) · `destructive` (red).
- **size**: `small` 32 · `medium` 40 · `large` 50 (use large + `fullWidth` for primary CTAs).
- **shape**: `rounded` (continuous 14px) or `capsule`.
- **icon**: a Lucide name (SF Symbol substitute); `iconTrailing` to place it after the label. Requires Lucide loaded on the page.
- Press = opacity dip + slight scale; plain just dims.
