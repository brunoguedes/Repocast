iOS grouped container — wrap `ListRow`s for the inset Settings/Form card look, or use `elevated` for a floating tile. `header`/`footer` render the small caption text around a grouped section.

```jsx
<Card variant="grouped" header="Voice" footer="Used for new tracks.">
  <ListRow title="Voice" value="System Default" accessory="disclosure" />
  <ListRow title="Speech Rate" value="Default" />
</Card>
```

- **variant**: `grouped` (inset white card) · `plain` (flat) · `elevated` (soft shadow).
- Leave `padded` off when packing `ListRow`s (they own their padding); turn it on for free-form content.
