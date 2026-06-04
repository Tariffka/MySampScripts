local script_name = "CEF Character Stats"
local script_version = '1.0'

local AUTHOR_NAME = "RAYMOND"
local TELEGRAM_URL = "https://t.me/raymondes"
local TELEGRAM_HANDLE = "@raymondes"
local PROFILE_META_LOCK = 2091203375

script_author(AUTHOR_NAME)

require "lib.moonloader"

local acef = require("arizona-events")
local sampev = require("lib.samp.events")
local encoding = require("encoding")
local vkeys = require("vkeys")
local socket_ok, socket = pcall(require, "socket")

encoding.default = "CP1251"
local u8 = encoding.UTF8

local TD_COLLECT_DELAY = 0.35
local REQUEST_TIMEOUT = 2.20

local cefVisible = false
local waitingStats = false
local captureStarted = false

local lastRequestTime = 0.0
local lastTextdrawTime = 0.0
local lastRawStats = ""

local tdCollector = {}

local STATE_SERVER_HOST = "127.0.0.1"
local STATE_SERVER_PORT = 38129
local STATE_SERVER_ENDPOINT = "http://" .. STATE_SERVER_HOST .. ":" .. tostring(STATE_SERVER_PORT) .. "/ml_char_stats_state"
local STATE_FILE_NAME = "CEFStatsWindow.state.json"
local LOG_FILE_NAME = "CEFStatsWindow.log.txt"

local stateServer = nil
local stateServerThread = nil
local lastPersistedUiStateRaw = nil

local function profileMetaHash(s)
    local h = 7
    for i = 1, #s do
        h = (h * 131 + string.byte(s, i)) % 2147483647
    end
    return h
end

local function isProfileMetaIntact()
    return profileMetaHash(AUTHOR_NAME .. "\0" .. TELEGRAM_URL .. "\0" .. TELEGRAM_HANDLE) == PROFILE_META_LOCK
end

local function jsQuoted(value)
    return string.format("%q", tostring(value or ""))
end


