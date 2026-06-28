// Repos flow shell — mirrors ReposView: connect state, repo list (+ empty
// states), Add Repository / Connect sheets, and a push navigation stack of
// directory browsers. Generation adds tracks to the library (a toast confirms).
function ReposFlow() {
  const { NavBar, Card, Button } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;

  const [connected, setConnected] = React.useState(false);
  const [repos, setRepos] = React.useState([]);
  const [activeRepo, setActiveRepo] = React.useState(null);
  const [nav, setNav] = React.useState([]); // array of paths (browser stack)
  const [sheet, setSheet] = React.useState(null); // "connect" | "add" | null
  const [toast, setToast] = React.useState(null);

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(null), 2600); };

  const addedNames = new Set(repos.map((r) => r.fullName));
  const addRepo = (r) => { if (!addedNames.has(r.fullName)) setRepos((p) => [{ fullName: r.fullName, owner: r.owner, name: r.name, description: r.description }, ...p]); };
  const openRepo = (r) => { setActiveRepo(r); setNav([""]); };
  const generated = (n) => showToast(`Added ${n} track${n > 1 ? "s" : ""} to your library.`);

  const fmtNow = () => { const d = new Date(); return `${((d.getHours() + 11) % 12) + 1}:${String(d.getMinutes()).padStart(2, "0")}`; };

  const empty = (icon, title, desc, btn, onBtn) => (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10, padding: 32, textAlign: "center" }}>
      <RCIcon name={icon} size={50} color="var(--label-tertiary)" />
      <div style={{ font: "var(--type-title-3)", color: "var(--text-primary)" }}>{title}</div>
      <div style={{ font: "var(--type-subheadline)", color: "var(--text-secondary)", maxWidth: 270 }}>{desc}</div>
      <div style={{ marginTop: 8 }}><Button variant="filled" onClick={onBtn}>{btn}</Button></div>
    </div>
  );

  return (
    <div className="rc-phone">
      <div className="rc-statusbar">
        <span className="rc-time">{fmtNow()}</span>
        <span className="rc-status-icons">
          <RCIcon name="signal" size={17} color="var(--text-primary)" />
          <RCIcon name="wifi" size={17} color="var(--text-primary)" />
          <RCIcon name="battery-full" size={22} color="var(--text-primary)" />
        </span>
      </div>

      <div className="rc-screen">
        {nav.length > 0 ? (
          <window.RepoBrowser
            key={activeRepo.fullName + "|" + nav[nav.length - 1]}
            repo={{ name: activeRepo.name, fullName: activeRepo.fullName }}
            path={nav[nav.length - 1]}
            depth={nav.length - 1}
            onPush={(p) => setNav((s) => [...s, p])}
            onBack={() => setNav((s) => s.slice(0, -1))}
            onGenerated={generated}
          />
        ) : (
          <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
            <NavBar title="Repos" largeTitle
              trailing={connected ? <window.RepocastDesignSystem_a3bb12.IconButton icon="plus" label="Add Repository" onClick={() => setSheet("add")} /> : null} />
            <div style={{ flex: 1, overflowY: "auto" }}>
              {!connected
                ? empty("folder-plus", "Connect GitHub", "Add a GitHub token to browse your repositories and turn files into audio.", "Connect GitHub", () => setSheet("connect"))
                : repos.length === 0
                  ? empty("folder", "No Repositories", "Add a repository to start selecting files.", "Add Repository", () => setSheet("add"))
                  : (
                    <div style={{ padding: "8px 16px 16px" }}>
                      <Card variant="grouped">
                        {repos.map((r, i) => (
                          <div key={r.fullName} className="rc-tap-row" onClick={() => openRepo(r)}
                            style={{ display: "flex", alignItems: "center", gap: 11, padding: "11px 16px", cursor: "pointer", boxShadow: i === repos.length - 1 ? "none" : "inset 0 -0.5px 0 var(--separator)" }}>
                            <RCIcon name="book-marked" size={20} color="var(--text-secondary)" />
                            <div style={{ flex: 1, minWidth: 0 }}>
                              <div style={{ font: "var(--type-body)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{r.fullName}</div>
                              {r.description && <div style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{r.description}</div>}
                            </div>
                            <RCIcon name="chevron-right" size={18} color="var(--label-tertiary)" />
                          </div>
                        ))}
                      </Card>
                    </div>
                  )}
            </div>
          </div>
        )}
      </div>

      {/* Sheets */}
      <div className={"rc-scrim" + (sheet ? " show" : "")} onClick={() => setSheet(null)} />
      <div className={"rc-sheet" + (sheet === "connect" ? " up" : "")}>
        {sheet === "connect" && <window.ConnectGitHubSheet onCancel={() => setSheet(null)} onConnect={() => { setConnected(true); setSheet(null); showToast("Connected to GitHub."); }} />}
      </div>
      <div className={"rc-sheet" + (sheet === "add" ? " up" : "")}>
        {sheet === "add" && <window.AddRepoSheet addedNames={addedNames} onDone={() => setSheet(null)} onAdd={addRepo} />}
      </div>

      {/* Toast */}
      <div className={"rc-toast" + (toast ? " show" : "")}>
        <RCIcon name="circle-check-big" size={18} color="var(--green)" />
        <span>{toast}</span>
      </div>
    </div>
  );
}
window.ReposFlow = ReposFlow;
