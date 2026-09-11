import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import QtTest
import qs.Commons
import "plugin" as Plugin

ShellRoot {
  id: harness
  property var saved: ({id: "spencerbull.drawer", drawerController: true})
  QtObject {
    id: testBar
    property bool vertical: false
    property int barSize: 28
    property string position: "top"
    property string fontFamily: Style.font.family
    property color barForeground: Color.foreground
    property color foreground: Color.foreground
    property color background: Color.background
    property color urgent: Color.accent
    property bool foregroundAnimationEnabled: false
    property bool drawerSupported: true
    property var layoutConfig: ({left: [{id: "omarchy.menu"}, {id: "omarchy.workspaces"}], center: [{id: "omarchy.clock"}, {id: "omarchy.weather"}], right: [{id: "37signals.hey"}, {id: "hass"}, {id: "robzolkos.github"}, {id: "spencerbull.drawer"}]})
    property var shell: QtObject {
      function updateEntryInline(id, entry) {
        var copy = JSON.parse(JSON.stringify(entry)); delete copy.id
        if (JSON.stringify(copy) === JSON.stringify(harness.saved)) return false
        harness.saved = copy; return true
      }
    }
    function registerClickTarget(target) {}
    function unregisterClickTarget(target) {}
    function hideTooltip(target) {}
    function showTooltip(target, text) {}
    function setDrawerOpen(open) { widget.opened = open }
  }
  Timer { id: quitTimer; interval: 300; onTriggered: Qt.quit() }
  Plugin.BarWidget { id: widget; bar: testBar; settings: harness.saved }
  FloatingWindow {
    id: window
    visible: true
    implicitWidth: Number(Quickshell.env("DRAWER_TEST_WIDTH")) || 520
    implicitHeight: 820
    color: Color.background
    Rectangle {
      color: Color.background
      id: capture
      width: parent.width
      height: content.height + 40
      Plugin.DrawerContent { id: content; x: 20; y: 20; width: parent.width - 40; controller: widget }
    }
    TestCase {
      name: "DrawerUI"
      when: window.visible
      function test_flow() {
        wait(200)
        verify(widget.supported)
        widget.selectSpace("global")
        compare(widget.error, "")
        widget.createSpace("Writing")
        compare(widget.spaceName, "Writing")
        widget.setHidden("hass", true)
        compare(widget.hiddenIds.indexOf("hass") >= 0, true)
        widget.toggleDefaults()
        compare(widget.state.mode, "defaults")
        verify(widget.hiddenIds.indexOf("37signals.hey") >= 0)
        widget.toggleDefaults()
        compare(widget.state.mode, "space")
        compare(widget.hiddenIds.length, 1)
        widget.renameSpace(widget.state.activeSpace, "A long project name to check narrow panels and safe text clips")
        widget.renameSpace(widget.state.activeSpace, widget.spaceName)
        compare(widget.error, "")
        // Exercise the actual redesigned controls, including narrow-panel input.
        var savedSpace = widget.state.activeSpace
        var picker = findChild(content, "spacePicker")
        picker.open()
        wait(50)
        keyClick(Qt.Key_Up)
        keyClick(Qt.Key_Return)
        compare(widget.state.activeSpace, "global")
        widget.selectSpace(savedSpace)
        compare(picker.value, savedSpace)

        mouseClick(findChild(content, "addSpace"))
        verify(content.editing)
        var input = findChild(content, "spaceNameInput")
        input.text = "Reading"
        keyClick(Qt.Key_Return)
        compare(widget.spaceName, "Reading")
        verify(!content.editing)
        mouseClick(findChild(content, "addSpace"))
        input.text = "Canceled space"
        wait(50)
        mouseClick(findChild(content, "cancelEditing"))
        verify(!content.editing)
        verify(findChild(content, "pluginSearch").activeFocus)
        keyClick(Qt.Key_Return)
        compare(widget.spaceName, "Reading")
        mouseClick(findChild(content, "renameSpace"))
        input.text = "Canceled name"
        keyClick(Qt.Key_Escape)
        verify(!content.editing)
        verify(!input.activeFocus)
        content.saveSpace()
        compare(widget.spaceName, "Reading")
        keyClick(Qt.Key_Return)
        compare(widget.spaceName, "Reading")
        keyClick(Qt.Key_Escape)
        mouseClick(findChild(content, "renameSpace"))
        input.text = "Research"
        keyClick(Qt.Key_Return)
        compare(widget.spaceName, "Research")

        var search = findChild(content, "pluginSearch")
        search.text = "hey"
        wait(50)
        compare(content.filteredPlugins.length, 1)
        var row = findChild(content, "pluginRow:37signals.hey")
        verify(row.inBar)
        mouseClick(row)
        verify(!row.inBar)
        keyClick(Qt.Key_Space)
        verify(row.inBar)
        search.text = "no matching plugin"
        compare(content.filteredPlugins.length, 0)
        search.text = ""

        mouseClick(findChild(content, "removeSpace"))
        wait(50)
        mouseClick(findChild(content, "cancelRemoval"))
        compare(widget.spaceName, "Research")
        mouseClick(findChild(content, "removeSpace"))
        wait(50)
        mouseClick(findChild(content, "confirmRemoval"))
        compare(widget.state.activeSpace, "global")
        widget.selectSpace(savedSpace)
        compare(picker.value, savedSpace)
        var modes = findChild(content, "viewMode:space")
        modes.forceActiveFocus()
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Return)
        compare(widget.state.mode, "defaults")
        keyClick(Qt.Key_Return)
        compare(widget.state.mode, "space")
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Return)
        compare(widget.state.mode, "all")
        keyClick(Qt.Key_Return)
        compare(widget.state.mode, "space")
        compare(widget.hiddenIds.length, 1)
        widget.renameSpace(savedSpace, "Writing")
        window.contentItem.forceActiveFocus()
        mouseMove(window.contentItem, 2, 780)
        widget.open()
        verify(widget.opened)
        verify(content.height < window.height - 40)
        wait(200)
        var done = false
        capture.grabToImage(function(result) {
          result.saveToFile(Quickshell.env("DRAWER_TEST_IMAGE"))
          done = true
        })
        tryVerify(function() { return done }, 3000)
        console.log("DRAWER_UI_OK")
        quitTimer.start()
      }
    }
  }
}
