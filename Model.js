// Pure state helpers shared by QML and the Node test suite.
var CONTROLLER_ID = "spencerbull.drawer";
var MAX_SPACES = 32;
var MAX_NAME_LENGTH = 60;
var MAX_IDS = 4096;

function object(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validId(value) {
    return typeof value === "string" && value.length > 0 && value.length <= 256
        && value.trim() === value;
}

function uniqueIds(values) {
    var result = [];
    var seen = Object.create(null);
    if (!Array.isArray(values)) return result;
    for (var i = 0; i < values.length && result.length < MAX_IDS; i++) {
        var id = values[i];
        if (validId(id) && id !== CONTROLLER_ID && !seen[id]) {
            result.push(id);
            seen[id] = true;
        }
    }
    return result;
}

function cleanName(value) {
    return typeof value === "string" ? value.trim().slice(0, MAX_NAME_LENGTH) : "";
}

function normalize(raw) {
    raw = object(raw) ? raw : {};
    var spaces = [{ id: "global", name: "Global", hidden: [] }];
    var seen = ["global"];
    var input = Array.isArray(raw.spaces) ? raw.spaces : [];
    var globalFound = false;
    for (var i = 0; i < input.length; i++) {
        var space = input[i];
        if (!object(space) || !validId(space.id)) continue;
        if (space.id === "global") {
            if (!globalFound) spaces[0].hidden = uniqueIds(space.hidden);
            globalFound = true;
            continue;
        }
        if (spaces.length >= MAX_SPACES || seen.indexOf(space.id) !== -1) continue;
        var name = cleanName(space.name);
        if (!name) continue;
        spaces.push({ id: space.id, name: name, hidden: uniqueIds(space.hidden) });
        seen.push(space.id);
    }
    return {
        version: 1,
        activeSpace: seen.indexOf(raw.activeSpace) !== -1 ? raw.activeSpace : "global",
        mode: raw.mode === "defaults" || raw.mode === "all" ? raw.mode : "space",
        returnMode: raw.returnMode === "all" ? "all" : "space",
        spaces: spaces
    };
}

function activeSpace(state) {
    for (var i = 0; i < state.spaces.length; i++)
        if (state.spaces[i].id === state.activeSpace) return state.spaces[i];
    return state.spaces[0];
}

function visibleNormalized(state, id) {
    if (id === CONTROLLER_ID) return true;
    if (!validId(id)) return false;
    if (state.mode === "all") return true;
    if (state.mode === "defaults") return id.indexOf("omarchy.") === 0;
    return activeSpace(state).hidden.indexOf(id) === -1;
}

function visible(state, id) {
    return visibleNormalized(normalize(state), id);
}

function setMode(state, mode) {
    var next = normalize(state);
    if (mode !== "space" && mode !== "defaults" && mode !== "all") return next;
    if (mode === "defaults" && next.mode !== "defaults") next.returnMode = next.mode;
    next.mode = mode;
    return next;
}

function toggleDefaults(state) {
    var next = normalize(state);
    return setMode(next, next.mode === "defaults" ? next.returnMode : "defaults");
}

function createSpace(state, name) {
    var next = normalize(state);
    name = cleanName(name);
    if (!name || next.spaces.length >= MAX_SPACES) return next;
    var existing = next.spaces.map(function(space) { return space.id; });
    var suffix = 1;
    while (existing.indexOf("space-" + suffix) !== -1) suffix++;
    var id = "space-" + suffix;
    next.spaces.push({ id: id, name: name, hidden: activeSpace(next).hidden.slice() });
    next.activeSpace = id;
    next.mode = "space";
    return next;
}

function selectSpace(state, id) {
    var next = normalize(state);
    for (var i = 0; i < next.spaces.length; i++) {
        if (next.spaces[i].id === id) {
            next.activeSpace = id;
            next.mode = "space";
            break;
        }
    }
    return next;
}

function renameSpace(state, id, name) {
    var next = normalize(state);
    name = cleanName(name);
    if (!name || id === "global") return next;
    for (var i = 0; i < next.spaces.length; i++)
        if (next.spaces[i].id === id) next.spaces[i].name = name;
    return next;
}

function deleteSpace(state, id) {
    var next = normalize(state);
    if (id === "global") return next;
    next.spaces = next.spaces.filter(function(space) { return space.id !== id; });
    if (next.activeSpace === id) {
        next.activeSpace = "global";
        next.mode = "space";
    }
    return next;
}

// ids is the current widget catalog. Supply it when editing a temporary view
// so the first edit preserves what is currently on screen in the active space.
function setHidden(state, id, hidden, ids) {
    var next = normalize(state);
    if (!validId(id) || id === CONTROLLER_ID) return next;
    var space = activeSpace(next);
    if (next.mode !== "space") {
        var catalog = uniqueIds(Array.isArray(ids) ? ids : space.hidden.concat([id]));
        space.hidden = hiddenIds(next, catalog);
        next.mode = "space";
    }
    var index = space.hidden.indexOf(id);
    if (hidden && index === -1 && space.hidden.length < MAX_IDS) space.hidden.push(id);
    if (!hidden && index !== -1) space.hidden.splice(index, 1);
    return next;
}

function hiddenIds(state, ids) {
    var next = normalize(state);
    var hidden = Object.create(null);
    activeSpace(next).hidden.forEach(function(id) { hidden[id] = true; });
    return uniqueIds(ids).filter(function(id) {
        if (next.mode === "all") return false;
        if (next.mode === "defaults") return id.indexOf("omarchy.") !== 0;
        return hidden[id] === true;
    });
}

// Visibility is per plugin id even when the layout contains several instances.
// Keep the first raw entry intact, including all plugin-specific settings.
function entries(layout) {
    if (!object(layout)) return [];
    var result = [];
    var seen = [];
    var sections = ["left", "center", "right"];
    for (var s = 0; s < sections.length; s++) {
        var section = sections[s];
        var values = Array.isArray(layout[section]) ? layout[section] : [];
        for (var i = 0; i < values.length; i++) {
            var entry = values[i];
            var id = typeof entry === "string" ? entry : object(entry) ? entry.id : null;
            if (!validId(id) || seen.indexOf(id) !== -1) continue;
            result.push({ id: id, entry: entry, section: section });
            seen.push(id);
        }
    }
    return result;
}

// Versioned scalar-only integration. No plugin/service objects cross IPC.
function status(state, ids, supported) {
    var next = normalize(state);
    return { version: 1, supported: supported === true, mode: next.mode,
        activeProfile: next.activeSpace,
        profiles: next.spaces.map(function(space) { return { id: space.id, name: space.name }; }),
        hiddenIds: hiddenIds(next, ids) };
}
function hasProfile(state, id) {
    return normalize(state).spaces.some(function(space) { return space.id === id; });
}
function knownWidget(ids, id) {
    return validId(id) && id !== CONTROLLER_ID && uniqueIds(ids).indexOf(id) !== -1;
}
