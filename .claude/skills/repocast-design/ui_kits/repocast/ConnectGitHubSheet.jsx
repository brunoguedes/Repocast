// Connect GitHub sheet — mirrors ConnectGitHubView: a Form with a secure token
// field, explanatory footer, Cancel / Connect, and a "Connecting…" overlay.
function ConnectGitHubSheet({ onCancel, onConnect }) {
  const { NavBar, Card, SectionHeader, TextField, Button } = window.RepocastDesignSystem_a3bb12;
  const [token, setToken] = React.useState("");
  const [connecting, setConnecting] = React.useState(false);
  const canConnect = token.trim().length > 0 && !connecting;

  const connect = () => {
    if (!canConnect) return;
    setConnecting(true);
    setTimeout(onConnect, 900);
  };

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)", position: "relative" }}>
      <NavBar title="Connect GitHub"
        leading={<Button variant="plain" onClick={onCancel}>Cancel</Button>}
        trailing={<Button variant="plain" onClick={connect} disabled={!canConnect} style={{ fontWeight: 600 }}>Connect</Button>} />
      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px" }}>
        <SectionHeader>GitHub Token</SectionHeader>
        <Card variant="grouped" padded>
          <TextField variant="plain" value={token ? "•".repeat(token.length) : ""} onChange={(v) => setToken(v.replace(/•/g, ""))} placeholder="Personal access token" />
        </Card>
        <div style={{ font: "var(--type-footnote)", color: "var(--text-secondary)", padding: "8px 4px 0" }}>
          Create a fine-grained token at github.com/settings/tokens with read-only access to repository contents. It's kept in your device Keychain and only ever sent to GitHub.
        </div>
      </div>
      {connecting && (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "color-mix(in srgb, var(--bg) 30%, transparent)" }}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, padding: 24, borderRadius: "var(--radius-lg)", background: "var(--material-thick)", backdropFilter: "var(--blur-thick)", boxShadow: "var(--shadow-lg)" }}>
            <span className="rc-spinner" />
            <span style={{ font: "var(--type-subheadline)", color: "var(--text-primary)" }}>Connecting…</span>
          </div>
        </div>
      )}
    </div>
  );
}
window.ConnectGitHubSheet = ConnectGitHubSheet;
