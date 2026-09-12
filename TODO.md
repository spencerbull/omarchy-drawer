# Omarchy Drawer

## Missing host extension repair (2026-09-11)

- Active host had advanced to `9f066b64` and all four drawer-extension target files were clean; `drawerSupported`, `setDrawerOpen`, and `drawerControllerFor` were absent. Installed plugin `114d543` remained present, so its support guard prevented opening. The action that removed the extension was not established.
- Reapplied the existing tested integration patch, including the coordinate fix, through `scripts/apply-host-extension`. Host contracts and reverse-application check pass. Restarted the active shell; initial ping was premature, subsequent ping and compositor checks passed.
- Cua session `drawer-click-check` performed real desktop clicks on the drawer button and close button; fresh screenshots confirmed open and closed states. Session ended. No worker needed for this bounded restoration.
- Saved shell.json remained byte-for-byte equal to `.artifacts/click-repair/shell-before.json`. Existing repository edits and installed single-button plugin were preserved. The host extension remains a local patch and can require reapplication after host checkout changes.

## Bar refresh repair (2026-09-10)

- Goal: restore drawer widgets without stale offsets, preserving instances, services, ordering, saved configuration, and existing host edits.
- Branch: `drawer-layout-refresh` in `/home/sbull/omarchy-drawer`; initial checkout clean. Allowed: focused repair, fixtures, local host update and runtime checks. No remote publication or merge.
- [x] Reproduced against the active host: returning a wrapped widget retained y=36; center anchor retained x=63.875. Existing tests covered ordering but missed perpendicular displacement.
- [x] Clear both coordinates before parent transfer, including drawer-host teardown. Update the distributable stock-bar patch and add two wrapped arrangements covering ordinary Row/Column children and the center anchor.
- [x] Native pointer drag, services, popups, persistence, ordering, and new geometry checks pass on top, bottom, left, and right. Ten model tests, host contracts, installer application/idempotence/reverse/dirty preservation, plugin validation, and diff whitespace checks pass.
- [x] Read-only T3 worker `/root/drawer_layout_review` independently confirmed the cause and reviewed the fix. Its vertical-test coverage finding was addressed; worker complete, no worker resources to clean up.
- [x] Applied only the six-line delta to active `/home/sbull/omarchy/shell/plugins/bar/Bar.qml`, preserving previous dirty edits. Restart and shell ping pass; compositor config errors empty. Inspected live drawer and bar captures. Saved shell.json is byte-for-byte unchanged. Installed single-button plugin checkout `114d543` was preserved.
- Evidence: ignored `.artifacts/native-*.log`, `.artifacts/native-*-restored-*.png`, and `.artifacts/refresh-live/` (pre-change host/config backup, exact local delta, screenshots, fresh shell log). Parent owns generated fixtures; `.artifacts/validation-root.txt` records their temporary location.
- Remaining limits: one attached monitor; native fixture tests use synthetic widgets. No publication requested or performed.

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
- [x] Published design PR #2; both push and PR CI checks passed for runtime commit 2215233 (runs 34421554318 / 34421558331).
- [x] Live verifier /root/drawer_live_verify opened the native panel on installed 2215233 after a shell restart cleared stale QML. Parent inspected private panel capture: native controls, 14 in bar / 20 in drawer, no clipping. Full configuration semantically equals the prework backup; shell ping and compositor config checks pass. No Drawer QML errors in fresh logs.
- Runtime remains installed on drawer-native-design for preview; main is unchanged. No contributor PR merged. PR #2 awaits explicit merge approval. Multi-monitor behavior was not rerun (one monitor currently attached); assistive-client interaction remains unverified. All three read-only workers completed; parent retains the design worktree for review.
- Live restart exposed pre-existing saved-state loss: host QVariant sequences failed the model's strict array checks. Reproduced in native fixture; JSON materialization at the plugin boundary fixes it. All four native orientations and both QML widths pass with preconfigured profiles. Removing the fix fails the new regression. Independent reviewer found no issues in the narrow follow-up.
