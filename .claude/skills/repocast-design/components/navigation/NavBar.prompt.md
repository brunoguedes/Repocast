Frosted iOS navigation bar. Use `largeTitle` for the scrolled-to-top big-title state; put nav actions in `leading`/`trailing` (usually `<Button variant="plain">`).

```jsx
<NavBar title="Tracks" largeTitle trailing={<IconButton icon="plus" label="New" />} />
<NavBar title="New Track" leading={<Button variant="plain">Cancel</Button>} trailing={<Button variant="plain">Generate</Button>} />
```
