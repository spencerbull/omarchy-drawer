const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(process.argv[2], 'shell/plugins/bar/Bar.qml'), 'utf8');
function method(name) {
  const start = source.indexOf(`  function ${name}(`);
  assert(start >= 0, `Missing ${name}`);
  const body = source.indexOf('{', start);
  let depth = 1, end = body + 1;
  while (depth) { if (source[end] === '{') depth++; if (source[end] === '}') depth--; end++; }
  return source.slice(start, end);
}
const screen = { name: 'one', width: 1000, height: 800 };
const barWindow = { screen, width: 1000, height: 30, contentItem: {} };
const drawerWindow = { screen, width: 1000, height: 800, contentItem: {} };
const layout = { left: [{ id: 'omarchy.menu' }], center: [{ id: 'test.music' }], right: [{ id: 'test.drawer', drawerController: true, hiddenWidgets: ['test.music', 'test.drawer'] }] };
const context = {
  drawerRevision: 0, drawerHosts: [], layoutConfig: layout, moduleSlots: [],
  entryId: e => e.id, entrySettings: e => e, canonicalWidgetId: id => id,
  BarModel: require(path.join(process.argv[2], 'shell/plugins/bar/BarModel.js')),
  focusedScreenName: () => 'one', slotScreenName: () => 'one',
  sameWindow: (a,b) => a === b,
  slotWindow: slot => slot.window,
  position: 'top', vertical: false,
  barWidgetRegistry: { widgets: { 'omarchy.menu': { metadata: { displayName: 'Menu' } } } },
};
context.root = context;
vm.createContext(context);
for (const name of ['drawerControllerFor', 'publicDrawerEntries', 'setPluginDrawerOpen', 'windowScreenPoint', 'scenePointInWindow', 'slotContainsScenePoint', 'moduleDropAtScene', 'dropBarModuleAtTarget', 'syncDrawerParent', 'restoreDrawerOrder']) vm.runInContext(method(name), context);
assert.equal(context.drawerControllerFor('test.music'), 'test.drawer');
assert.equal(context.drawerControllerFor('test.drawer'), '');
assert.equal(context.drawerControllerFor('unknown'), '');
assert.equal(context.publicDrawerEntries('foreign').length, 0);
assert.equal(context.publicDrawerEntries('test.drawer')[0].name, 'Menu');
const catalog = context.publicDrawerEntries('test.drawer'); catalog[0].id = 'tampered';
assert.equal(layout.left[0].id, 'omarchy.menu');
assert.equal(context.setPluginDrawerOpen('foreign', true), false);
const panel = { open: false };
context.moduleSlots = [{ pluginApiId: 'test.drawer', drawerController: true, drawerPanel: panel }];
assert.equal(context.setPluginDrawerOpen('test.drawer', true), true);
assert.equal(panel.open, true);
const otherPanel = { open: true };
context.moduleSlots.push({ pluginApiId: 'test.drawer', drawerController: true, drawerPanel: otherPanel });
context.setPluginDrawerOpen('test.drawer', false);
assert.equal(panel.open, false); assert.equal(otherPanel.open, false);
let siblingParents = [];
const sibling = { moduleName: 'test.second', set parent(value) { siblingParents.push(value); } };
context.originalParent = { children: [sibling] };
context.drawerHost = null;
context.parent = {};
context.layoutRegion = 'center';
context.moduleName = 'test.first';
context.slot = {};
context.slot.restoreDrawerOrder = context.restoreDrawerOrder;
context.layoutEntries = () => [{id: 'test.first'}, {id: 'test.second'}];
context.entryIndex = (entries, id) => entries.findIndex(entry => entry.id === id);
context.syncDrawerParent();
assert.equal(siblingParents.length, 2);
assert.equal(siblingParents[0], null);
assert.equal(siblingParents[1], context.originalParent);
assert.equal(context.parent, context.originalParent);
let accepted = '', restored = '', moved = false;
const target = { originalWindow: barWindow, window: barWindow, moduleName: 'test.drawer', region: 'right', drawerController: true, width: 40, height: 30, visible: true, mapToItem: () => ({x: 900,y: 0}), activeItem: { acceptBarDrop: id => accepted = id } };
const sourceSlot = { originalWindow: barWindow, window: barWindow, moduleName: 'test.music', region: 'center', drawerController: false };
context.nextVisibleModuleName = () => '';
context.dropBarModule = () => moved = true;
assert.equal(context.dropBarModuleAtTarget(sourceSlot, target, false, {x:910,y:10}, barWindow), true);
assert.equal(accepted, 'test.music'); assert.equal(moved, false);
accepted = '';
context.dropBarModuleAtTarget(sourceSlot, target, false, {x:899,y:10}, barWindow);
assert.equal(accepted, ''); assert.equal(moved, true);
const hidden = {...sourceSlot, region: 'drawer', window: drawerWindow, drawerHost: {controllerSlot: {activeItem: {restoreBarWidget: id => restored = id}}}};
context.moduleSlots = [target, hidden];
assert.equal(context.moduleDropAtScene({x:910,y:400}, hidden), null);
assert.equal(context.moduleDropAtScene({x:910,y:10}, hidden).slot, target);
context.dropBarModuleAtTarget(hidden, target, false, {x:910,y:10}, drawerWindow);
assert.equal(restored, 'test.music');
context.position = 'bottom';
assert.equal(context.moduleDropAtScene({x:910,y:785}, hidden).slot, target);
assert.equal(context.moduleDropAtScene({x:910,y:600}, hidden), null);
context.position = 'right';
barWindow.width = 30; barWindow.height = 800;
assert.equal(context.moduleDropAtScene({x:985,y:10}, hidden).slot, target);
assert.equal(context.moduleDropAtScene({x:600,y:10}, hidden), null);
// Prove the real native edge algorithm's tie, then verify receiving priority.
context.position = 'left'; context.vertical = true;
screen.height = 1000; barWindow.height = 1000;
const neighbor = {...target, moduleName: 'omarchy.example', drawerController: false, width: 28, height: 28, mapToItem: () => ({x:0,y:784})};
const largeController = {...target, width: 28, height: 54, mapToItem: () => ({x:0,y:812})};
const tiePoint = {x:14,y:839};
const edgeCandidates = [neighbor, largeController].map(slot => ({slot, ...slot.mapToItem(), width:slot.width, height:slot.height}));
assert.equal(context.BarModel.nearestDropTarget(edgeCandidates, tiePoint, true).slot, neighbor);
context.moduleSlots = [neighbor, largeController];
assert.equal(context.moduleDropAtScene(tiePoint, sourceSlot).slot, largeController);
assert.equal(context.moduleDropAtScene({x:14,y:811}, sourceSlot).slot, neighbor);
assert.equal(context.moduleDropAtScene(tiePoint, {...sourceSlot, drawerController:true}).slot, neighbor);
console.log('Host contracts: controller safety, detached labels, scoped open, exact drop, restore and cross-window coordinates passed.');
