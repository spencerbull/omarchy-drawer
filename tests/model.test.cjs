const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const model = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '..', 'Model.js'), 'utf8'), model);
const json = value => JSON.parse(JSON.stringify(value));
const ids = ['omarchy.clock', 'omarchy.tray', 'example.music', 'example.work', 'spencerbull.drawer'];
const hide = (state, id) => model.setHidden(state, id, true, ids);

test('a new configuration shows all configured plugins, including future additions', () => {
    const state = model.normalize(null);
    assert.equal(state.activeSpace, 'global');
    assert.equal(state.spaces[0].name, 'Global');
    for (const id of ids.concat('example.new')) assert.equal(model.visible(state, id), true);
    const edited = hide(state, 'example.music');
    assert.equal(model.visible(edited, 'example.music'), false);
    assert.equal(model.visible(edited, 'example.new'), true);
});

test('Defaults temporarily shows omarchy IDs and controller; toggling restores custom or All view', () => {
    const configured = hide(hide(model.normalize(), 'example.work'), 'omarchy.clock');
    const defaults = model.toggleDefaults(configured);
    assert.deepEqual(json(model.hiddenIds(defaults, ids)), ['example.music', 'example.work']);
    assert.equal(model.visible(defaults, 'not.omarchy.clock'), false);
    assert.equal(model.visible(defaults, 'omarchy2.clock'), false);
    assert.equal(model.visible(defaults, 'spencerbull.drawer'), true);
    assert.deepEqual(json(model.toggleDefaults(defaults)), json(configured));
    const all = model.setMode(configured, 'all');
    const restored = model.toggleDefaults(model.toggleDefaults(all));
    assert.equal(restored.mode, 'all');
    assert.deepEqual(json(model.hiddenIds(restored, ids)), []);
    assert.deepEqual(json(model.setMode(restored, 'space').spaces), json(configured.spaces));
});

test('spaces copy custom configuration and then change independently', () => {
    const global = hide(model.normalize(), 'example.music');
    const work = model.createSpace(global, '  Work  ');
    assert.equal(work.spaces[1].name, 'Work');
    assert.equal(work.mode, 'space');
    assert.equal(model.visible(work, 'example.music'), false);
    const edited = hide(work, 'example.work');
    const returned = model.selectSpace(model.setMode(edited, 'all'), 'global');
    assert.equal(returned.mode, 'space');
    assert.equal(model.visible(returned, 'example.work'), true);
    assert.equal(model.visible(edited, 'example.work'), false);
    assert.equal(global.spaces.length, 1);
    const second = model.createSpace(edited, 'Work');
    assert.notEqual(second.activeSpace, work.activeSpace);
});

test('first edits to Defaults or All preserve the visible view in the active space', () => {
    const configured = hide(model.normalize(), 'omarchy.clock');
    const defaults = model.setMode(configured, 'defaults');
    const edited = model.setHidden(defaults, 'example.music', false, ids);
    assert.equal(edited.mode, 'space');
    assert.deepEqual(json(model.hiddenIds(edited, ids)), ['example.work']);
    const all = model.setMode(configured, 'all');
    const allEdited = hide(all, 'example.work');
    assert.deepEqual(json(model.hiddenIds(allEdited, ids)), ['example.work']);
    assert.equal(model.visible(configured, 'omarchy.clock'), false);
});

test('controller cannot be hidden by input or editing', () => {
    const raw = { spaces: [{ id: 'global', hidden: ['spencerbull.drawer'] }] };
    const state = hide(raw, 'spencerbull.drawer');
    assert.deepEqual(json(state.spaces[0].hidden), []);
    for (const mode of ['space', 'defaults', 'all'])
        assert.equal(model.visible(model.setMode(state, mode), 'spencerbull.drawer'), true);
});

test('rename and removal retain a permanent Global and select it when removing the active space', () => {
    const state = model.createSpace(model.normalize(), 'Work');
    const id = state.activeSpace;
    assert.equal(model.renameSpace(state, id, ' Focus ').spaces[1].name, 'Focus');
    assert.equal(model.renameSpace(state, id, ' ').spaces[1].name, 'Work');
    assert.equal(model.renameSpace(state, 'global', 'Elsewhere').spaces[0].name, 'Global');
    assert.equal(model.deleteSpace(state, 'global').spaces.length, 2);
    const deleted = model.deleteSpace(model.setMode(state, 'defaults'), id);
    assert.equal(deleted.activeSpace, 'global');
    assert.equal(deleted.mode, 'space');
    assert.equal(deleted.spaces.length, 1);
    assert.equal(model.selectSpace(state, 'missing').activeSpace, id);
});

