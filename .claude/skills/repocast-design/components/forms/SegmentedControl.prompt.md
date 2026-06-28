iOS segmented control — mutually-exclusive options in a capsule with a sliding white thumb. Used for the playback-speed picker.

```jsx
<SegmentedControl
  value={rate}
  onChange={setRate}
  options={[
    { label: "0.75×", value: 0.75 },
    { label: "1×", value: 1 },
    { label: "1.5×", value: 1.5 },
    { label: "2×", value: 2 },
  ]}
/>
```

Keep labels short (2–4 segments works best).
