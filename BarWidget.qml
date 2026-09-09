import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "spencerbull.drawer"
  property bool opened: false
  readonly property bool supported: bar && typeof bar.setDrawerOpen === "function" && bar.drawerSupported === true && bar.drawerApiVersion === 1
  readonly property var state: Model.normalize(settings.drawerState)
  readonly property var catalog: Model.entries(bar ? bar.layoutConfig : {})
  readonly property var widgetIds: catalog.map(function(item) { return item.id })
  readonly property var hiddenIds: Model.hiddenIds(state, widgetIds)
  readonly property string spaceName: {
    for (var i = 0; i < state.spaces.length; i++)
      if (state.spaces[i].id === state.activeSpace) return state.spaces[i].name
    return "Global"
  }
  readonly property string viewName: state.mode === "defaults" ? "Defaults" : state.mode === "all" ? "All plugins" : spaceName
  property string error: ""
  property Component drawerContent: Component { DrawerContent { controller: root } }

  function displayName(id) {
    var names = bar && bar.drawerEntries ? bar.drawerEntries : []
    for (var i = 0; i < names.length; i++) if (names[i].id === id) return names[i].name
    var name = id.split(".").pop().replace(/-/g, " ")
    return name.charAt(0).toUpperCase() + name.slice(1)
  }

  function save(next) {
    if (!supported) { error = "Install the stock-bar drawer extension first."; return false }
    var entry = JSON.parse(JSON.stringify(settings || {}))
    entry.id = moduleName
    entry.drawerController = true
    entry.drawerState = next
    entry.hiddenWidgets = Model.hiddenIds(next, widgetIds)
    var previous = JSON.parse(JSON.stringify(settings || {}))
    var comparable = JSON.parse(JSON.stringify(entry))
    delete previous.id
    delete comparable.id
    if (JSON.stringify(comparable) === JSON.stringify(previous)) { error = ""; return true }
    if (!bar.shell || !bar.shell.updateEntryInline(moduleName, entry)) {
      error = "Could not save this space. Your previous setting is unchanged."
      return false
    }
    error = ""
    return true
  }
  function setMode(mode) { save(Model.setMode(state, mode)) }
  function toggleDefaults() { save(Model.toggleDefaults(state)) }
  function setHidden(id, hidden) {
    if (!Model.knownWidget(widgetIds, id)) return false
    return save(Model.setHidden(state, id, hidden, widgetIds))
  }
  function acceptBarDrop(id) { if (id !== moduleName) setHidden(id, true) }
  function restoreBarWidget(id) { setHidden(id, false) }
  function createSpace(name) { save(Model.createSpace(state, name)) }
  function selectSpace(id) {
    if (!Model.hasProfile(state, id)) return false
    return save(Model.selectSpace(state, id))
  }
  function renameSpace(id, name) { save(Model.renameSpace(state, id, name)) }
  function deleteSpace(id) { save(Model.deleteSpace(state, id)) }
  function open() {
    if (!supported) { error = "Install the stock-bar drawer extension first."; return }
    bar.setDrawerOpen(true)
  }
  function close() { if (supported) bar.setDrawerOpen(false) }
  function toggle() { if (opened) close(); else open() }
  function reconcile() {
    if (!supported) return
    var expected = Model.hiddenIds(state, widgetIds)
    if (settings.drawerController !== true || JSON.stringify(settings.hiddenWidgets || []) !== JSON.stringify(expected))
      save(state)
  }
  onCatalogChanged: Qt.callLater(reconcile)
  onSupportedChanged: Qt.callLater(reconcile)
  Component.onCompleted: Qt.callLater(reconcile)

  implicitWidth: vertical ? barSize : buttons.implicitWidth
  implicitHeight: vertical ? drawerButton.implicitHeight + defaultButton.implicitHeight : barSize
  Grid {
    id: buttons
    columns: root.vertical ? 1 : 2
    WidgetButton {
      id: drawerButton
      bar: root.bar
      activeFocusOnTab: true
      Accessible.role: Accessible.Button
      Accessible.name: "Open plugin drawer"
      Keys.onReturnPressed: root.toggle()
      Keys.onSpacePressed: root.toggle()
      text: "▤"
      active: root.opened
      tooltipText: root.supported ? "Drawer · " + root.viewName + " · " + root.hiddenIds.length + " tucked away\nDrag a plugin here to hide it" : "Drawer requires the stock-bar extension"
      onPressed: function(button) { if (button === Qt.RightButton) root.setMode(root.state.mode === "all" ? "space" : "all"); else root.toggle() }
    }
    WidgetButton {
      id: defaultButton
      bar: root.bar
      activeFocusOnTab: true
      Accessible.role: Accessible.Button
      Accessible.name: root.state.mode === "defaults" ? "Restore previous view" : "Show defaults"
      Keys.onReturnPressed: root.toggleDefaults()
      Keys.onSpacePressed: root.toggleDefaults()
      text: root.state.mode === "defaults" ? "↶" : "◉"
      active: root.state.mode === "defaults"
      tooltipText: root.state.mode === "defaults" ? "Restore previous view" : "Show Omarchy defaults only"
      onPressed: root.toggleDefaults()
    }
  }
  IpcHandler {
    target: "spencerbull.drawer"
    function status(): string { return JSON.stringify(Model.status(root.state, root.widgetIds, root.supported)) }
    function selectProfile(id: string): bool { return root.selectSpace(id) }
    function setWidgetVisible(id: string, visible: bool): bool { return root.setHidden(id, !visible) }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function defaults(): void { root.toggleDefaults() }
    function all(): void { root.setMode("all") }
    function restore(): void { root.setMode("space") }
  }
}
