# Omarchy Drawer

Goal: publish a new Omarchy drawer plugin repository under spencerbull, with drag organization, Default/All temporary modes, Global and named spaces, and persistence.

Done criteria: focused state tests, plugin validation, independent review, rendered UI and drag/input evidence where available, GitHub repository created and exact source pushed.

## Ownership and boundaries
- Main checkout: /home/sbull/src/github.com/spencerbull/omarchy-drawer, main (new empty repository).
- Existing /home/sbull/Work/my-omarchy images and dirty ~/omarchy files belong to user; preserve.
- Allowed: implementation, tests, isolated test environment, new GitHub repository and push via gh.
- No production changes or unrelated desktop configuration changes.

## Checkpoints
- [x] Inspect current plugin/bar API and GitHub identity (spencerbull).
- [x] Independent contract investigation: /root/drawer_contracts, read-only ~/omarchy at 82652c8bdba65c05954fe6ebd961d90029250a5d. Native drag private; keep layout intact; replacement bar restricts third-party services. Worker complete; no cleanup needed.
- [x] User selected plugin plus stock-bar extension.
- [x] Implement state, plugin, and drag integration. State worker /root/drawer_state, drawer-state worktree, 45e69fe integrated. Host worker /root/drawer_contracts, drawer-host worktree, 0edcf14 integrated. Parent owns cleanup.
- [x] 10 state tests; native plugin validation; offscreen QML at 520/360 px, including long name and no-op persistence.
- [x] Independent reviewer /root/drawer_review found no-op save/long-name errors (fixed), host ordering/multi-screen close/center slot/popup switch issues (fixed), and missing hidden tooltips (fixed). Final review no new critical findings.
- [x] Native Wayland fixture passes top/bottom/left/right: actual pointer drag both directions, same-instance service access, center-anchor hiding, original order, popup handoff, and closed input mask. Rendered panel visually inspected.
- [ ] GitHub repository created via gh: https://github.com/spencerbull/omarchy-drawer (public). Push verified source after final fixes.
