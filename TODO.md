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
- [ ] Resolve integration: small stock-bar extension vs standalone replacement.
- [ ] Implement state, plugin, and drag integration.
- [ ] Focused tests and native validation.
- [ ] Independent review and fixes.
- [ ] Runtime visual/input verification.
- [ ] Create repository via gh and push verified source.
