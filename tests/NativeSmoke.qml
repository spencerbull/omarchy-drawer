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
    property var config: ({bar: {position: Quickshell.env("DRAWER_POSITION") || "bottom", transparent: false, centerAnchor: "omarchy.center", layout: {left: [], center: [{id:"omarchy.center"}], right: [{id: "test.widget", preserved: "keep me"}, {id: "omarchy.example"}, {
      id: "spencerbull.drawer", drawerController: true,
      drawerState: {version: 1, activeSpace: "space-1", mode: "space", returnMode: "all", spaces: [
        {id: "global", name: "Global", hidden: ["omarchy.example"]},
        {id: "space-1", name: "Writing", hidden: ["test.widget"]}
      ]},
      hiddenWidgets: ["test.widget"]
    }]}}})
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
      property bool opened: false
      property alias testPanel: childPanel
      function close() { opened = false }
      readonly property var ownService: bar && bar.shell ? bar.shell.serviceFor("test.widget") : null
      WidgetButton { id: button; bar: demo.bar; text: demo.moduleName === "test.widget" ? "Demo" : "Stock"; onPressed: { if (demo.ownService) demo.ownService.count++; demo.opened = true } }
      KeyboardPanel {
        id: childPanel
        anchorItem: button
        bar: demo.bar
        owner: demo
        open: demo.opened
        contentWidth: 240
        contentHeight: 120
        Text { text: "Service panel"; color: Color.foreground }
      }
    }
  }
  QtObject {
    id: registry
    property var widgets: ({"omarchy.center": {component:exampleComponent,metadata:{firstParty:false,displayName:"Center anchor"}}, "spencerbull.drawer": {component: drawerComponent, metadata: {firstParty:false,displayName:"Drawer"}}, "test.widget": {component:exampleComponent,metadata:{firstParty:false,displayName:"Service demo"}}, "omarchy.example":{component:exampleComponent,metadata:{firstParty:false,displayName:"Stock example"}}})
    property int revision: 1
    function metadataFor(id) { return widgets[id] ? widgets[id].metadata : null }
  }
  Stock.Bar { id: bar; shell: hostShell; barWidgetRegistry: registry; barConfig: hostShell.config.bar }
  Timer { id: done; interval: 300; onTriggered: Qt.quit() }
  Timer { interval: 14000; running: true; onTriggered: { console.error("NATIVE_TIMEOUT"); Qt.quit() } }
  TestCase {
    id: test
    name: "DrawerNative"
    parent: bar.moduleSlots.length && bar.moduleSlots[0].originalWindow ? bar.moduleSlots[0].originalWindow.contentItem : null
    when: bar.moduleSlots.length >= 3
    function slot(id) {
      for (var i=0;i<bar.moduleSlots.length;i++) if(bar.moduleSlots[i].moduleName === id) return bar.moduleSlots[i]
      return null
    }
    function drag(source, target) {
      var scene = bar.scenePointInWindow(target.mapToItem(null, target.width / 2, target.height / 2), bar.slotWindow(target), bar.slotWindow(source))
      var at = source.mapFromItem(null, scene.x, scene.y)
      mousePress(source, source.width/2, source.height/2, Qt.LeftButton)
      mouseMove(source, source.width/2 + 8, source.height/2, 30)
      mouseMove(source, at.x, at.y, 80)
      console.log("NATIVE_DRAG", bar.barDragTarget ? bar.barDragTarget.moduleName : "none", at.x, at.y, bar.barDragSceneX, bar.barDragSceneY, source.region, target.drawerController)
      console.log("NATIVE_HIT", bar.slotContainsScenePoint(target, source.mapToItem(null, at.x, at.y), bar.barDragWindow), source.originalWindow, target.originalWindow, bar.barDragWindow, JSON.stringify(source.mapToItem(null, at.x, at.y)), JSON.stringify(target.mapToItem(null,0,0)))
      mouseRelease(source, at.x, at.y, Qt.LeftButton)
      wait(150)
    }
    function test_native_drag() {
      console.log("NATIVE_STAGE start")
      wait(500)
      // Real host injection wraps nested settings in QVariant sequences. Saved
      // visibility and named spaces must survive before any user interaction.
      var restored = slot("spencerbull.drawer").activeItem
      compare(restored.state.activeSpace, "space-1")
      compare(restored.spaceName, "Writing")
      compare(restored.state.spaces.length, 2)
      compare(restored.state.spaces[0].hidden.join(","), "omarchy.example")
      compare(restored.hiddenIds.join(","), "test.widget")
      compare(restored.state.returnMode, "all")
      restored.restoreBarWidget("test.widget")
      wait(150)
      var baseline = JSON.parse(JSON.stringify(hostShell.config))
      var transient = JSON.parse(JSON.stringify(baseline))
      transient.bar.layout.right = []
      hostShell.config = transient
      hostShell.config = baseline
      wait(200)
      var controllerSlot = slot("spencerbull.drawer")
      var demoSlot = slot("test.widget")
      verify(controllerSlot !== null && demoSlot !== null)
      var widget = controllerSlot.activeItem
      var originalInstance = demoSlot.activeItem
      compare(originalInstance.ownService, service)
      compare(widget.supported, true)
      widget.setHidden("omarchy.center", true)
      wait(150)
      var centerCount = 0
      for (var i = 0; i < bar.moduleSlots.length; i++) {
        var candidate = bar.moduleSlots[i]
        if(candidate.moduleName === "omarchy.center" && candidate.region === "drawer" && candidate.originalWindow === controllerSlot.originalWindow) centerCount++
      }
      compare(centerCount, 1, "one live center-anchor widget per drawer")
      widget.setHidden("omarchy.center", false)
      wait(150)
      console.log("NATIVE_STAGE before drag", demoSlot.x, controllerSlot.x)
      drag(demoSlot, controllerSlot)
      console.log("NATIVE_STAGE after drag", JSON.stringify(widget.hiddenIds), demoSlot.region, JSON.stringify(hostShell.config))
      compare(widget.hiddenIds.indexOf("test.widget") >= 0, true)
      compare(demoSlot.activeItem, originalInstance)
      compare(demoSlot.region, "drawer")
      compare(hostShell.config.bar.layout.right[0].preserved, "keep me")
      console.log("NATIVE_STAGE opening")
      widget.open()
      wait(300)
      compare(widget.opened, true)
      verify(controllerSlot.drawerPanel.visible)
      mouseClick(demoSlot, demoSlot.width/2, demoSlot.height/2, Qt.LeftButton)
      console.log("NATIVE_STAGE clicked", service.count)
      compare(service.count, 1)
      wait(250)
      verify(originalInstance.opened, "hidden widget popup opened")
      verify(!widget.opened, "drawer closes for child popup handoff")
      verify(controllerSlot.drawerPanel.visible, "drawer window retained for child popup")
      compare(controllerSlot.drawerPanel.mask.width, 0, "closed drawer has empty input mask")
      verify(originalInstance.testPanel.cardOrigin.y + originalInstance.testPanel.contentHeight <= controllerSlot.originalWindow.screen.height, "child popup fits screen")
      originalInstance.close()
      widget.open()
      wait(200)
      var captured = false
      controllerSlot.drawerPanel.contentItem[0].parent.parent.grabToImage(function(result) {
        result.saveToFile(Quickshell.env("DRAWER_NATIVE_IMAGE")); captured = true
      })
      tryVerify(function() { return captured }, 3000)
      drag(demoSlot, slot("omarchy.example"))
      compare(widget.hiddenIds.indexOf("test.widget"), -1)
      compare(demoSlot.activeItem, originalInstance)
      compare(demoSlot.region, "right")
      verify(bar.vertical ? demoSlot.mapToItem(null,0,0).y < slot("omarchy.example").mapToItem(null,0,0).y : demoSlot.mapToItem(null,0,0).x < slot("omarchy.example").mapToItem(null,0,0).x, "restored original order")
      widget.toggleDefaults()
      wait(100)
      compare(demoSlot.region, "drawer")
      widget.toggleDefaults()
      wait(100)
      compare(demoSlot.region, "right")
      verify(bar.vertical ? demoSlot.mapToItem(null,0,0).y < slot("omarchy.example").mapToItem(null,0,0).y : demoSlot.mapToItem(null,0,0).x < slot("omarchy.example").mapToItem(null,0,0).x, "restored original order")
      widget.close()
      wait(200)
      verify(!widget.opened)
      console.log("DRAWER_NATIVE_OK")
      harness.finished = true
      done.start()
    }
  }
}
