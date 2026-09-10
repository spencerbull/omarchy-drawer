import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui
import "Model.js" as Model

Column {
  id: root
  required property var controller
  property bool editing: false
  property string editingId: ""
  property string removalId: ""
  property string search: ""
  readonly property var plugins: controller.catalog.filter(function(row) { return row.id !== controller.moduleName })
  readonly property var filteredPlugins: plugins.filter(function(row) {
    return (row.id + " " + controller.displayName(row.id)).toLowerCase().indexOf(root.search) !== -1
  })
  width: parent ? parent.width : Style.space(460)
  spacing: Style.spacing.lg

  component DrawerAction: Ui.PanelActionButton {
    id: action
    focusable: true
    Accessible.role: Accessible.Button
    Accessible.name: tooltipText
    Accessible.onPressAction: if (enabled) action.clicked()
  }

  function editSpace(rename) {
    removalId = ""
    editingId = rename ? controller.state.activeSpace : ""
    nameInput.text = rename ? controller.spaceName : ""
    editing = true
    nameInput.forceActiveFocus()
    nameInput.selectAll()
  }
  function saveSpace() {
    if (!editing || !nameInput.text.trim()) return
    if (editingId) controller.renameSpace(editingId, nameInput.text)
    else controller.createSpace(nameInput.text)
    if (controller.error) return
    editing = false
    searchInput.forceActiveFocus()
  }
  function cancelEditing() {
    var wasEditing = editing
    editing = false
    if (wasEditing) searchInput.forceActiveFocus()
  }
  function finishRemoval(remove) {
    if (remove) controller.deleteSpace(removalId)
    removalId = ""
    searchInput.forceActiveFocus()
  }
  function chooseMode(value) {
    if (value === "defaults") controller.toggleDefaults()
    else controller.setMode(value === "all" && controller.state.mode === "all" ? "space" : value)
  }

  Ui.PanelHero {
    title: "Plugin drawer"
    meta: (root.plugins.length - controller.hiddenIds.length) + " in bar · " + controller.hiddenIds.length + " in drawer"
    iconComponent: Text {
      text: "▤"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.display
    }
    trailingControl: DrawerAction {
      iconText: "󰅖"
      tooltipText: "Close drawer"
      onClicked: controller.close()
    }
  }

  Flow {
    width: parent.width
    spacing: Style.spacing.md
    Repeater {
      id: viewButtons
      model: [{value: "space", label: "Space"}, {value: "defaults", label: "Defaults"}, {value: "all", label: "All"}]
      Ui.Button {
        required property var modelData
        required property int index
        objectName: "viewMode:" + modelData.value
        text: modelData.label
        selected: controller.state.mode === modelData.value
        focusable: true
        bordered: true
        Accessible.role: Accessible.Button
        Accessible.name: text
        Accessible.checkable: true
        Accessible.checked: selected
        Accessible.onPressAction: clicked()
        onClicked: root.chooseMode(modelData.value)
        Keys.onLeftPressed: viewButtons.itemAt(Math.max(0, index - 1)).forceActiveFocus()
        Keys.onRightPressed: viewButtons.itemAt(Math.min(viewButtons.count - 1, index + 1)).forceActiveFocus()
      }
    }
  }

  Ui.PanelSeparator {}

  Column {
    width: parent.width
    spacing: Style.spacing.sm
    Ui.PanelSectionHeader { text: "Space" }
    RowLayout {
      width: parent.width
      spacing: Style.spacing.xs
      Ui.Dropdown {
        id: spacePicker
        objectName: "spacePicker"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        showLabel: false
        options: controller.state.spaces.map(function(space) { return {value: space.id, label: space.name} })
        // Dropdown assigns value on selection; Binding keeps external changes reactive.
        Binding on value { value: controller.state.activeSpace }
        onChanged: function(value) { root.cancelEditing(); root.removalId = ""; controller.selectSpace(value) }
        Accessible.name: "Active space"
        Accessible.role: Accessible.ComboBox
        Accessible.description: "Current space: " + controller.spaceName
        Accessible.onPressAction: open()
      }
      DrawerAction {
        objectName: "addSpace"
        iconText: "󰐕"
        tooltipText: "New space"
        enabled: controller.state.spaces.length < 32
        onClicked: root.editSpace(false)
      }
      DrawerAction {
        objectName: "renameSpace"
        iconText: "󰏫"
        tooltipText: "Rename space"
        enabled: controller.state.activeSpace !== "global"
        onClicked: root.editSpace(true)
      }
      DrawerAction {
        objectName: "removeSpace"
        iconText: "󰆴"
        tooltipText: "Remove space"
        enabled: controller.state.activeSpace !== "global"
        onClicked: { root.cancelEditing(); root.removalId = controller.state.activeSpace }
      }
    }
    RowLayout {
      width: parent.width
      visible: root.editing
      spacing: Style.spacing.sm
      Ui.TextField {
        id: nameInput
        objectName: "spaceNameInput"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        maximumLength: 60
        placeholderText: root.editingId ? "Space name" : "New space name"
        Accessible.name: placeholderText
        onAccepted: root.saveSpace()
        Keys.onEscapePressed: root.cancelEditing()
      }
      DrawerAction {
        objectName: "saveSpace"
        iconText: "󰄬"
        tooltipText: "Save space"
        enabled: nameInput.text.trim().length > 0
        onClicked: root.saveSpace()
      }
      DrawerAction {
        objectName: "cancelEditing"
        iconText: "󰅖"
        tooltipText: "Cancel"
        onClicked: root.cancelEditing()
      }
    }
    Column {
      width: parent.width
      visible: root.removalId !== ""
      spacing: Style.spacing.sm
      Text {
        width: parent.width
        text: "Remove this space? Plugins and Global settings are kept."
        textFormat: Text.PlainText
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }
      Row {
        spacing: Style.spacing.sm
        Ui.Button {
          objectName: "confirmRemoval"
          text: "Remove"
          Accessible.role: Accessible.Button
          Accessible.name: text
          Accessible.onPressAction: clicked()
          focusable: true
          bordered: true
          foreground: Color.urgent
          onClicked: root.finishRemoval(true)
        }
        Ui.Button {
          objectName: "cancelRemoval"
          text: "Cancel"
          Accessible.role: Accessible.Button
          Accessible.name: text
          Accessible.onPressAction: clicked()
          focusable: true
          bordered: true
          onClicked: root.finishRemoval(false)
        }
      }
    }
  }

  Ui.PanelSeparator {}

  Column {
    width: parent.width
    spacing: Style.spacing.sm
    Ui.PanelSectionHeader { text: "Show in bar" }
    Ui.TextField {
      id: searchInput
      objectName: "pluginSearch"
      width: parent.width
      placeholderText: "Find a plugin…"
      Accessible.name: "Find a plugin"
      onTextChanged: root.search = text.trim().toLowerCase()
    }
    Flickable {
      id: pluginScroll
      width: parent.width
      height: Math.min(Style.space(216), list.implicitHeight)
      contentHeight: list.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: Controls.ScrollBar {}
      Column {
        id: list
        width: parent.width
        Repeater {
          model: root.filteredPlugins
          Ui.CursorSurface {
            id: pluginRow
            required property var modelData
            readonly property bool inBar: Model.visible(controller.state, modelData.id)
            objectName: "pluginRow:" + modelData.id
            width: list.width
            height: Style.space(36)
            hasCursor: activeFocus || rowMouse.containsMouse
            activeFocusOnTab: true
            Accessible.role: Accessible.CheckBox
            Accessible.name: controller.displayName(modelData.id) + " in bar"
            Accessible.checkable: true
            Accessible.checked: inBar
            Accessible.onToggleAction: toggle()
            function toggle() { controller.setHidden(modelData.id, inBar) }
            Keys.onSpacePressed: toggle()
            Keys.onReturnPressed: toggle()
            Keys.onEnterPressed: toggle()
            onActiveFocusChanged: {
              if (!activeFocus) return
              if (y < pluginScroll.contentY) pluginScroll.contentY = y
              else if (y + height > pluginScroll.contentY + pluginScroll.height)
                pluginScroll.contentY = y + height - pluginScroll.height
            }
            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.sm
              anchors.right: visibilitySwitch.left
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              text: controller.displayName(pluginRow.modelData.id)
              textFormat: Text.PlainText
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
            Ui.ToggleSwitch {
              id: visibilitySwitch
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.sm
              anchors.verticalCenter: parent.verticalCenter
              checked: pluginRow.inBar
              interactive: false
              trackHeight: Style.space(16)
            }
            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { pluginRow.forceActiveFocus(); pluginRow.toggle() }
            }
          }
        }
      }
    }
    Text {
      visible: root.filteredPlugins.length === 0
      width: parent.width
      text: root.plugins.length ? "No matching plugins" : "Add plugins to the bar to organize them here."
      color: Qt.darker(Color.foreground, 1.4)
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      wrapMode: Text.WordWrap
    }
  }
  Text {
    width: parent.width
    text: "Drag plugins onto ▤ to tuck them away."
    color: Qt.darker(Color.foreground, 1.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
  Text {
    visible: controller.error !== ""
    width: parent.width
    text: controller.error
    textFormat: Text.PlainText
    color: Color.urgent
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.body
  }
}