local BASE_JS = [=[
(function () {
    if (window.mlCharStats && window.mlCharStats.ready) return;

    const STORAGE_KEY = 'ml_char_stats_rect_v7';
    const STORAGE_BACKUP_KEY = 'ml_char_stats_rect_v7_backup';
    const STORAGE_COOKIE_KEY = 'ml_char_stats_rect_v7';
    const STORAGE_KEY_LEGACY = 'ml_char_stats_rect_v6';
    const STORAGE_KEY_LEGACY_2 = 'ml_char_stats_rect_v5';
    const STORAGE_WINDOW_NAME_PREFIX = '__ml_char_stats_rect_v7__=';
    const STORAGE_WINDOW_NAME_PREFIX_LEGACY = '__ml_char_stats_rect_v6__=';
    const DEFAULT_RECT = { x: null, y: null, width: 1420, height: 752 };
    const MIN_WIDTH = 1020;
    const MIN_HEIGHT = 680;
    const VIEWPORT_MARGIN = 16;

    const VISUAL_STORAGE_KEY = 'ml_char_stats_visual_v1';
    const DEFAULT_VISUAL = {
        overlayOpacity: 0.08,
        panelOpacity: 0.94,
        shadowStrength: 0.55,
        accentColor: '#000000'
    };

    let dragState = null;
    let resizeState = null;
    let saveTimer = 0;
    let visualSaveTimer = 0;
    let interactionsBound = false;
    let settingsBound = false;
    let visualState = null;
    let rectState = null;
    let rectRevision = 0;
    let rectLastSavedSig = '';
    let rectWatchTimer = 0;
    let ignoreViewportSaveUntil = 0;
    let rectResizeObserver = null;
    let rectMutationObserver = null;
    let interactionRaf = 0;

    const LUA_STATE_KEY = '__mlCharStatsLuaState';
    const LUA_PERSIST_ENDPOINT = String(window.__mlCharStatsLuaPersistEndpoint || 'http://127.0.0.1:38129/ml_char_stats_state');

    function cloneStateValue(value) {
        if (value == null) return null;
        try { return JSON.parse(JSON.stringify(value)); } catch (e) { return null; }
    }

    function ensureLuaStateStore() {
        let store = window[LUA_STATE_KEY];
        if (!store || typeof store !== 'object') store = {};
        if (!store.version || typeof store.version !== 'number') store.version = 1;
        window[LUA_STATE_KEY] = store;
        return store;
    }

    const persistence = (function () {
        let remoteSaveTimer = 0;

        function scheduleRemoteSave() {
            if (remoteSaveTimer) clearTimeout(remoteSaveTimer);
            remoteSaveTimer = setTimeout(function () {
                remoteSaveTimer = 0;
                sendRemote();
            }, 70);
        }

        function buildPayload() { return JSON.stringify(ensureLuaStateStore()); }

        function sendRemote() {
            const payload = buildPayload();
            try {
                if (typeof navigator !== 'undefined' && navigator && typeof navigator.sendBeacon === 'function' && typeof Blob !== 'undefined') {
                    const blob = new Blob([payload], { type: 'text/plain;charset=UTF-8' });
                    if (navigator.sendBeacon(LUA_PERSIST_ENDPOINT, blob)) return true;
                }
            } catch (e) {}

            try {
                if (typeof fetch === 'function') {
                    fetch(LUA_PERSIST_ENDPOINT, {
                        method: 'POST', headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
                        body: payload, mode: 'cors', cache: 'no-store', credentials: 'omit', keepalive: true
                    }).catch(function () {});
                    return true;
                }
            } catch (e) {}

            try {
                const xhr = new XMLHttpRequest();
                xhr.open('POST', LUA_PERSIST_ENDPOINT, true);
                xhr.setRequestHeader('Content-Type', 'text/plain;charset=UTF-8');
                xhr.send(payload);
                return true;
            } catch (e) {}
            return false;
        }

        return {
            getRectEntry: function () { return cloneStateValue(ensureLuaStateStore().rectEntry); },
            setRectEntry: function (entry) { ensureLuaStateStore().rectEntry = cloneStateValue(entry); scheduleRemoteSave(); return entry; },
            getVisual: function () { return cloneStateValue(ensureLuaStateStore().visual); },
            setVisual: function (visual) { ensureLuaStateStore().visual = cloneStateValue(visual); scheduleRemoteSave(); return visual; },
            getLayout: function () { return cloneStateValue(ensureLuaStateStore().layout); },
            setLayout: function (layout) { ensureLuaStateStore().layout = cloneStateValue(layout); scheduleRemoteSave(); return layout; },
            clearLayout: function () { delete ensureLuaStateStore().layout; scheduleRemoteSave(); },
            flush: function () { if (remoteSaveTimer) { clearTimeout(remoteSaveTimer); remoteSaveTimer = 0; } return sendRemote(); }
        };
    })();

    window.mlCharStatsLoadItems = function() {
        try { var raw = window.localStorage.getItem('ml_char_stats_items_v2'); return raw ? JSON.parse(raw) : {}; } catch(e) { return {}; }
    };

    window.mlCharStatsSaveItems = function(state) {
        try { if(window.localStorage) window.localStorage.setItem('ml_char_stats_items_v2', JSON.stringify(state)); } catch(e) {}
    };

    window.mlCharStatsApplyItemsToRaw = function() {
        var itemState = window.mlCharStatsLoadItems();
        document.querySelectorAll('#ml_char_stats_content [data-container]').forEach(function(c) {
            var key = c.getAttribute('data-container');
            if (itemState[key]) {
                itemState[key].forEach(function(id) {
                    var child = null;
                    for(var i=0; i<c.children.length; i++) {
                        if (c.children[i].getAttribute('data-id') === id) { child = c.children[i]; break; }
                    }
                    if (child) c.appendChild(child);
                });
            }
        });
        document.querySelectorAll('#ml_char_stats_content [data-id]').forEach(function(el) {
            var id = el.getAttribute('data-id');
            if (itemState.hidden && itemState.hidden.indexOf(id) !== -1) {
                el.style.display = 'none';
            } else {
                el.style.display = '';
            }
        });
    };

    function getViewport() {
        const doc = document.documentElement || {};
        return {
            width: Math.max(doc.clientWidth || 0, window.innerWidth || 0, 320),
            height: Math.max(doc.clientHeight || 0, window.innerHeight || 0, 320)
        };
    }

    function clampSize(width, height) {
        const viewport = getViewport();
        const maxWidth = Math.max(360, viewport.width - VIEWPORT_MARGIN * 2);
        const maxHeight = Math.max(320, viewport.height - VIEWPORT_MARGIN * 2);
        const minWidth = Math.min(MIN_WIDTH, maxWidth);
        const minHeight = Math.min(MIN_HEIGHT, maxHeight);

        width = Math.round(Number(width) || DEFAULT_RECT.width);
        height = Math.round(Number(height) || DEFAULT_RECT.height);
        width = Math.max(minWidth, Math.min(maxWidth, width));
        height = Math.max(minHeight, Math.min(maxHeight, height));

        return { width: width, height: height, maxWidth: maxWidth, maxHeight: maxHeight };
    }

    function clampRect(rect) {
        rect = rect || {};
        const viewport = getViewport();
        const size = clampSize(rect.width, rect.height);
        let x = rect.x == null ? NaN : Number(rect.x);
        let y = rect.y == null ? NaN : Number(rect.y);

        if (!Number.isFinite(x)) x = Math.round((viewport.width - size.width) / 2);
        if (!Number.isFinite(y)) y = Math.round((viewport.height - size.height) / 2);

        const maxX = Math.max(VIEWPORT_MARGIN, viewport.width - size.width - VIEWPORT_MARGIN);
        const maxY = Math.max(VIEWPORT_MARGIN, viewport.height - size.height - VIEWPORT_MARGIN);

        x = Math.max(VIEWPORT_MARGIN, Math.min(maxX, Math.round(x)));
        y = Math.max(VIEWPORT_MARGIN, Math.min(maxY, Math.round(y)));

        return { x: x, y: y, width: size.width, height: size.height };
    }

    function rectSig(rect) {
        const safeRect = clampRect(rect || rectState || getDefaultRectCentered());
        return [safeRect.x, safeRect.y, safeRect.width, safeRect.height].join('|');
    }

    function buildRectEntry(rect) {
        const safeRect = clampRect(rect || rectState || getDefaultRectCentered());
        const nextRev = Math.max(0, Number(rectRevision) || 0) + 1;
        rectRevision = nextRev;
        return { version: 3, rev: nextRev, updatedAt: Date.now(), rect: safeRect };
    }

    function parseRectEntry(raw) {
        if (!raw) return null;
        try {
            const data = JSON.parse(raw);
            if (!data || typeof data !== 'object') return null;
            if (data.rect && typeof data.rect === 'object') {
                return { rect: clampRect(data.rect), rev: Math.max(0, Number(data.rev) || 0), updatedAt: Math.max(0, Number(data.updatedAt) || 0) };
            }
            return { rect: clampRect({ x: Number(data.x), y: Number(data.y), width: Number(data.width), height: Number(data.height) }), rev: 0, updatedAt: 0 };
        } catch (e) { return null; }
    }

    function normalizeRectEntry(entry) {
        if (!entry) return null;
        if (entry.rect && typeof entry.rect === 'object') {
            return { rect: clampRect(entry.rect), rev: Math.max(0, Number(entry.rev) || 0), updatedAt: Math.max(0, Number(entry.updatedAt) || 0) };
        }
        if (typeof entry === 'object' && ('x' in entry || 'y' in entry || 'width' in entry || 'height' in entry)) {
            return { rect: clampRect(entry), rev: 0, updatedAt: 0 };
        }
        return null;
    }

    function pickNewestRectEntry(entries) {
        let best = null;
        (entries || []).forEach(function (entry) {
            entry = normalizeRectEntry(entry);
            if (!entry || !entry.rect) return;
            if (!best) { best = entry; return; }
            const entryRev = Math.max(0, Number(entry.rev) || 0);
            const bestRev = Math.max(0, Number(best.rev) || 0);
            if (entryRev > bestRev) { best = entry; return; }
            if (entryRev === bestRev) {
                const entryTime = Math.max(0, Number(entry.updatedAt) || 0);
                const bestTime = Math.max(0, Number(best.updatedAt) || 0);
                if (entryTime >= bestTime) best = entry;
            }
        });
        return best;
    }

    function parseRectRaw(raw) {
        if (!raw) return null;
        try {
            const data = JSON.parse(raw);
            if (!data || typeof data !== 'object') return null;
            return clampRect({ x: Number(data.x), y: Number(data.y), width: Number(data.width), height: Number(data.height) });
        } catch (e) { return null; }
    }

    function readCookieValue(name) {
        try {
            const escaped = String(name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const match = document.cookie.match(new RegExp('(?:^|; )' + escaped + '=([^;]*)'));
            return match ? decodeURIComponent(match[1]) : null;
        } catch (e) { return null; }
    }

    function writeCookieValue(name, value, maxAgeSeconds) {
        try {
            document.cookie = String(name) + '=' + encodeURIComponent(String(value)) + '; path=/; max-age=' + String(Math.max(0, Number(maxAgeSeconds) || 0)) + '; SameSite=Lax';
        } catch (e) {}
    }

    function readWindowNameRect() {
        try {
            const rawName = String(window.name || '');
            let index = rawName.indexOf(STORAGE_WINDOW_NAME_PREFIX);
            let prefix = STORAGE_WINDOW_NAME_PREFIX;
            if (index === -1) {
                index = rawName.indexOf(STORAGE_WINDOW_NAME_PREFIX_LEGACY);
                prefix = STORAGE_WINDOW_NAME_PREFIX_LEGACY;
            }
            if (index === -1) return null;
            const raw = rawName.slice(index + prefix.length);
            return parseRectEntry(raw) || parseRectRaw(raw);
        } catch (e) { return null; }
    }

    function writeWindowNameRect(entry) {
        try { window.name = STORAGE_WINDOW_NAME_PREFIX + JSON.stringify(entry); } catch (e) {}
    }

    function readRectEntry() {
        const primaryEntries = [];
        const legacyEntries = [];

        primaryEntries.push(persistence.getRectEntry());
        try {
            if (window.localStorage) {
                primaryEntries.push(parseRectEntry(window.localStorage.getItem(STORAGE_KEY)));
                primaryEntries.push(parseRectEntry(window.localStorage.getItem(STORAGE_BACKUP_KEY)));
                primaryEntries.push(parseRectRaw(window.localStorage.getItem(STORAGE_KEY)));
                primaryEntries.push(parseRectRaw(window.localStorage.getItem(STORAGE_BACKUP_KEY)));
            }
        } catch (e) {}

        primaryEntries.push(parseRectEntry(readCookieValue(STORAGE_COOKIE_KEY)));
        primaryEntries.push(parseRectRaw(readCookieValue(STORAGE_COOKIE_KEY)));

        const winEntry = readWindowNameRect();
        if (winEntry) primaryEntries.push(winEntry);

        const primaryBest = pickNewestRectEntry(primaryEntries);
        if (primaryBest && primaryBest.rect) {
            rectRevision = Math.max(rectRevision, Number(primaryBest.rev) || 0);
            return primaryBest;
        }
        return null;
    }

    function readRect() {
        const entry = readRectEntry();
        return entry ? entry.rect : null;
    }

    function saveRect(rect) {
        const entry = buildRectEntry(rect || rectState || getDefaultRectCentered());
        const safeRect = entry.rect;
        rectState = safeRect;
        rectLastSavedSig = rectSig(safeRect);

        try {
            if (window.localStorage) {
                const raw = JSON.stringify(entry);
                window.localStorage.setItem(STORAGE_KEY, raw);
                window.localStorage.setItem(STORAGE_BACKUP_KEY, raw);
            }
        } catch (e) {}

        try {
            const raw = JSON.stringify(entry);
            writeCookieValue(STORAGE_COOKIE_KEY, raw, 60 * 60 * 24 * 365);
            writeWindowNameRect(entry);
        } catch (e) {}

        persistence.setRectEntry(entry);
        return safeRect;
    }

    function getDefaultRectCentered() {
        return clampRect({ x: null, y: null, width: DEFAULT_RECT.width, height: DEFAULT_RECT.height });
    }

    function loadRect() {
        const entry = readRectEntry();
        const safeRect = clampRect((entry && entry.rect) || rectState || getDefaultRectCentered());
        rectState = safeRect;
        rectLastSavedSig = rectSig(safeRect);
        return safeRect;
    }

    function clampVisual(visual) {
        visual = visual || {};
        function clampNumber(value, fallback, min, max) {
            value = Number(value);
            if (!Number.isFinite(value)) value = fallback;
            value = Math.max(min, Math.min(max, value));
            return Math.round(value * 100) / 100;
        }

        return {
            overlayOpacity: clampNumber(visual.overlayOpacity, DEFAULT_VISUAL.overlayOpacity, 0, 0.35),
            panelOpacity: clampNumber(visual.panelOpacity, DEFAULT_VISUAL.panelOpacity, 0.72, 1),
            shadowStrength: clampNumber(visual.shadowStrength, DEFAULT_VISUAL.shadowStrength, 0.18, 0.90),
            accentColor: (visual.accentColor && /^#[0-9A-F]{6}$/i.test(visual.accentColor)) ? visual.accentColor : DEFAULT_VISUAL.accentColor
        }
    }

    function readVisual() {
        const persistedVisual = persistence.getVisual();
        if (persistedVisual) return clampVisual(persistedVisual);
        try {
            const raw = window.localStorage && window.localStorage.getItem(VISUAL_STORAGE_KEY);
            if (!raw) return null;
            return clampVisual(JSON.parse(raw));
        } catch (e) { return null; }
    }

    function saveVisual(visual) {
        const safeVisual = clampVisual(visual);
        visualState = safeVisual;
        try {
            if (window.localStorage) {
                window.localStorage.setItem(VISUAL_STORAGE_KEY, JSON.stringify(safeVisual));
            }
        } catch (e) {}
        persistence.setVisual(safeVisual);
        return safeVisual;
    }

    function loadVisual() {
        return clampVisual(readVisual() || DEFAULT_VISUAL);
    }

    function scheduleSaveVisual(visual) {
        const safeVisual = clampVisual(visual || visualState || DEFAULT_VISUAL);
        if (visualSaveTimer) clearTimeout(visualSaveTimer);
        visualSaveTimer = setTimeout(function () {
            saveVisual(safeVisual);
            visualSaveTimer = 0;
        }, 80);
        return safeVisual;
    }

    function hexToRgb(hex) {
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : { r: 0, g: 0, b: 0 };
    }

    function hsvToRgb(h, s, v) {
        let r, g, b, i = Math.floor(h * 6), f = h * 6 - i, p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s);
        switch (i % 6) {
            case 0: r = v, g = t, b = p; break; case 1: r = q, g = v, b = p; break;
            case 2: r = p, g = v, b = t; break; case 3: r = p, g = q, b = v; break;
            case 4: r = t, g = p, b = v; break; case 5: r = v, g = p, b = q; break;
        }
        return { r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255) };
    }

    function rgbToHsv(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        let max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min, h, s = (max === 0 ? 0 : d / max), v = max;
        if (max === min) h = 0;
        else {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return { h: h, s: s, v: v };
    }

    function rgbToHex(r, g, b) {
        return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1).toUpperCase().padStart(6, '0');
    }

    function updateSettingsInputs(visual) {
        const map = { overlayOpacity: 'ml_char_stats_overlay_input', panelOpacity: 'ml_char_stats_panel_opacity_input', shadowStrength: 'ml_char_stats_shadow_input' };

        Object.keys(map).forEach(function (key) {
            const input = document.getElementById(map[key]);
            const valueEl = document.getElementById(map[key] + '_value');
            if (!input) return;
            const value = Number(visual[key]);
            input.value = String(value);
            if (valueEl) valueEl.textContent = Math.round(value * 100) + '%';
        });

        if (visual.accentColor) {
            const hexInput = document.getElementById('ml_char_stats_hex_input');
            const rInput = document.getElementById('ml_cp_r');
            const gInput = document.getElementById('ml_cp_g');
            const bInput = document.getElementById('ml_cp_b');
            const area = document.getElementById('ml_cp_area');
            const thumb = document.getElementById('ml_cp_thumb');
            const hueThumb = document.getElementById('ml_cp_hue_thumb');

            if (hexInput && document.activeElement !== hexInput) {
                hexInput.value = visual.accentColor.toUpperCase();
            }
            
            const rgb = hexToRgb(visual.accentColor);
            if (rInput && document.activeElement !== rInput) rInput.value = rgb.r;
            if (gInput && document.activeElement !== gInput) gInput.value = rgb.g;
            if (bInput && document.activeElement !== bInput) bInput.value = rgb.b;

            const hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
            
            if (area) {
                let currentHue = area.getAttribute('data-hue');
                if (area.getAttribute('data-dragging') !== '1' || currentHue == null) {
                    currentHue = hsv.h;
                    area.setAttribute('data-hue', currentHue);
                }
                area.style.backgroundColor = 'hsl(' + Math.round(Number(currentHue) * 360) + ', 100%, 50%)';
            }
            if (thumb && (!area || area.getAttribute('data-dragging') !== '1')) {
                thumb.style.left = (hsv.s * 100) + '%';
                thumb.style.top = ((1 - hsv.v) * 100) + '%';
            }
            const hueContainer = document.getElementById('ml_cp_hue');
            if (hueThumb && (!hueContainer || hueContainer.getAttribute('data-dragging') !== '1')) {
                hueThumb.style.top = (hsv.h * 100) + '%';
            }
        }
    }

    function applyVisual(visual) {
        const root = getRoot();
        const panel = getPanel();
        const safeVisual = clampVisual(visual || visualState || DEFAULT_VISUAL);
        visualState = safeVisual;

        if (!root || !panel) return safeVisual;

        const rgb = hexToRgb(safeVisual.accentColor);
        const topAlpha = Math.max(0.64, Math.min(1, safeVisual.panelOpacity - 0.06));
        const bottomAlpha = Math.max(0.68, Math.min(1, safeVisual.panelOpacity));

        const rTop = rgb.r, gTop = rgb.g, bTop = rgb.b;
        const rBot = Math.max(0, rgb.r - 20), gBot = Math.max(0, rgb.g - 20), bBot = Math.max(0, rgb.b - 20);
        const rBrd = Math.min(255, rgb.r + 50), gBrd = Math.min(255, rgb.g + 50), bBrd = Math.min(255, rgb.b + 50);

        const topColor = 'rgba(' + rTop + ', ' + gTop + ', ' + bTop + ', ' + topAlpha + ')';
        const bottomColor = 'rgba(' + rBot + ', ' + gBot + ', ' + bBot + ', ' + bottomAlpha + ')';
        const borderColor = 'rgba(' + rBrd + ', ' + gBrd + ', ' + bBrd + ', 0.16)';

        root.style.background = 'rgba(8, 10, 14, ' + safeVisual.overlayOpacity + ')';
        panel.style.background = 'linear-gradient(180deg, ' + topColor + ', ' + bottomColor + ')';
        panel.style.border = '1px solid ' + borderColor;
        panel.style.boxShadow = '0 24px 90px rgba(0,0,0,' + safeVisual.shadowStrength + ')';
        
        updateSettingsInputs(safeVisual);
        return safeVisual;
    }

    function setSettingsOpen(open) {
        const settingsPanel = document.getElementById('ml_char_stats_settings_panel');
        const toggle = document.getElementById('ml_char_stats_settings_toggle');
        if (settingsPanel) settingsPanel.style.display = open ? 'block' : 'none';
        if (toggle) {
            if (open) toggle.classList.add('active');
            else toggle.classList.remove('active');
        }
    }

    function toggleSettings(forceOpen) {
        const settingsPanel = document.getElementById('ml_char_stats_settings_panel');
        if (!settingsPanel) return;
        const shouldOpen = typeof forceOpen === 'boolean' ? forceOpen : settingsPanel.style.display === 'none' || settingsPanel.style.display === '';
        setSettingsOpen(shouldOpen);
        if (shouldOpen) applyVisual(visualState || loadVisual());
    }

    function setVisualPatch(patch) {
        const nextVisual = clampVisual(Object.assign({}, visualState || loadVisual(), patch || {}));
        applyVisual(nextVisual);
        scheduleSaveVisual(nextVisual);
    }

    function getRoot() { return document.getElementById('ml_char_stats_root'); }
    function getPanel() { return document.getElementById('ml_char_stats_panel'); }

    function readPanelRect() {
        const panel = getPanel();
        if (!panel) return rectState || getDefaultRectCentered();

        let x = parseFloat(panel.style.left);
        let y = parseFloat(panel.style.top);
        let width = parseFloat(panel.style.width);
        let height = parseFloat(panel.style.height);

        try {
            const bounds = typeof panel.getBoundingClientRect === 'function' ? panel.getBoundingClientRect() : null;
            if (bounds) {
                if (!Number.isFinite(x)) x = bounds.left;
                if (!Number.isFinite(y)) y = bounds.top;
                if (Number.isFinite(bounds.width) && bounds.width > 0) width = bounds.width;
                if (Number.isFinite(bounds.height) && bounds.height > 0) height = bounds.height;
            }
        } catch (e) {}

        if (!Number.isFinite(width) || width <= 0) width = panel.offsetWidth || DEFAULT_RECT.width;
        if (!Number.isFinite(height) || height <= 0) height = panel.offsetHeight || DEFAULT_RECT.height;

        const rect = clampRect({ x: x, y: y, width: width, height: height });
        rectState = rect;
        return rect;
    }

    function queueInteractionPump() {
        if (interactionRaf) return;
        const tick = function () {
            if (!dragState && !resizeState) { interactionRaf = 0; return; }
            rectState = readPanelRect();
            interactionRaf = window.requestAnimationFrame(tick);
        };
        interactionRaf = window.requestAnimationFrame(tick);
    }

    function stopInteractionPump() {
        if (!interactionRaf) return;
        try { window.cancelAnimationFrame(interactionRaf); } catch (e) {}
        interactionRaf = 0;
    }

    function startRectObservers() {
        const panel = getPanel();
        if (!panel) return;

        if (!rectResizeObserver && typeof ResizeObserver === 'function') {
            rectResizeObserver = new ResizeObserver(function () {
                if (Date.now() < ignoreViewportSaveUntil) return;
                const rect = readPanelRect();
                if (rectSig(rect) !== rectLastSavedSig) scheduleSaveRect(rect);
            });
            try { rectResizeObserver.observe(panel); } catch (e) {}
        }

        if (!rectMutationObserver && typeof MutationObserver === 'function') {
            rectMutationObserver = new MutationObserver(function () {
                if (Date.now() < ignoreViewportSaveUntil) return;
                const rect = readPanelRect();
                if (rectSig(rect) !== rectLastSavedSig) scheduleSaveRect(rect);
            });
            try { rectMutationObserver.observe(panel, { attributes: true, attributeFilter: ['style'] }); } catch (e) {}
        }
    }

    function stopRectObservers() {
        if (rectResizeObserver) { try { rectResizeObserver.disconnect(); } catch (e) {} rectResizeObserver = null; }
        if (rectMutationObserver) { try { rectMutationObserver.disconnect(); } catch (e) {} rectMutationObserver = null; }
        stopInteractionPump();
    }

    function startRectWatcher() {
        if (rectWatchTimer) return;
        rectWatchTimer = setInterval(function () {
            const panel = getPanel();
            if (!panel) return;
            if (Date.now() < ignoreViewportSaveUntil) return;
            const rect = readPanelRect();
            const sig = rectSig(rect);
            if (sig !== rectLastSavedSig) scheduleSaveRect(rect);
        }, 90);
    }

    function stopRectWatcher() {
        if (!rectWatchTimer) return;
        clearInterval(rectWatchTimer);
        rectWatchTimer = 0;
    }

    function updateAdaptiveLayout(rect) {
        const panel = getPanel();
        if (!panel) return;

        rect = clampRect(rect || readPanelRect());

        const sf = 1;
        panel.style.setProperty('--sf', sf);

        const compact = rect.width < 1180;
        const narrow = rect.width < 980;
        const veryNarrow = rect.width < 820;

        const layout = document.getElementById('ml_char_stats_content');
        if (layout) {
            layout.style.gridTemplateColumns = compact ? '1fr' : '1.18fr 0.92fr';
        }

        panel.querySelectorAll('.ml-grid-two').forEach(function (el) {
            el.style.gridTemplateColumns = narrow ? '1fr' : 'repeat(2, minmax(0, 1fr))';
        });

        panel.querySelectorAll('.ml-section-list.ml-chip-grid').forEach(function (el) {
            el.style.gridTemplateColumns = veryNarrow ? '1fr' : 'repeat(2, minmax(0, 1fr))';
        });

        panel.querySelectorAll('.ml-metrics').forEach(function (el) {
            if (veryNarrow) el.style.gridTemplateColumns = '1fr';
            else if (compact) el.style.gridTemplateColumns = 'repeat(2, minmax(0, 1fr))';
            else el.style.gridTemplateColumns = 'repeat(3, minmax(0, 1fr))';
        });
    }

    function applyRect(rect) {
        const panel = getPanel();
        if (!panel) return null;

        const safeRect = clampRect(rect || rectState || DEFAULT_RECT);
        rectState = safeRect;
        panel.style.left = safeRect.x + 'px';
        panel.style.top = safeRect.y + 'px';
        panel.style.width = safeRect.width + 'px';
        panel.style.height = safeRect.height + 'px';
        updateAdaptiveLayout(safeRect);
        return safeRect;
    }

    function scheduleSaveRect(rect) {
        const safeRect = clampRect(rect || readPanelRect() || rectState || getDefaultRectCentered());
        rectState = safeRect;
        if (saveTimer) clearTimeout(saveTimer);
        saveTimer = setTimeout(function () {
            saveRect(clampRect(readPanelRect() || rectState || safeRect || getDefaultRectCentered()));
            saveTimer = 0;
        }, 120);
        return safeRect;
    }

    function flushSaveRect(rect) {
        const safeRect = clampRect(rect || readPanelRect() || rectState || getDefaultRectCentered());
        rectState = safeRect;
        if (saveTimer) { clearTimeout(saveTimer); saveTimer = 0; }
        return saveRect(safeRect);
    }

    function stopPointerAction() {
        if (dragState || resizeState) {
            dragState = null;
            resizeState = null;
            document.body.style.userSelect = '';
            document.body.style.cursor = '';
        }
    }

    function onDragMove(event) {
        if (!dragState) return;
        event.preventDefault();
        const dx = event.clientX - dragState.startX;
        const dy = event.clientY - dragState.startY;
        scheduleSaveRect(applyRect({ x: dragState.rect.x + dx, y: dragState.rect.y + dy, width: dragState.rect.width, height: dragState.rect.height }));
    }

    function onResizeMove(event) {
        if (!resizeState) return;
        event.preventDefault();
        const dx = event.clientX - resizeState.startX;
        const dy = event.clientY - resizeState.startY;
        let width = resizeState.rect.width;
        let height = resizeState.rect.height;

        if (resizeState.dir.indexOf('e') !== -1) width = resizeState.rect.width + dx;
        if (resizeState.dir.indexOf('s') !== -1) height = resizeState.rect.height + dy;

        sc
    }
})();
]=]
