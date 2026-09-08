import QtQuick
import QtQuick.Controls
import qs.Commons

Button {
  id: root
  property bool selected: false
  implicitHeight: Style.space(32)
  implicitWidth: label.implicitWidth + Style.space(24)
  hoverEnabled: true
  font.family: Style.font.family
  font.pixelSize: Style.font.body
  contentItem: Text {
    id: label
    text: root.text
    textFormat: Text.PlainText
    color: root.selected ? Color.background : Color.foreground
    font: root.font
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  background: Rectangle {
    radius: Style.space(6)
    color: root.selected ? Color.accent : root.down ? Qt.alpha(Color.foreground, 0.18) : root.hovered ? Qt.alpha(Color.foreground, 0.10) : Qt.alpha(Color.foreground, 0.04)
    border.width: root.activeFocus ? 2 : 1
    border.color: root.activeFocus ? Color.accent : Qt.alpha(Color.foreground, 0.14)
  }
}
