import QtQuick
import QtTest
import Quickshell
import qs.Commons
import qs.Ui
import "stock" as Stock
import "plugin" as Plugin

ShellRoot {
  id: harness
  property bool finished: false
  QtObject { id: service; property int count: 0 }
  QtObject {
    id: hostShell
    property var config: ({bar: {position: "bottom", transparent: false, centerAnchor: "", layout: {left: [], center: [], right: [{id: "test.widget", preserved: "keep me"}, {id: "omarchy.example"}, {id: "spencerbull.drawer", drawerController: true}]}}})
    function pluginShellForId(id) { return scopedShell }
    function mutateShellConfig(mutator) {
      var next = JSON.parse(JSON.stringify(config)); mutator(next); config = next
    }
  }
  QtObject {
    id: scopedShell
    function serviceFor(id) { return id === "test.widget" ? service : null }
    function updateEntryInline(id, entry) {
      var next = JSON.parse(JSON.stringify(hostShell.config))
      var rows = next.bar.layout.right
      for (var i = 0; i < rows.length; i++) if (rows[i].id === id) {
        if (JSON.stringify(rows[i]) === JSON.stringify(entry)) return false
        rows[i] = entry; hostShell.config = next; return true
      }
      return false
    }
  }
  Component { id: drawerComponent; Plugin.BarWidget {} }
  Component {
    id: exampleComponent
    BarWidget {
      id: demo
      implicitWidth: button.implicitWidth
      implicitHeight: button.implicitHeight
      readonly property var ownService: bar && bar.shell ? bar.shell.serviceFor("test.widget") : null
      WidgetButton { id: button; bar: demo.bar; text: demo.moduleName === "test.widget" ? "Demo" : "Stock"; onPressed: if (demo.ownService) demo.ownService.count++ }
    }
  }
  QtObject {
    id: registry
    property var widgets: ({"spencerbull.drawer": {component: drawerComponent, metadata: {firstParty:false,displayName:"Drawer"}}, "test.widget": {component:exampleComponent,metadata:{firstParty:false,displayName:"Service demo"}}, "omarchy.example":{component:exampleComponent,metadata:{firstParty:false,displayName:"Stock example"}}})
    property int revision: 1
    function metadataFor(id) { return widgets[id] ? widgets[id].metadata : null }
  }
  Stock.Bar { id: bar; shell: hostShell; barWidgetRegistry: registry; barConfig: hostShell.config.bar }
  Timer { id: done; interval: 300; onTriggered: Qt.quit() }
  Timer { interval: 14000; running: true; onTriggered: { console.error("NATIVE_TIMEOUT"); Qt.quit() } }
  TestCase {
    id: test
    name: "DrawerNative"
    when: bar.moduleSlots.length >= 3
    function slot(id) {
      for (var i=0;i<bar.moduleSlots.length;i++) if(bar.moduleSlots[i].moduleName === id) return bar.moduleSlots[i]
      return null
    }
    function drag(source, target) {
      var at = target.mapToItem(source, target.width / 2, target.height / 2)
      mousePress(source, source.width/2, source.height/2, Qt.LeftButton)
      mouseMove(source, source.width/2 + 8, source.height/2, 30)
      mouseMove(source, at.x, at.y, 80)
      mouseRelease(source, at.x, at.y, Qt.LeftButton)
      wait(150)
    }
    function test_native_drag() {
      wait(500)
      var controllerSlot = slot("spencerbull.drawer")
      var demoSlot = slot("test.widget")
      verify(controllerSlot !== null && demoSlot !== null)
      var widget = controllerSlot.activeItem
      var originalInstance = demoSlot.activeItem
      compare(originalInstance.ownService, service)
      compare(widget.supported, true)
      drag(demoSlot, controllerSlot)
      compare(widget.hiddenIds.indexOf("test.widget") >= 0, true)
      compare(demoSlot.activeItem, originalInstance)
      compare(demoSlot.region, "drawer")
      compare(hostShell.config.bar.layout.right[0].preserved, "keep me")
      widget.open()
      wait(300)
      compare(widget.opened, true)
      verify(controllerSlot.drawerPanel.visible)
      mouseClick(demoSlot, demoSlot.width/2, demoSlot.height/2, Qt.LeftButton)
      compare(service.count, 1)
      var captured = false
      controllerSlot.drawerPanel.contentItem[0].grabToImage(function(result) {
        result.saveToFile(Quickshell.env("DRAWER_NATIVE_IMAGE")); captured = true
      })
      tryVerify(function() { return captured }, 3000)
      drag(demoSlot, slot("omarchy.example"))
      compare(widget.hiddenIds.indexOf("test.widget"), -1)
      compare(demoSlot.activeItem, originalInstance)
      compare(demoSlot.region, "right")
      widget.toggleDefaults()
      wait(100)
      compare(demoSlot.region, "drawer")
      widget.toggleDefaults()
      wait(100)
      compare(demoSlot.region, "right")
      widget.close()
      wait(200)
      verify(!widget.opened)
      console.log("DRAWER_NATIVE_OK")
      harness.finished = true
      done.start()
    }
  }
}
