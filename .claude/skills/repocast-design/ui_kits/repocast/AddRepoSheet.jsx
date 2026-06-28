// Add Repository sheet — mirrors AddRepoView: lists the connected account's
// repositories (fullName + lock if private + description); tapping adds one.
function AddRepoSheet({ addedNames, onDone, onAdd }) {
  const { NavBar, Card, Button } = window.RepocastDesignSystem_a3bb12;
  const RCIcon = window.RCIcon;

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", background: "var(--bg-grouped)" }}>
      <NavBar title="Add Repository" trailing={<Button variant="plain" onClick={onDone} style={{ fontWeight: 600 }}>Done</Button>} />
      <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px 16px" }}>
        <Card variant="grouped">
          {window.RC_GH_REPOS.map((r, i) => {
            const added = addedNames.has(r.fullName);
            return (
              <div key={r.id} className={added ? "" : "rc-tap-row"} onClick={() => !added && onAdd(r)}
                style={{ display: "flex", alignItems: "center", gap: 12, padding: "11px 16px", cursor: added ? "default" : "pointer", boxShadow: i === window.RC_GH_REPOS.length - 1 ? "none" : "inset 0 -0.5px 0 var(--separator)" }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <span style={{ font: "var(--type-body)", color: "var(--text-primary)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      <span style={{ color: "var(--text-secondary)" }}>{r.owner}/</span>{r.name}
                    </span>
                    {r.priv && <RCIcon name="lock" size={12} color="var(--text-secondary)" />}
                  </div>
                  {r.description && (
                    <div style={{ font: "var(--type-caption-1)", color: "var(--text-secondary)", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{r.description}</div>
                  )}
                </div>
                {added
                  ? <span style={{ font: "var(--type-subheadline)", color: "var(--text-secondary)", display: "inline-flex", alignItems: "center", gap: 4 }}><RCIcon name="check" size={16} color="var(--green)" />Added</span>
                  : <RCIcon name="plus" size={20} color="var(--tint)" />}
              </div>
            );
          })}
        </Card>
      </div>
    </div>
  );
}
window.AddRepoSheet = AddRepoSheet;
