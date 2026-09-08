import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import "Model.js" as Model

Column {
  id: root
  required property var controller
  property bool editing: false
  property string editingId: ""
  width: parent ? parent.width : Style.space(460)
  spacing: Style.space(12)
  property string search: ""

  RowLayout {
    width: parent.width
    Column {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: Style.space(4)
      Text { text: "Plugin drawer"; color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.body * 1.5; font.bold: true }
      Text { width: parent.width; elide: Text.ElideRight; text: controller.viewName + " · " + controller.hiddenIds.length + " tucked away"; textFormat: Text.PlainText; color: Qt.alpha(Color.foreground, 0.7); font.family: Style.font.family; font.pixelSize: Style.font.body }
    }
    DrawerButton { text: "×"; Accessible.name: "Close drawer"; onClicked: controller.close() }
  }
  Flow {
    width: parent.width
    spacing: Style.space(6)
    DrawerButton { text: "My space"; selected: controller.state.mode === "space"; onClicked: controller.setMode("space") }
    DrawerButton { text: controller.state.mode === "defaults" ? "Restore view" : "Defaults"; selected: controller.state.mode === "defaults"; onClicked: controller.toggleDefaults() }
    DrawerButton { text: controller.state.mode === "all" ? "Restore space" : "Show all"; selected: controller.state.mode === "all"; onClicked: controller.setMode(controller.state.mode === "all" ? "space" : "all") }
  }
  Text { text: "SPACES"; color: Qt.alpha(Color.foreground, 0.7); font.family: Style.font.family; font.pixelSize: Style.font.body * 0.8; font.letterSpacing: 1.5 }
  Flow {
    width: parent.width
    spacing: Style.space(6)
    Repeater {
      model: controller.state.spaces
      DrawerButton {
        required property var modelData
        text: modelData.name
        width: Math.min(implicitWidth, root.width)
        selected: controller.state.activeSpace === modelData.id
        onClicked: controller.selectSpace(modelData.id)
      }
    }
    DrawerButton { text: "+ New space"; enabled: controller.state.spaces.length < 32; onClicked: { root.editingId = ""; nameInput.text = ""; root.editing = true; nameInput.forceActiveFocus() } }
  }
  Row {
    spacing: Style.space(6)
    visible: controller.state.activeSpace !== "global"
    DrawerButton { text: "Rename"; onClicked: { root.editingId = controller.state.activeSpace; nameInput.text = controller.spaceName; root.editing = true; nameInput.forceActiveFocus() } }
    DrawerButton { text: "Remove space"; onClicked: removeDialog.open() }
  }
  Dialog {
    id: removeDialog
    title: "Remove this space?"
    modal: true
    standardButtons: Dialog.Cancel | Dialog.Ok
    onAccepted: controller.deleteSpace(controller.state.activeSpace)
    Label { text: "Plugins and Global settings are kept." }
  }
  RowLayout {
    width: parent.width
    visible: root.editing
    TextField {
      id: nameInput
      Layout.fillWidth: true
      maximumLength: 60
      placeholderText: "e.g. Writing, Music, Client project"
      color: Color.foreground
      font.family: Style.font.family
      background: Rectangle { color: Qt.alpha(Color.foreground, 0.05); radius: Style.space(6); border.color: Qt.alpha(Color.foreground, 0.7) }
      onAccepted: saveName.clicked()
    }
    DrawerButton {
      id: saveName
      text: "Save"
      enabled: nameInput.text.trim().length > 0
      onClicked: {
        if (!enabled) return
        if (root.editingId) controller.renameSpace(root.editingId, nameInput.text)
        else controller.createSpace(nameInput.text)
        root.editing = false
      }
    }
    DrawerButton { text: "Cancel"; onClicked: root.editing = false }
  }
  Text {
    width: parent.width
    text: "Drag a bar plugin onto ▤ to tuck it away. Drag an icon below back to the bar, or use the list to choose what shows."
    color: Qt.alpha(Color.foreground, 0.7); font.family: Style.font.family; font.pixelSize: Style.font.body
    wrapMode: Text.WordWrap
  }
  TextField {
    width: parent.width
    placeholderText: "Find a plugin…"
    color: Color.foreground
    font.family: Style.font.family
    onTextChanged: root.search = text.toLowerCase()
    background: Rectangle { color: Qt.alpha(Color.foreground, 0.05); radius: Style.space(6); border.color: Qt.alpha(Color.foreground, 0.14) }
  }
  Flickable {
    width: parent.width
    height: Math.min(Style.space(180), list.implicitHeight)
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}
    Column {
      id: list
      width: parent.width
      spacing: Style.space(4)
      Repeater {
        model: controller.catalog.filter(function(row) { return row.id !== controller.moduleName && (row.id + " " + controller.displayName(row.id)).toLowerCase().indexOf(root.search) !== -1 })
        RowLayout {
          required property var modelData
          width: list.width
          Text {
            Layout.fillWidth: true
            text: controller.displayName(modelData.id)
            textFormat: Text.PlainText
            color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.body
            elide: Text.ElideMiddle
          }
          DrawerButton {
            readonly property bool inBar: Model.visible(controller.state, modelData.id)
            text: inBar ? "To drawer" : "To bar"
            Accessible.name: text + ": " + controller.displayName(modelData.id)
            onClicked: controller.setHidden(modelData.id, inBar)
          }
        }
      }
    }
  }
  Text { visible: controller.error !== ""; width: parent.width; text: controller.error; color: Color.urgent; wrapMode: Text.WordWrap; font.family: Style.font.family }
}
