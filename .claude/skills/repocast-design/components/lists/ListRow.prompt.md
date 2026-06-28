A single row in an iOS grouped list / Form. Compose rows inside a `Card variant="grouped"`; set `last` on the final row to drop its hairline.

```jsx
<Card variant="grouped" header="Voice">
  <ListRow icon="mic" iconBg="var(--purple)" title="Voice" value="System Default" accessory="disclosure" onClick={pick} />
  <ListRow title="Speech Rate" trailing={<Slider value={r} onChange={setR} style={{width:160}} />} last />
</Card>
```

- **icon**: Lucide name (bare, tinted) or pass `iconBg` for the rounded color-tile Settings look. Can also be any node.
- **accessory**: `"disclosure"` chevron, `"checkmark"`, or a custom node (a `Toggle`, a `Badge`).
- **value**: right-aligned secondary text. **destructive**: red title (Delete row).