test('persistence roundtrip retains all spaces, custom hidden sets, and temporary return mode', () => {
    let state = model.createSpace(hide(model.normalize(), 'example.work'), 'Music');
    state = model.setHidden(state, 'example.work', false, ids);
    state = hide(state, 'example.music');
    state = model.toggleDefaults(model.setMode(state, 'all'));
    const restored = model.normalize(JSON.parse(JSON.stringify(state)));
    assert.deepEqual(json(restored), json(state));
    assert.equal(model.toggleDefaults(restored).mode, 'all');
    assert.equal(model.visible(model.selectSpace(restored, 'global'), 'example.work'), false);
    assert.equal(model.visible(model.selectSpace(restored, state.activeSpace), 'example.work'), true);
});

test('malformed configuration is repaired with bounded names, spaces, IDs and unique space IDs', () => {
    for (const raw of [undefined, null, [], true, 7, 'broken', { spaces: {} }])
        assert.equal(model.normalize(raw).activeSpace, 'global');
    const raw = { version: 99, activeSpace: 'missing', mode: 'broken', returnMode: 'defaults', spaces: [
        null, {}, { id: 'global', hidden: ['a', 'a', null, '', 1, 'spencerbull.drawer'] },
        { id: 'global', hidden: ['b'] },
        { id: 'work', name: 'x'.repeat(100), hidden: {} },
        { id: 'work', name: 'duplicate' }, { id: '', name: 'empty' },
        ...Array.from({ length: 50 }, (_, i) => ({ id: `space-${i}`, name: `Space ${i}` }))
    ] };
    const normalized = model.normalize(raw);
    assert.equal(normalized.version, 1);
    assert.equal(normalized.mode, 'space');
    assert.equal(normalized.returnMode, 'space');
    assert.equal(normalized.activeSpace, 'global');
    assert.deepEqual(json(normalized.spaces[0].hidden), ['a']);
    assert.equal(normalized.spaces[1].name.length, 60);
    assert.equal(normalized.spaces.length, 32);
    assert.equal(model.createSpace(normalized, 'Overflow').spaces.length, 32);
    assert.equal(model.createSpace(model.normalize(), ' ').spaces.length, 1);
});

test('all mutation helpers leave deeply frozen caller input intact', () => {
    function freeze(value) {
        if (value && typeof value === 'object') {
            Object.values(value).forEach(freeze);
            Object.freeze(value);
        }
        return value;
    }
    const state = freeze(json(model.createSpace(hide(model.normalize(), 'example.music'), 'Work')));
    const before = JSON.stringify(state);
    model.normalize(state);
    model.setMode(state, 'defaults');
    model.toggleDefaults(state);
    model.createSpace(state, 'Other');
    model.selectSpace(state, 'global');
    model.renameSpace(state, state.activeSpace, 'Renamed');
    model.deleteSpace(state, state.activeSpace);
    model.setHidden(state, 'example.work', true, ids);
    assert.equal(JSON.stringify(state), before);
});

test('layout entries deduplicate instances and preserve original settings and section', () => {
    const clock = Object.freeze({ id: 'omarchy.clock', format: 'HH:mm', nested: { enabled: true } });
    const layout = { left: [null, 'example.music', {}, 1], center: [clock],
        right: [{ id: 'omarchy.clock', format: 'different' }, 'example.music', { id: 'example.work' }] };
    const result = model.entries(layout);
    assert.deepEqual(json(result.map(entry => [entry.id, entry.section])), [
        ['example.music', 'left'], ['omarchy.clock', 'center'], ['example.work', 'right']
    ]);
    assert.equal(result[1].entry, clock);
    assert.deepEqual(json(model.hiddenIds(hide(model.normalize(), 'omarchy.clock'), result.map(e => e.id))), ['omarchy.clock']);
    assert.deepEqual(json(model.entries(null)), []);
    assert.deepEqual(json(model.entries({ left: 'bad', center: [false, { id: '' }] })), []);
});

test('profile interface is versioned, detached and rejects unknown IDs', () => {
    const state = model.createSpace(model.normalize(null), 'Writing');
    const status = model.status(state, ids, true);
    assert.equal(status.version, 1);
    assert.equal(status.supported, true);
    assert.equal(status.activeProfile, state.activeSpace);
    status.profiles[0].name = 'changed';
    assert.equal(state.spaces[0].name, 'Global');
    assert.equal(model.hasProfile(state, 'missing'), false);
    assert.equal(model.knownWidget(ids, 'missing'), false);
    assert.equal(model.knownWidget(ids, model.CONTROLLER_ID), false);
});

test('large visibility sets preserve prototype-like IDs and deduplicate', () => {
    const catalog = ['__proto__', 'constructor'].concat(Array.from({length: 4094}, (_, i) => 'plugin.' + i));
    const state = model.normalize({spaces: [{id: 'global', hidden: catalog}]});
    assert.equal(model.hiddenIds(state, catalog.concat(catalog)).length, 4096);
});
