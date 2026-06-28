// Settings screen — grouped Form: voice, speech rate, on-device AI, about.
function SettingsScreen({ rate, onRate, ai, onAi }) {
  const { NavBar, Card, ListRow, SectionHeader, Slider, Toggle } = window.RepocastDesignSystem_a3bb12;
  React.useEffect(() => { window.lucide && window.lucide.createIcons(); });

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
      <NavBar title="Settings" largeTitle />
      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px", display: "flex", flexDirection: "column", gap: 18 }}>
        <div>
          <SectionHeader>Voice</SectionHeader>
          <Card variant="grouped">
            <ListRow icon="mic" iconBg="var(--purple)" title="Voice" value="System Default" accessory="disclosure" onClick={() => {}} />
            <ListRow icon="gauge" iconBg="var(--blue)" title="Speech Rate" last
              trailing={<div style={{ width: 150 }}><Slider value={rate} min={0} max={1} onChange={onRate} minIcon="turtle" maxIcon="rabbit" /></div>} />
          </Card>
        </div>
        <div>
          <SectionHeader>On-Device AI</SectionHeader>
          <Card variant="grouped" footer="Summaries are generated on-device with Apple Intelligence. Nothing is sent to a server.">
            <ListRow icon="sparkles" iconBg="var(--green)" title="Apple Intelligence" subtitle={ai ? "Summarize code" : "Read verbatim"}
              trailing={<Toggle checked={ai} onChange={onAi} />} last />
          </Card>
        </div>
        <div>
          <SectionHeader>About</SectionHeader>
          <Card variant="grouped">
            <ListRow icon="info" iconBg="var(--gray)" title="App" value="Repocast" />
            <ListRow icon="git-branch" iconBg="var(--orange)" title="Version" value="1.0 (Phase 1)" last />
          </Card>
        </div>
      </div>
    </div>
  );
}
window.SettingsScreen = SettingsScreen;
