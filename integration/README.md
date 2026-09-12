# Stock-bar drawer extension

`stock-bar-drawer.patch` adds the host mechanisms required by an ordinary third-party drawer plugin. It targets Omarchy commit `82652c8bdba65c05954fe6ebd961d90029250a5d` (the four target files were clean in the development checkout). It was generated from those exact files, not from a replacement bar or copied plugin service implementation.

Apply to an explicitly selected development checkout with `scripts/apply-host-extension /absolute/path/to/omarchy`. The script refuses `/usr/share`, symlinked targets, dirty target files, and patches that fail `git apply --check`. Re-running recognizes an already applied patch. It does not restart or install the shell. To undo, run `git -C /path/to/omarchy apply --reverse --check /path/to/plugin/integration/stock-bar-drawer.patch`, review the result, then repeat without `--check`; preserve any later work first.

## Controller contract

An ordinary bar widget opts in using inline settings `drawerController: true` and `hiddenWidgets: [canonicalWidgetId, ...]`. The first configured controller claiming an ID owns its presentation; controllers themselves always remain on the bar. Unknown IDs have no effect.

The widget exposes `drawerContent` (a QML `Component`), writable `opened` boolean, `open()` and `close()` methods, `acceptBarDrop(id)`, and `restoreBarWidget(id)`. The controller persists its own settings through its existing scoped `bar.shell.updateEntryInline()` API. It receives no other widget's component, service, or live object.

`PluginBarApi` gains `drawerSupported`, `setDrawerOpen(bool)`, and scalar catalog `drawerEntries: [{id, name}]`. The setter independently locates the caller's configured controller; it cannot open a foreign drawer. Catalog entries are detached scalar records and only supplied to configured controllers. Opening chooses the focused screen's controller, with the existing first-instance fallback. Closing closes every open instance belonging to that controller ID, so dismissing after focus moves to another output cannot strand a drawer.

The host retains each canonical `ModuleSlot` and changes its visual parent to the appropriate per-screen drawer container. This visually filters the bar without removing layout entries, duplicating services, unregistering plugins, or rebuilding every controller on a settings change. Restoring returns the same instance to its original section. Dragging a visible widget directly onto the controller calls `acceptBarDrop`; adjacent drops still reorder. Dragging a hidden widget onto the bar calls `restoreBarWidget`, returning it to its saved position. Canceled and off-bar drops do nothing.

Parent transfers clear both local coordinates before the destination lays out the widget. The drawer's wrapping Flow assigns both axes, while bar Rows and Columns only position one axis and the center anchor has no positioner. Keeping drawer offsets would leave restored widgets displaced or clipped.

The host supplies a bounded, scrollable `KeyboardPanel`, loading the controller's component as its header and rendering the actual hidden widgets beneath it. Closing leaves hidden widgets and their window instantiated. The closed window has an empty input mask and no keyboard focus, so child popups can survive the normal popup handoff. `KeyboardPanel` and `PopupCard` use scalar bar dimensions exposed by the drawer surface for popup fitting, rather than mistaking its fullscreen window for the bar strip. Nested popup mapping uses the actual scene Item through `panelSurfaceItem`, since `KeyboardPanel.contentItem` is a list alias for supplied children. The stock tooltip popup is reused on the drawer surface, preserving native plugin hover labels.

## Verification

Run `node integration/host-contract.test.cjs /path/to/patched/omarchy` for focused drag and capability tests, and `integration/test-apply.sh` for application, idempotence, and dirty-file preservation. Real compositor testing remains necessary for reparented widgets, popup handoff, dragging across surfaces, both bar orientations, and multiple monitors. These checks do not replace that evidence.
