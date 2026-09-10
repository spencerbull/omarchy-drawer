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
- [x] Published https://github.com/spencerbull/omarchy-drawer via gh. Hosted CI run 34278907743 passed state, metadata, shell syntax, exact-baseline host contract and installer checks.

## Live verification
- Installed plugin from main; applied extension only to four previously clean files under active ~/omarchy. Unrelated dirty work preserved.
- Backup: .artifacts/live-backup/shell-before.json (private, ignored). Configuration matches backup after excluding only new drawer entry.
- Live Defaults persisted 20 hidden third-party IDs, zero omarchy.* IDs. Restore returned to Global with no hidden IDs.
- Live panel screenshot inspected; subsequent close and shell ping passed.
- Startup found stale queued callbacks; replaced with slot-owned Timer in 0395144. Restarted shell; no TypeError, invalid-context, ReferenceError, assignment or binding-loop errors in fresh logs.

## Completion
- Final native rerun passed all four orientations after lifecycle fix. Live shell ping and unchanged original configuration rechecked.
- Installed clone now tracks the GitHub repository for normal plugin updates.
- Independent state/host/review workers complete. Temporary state and host worktrees removed by parent after confirming clean status; branch commits retained.
- Remaining maintenance constraint: stock-bar extension must be kept compatible with future Omarchy updates. No human gates pending.

## Native design pass and PR triage (2026-09-09)
- Scope: read-only omabot review of Drawer PRs; redesign using stock Omarchy controls; no merge of contributor PRs or default-branch push.
- Design stream: /home/sbull/worktrees/omarchy-drawer-native-design, branch drawer-native-design; parent owns edits and cleanup. Started from clean c051f57.
- Review worker: /root/drawer_pr_review, read-only PR #1 at 307652eb5909ac073c7f21333455c2f6ee58a0be; contributor code not executed on coordinator.
- [x] Review PR #1 and independently verify findings; recommendation in docs/pr-review-2026-09-09.md. Leave draft pending coordinated host upgrade and validation.
- [x] Replace custom controls with native controls; compact space selection and plugin visibility rows.
- [x] Ten state tests, plugin validation, 360/520 px pointer/keyboard QML checks and renders; native drag regression on all four edges passed.
- [x] Independent /root/drawer_design_review found canceled-input focus and missing accessibility actions; fixed, including Cancel-button focus follow-up. Regression tests pass; mutation without cancellation fix fails. Assistive-client validation remains untested.
- [ ] Publish reviewable branch/PR and verify CI.
- [ ] Live visual verification and report exact source identity and remaining gates.
- Live restart exposed pre-existing saved-state loss: host QVariant sequences failed the model's strict array checks. Reproduced in native fixture; JSON materialization at the plugin boundary fixes it. All four native orientations and both QML widths pass with preconfigured profiles. Removing the fix fails the new regression. Independent reviewer found no issues in the narrow follow-up.
