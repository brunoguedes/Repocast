iOS slider with a tint-filled track and white knob. Pass `minIcon`/`maxIcon` (Lucide names) to flank it like the tortoise/hare speech-rate control.

```jsx
<Slider value={rate} min={0} max={1} onChange={setRate} minIcon="turtle" maxIcon="rabbit" />
```
