script_name("CEF Character Stats")

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
u8 = encoding.UTF8

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
local CONFIG_DIRECTORY = "C:\\Users\\emild\\AppData\\Local\\Programs\\Arizona Games Launcher\\bin\\arizona\\moonloader\\config"

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
    const DEFAULT_RECT = { x: null, y: null, width: 1420, height: 620 };
    const MIN_WIDTH = 1020;
    const MIN_HEIGHT = 520;
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
        };
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

        scheduleSaveRect(applyRect({ x: resizeState.rect.x, y: resizeState.rect.y, width: width, height: height }));
    }

    function onPointerUp() {
        if (dragState || resizeState) flushSaveRect(readPanelRect());
        stopPointerAction();
        stopInteractionPump();
    }

    function beginDrag(event) {
        if (event.button !== 0 || resizeState) return;
        if (event.target && (event.target.closest('.ml-resize-handle') || event.target.closest('.ml-no-drag'))) return;

        dragState = { startX: event.clientX, startY: event.clientY, rect: readPanelRect() };
        resizeState = null;
        queueInteractionPump();
        document.body.style.userSelect = 'none';
        document.body.style.cursor = 'move';
        event.preventDefault();
    }

    function beginResize(event) {
        if (event.button !== 0) return;
        const handle = event.currentTarget;
        resizeState = { dir: handle.getAttribute('data-dir') || 'se', startX: event.clientX, startY: event.clientY, rect: readPanelRect() };
        dragState = null;
        queueInteractionPump();
        document.body.style.userSelect = 'none';
        document.body.style.cursor = window.getComputedStyle(handle).cursor || 'nwse-resize';
        event.preventDefault();
        event.stopPropagation();
    }

    function attachInteractions(panel) {
        if (!panel || panel.dataset.mlBound === '1') return;
        panel.dataset.mlBound = '1';

        const dragHandle = panel.querySelector('#ml_char_stats_drag_handle');
        if (dragHandle) dragHandle.addEventListener('mousedown', beginDrag);

        panel.querySelectorAll('.ml-resize-handle').forEach(function (handle) {
            handle.addEventListener('mousedown', beginResize);
        });

        if (!interactionsBound) {
            interactionsBound = true;
            window.addEventListener('mousemove', onDragMove, true);
            window.addEventListener('mousemove', onResizeMove, true);
            window.addEventListener('mouseup', onPointerUp, true);
            window.addEventListener('blur', onPointerUp, true);
        }
    }

    function attachSettings(panel) {
        if (!panel || panel.dataset.mlSettingsBound === '1') return;
        panel.dataset.mlSettingsBound = '1';

        const toggle = panel.querySelector('#ml_char_stats_settings_toggle');
        const reset = panel.querySelector('#ml_char_stats_visual_reset');
        const overlayInput = panel.querySelector('#ml_char_stats_overlay_input');
        const panelOpacityInput = panel.querySelector('#ml_char_stats_panel_opacity_input');
        const shadowInput = panel.querySelector('#ml_char_stats_shadow_input');
        
        const hexInput = panel.querySelector('#ml_char_stats_hex_input');
        const rInp = panel.querySelector('#ml_cp_r');
        const gInp = panel.querySelector('#ml_cp_g');
        const bInp = panel.querySelector('#ml_cp_b');
        const cpArea = panel.querySelector('#ml_cp_area');
        const cpHue = panel.querySelector('#ml_cp_hue');
        const cpThumb = panel.querySelector('#ml_cp_thumb');
        const cpHueThumb = panel.querySelector('#ml_cp_hue_thumb');

        let isDraggingArea = false;
        let isDraggingHue = false;

        if (toggle) {
            toggle.addEventListener('click', function (event) {
                event.preventDefault(); event.stopPropagation(); toggleSettings();
            });
            toggle.addEventListener('mousedown', function (event) { event.stopPropagation(); });
        }

        if (reset) {
            reset.addEventListener('click', function (event) {
                event.preventDefault(); event.stopPropagation();
                applyVisual(saveVisual(DEFAULT_VISUAL));
            });
            reset.addEventListener('mousedown', function (event) { event.stopPropagation(); });
        }

        [[overlayInput, 'overlayOpacity'], [panelOpacityInput, 'panelOpacity'], [shadowInput, 'shadowStrength']].forEach(function (entry) {
            const input = entry[0], key = entry[1];
            if (!input) return;
            input.addEventListener('input', function (event) {
                event.stopPropagation();
                const patch = {}; patch[key] = Number(input.value);
                setVisualPatch(patch);
            });
            input.addEventListener('mousedown', function (event) { event.stopPropagation(); });
        });

        function applyHsvFromMouse(e, isArea) {
            if (!visualState) return;
            const rgb = hexToRgb(visualState.accentColor);
            let hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);

            if (cpArea && cpArea.hasAttribute('data-hue')) {
                hsv.h = Number(cpArea.getAttribute('data-hue'));
            }

            if (isArea && cpArea) {
                const rect = cpArea.getBoundingClientRect();
                let x = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
                let y = Math.max(0, Math.min(1, (e.clientY - rect.top) / rect.height));
                hsv.s = x; 
                hsv.v = 1 - y;
                
                if (cpThumb) {
                    cpThumb.style.left = (x * 100) + '%';
                    cpThumb.style.top = (y * 100) + '%';
                }
            } else if (!isArea && cpHue) {
                const rect = cpHue.getBoundingClientRect();
                let y = Math.max(0, Math.min(1, (e.clientY - rect.top) / rect.height));
                hsv.h = y;
                
                if (cpArea) {
                    cpArea.setAttribute('data-hue', y);
                    cpArea.style.backgroundColor = 'hsl(' + Math.round(y * 360) + ', 100%, 50%)';
                }
                if (cpHueThumb) {
                    cpHueThumb.style.top = (y * 100) + '%';
                }
            }

            const newRgb = hsvToRgb(hsv.h, hsv.s, hsv.v);
            setVisualPatch({ accentColor: rgbToHex(newRgb.r, newRgb.g, newRgb.b) });
        }

        if (cpArea) {
            cpArea.addEventListener('mousedown', function(e) {
                if (e.button !== 0) return;
                isDraggingArea = true; 
                cpArea.setAttribute('data-dragging', '1');
                applyHsvFromMouse(e, true);
                e.preventDefault(); e.stopPropagation();
            });
        }
        if (cpHue) {
            cpHue.addEventListener('mousedown', function(e) {
                if (e.button !== 0) return;
                isDraggingHue = true; 
                cpHue.setAttribute('data-dragging', '1');
                applyHsvFromMouse(e, false);
                e.preventDefault(); e.stopPropagation();
            });
        }

        if (hexInput) {
            hexInput.addEventListener('input', function (e) {
                e.stopPropagation();
                let val = hexInput.value.trim();
                if (/^#[0-9A-F]{6}$/i.test(val)) setVisualPatch({ accentColor: val });
            });
            hexInput.addEventListener('mousedown', function (e) { e.stopPropagation(); });
        }

        function updateFromRGB() {
            const r = parseInt(rInp.value).toString(16).padStart(2, '0');
            const g = parseInt(gInp.value).toString(16).padStart(2, '0');
            const b = parseInt(bInp.value).toString(16).padStart(2, '0');
            setVisualPatch({ accentColor: '#' + r + g + b });
        }

        [rInp, gInp, bInp].forEach(function(inp) {
            if (!inp) return;
            inp.addEventListener('input', function(e) {
                e.stopPropagation();
                updateFromRGB();
            });
            inp.addEventListener('mousedown', function(e) { e.stopPropagation(); });
        });

        if (!settingsBound) {
            settingsBound = true;
            document.addEventListener('mousedown', function (event) {
                const settingsPanel = document.getElementById('ml_char_stats_settings_panel');
                const settingsToggle = document.getElementById('ml_char_stats_settings_toggle');
                if (!settingsPanel || settingsPanel.style.display !== 'block') return;
                
                if (settingsPanel.contains(event.target)) return;
                if (settingsToggle && settingsToggle.contains(event.target)) return;
                setSettingsOpen(false);
            }, true);

            window.addEventListener('mousemove', function(e) {
                if (isDraggingArea) {
                    applyHsvFromMouse(e, true);
                    e.preventDefault();
                }
                if (isDraggingHue) {
                    applyHsvFromMouse(e, false);
                    e.preventDefault();
                }
            }, { passive: false });

            window.addEventListener('mouseup', function(e) {
                if (isDraggingArea || isDraggingHue) {
                    isDraggingArea = false;
                    isDraggingHue = false;
                    if (cpArea) cpArea.setAttribute('data-dragging', '0');
                    if (cpHue) cpHue.setAttribute('data-dragging', '0');
                }
            });
        }

        setSettingsOpen(false);
        applyVisual(visualState || loadVisual());
    }

    function ensureRoot() {
        let root = document.getElementById('ml_char_stats_root');
        if (root) {
            const panel = getPanel();
            attachInteractions(panel);
            attachSettings(panel);
            applyVisual(visualState || loadVisual());
            applyRect(rectState || readPanelRect() || loadRect());
            startRectWatcher();
            startRectObservers();
            return root;
        }

        root = document.createElement('div');
        root.id = 'ml_char_stats_root';
        root.style.position = 'fixed';
        root.style.inset = '0';
        root.style.zIndex = '999999';
        root.style.pointerEvents = 'auto';
        root.style.background = 'rgba(8, 10, 14, 0.08)';
        root.style.fontFamily = 'Arial, sans-serif';
        root.style.padding = '0';
        root.style.overflow = 'hidden';

        const panel = document.createElement('div');
        panel.id = 'ml_char_stats_panel';
        panel.style.position = 'absolute';
        panel.style.left = '0px';
        panel.style.top = '0px';
        panel.style.transform = 'none';
        panel.style.width = DEFAULT_RECT.width + 'px';
        panel.style.height = DEFAULT_RECT.height + 'px';
        panel.style.borderRadius = '24px';
        panel.style.overflow = 'visible';
        panel.style.background = 'linear-gradient(180deg, rgba(18,19,27,0.88), rgba(8,9,14,0.94))';
        panel.style.border = '1px solid rgba(255,255,255,0.10)';
        panel.style.boxShadow = '0 24px 90px rgba(0,0,0,0.48)';
        panel.style.color = '#F4F4F4';
        panel.style.pointerEvents = 'auto';
        panel.style.display = 'flex';
        panel.style.flexDirection = 'column';

        panel.innerHTML = `
            <style>
                #ml_char_stats_root * { box-sizing: border-box; }
                #ml_char_stats_panel { --sf: 1; }
                
                #ml_char_stats_root .ml-topbar { display:flex; align-items:center; justify-content:space-between; gap:calc(14px * var(--sf)); padding:calc(18px * var(--sf)) calc(22px * var(--sf)) calc(16px * var(--sf)) calc(22px * var(--sf)); border-bottom:1px solid rgba(255,255,255,0.08); background:rgba(255,255,255,0.02); cursor:move; user-select:none; flex:0 0 auto; }
                #ml_char_stats_root .ml-title-wrap { display:flex; flex-direction:column; gap:0; }
                #ml_char_stats_root .ml-title { font-size:calc(28px * var(--sf)); font-weight:800; line-height:1; color:#FFFFFF; }
                #ml_char_stats_root .ml-actions { display:flex; align-items:center; gap:calc(10px * var(--sf)); flex-wrap:wrap; justify-content:flex-end; }
                #ml_char_stats_root .ml-pill { display:inline-flex; align-items:center; gap:calc(8px * var(--sf)); padding:calc(9px * var(--sf)) calc(13px * var(--sf)); border-radius:calc(14px * var(--sf)); background:rgba(255,255,255,0.055); border:1px solid rgba(255,255,255,0.08); font-size:calc(12px * var(--sf)); font-weight:700; color:rgba(255,255,255,0.88); white-space:nowrap; }
                #ml_char_stats_root .ml-icon-btn { width:calc(38px * var(--sf)); height:calc(38px * var(--sf)); display:inline-flex; align-items:center; justify-content:center; border-radius:calc(14px * var(--sf)); background:rgba(255,255,255,0.055); border:1px solid rgba(255,255,255,0.08); color:rgba(255,255,255,0.92); font-size:calc(18px * var(--sf)); font-weight:800; line-height:1; cursor:pointer; transition:background 0.12s ease, border-color 0.12s ease, transform 0.12s ease; }
                #ml_char_stats_root .ml-icon-btn:hover, #ml_char_stats_root .ml-icon-btn.active { background:rgba(255,255,255,0.10); border-color:rgba(255,255,255,0.16); }
                #ml_char_stats_root .ml-icon-btn:active { transform:scale(0.98); }
                
                #ml_char_stats_root .ml-settings-panel { position:absolute; top:calc(74px * var(--sf)); right:18px; width:290px; display:none; z-index:14; border-radius:18px; border:1px solid rgba(255,255,255,0.10); background:linear-gradient(180deg, rgba(20,22,31,0.96), rgba(10,12,18,0.98)); box-shadow:0 20px 50px rgba(0,0,0,0.36); padding:14px; }
                #ml_char_stats_root .ml-settings-title { font-size:14px; font-weight:800; color:#FFFFFF; margin-bottom:4px; }
                #ml_char_stats_root .ml-settings-sub { font-size:11px; font-weight:700; color:rgba(255,255,255,0.54); margin-bottom:12px; }
                #ml_char_stats_root .ml-settings-stack { display:flex; flex-direction:column; gap:10px; }
                #ml_char_stats_root .ml-setting-row { display:flex; flex-direction:column; gap:6px; }
                #ml_char_stats_root .ml-setting-top { display:flex; align-items:center; justify-content:space-between; gap:10px; }
                #ml_char_stats_root .ml-setting-label { font-size:12px; font-weight:700; color:rgba(255,255,255,0.82); }
                #ml_char_stats_root .ml-setting-value { font-size:11px; font-weight:800; color:#FFD783; }
                #ml_char_stats_root .ml-setting-range { width:100%; margin:0; accent-color:#6FB7FF; cursor:pointer; }
                
                #ml_char_stats_root .ml-cp-container { display:flex; gap:8px; margin-top:6px; background:rgba(0,0,0,0.2); padding:8px; border-radius:12px; border:1px solid rgba(255,255,255,0.05); }
                #ml_char_stats_root .ml-cp-area { position:relative; width:130px; height:100px; border-radius:6px; cursor:crosshair; overflow:hidden; }
                #ml_char_stats_root .ml-cp-bg { position:absolute; inset:0; background:linear-gradient(to top, #000, transparent), linear-gradient(to right, #fff, transparent); pointer-events:none; }
                #ml_char_stats_root .ml-cp-thumb { position:absolute; width:10px; height:10px; border:2px solid #fff; border-radius:50%; transform:translate(-50%,-50%); box-shadow:0 0 3px rgba(0,0,0,0.8); pointer-events:none; z-index:2; }
                #ml_char_stats_root .ml-cp-hue { position:relative; width:14px; height:100px; border-radius:6px; cursor:pointer; background:linear-gradient(to bottom, #f00, #ff0, #0f0, #0ff, #00f, #f0f, #f00); }
                #ml_char_stats_root .ml-cp-hue-thumb { position:absolute; left:-2px; right:-2px; height:6px; background:#fff; border:1px solid #000; border-radius:2px; transform:translateY(-50%); pointer-events:none; }
                #ml_char_stats_root .ml-cp-inputs { display:flex; flex-direction:column; gap:4px; justify-content:space-between; }
                #ml_char_stats_root .ml-cp-row { display:flex; align-items:center; justify-content:space-between; width:100%; font-size:10px; font-weight:800; color:rgba(255,255,255,0.6); }
                #ml_char_stats_root .ml-cp-row input { width:34px; background:rgba(0,0,0,0.4); border:1px solid rgba(255,255,255,0.1); color:#FFD783; font-size:10px; font-weight:800; text-align:center; border-radius:4px; padding:3px 0; outline:none; }
                
                #ml_char_stats_root .ml-settings-actions { display:flex; justify-content:flex-end; margin-top:4px; }
                #ml_char_stats_root .ml-settings-reset { padding:8px 12px; border-radius:12px; border:1px solid rgba(255,255,255,0.08); background:rgba(255,255,255,0.05); color:#FFFFFF; font-size:12px; font-weight:800; cursor:pointer; }
                
                #ml_char_stats_root .ml-body { display:flex; flex-direction:column; flex:1 1 auto; min-height:0; padding:calc(8px * var(--sf)) calc(18px * var(--sf)) calc(8px * var(--sf)) calc(18px * var(--sf)); overflow:hidden; }
                #ml_char_stats_root .ml-layout { display:grid; grid-template-columns:1.18fr 0.92fr; gap:calc(18px * var(--sf)); flex:1 1 auto; min-height:0; height:100%; }
                #ml_char_stats_root .ml-col { display:flex; flex-direction:column; min-height:0; overflow-x:hidden; overflow-y:auto; padding-right:0; scrollbar-width:none; -ms-overflow-style:none; height:100%; }
                #ml_char_stats_root .ml-col::-webkit-scrollbar { width:0; height:0; display:none; }
                #ml_char_stats_root .ml-stack { display:flex; flex-direction:column; flex:1 1 auto; min-height:100%; gap:calc(12px * var(--sf)); justify-content:flex-start; }
                
                #ml_char_stats_root .ml-hero { position:relative; overflow:hidden; border-radius:calc(14px * var(--sf)); border:1px solid rgba(255,255,255,0.08); background: radial-gradient(circle at top right, rgba(255,180,80,0.10), transparent 28%), radial-gradient(circle at bottom left, rgba(120,170,255,0.10), transparent 24%), linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0.018)); padding:calc(10px * var(--sf)) calc(12px * var(--sf)); flex:0 0 auto; }
                #ml_char_stats_root .ml-hero-kicker { font-size:calc(8px * var(--sf)); font-weight:700; letter-spacing:calc(0.8px * var(--sf)); text-transform:uppercase; color:rgba(255,255,255,0.48); margin-bottom:calc(3px * var(--sf)); }
                #ml_char_stats_root .ml-hero-name { font-size:calc(22px * var(--sf)); font-weight:800; line-height:1.02; color:#FFFFFF; margin-bottom:calc(6px * var(--sf)); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
                #ml_char_stats_root .ml-chip-wrap { display:flex; flex-wrap:wrap; gap:calc(5px * var(--sf)); }
                #ml_char_stats_root .ml-chip { padding:calc(5px * var(--sf)) calc(9px * var(--sf)); border-radius:calc(10px * var(--sf)); background:rgba(255,255,255,0.055); border:1px solid rgba(255,255,255,0.08); font-size:calc(10px * var(--sf)); font-weight:700; color:rgba(255,255,255,0.92); line-height:1.2; }
                
                #ml_char_stats_root .ml-metrics { display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); gap:calc(12px * var(--sf)); flex:0 0 auto; }
                #ml_char_stats_root .ml-metric { border-radius:calc(16px * var(--sf)); border:1px solid rgba(255,255,255,0.08); background:rgba(255,255,255,0.035); padding:calc(11px * var(--sf)); overflow:hidden; position:relative; }
                #ml_char_stats_root .ml-metric.accent-green { background: radial-gradient(circle at top left, rgba(80,255,160,0.12), transparent 32%), rgba(255,255,255,0.035); }
                #ml_char_stats_root .ml-metric.accent-blue { background: radial-gradient(circle at top left, rgba(80,170,255,0.14), transparent 32%), rgba(255,255,255,0.035); }
                #ml_char_stats_root .ml-metric.accent-gold { background: radial-gradient(circle at top left, rgba(255,180,80,0.14), transparent 32%), rgba(255,255,255,0.035); }
                #ml_char_stats_root .ml-metric-label { font-size:calc(12px * var(--sf)); color:rgba(255,255,255,0.50); font-weight:700; margin-bottom:calc(7px * var(--sf)); }
                #ml_char_stats_root .ml-metric-value { font-size:calc(21px * var(--sf)); font-weight:800; color:#FFFFFF; line-height:1.08; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
                #ml_char_stats_root .ml-metric-note { margin-top:calc(6px * var(--sf)); font-size:calc(11px * var(--sf)); color:rgba(255,255,255,0.46); line-height:1.35; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
                
                #ml_char_stats_root .ml-section { border-radius:calc(18px * var(--sf)); border:1px solid rgba(255,255,255,0.08); background:rgba(255,255,255,0.03); padding:calc(15px * var(--sf)); display:flex; flex-direction:column; justify-content:space-evenly; flex:1 1 auto; min-height:0; }
                #ml_char_stats_root .ml-section-title { display:flex; align-items:center; justify-content:space-between; gap:calc(10px * var(--sf)); margin-bottom:calc(10px * var(--sf)); flex:0 0 auto; }
                #ml_char_stats_root .ml-section-title-main { font-size:calc(17px * var(--sf)); font-weight:800; color:#FFFFFF; }
                #ml_char_stats_root .ml-section-title-sub { font-size:calc(10px * var(--sf)); font-weight:700; letter-spacing:calc(0.8px * var(--sf)); text-transform:uppercase; color:rgba(255,255,255,0.48); }
                
                #ml_char_stats_root .ml-section-list { display:flex; flex-direction:column; flex:1 1 auto; gap:6px; }
                #ml_char_stats_root .ml-section-list.ml-chip-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:calc(10px * var(--sf)); }
                
                #ml_char_stats_root .ml-row { display:grid; grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr); gap:calc(10px * var(--sf)); align-items:center; border-bottom:1px solid rgba(255,255,255,0.05); flex:1 1 auto; min-height:calc(28px * var(--sf)); }
                #ml_char_stats_root .ml-row:last-child { border-bottom:none; }
                #ml_char_stats_root .ml-label { font-size:calc(13px * var(--sf)); font-weight:700; color:rgba(255,255,255,0.62); line-height:1.2; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; min-width:0; }
                #ml_char_stats_root .ml-label.gold { color:#FFD783; }
                #ml_char_stats_root .ml-value { font-size:calc(13px * var(--sf)); font-weight:800; color:#F5F7FF; line-height:1.2; text-align:right; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; min-width:0; }
                #ml_char_stats_root .ml-value.good { color:#95F3AA; }
                #ml_char_stats_root .ml-value.bad { color:#FF8A8A; }
                #ml_char_stats_root .ml-value.gold { color:#FFD783; }
                
                #ml_char_stats_root .ml-grid-two { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:calc(18px * var(--sf)); flex:1 1 auto; min-height:0; }
                #ml_char_stats_root .ml-stat-chip { display:flex; align-items:center; justify-content:space-between; gap:calc(10px * var(--sf)); border-radius:calc(14px * var(--sf)); border:1px solid rgba(255,255,255,0.08); background:rgba(255,255,255,0.04); padding:calc(8px * var(--sf)) calc(12px * var(--sf)); flex:1 1 auto; min-width:0; }
                #ml_char_stats_root .ml-stat-chip-label { font-size:calc(12px * var(--sf)); font-weight:700; color:rgba(255,255,255,0.72); line-height:1.25; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; min-width:0; }
                #ml_char_stats_root .ml-stat-chip-value { font-size:calc(12px * var(--sf)); font-weight:800; color:#FFFFFF; text-align:right; line-height:1.25; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; min-width:0; }
                #ml_char_stats_root .ml-stat-chip-value.good { color:#95F3AA; }
                #ml_char_stats_root .ml-stat-chip-value.bad { color:#FF8A8A; }
                #ml_char_stats_root .ml-stat-chip-value.gold { color:#FFD783; }
                
                #ml_char_stats_root .ml-empty { padding:calc(16px * var(--sf)); border-radius:calc(14px * var(--sf)); background:rgba(255,255,255,0.04); border:1px dashed rgba(255,255,255,0.10); font-size:calc(13px * var(--sf)); font-weight:700; color:rgba(255,255,255,0.60); flex:1 1 auto; display:flex; align-items:center; justify-content:center; }
                #ml_char_stats_root .ml-resize-handle { position:absolute; z-index:8; user-select:none; }
                #ml_char_stats_root .ml-resize-handle.corner { right:0; bottom:0; width:22px; height:22px; cursor:nwse-resize; }
                #ml_char_stats_root .ml-resize-handle.corner::before { content:''; position:absolute; right:6px; bottom:6px; width:10px; height:10px; border-right:2px solid rgba(255,255,255,0.32); border-bottom:2px solid rgba(255,255,255,0.32); border-radius:2px; }
                #ml_char_stats_root .ml-resize-handle.right { top:84px; right:0; bottom:18px; width:8px; cursor:ew-resize; }
                #ml_char_stats_root .ml-resize-handle.bottom { left:18px; right:18px; bottom:0; height:8px; cursor:ns-resize; }
            </style>

            <div class="ml-topbar" id="ml_char_stats_drag_handle">
                <div class="ml-title-wrap">
                    <div class="ml-title">\u0421\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043A\u0430 \u043F\u0435\u0440\u0441\u043E\u043D\u0430\u0436\u0430</div>
                </div>
                <div class="ml-actions">
                    <div class="ml-pill" id="ml_char_stats_status">\u0417\u0430\u0433\u0440\u0443\u0437\u043A\u0430...</div>
                    <button type="button" class="ml-icon-btn ml-no-drag" id="ml_char_stats_settings_toggle" title="\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438">&#9881;</button>
                    <button type="button" class="ml-icon-btn ml-no-drag" id="ml_char_stats_profile_stub" title="Profile">P</button>
                    <div class="ml-pill">ESC</div>
                </div>
            </div>

            <div class="ml-settings-panel ml-no-drag" id="ml_char_stats_settings_panel">
                <div class="ml-settings-title">\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438 \u043e\u043a\u043d\u0430</div>
                <div class="ml-settings-sub">\u041c\u043e\u0436\u043d\u043e \u043c\u0435\u043d\u044f\u0442\u044c \u0437\u0430\u0442\u0435\u043c\u043d\u0435\u043d\u0438\u0435 \u0441\u0437\u0430\u0434\u0438, \u043f\u0440\u043e\u0437\u0440\u0430\u0447\u043d\u043e\u0441\u0442\u044c \u043e\u043a\u043d\u0430, \u0442\u0435\u043d\u044c \u0438 \u0446\u0432\u0435\u0442 \u043e\u043a\u043d\u0430.</div>
                <div class="ml-settings-stack">
                    <div class="ml-setting-row">
                        <div class="ml-setting-top">
                            <span class="ml-setting-label">\u0417\u0430\u0442\u0435\u043c\u043d\u0435\u043d\u0438\u0435 \u0441\u0437\u0430\u0434\u0438</span>
                            <span class="ml-setting-value" id="ml_char_stats_overlay_input_value">8%</span>
                        </div>
                        <input class="ml-setting-range" id="ml_char_stats_overlay_input" type="range" min="0" max="0.35" step="0.01" value="0.08">
                    </div>
                    <div class="ml-setting-row">
                        <div class="ml-setting-top">
                            <span class="ml-setting-label">\u041f\u0440\u043e\u0437\u0440\u0430\u0447\u043d\u043e\u0441\u0442\u044c \u043e\u043a\u043d\u0430</span>
                            <span class="ml-setting-value" id="ml_char_stats_panel_opacity_input_value">94%</span>
                        </div>
                        <input class="ml-setting-range" id="ml_char_stats_panel_opacity_input" type="range" min="0.72" max="1" step="0.01" value="0.94">
                    </div>
                    <div class="ml-setting-row">
                        <div class="ml-setting-top">
                            <span class="ml-setting-label">\u0422\u0435\u043d\u044c \u043e\u043a\u043d\u0430</span>
                            <span class="ml-setting-value" id="ml_char_stats_shadow_input_value">55%</span>
                        </div>
                        <input class="ml-setting-range" id="ml_char_stats_shadow_input" type="range" min="0.18" max="0.90" step="0.01" value="0.55">
                    </div>
                    <div class="ml-setting-row">
                        <div class="ml-setting-top">
                            <span class="ml-setting-label">\u0426\u0432\u0435\u0442 \u043e\u043a\u043d\u0430</span>
                        </div>
                        <div class="ml-cp-container">
                            <div class="ml-cp-area" id="ml_cp_area">
                                <div class="ml-cp-bg"></div>
                                <div class="ml-cp-thumb" id="ml_cp_thumb"></div>
                            </div>
                            <div class="ml-cp-hue" id="ml_cp_hue">
                                <div class="ml-cp-hue-thumb" id="ml_cp_hue_thumb"></div>
                            </div>
                            <div class="ml-cp-inputs">
                                <div class="ml-cp-row"><span>R:</span><input type="text" id="ml_cp_r" maxlength="3"></div>
                                <div class="ml-cp-row"><span>G:</span><input type="text" id="ml_cp_g" maxlength="3"></div>
                                <div class="ml-cp-row"><span>B:</span><input type="text" id="ml_cp_b" maxlength="3"></div>
                                <div class="ml-cp-row" style="margin-top:2px;"><input type="text" id="ml_char_stats_hex_input" maxlength="7" style="width:44px;"></div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="ml-settings-actions">
                    <button type="button" class="ml-settings-reset ml-no-drag" id="ml_char_stats_visual_reset">\u0421\u0431\u0440\u043e\u0441</button>
                </div>
            </div>

            <div class="ml-body">
                <div class="ml-layout" id="ml_char_stats_content">
                    <div class="ml-col">
                        <div class="ml-empty">\u0417\u0430\u0433\u0440\u0443\u0437\u043A\u0430 \u0441\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043A\u0438...</div>
                    </div>
                    <div class="ml-col"></div>
                </div>
            </div>

            <div class="ml-resize-handle right" data-dir="e"></div>
            <div class="ml-resize-handle bottom" data-dir="s"></div>
            <div class="ml-resize-handle corner" data-dir="se"></div>
        `;

        root.appendChild(panel);
        document.body.appendChild(root);

        attachInteractions(panel);
        attachSettings(panel);
        applyVisual(visualState || loadVisual());
        const initialRect = loadRect();
        applyRect(initialRect);
        rectState = initialRect;
        rectLastSavedSig = rectSig(initialRect);
        startRectWatcher();
        startRectObservers();
        return root;
    }

    window.addEventListener('resize', function () {
        const panel = getPanel();
        if (!panel) return;
        if (Date.now() < ignoreViewportSaveUntil) {
            applyRect(rectState || loadRect() || getDefaultRectCentered());
            return;
        }
        flushSaveRect(applyRect(rectState || readPanelRect() || loadRect()));
    });

    window.addEventListener('beforeunload', function () {
        if (getPanel()) flushSaveRect(readPanelRect());
        saveVisual(visualState || loadVisual());
        persistence.flush();
    });

    window.addEventListener('pagehide', function () {
        if (getPanel()) flushSaveRect(readPanelRect());
        saveVisual(visualState || loadVisual());
        persistence.flush();
    });

    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'hidden') {
            if (getPanel()) flushSaveRect(readPanelRect());
            saveVisual(visualState || loadVisual());
            persistence.flush();
        }
    });

    window.mlCharStats = {
        ready: true,
        open: function () {
            ensureRoot();
            applyVisual(visualState || loadVisual());
            const wantedRect = loadRect();
            rectState = wantedRect;
            rectLastSavedSig = rectSig(wantedRect);
            ignoreViewportSaveUntil = Date.now() + 320;
            const applyWanted = function () {
                const nextRect = applyRect(wantedRect);
                rectState = nextRect;
                rectLastSavedSig = rectSig(nextRect);
            };
            applyWanted();
            window.setTimeout(applyWanted, 60);
            window.setTimeout(function () {
                const liveRect = readPanelRect() || wantedRect;
                rectState = liveRect;
                rectLastSavedSig = rectSig(liveRect);
                ignoreViewportSaveUntil = 0;
            }, 220);
            startRectWatcher();
            startRectObservers();
        },
        close: function () {
            if (getPanel()) flushSaveRect(readPanelRect() || rectState);
            saveVisual(visualState || loadVisual());
            persistence.flush();
            stopPointerAction();
            stopRectWatcher();
            stopRectObservers();
            const root = document.getElementById('ml_char_stats_root');
            if (root) root.remove();
        },
        resetRect: function () {
            ensureRoot();
            try {
                if (window.localStorage) {
                    window.localStorage.removeItem(STORAGE_KEY);
                    window.localStorage.removeItem(STORAGE_BACKUP_KEY);
                    window.localStorage.removeItem(STORAGE_KEY_LEGACY);
                    window.localStorage.removeItem(STORAGE_KEY_LEGACY_2);
                }
            } catch (e) {}
            writeCookieValue(STORAGE_COOKIE_KEY, '', 0);
            writeCookieValue(STORAGE_KEY_LEGACY, '', 0);
            writeCookieValue(STORAGE_KEY_LEGACY_2, '', 0);
            try { window.name = ''; } catch (e) {}
            const safeRect = getDefaultRectCentered();
            applyRect(safeRect);
            saveRect(safeRect);
            persistence.flush();
            return safeRect;
        },
        getDefaultRect: function () { return getDefaultRectCentered(); },
        setStatus: function (text) {
            ensureRoot();
            const el = document.getElementById('ml_char_stats_status');
            if (el) el.textContent = String(text || '');
        },
        setContent: function (html) {
            ensureRoot();
            const el = document.getElementById('ml_char_stats_content');
            if (el) {
                el.innerHTML = String(html || '');
                updateAdaptiveLayout(readPanelRect());
                if (window.mlCharStatsApplyItemsToRaw) window.mlCharStatsApplyItemsToRaw();
            }
        },
        persistence: persistence
    };

    window.mlCharStatsPersistence = persistence;
})();
]=]

local EDITOR_JS = [=[
(function () {
    if (window.mlCharStatsEditor && window.mlCharStatsEditor.ready) return;
    if (!window.mlCharStats || !window.mlCharStats.ready) return;

    var LAYOUT_STORAGE_KEY = 'ml_char_stats_layout_overlay_v6';
    var ORDER = ['hero', 'metrics', 'main', 'finance', 'stats', 'property'];

    var base = window.mlCharStats;
    var baseOpen = base.open;
    var baseClose = base.close;
    var baseSetContent = base.setContent;

    var state = {
        ready: true,
        contentHtml: '',
        defaultLayout: null,
        currentLayout: null,
        editing: false,
        editMode: 'move',
        pointer: null,
        toolbarBound: false,
        lastPanelSig: '',
        layoutSaveTimer: 0
    };

    function cloneLayout(obj) {
        if (!obj) return null;
        try {
            return JSON.parse(JSON.stringify(obj));
        } catch (e) {
            return null;
        }
    }

    function num(value, fallback) {
        value = Number(value);
        if (!isFinite(value)) return fallback;
        return value;
    }

    function trimText(value) {
        return String(value == null ? '' : value).replace(/^\s+|\s+$/g, '');
    }

    function getPanel() {
        return document.getElementById('ml_char_stats_panel');
    }

    function getContent() {
        return document.getElementById('ml_char_stats_content');
    }

    function ensureStyles() {
        var style = document.getElementById('ml_char_stats_editor_styles');
        if (!style) {
            style = document.createElement('style');
            style.id = 'ml_char_stats_editor_styles';
            document.head.appendChild(style);
        }
        style.textContent = '' +
            '#ml_char_stats_root .ml-editor-trigger{width:100%;margin-top:10px;padding:9px 12px;border-radius:12px;border:1px solid rgba(111,183,255,0.28);background:rgba(111,183,255,0.10);color:#EAF4FF;font-size:12px;font-weight:800;cursor:pointer;}' +
            '#ml_char_stats_root .ml-editor-toolbar{position:absolute;top:50%;left:calc(100% + 12px);right:auto;bottom:auto;transform:translateY(-50%);display:none;flex-direction:column;align-items:stretch;justify-content:flex-start;gap:8px;flex-wrap:nowrap;z-index:340;pointer-events:auto;width:152px;max-width:152px;padding:10px;border-radius:18px;border:1px solid rgba(255,255,255,0.10);background:linear-gradient(180deg, rgba(20,22,31,0.96), rgba(10,12,18,0.98));box-shadow:0 20px 50px rgba(0,0,0,0.36);}' +
            '#ml_char_stats_root .ml-editor-toolbar.visible{display:flex;}' +
            '#ml_char_stats_root .ml-editor-toolbar, #ml_char_stats_root .ml-editor-toolbar *{pointer-events:auto;}' +
            '#ml_char_stats_root .ml-editor-btn{padding:10px 14px;border-radius:12px;border:1px solid rgba(255,255,255,0.10);background:rgba(255,255,255,0.08);color:#FFFFFF;font-size:12px;font-weight:800;cursor:pointer;}' +
            '#ml_char_stats_root .ml-editor-btn.primary{border-color:rgba(111,183,255,0.38);background:rgba(111,183,255,0.16);color:#EAF4FF;}#ml_char_stats_root .ml-editor-toolbar .ml-editor-btn{flex:0 0 auto;width:100%;min-width:0;text-align:center;}' +
            '#ml_char_stats_root .ml-layout-board-host{position:relative;display:block !important;min-height:0;overflow-x:hidden;overflow-y:auto;box-sizing:border-box;padding-right:0;padding-bottom:12px;scrollbar-width:none;-ms-overflow-style:none;height:100%;}' +
            '#ml_char_stats_root .ml-layout-board-host::-webkit-scrollbar{width:0;height:0;display:none;background:transparent;}' +
            '#ml_char_stats_root .ml-layout-board{position:relative;width:100%;height:100%;min-height:100%;box-sizing:border-box;overflow:hidden;padding:0;margin:0;}' +
            '#ml_char_stats_root .ml-layout-board.is-editing{background-image:linear-gradient(rgba(111,183,255,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(111,183,255,0.05) 1px, transparent 1px);background-size:24px 24px;}' +
            
            '#ml_char_stats_root .ml-layout-board [data-layout-card]{box-sizing:border-box;overflow:visible;min-height:0;transition: z-index 0s, outline 0.2s;}' +
            '#ml_char_stats_root .ml-layout-board.is-editing [data-layout-card]{outline:1px dashed rgba(111,183,255,0.4);}' +
            '#ml_char_stats_root .ml-layout-board [data-layout-card] > .ml-card-inner{position:relative;height:100%;min-height:0;overflow:hidden;padding-right:0;}' +
            '#ml_char_stats_root .ml-layout-board .ml-layout-overlap-layer{position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none;z-index:9;}' +
            '#ml_char_stats_root .ml-layout-board .ml-layout-overlap{position:absolute;box-sizing:border-box;border-radius:12px;background:rgba(255,82,82,0.24);border:1px solid rgba(255,82,82,0.85);box-shadow:0 0 0 1px rgba(255,82,82,0.10) inset;pointer-events:none;}' +
            
            '#ml_char_stats_root .ml-layout-board.is-editing.mode-move [data-layout-card]:hover{z-index: 50; outline: 2px solid rgba(111,183,255,0.9);}' +
            '#ml_char_stats_root .ml-layout-board.is-editing.mode-move [data-layout-card].is-dragging{z-index: 100; outline: 2px solid #FFD783;}' +
            '#ml_char_stats_root .ml-layout-board.is-editing.mode-move [data-layout-card].ml-card-overlap{outline:2px solid rgba(255,82,82,0.92);box-shadow:0 0 0 2px rgba(255,82,82,0.18);}' +
            '#ml_char_stats_root .ml-layout-board.is-editing.mode-move [data-layout-card] > .ml-card-inner{pointer-events:none; opacity: 0.85;}' +
            
            '#ml_char_stats_root .ml-layout-board.mode-move .ml-edit-drag-handle, #ml_char_stats_root .ml-layout-board.mode-move .ml-edit-resize{pointer-events:auto;}' +
            '#ml_char_stats_root .ml-edit-drag-handle{position:absolute;inset:0;background:rgba(111,183,255,0.05);border-radius:inherit;cursor:grab;z-index:50;}' +
            '#ml_char_stats_root .ml-layout-board.mode-move [data-layout-card].is-dragging .ml-edit-drag-handle{background:rgba(255,215,131,0.1);cursor:grabbing;}' +
            '#ml_char_stats_root .ml-edit-resize{position:absolute;width:20px;height:20px;border-radius:50%;background:#6FB7FF;border:2px solid #080A0E;box-shadow:0 2px 6px rgba(0,0,0,0.5);z-index:10;transition:transform 0.1s, background 0.1s;}' +
            '#ml_char_stats_root .ml-edit-resize:hover{transform:scale(1.3);background:#FFD783;}' +
            '#ml_char_stats_root .ml-layout-board.mode-move [data-layout-card].ml-card-overlap .ml-edit-resize{border-color:#FF5252; background:#FF8A8A;}' +
            '#ml_char_stats_root .ml-edit-resize.nw{left:-10px;top:-10px;cursor:nwse-resize;}' +
            '#ml_char_stats_root .ml-edit-resize.ne{right:-10px;top:-10px;cursor:nesw-resize;}' +
            '#ml_char_stats_root .ml-edit-resize.sw{left:-10px;bottom:-10px;cursor:nesw-resize;}' +
            '#ml_char_stats_root .ml-edit-resize.se{right:-10px;bottom:-10px;cursor:nwse-resize;}' +
            '#ml_char_stats_root .ml-layout-board.mode-items .ml-edit-drag-handle{display:none !important; pointer-events:none !important;}' +
            '#ml_char_stats_root .ml-layout-board.mode-items .ml-edit-resize{display:none !important; pointer-events:none !important;}' +
            '#ml_char_stats_root .ml-layout-board.mode-items [data-layout-card] > .ml-card-inner{pointer-events:auto; opacity: 1;}' +
            '#ml_char_stats_root .mode-move [data-id] .ml-item-controls{display:none !important;}' +
            '#ml_char_stats_root .mode-move [data-id]{outline:none !important;}' +
            '#ml_char_stats_root .mode-items [data-id]{position:relative;pointer-events:auto;outline:1px dashed transparent;}' +
            '#ml_char_stats_root .mode-items [data-id]:hover{outline:1px dashed rgba(255,215,131,0.6);z-index:20;background:rgba(255,255,255,0.03);}' +
            '#ml_char_stats_root .ml-item-controls{position:absolute !important;right:4px !important;top:50% !important;transform:translateY(-50%) !important;display:none;flex-direction:row;align-items:center;gap:4px;z-index:100;background:rgba(10,12,18,0.95);padding:4px;border-radius:6px;border:1px solid rgba(255,255,255,0.15);height:28px;box-sizing:border-box;}' +
            '#ml_char_stats_root .mode-items [data-id]:hover > .ml-item-controls{display:flex;}' +
            '#ml_char_stats_root .ml-trash-panel [data-id]:hover > .ml-item-controls{display:flex;}' +
            '#ml_char_stats_root .ml-item-btn{width:20px;height:20px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.05);border-radius:4px;cursor:pointer;font-size:10px;color:#FFF;transition:0.1s;user-select:none;}' +
            '#ml_char_stats_root .ml-item-btn:hover{background:rgba(255,255,255,0.2);}' +
            '#ml_char_stats_root .ml-item-btn.hide{color:#FF8A8A;}' +
            '#ml_char_stats_root .ml-item-btn.restore{color:#95F3AA;display:none;}' +
            '#ml_char_stats_root .ml-trash-panel [data-id] .ml-item-controls .up,' +
            '#ml_char_stats_root .ml-trash-panel [data-id] .ml-item-controls .down,' +
            '#ml_char_stats_root .ml-trash-panel [data-id] .ml-item-controls .hide{display:none;}' +
            '#ml_char_stats_root .ml-trash-panel [data-id] .ml-item-controls .restore{display:flex;}' +
            '#ml_char_stats_root .ml-trash-panel{position:absolute;right:-300px;top:18px;bottom:70px;width:260px;background:linear-gradient(180deg, rgba(20,22,31,0.96), rgba(10,12,18,0.98));border:1px solid rgba(255,82,82,0.3);border-radius:18px;box-shadow:0 20px 50px rgba(0,0,0,0.5);z-index:300;display:flex;flex-direction:column;overflow:hidden;transition:right 0.3s ease;pointer-events:auto;}' +
            '#ml_char_stats_root .ml-trash-panel.open{right:18px;}' +
            '#ml_char_stats_root .ml-trash-header{padding:14px;font-size:14px;font-weight:800;color:#FF8A8A;border-bottom:1px solid rgba(255,82,82,0.2);text-align:center;flex:0 0 auto;}' +
            '#ml_char_stats_root .ml-trash-content{flex:1 1 auto;overflow-y:auto;padding:10px;display:flex;flex-direction:column;gap:6px;}' +
            '#ml_char_stats_root .ml-trash-content [data-id]{position:relative; width:100% !important;height:auto !important;min-height:0 !important;flex:0 0 auto !important;margin:0;background:rgba(255,255,255,0.03) !important;border:1px solid rgba(255,255,255,0.05) !important;padding:8px 40px 8px 12px !important;border-radius:8px;box-sizing:border-box;display:flex !important;flex-direction:row !important;align-items:center;justify-content:space-between;gap:8px;}' +
            '#ml_char_stats_root .ml-trash-content .ml-metric-note{display:none;}' +
            '#ml_char_stats_root .ml-trash-content .ml-metric-label{font-size:12px;margin:0;}' +
            '#ml_char_stats_root .ml-trash-content .ml-metric-value{font-size:13px;}' +
            '#ml_char_stats_root .ml-trash-content .ml-stat-chip-label{font-size:12px;}' +
            '#ml_char_stats_root .ml-trash-content .ml-stat-chip-value{font-size:12px;}' +
            '#ml_char_stats_root .ml-trash-content .ml-label{font-size:12px;}' +
            '#ml_char_stats_root .ml-trash-content .ml-value{font-size:12px; text-align:right;}';
    }

    function panelSig() {
        var panel = getPanel();
        if (!panel) return '';
        return [panel.style.width || '', panel.style.height || '', panel.style.left || '', panel.style.top || ''].join('|');
    }

    function hideSettingsPanel() {
        var settings = document.getElementById('ml_char_stats_settings_panel');
        var toggle = document.getElementById('ml_char_stats_settings_toggle');
        if (settings) settings.style.display = 'none';
        if (toggle) toggle.className = String(toggle.className || '').replace(/\bactive\b/g, '').replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
    }

    function updateTrashCount() {
        var tc = document.getElementById('ml_trash_content');
        var btn = document.getElementById('ml_editor_trash_btn');
        if (tc && btn) {
            btn.textContent = '\u041a\u043e\u0440\u0437\u0438\u043d\u0430 (' + tc.children.length + ')';
        }
    }

    function runToolbarAction(action) {
        stopPointer();
        if (action === 'save') {
            saveEditor();
        } else if (action === 'cancel' || action === 'close') {
            cancelEditor();
        } else if (action === 'reset') {
            resetEditor();
        } else if (action === 'trash') {
            var tp = document.getElementById('ml_char_stats_trash');
            if (tp) tp.classList.toggle('open');
        } else if (action === 'toggle_mode') {
            state.editMode = state.editMode === 'move' ? 'items' : 'move';
            var btn = document.getElementById('ml_editor_mode_btn');
            if (btn) btn.textContent = state.editMode === 'move' ? '\u0420\u0435\u0436\u0438\u043c: \u041f\u0435\u0440\u0435\u043c\u0435\u0449\u0435\u043d\u0438\u0435' : '\u0420\u0435\u0436\u0438\u043c: \u042d\u043b\u0435\u043c\u0435\u043d\u0442\u044b';
            var board = document.getElementById('ml_char_stats_layout_board');
            if (board) {
                board.className = 'ml-layout-board mode-' + state.editMode + (state.editing ? ' is-editing' : '');
            }
        }
    }

    function ensureToolbar() {
        ensureStyles();
        var panel = getPanel();
        if (!panel) return null;
        var toolbar = document.getElementById('ml_char_stats_editor_toolbar');
        if (!toolbar) {
            toolbar = document.createElement('div');
            toolbar.id = 'ml_char_stats_editor_toolbar';
            toolbar.className = 'ml-editor-toolbar ml-no-drag';
            toolbar.innerHTML = '' +
                '<button type="button" class="ml-editor-btn primary" data-editor-action="save">\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c</button>' +
                '<button type="button" class="ml-editor-btn" data-editor-action="toggle_mode" id="ml_editor_mode_btn">\u0420\u0435\u0436\u0438\u043c: \u041f\u0435\u0440\u0435\u043c\u0435\u0449\u0435\u043d\u0438\u0435</button>' +
                '<button type="button" class="ml-editor-btn" data-editor-action="trash" id="ml_editor_trash_btn">\u041a\u043e\u0440\u0437\u0438\u043d\u0430 (0)</button>' +
                '<button type="button" class="ml-editor-btn" data-editor-action="reset">\u0421\u0431\u0440\u043e\u0441</button>' +
                '<button type="button" class="ml-editor-btn" data-editor-action="close">\u0417\u0430\u043a\u0440\u044b\u0442\u044c</button>';
            panel.appendChild(toolbar);
        }

        if (toolbar.getAttribute('data-ml-bound') !== '1') {
            toolbar.setAttribute('data-ml-bound', '1');
            var buttons = toolbar.querySelectorAll('[data-editor-action]');
            for (var i = 0; i < buttons.length; i++) {
                (function (button) {
                    var action = button.getAttribute('data-editor-action');
                    button.addEventListener('mousedown', function (event) {
                        stopPointer();
                        event.preventDefault();
                        event.stopPropagation();
                        if (event.stopImmediatePropagation) event.stopImmediatePropagation();
                        runToolbarAction(action);
                    }, false);
                    button.addEventListener('click', function (event) {
                        event.preventDefault();
                        event.stopPropagation();
                        if (event.stopImmediatePropagation) event.stopImmediatePropagation();
                    }, false);
                })(buttons[i]);
            }
            toolbar.addEventListener('mousedown', function (event) {
                stopPointer();
                event.preventDefault();
                event.stopPropagation();
                if (event.stopImmediatePropagation) event.stopImmediatePropagation();
            }, false);
        }

        return toolbar;
    }

    function setToolbarVisible(visible) {
        var toolbar = ensureToolbar();
        if (!toolbar) return;
        if (visible) toolbar.classList.add('visible');
        else toolbar.classList.remove('visible');
    }

    function ensureEditorButton() {
        ensureStyles();
        var panel = getPanel();
        if (!panel) return;
        var settings = document.getElementById('ml_char_stats_settings_panel');
        if (!settings) return;
        if (document.getElementById('ml_char_stats_editor_toggle')) return;

        var btn = document.createElement('button');
        btn.type = 'button';
        btn.id = 'ml_char_stats_editor_toggle';
        btn.className = 'ml-editor-trigger ml-no-drag';
        btn.textContent = '\u0420\u0435\u0434\u0430\u043a\u0442\u043e\u0440';
        btn.addEventListener('click', function (event) {
            event.preventDefault();
            event.stopPropagation();
            openEditor();
        });
        btn.addEventListener('mousedown', function (event) {
            event.stopPropagation();
        });
        settings.appendChild(btn);
    }

    function findSection(root, title) {
        if (!root) return null;
        var nodes = root.querySelectorAll('.ml-section');
        for (var i = 0; i < nodes.length; i++) {
            var head = nodes[i].querySelector('.ml-section-title-main');
            if (head && head.textContent.indexOf(title) !== -1) {
                return nodes[i];
            }
        }
        return null;
    }

    function findCards(root) {
        return {
            hero: root ? root.querySelector('.ml-hero') : null,
            metrics: root ? root.querySelector('.ml-metrics') : null,
            main: findSection(root, '\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435 \u0434\u0430\u043d\u043d\u044b\u0435'),
            finance: findSection(root, '\u0424\u0438\u043d\u0430\u043d\u0441\u044b'),
            stats: findSection(root, '\u0425\u0430\u0440\u0430\u043a\u0442\u0435\u0440\u0438\u0441\u0442\u0438\u043a\u0438'),
            property: findSection(root, '\u0418\u043c\u0443\u0449\u0435\u0441\u0442\u0432\u043e')
        };
    }

    function allCardsPresent(cards) {
        var i;
        for (i = 0; i < ORDER.length; i++) {
            if (!cards[ORDER[i]]) return false;
        }
        return true;
    }

    function captureDefaultLayout() {
        var content = getContent();
        if (!content) return null;
        var cards = findCards(content);
        if (!allCardsPresent(cards)) return null;

        var boardRect = content.getBoundingClientRect();
        var out = {};
        var maxBottom = 0;
        var key, el, rect;

        for (var i = 0; i < ORDER.length; i++) {
            key = ORDER[i];
            el = cards[key];
            rect = el.getBoundingClientRect();
            out[key] = {
                x: Math.round(rect.left - boardRect.left),
                y: Math.round(rect.top - boardRect.top),
                width: Math.round(rect.width),
                height: Math.round(rect.height)
            };
            maxBottom = Math.max(maxBottom, out[key].y + out[key].height);
        }

        out.__boardWidth = Math.max(320, Math.round(boardRect.width || content.clientWidth || 0));
        out.__boardHeight = Math.max(Math.round(content.clientHeight || 0), maxBottom + 8);
        return out;
    }

    function rectifyMetricsRect(layout, liveLayout) {
        if (!layout || !layout.metrics || !liveLayout || !liveLayout.metrics) return layout;
        var current = layout.metrics;
        var live = liveLayout.metrics;
        var currentRatio = num(current.width, 1) / Math.max(1, num(current.height, 1));
        var liveRatio = num(live.width, 1) / Math.max(1, num(live.height, 1));
        var widthTooLarge = num(current.width, 0) > num(live.width, 0) * 1.35;
        var heightTooLarge = num(current.height, 0) > num(live.height, 0) * 1.35;
        var ratioBroken = currentRatio > liveRatio * 1.6 || currentRatio < liveRatio * 0.6;
        if (widthTooLarge || heightTooLarge || ratioBroken) {
            layout.metrics = {
                x: Math.round(num(live.x, 0)),
                y: Math.round(num(live.y, 0)),
                width: Math.round(num(live.width, 0)),
                height: Math.round(num(live.height, 0))
            };
        }
        return layout;
    }

    function normalizeLayout(layout, fallback, boardWidth, boardHeight) {
        var source = layout && typeof layout === 'object' ? layout : null;
        var base = fallback && typeof fallback === 'object' ? fallback : null;
        if (!source && !base) return null;

        var out = {};
        var maxBottom = 0;
        var key, rect, minW, minH;

        for (var i = 0; i < ORDER.length; i++) {
            key = ORDER[i];
            rect = (source && source[key]) || (base && base[key]);
            if (!rect) return null;
            minW = key === 'hero' ? 320 : (key === 'metrics' ? 280 : 220);
            minH = key === 'hero' ? 92 : (key === 'metrics' ? 92 : 120);
            out[key] = {
                x: Math.max(0, Math.round(num(rect.x, 0))),
                y: Math.max(0, Math.round(num(rect.y, 0))),
                width: Math.max(minW, Math.round(num(rect.width, minW))),
                height: Math.max(minH, Math.round(num(rect.height, minH)))
            };
            maxBottom = Math.max(maxBottom, out[key].y + out[key].height);
        }

        out.__boardWidth = Math.max(320, Math.round(num(source && source.__boardWidth, num(base && base.__boardWidth, boardWidth || 320))));
        out.__boardHeight = Math.max(maxBottom + 8, Math.round(num(source && source.__boardHeight, num(base && base.__boardHeight, boardHeight || maxBottom + 8))));
        return out;
    }

    function getPersistence() {
        return (base && base.persistence) || window.mlCharStatsPersistence || null;
    }

    function loadLayout(boardWidth, boardHeight) {
        var persistence = getPersistence();
        if (persistence && persistence.getLayout) {
            try {
                var persistedLayout = persistence.getLayout();
                if (persistedLayout) {
                    return normalizeLayout(persistedLayout, state.defaultLayout, boardWidth || 0, boardHeight || 0);
                }
            } catch (e) {}
        }
        try {
            var raw = window.localStorage && window.localStorage.getItem(LAYOUT_STORAGE_KEY);
            if (!raw) return null;
            return normalizeLayout(JSON.parse(raw), state.defaultLayout, boardWidth || 0, boardHeight || 0);
        } catch (e) {
            return null;
        }
    }

    function saveLayout(layout) {
        var content = getContent();
        var width = Math.round((content && (content.clientWidth || content.getBoundingClientRect().width)) || 0) || (layout && layout.__boardWidth) || 0;
        var height = Math.round((content && (content.clientHeight || content.getBoundingClientRect().height)) || 0) || (layout && layout.__boardHeight) || 0;
        var safe = normalizeLayout(layout, state.defaultLayout, width, height);
        if (!safe) return null;
        safe.__boardHeight = Math.max(180, estimateBoardHeight(safe) || safe.__boardHeight || height || 180);
        safe.__boardWidth = Math.max(320, width || safe.__boardWidth || 320);
        try {
            if (window.localStorage) {
                window.localStorage.setItem(LAYOUT_STORAGE_KEY, JSON.stringify(safe));
            }
        } catch (e) {}
        var persistence = getPersistence();
        if (persistence && persistence.setLayout) {
            persistence.setLayout(safe);
        }
        return safe;
    }

    function clearLayout() {
        try {
            if (window.localStorage) window.localStorage.removeItem(LAYOUT_STORAGE_KEY);
        } catch (e) {}
        var persistence = getPersistence();
        if (persistence && persistence.clearLayout) {
            persistence.clearLayout();
        }
    }

    function scheduleLayoutSave(layout) {
        if (!layout) return;
        if (state.layoutSaveTimer) {
            clearTimeout(state.layoutSaveTimer);
        }
        state.layoutSaveTimer = setTimeout(function () {
            state.layoutSaveTimer = 0;
            if (state.currentLayout) {
                saveLayout(state.currentLayout);
            }
        }, 90);
    }

    function flushLayoutSave(layout) {
        if (state.layoutSaveTimer) {
            clearTimeout(state.layoutSaveTimer);
            state.layoutSaveTimer = 0;
        }
        if (layout || state.currentLayout) {
            return saveLayout(layout || state.currentLayout);
        }
        return null;
    }

    function estimateBoardHeight(layout) {
        if (!layout) return 0;
        var maxBottom = 0;
        for (var i = 0; i < ORDER.length; i++) {
            var key = ORDER[i];
            if (!layout[key]) continue;
            maxBottom = Math.max(maxBottom, num(layout[key].y, 0) + num(layout[key].height, 0));
        }
        return Math.max(maxBottom + 12, num(layout.__boardHeight, 0));
    }

    function rectOverlap(a, b) {
        if (!a || !b) return null;
        var left = Math.max(num(a.x, 0), num(b.x, 0));
        var top = Math.max(num(a.y, 0), num(b.y, 0));
        var right = Math.min(num(a.x, 0) + num(a.width, 0), num(b.x, 0) + num(b.width, 0));
        var bottom = Math.min(num(a.y, 0) + num(a.height, 0), num(b.y, 0) + num(b.height, 0));
        var width = right - left;
        var height = bottom - top;
        if (width <= 0 || height <= 0) return null;
        return {
            x: Math.round(left),
            y: Math.round(top),
            width: Math.round(width),
            height: Math.round(height)
        };
    }

    function getOverlapLayer(board) {
        if (!board) return null;
        var layer = board.querySelector('.ml-layout-overlap-layer');
        if (!layer) {
            layer = document.createElement('div');
            layer.className = 'ml-layout-overlap-layer';
            board.appendChild(layer);
        }
        return layer;
    }

    function updateOverlapState() {
        var board = document.getElementById('ml_char_stats_layout_board');
        if (!board) return;

        var layer = getOverlapLayer(board);
        if (!layer) return;
        layer.innerHTML = '';

        var cards = board.querySelectorAll('[data-layout-card]');
        for (var c = 0; c < cards.length; c++) {
            cards[c].classList.remove('ml-card-overlap');
        }

        if (!state.editing || !state.currentLayout) return;

        var overlapKeys = {};

        for (var i = 0; i < ORDER.length; i++) {
            var firstKey = ORDER[i];
            var firstRect = state.currentLayout[firstKey];
            if (!firstRect) continue;
            for (var j = i + 1; j < ORDER.length; j++) {
                var secondKey = ORDER[j];
                var secondRect = state.currentLayout[secondKey];
                if (!secondRect) continue;
                var overlap = rectOverlap(firstRect, secondRect);
                if (!overlap) continue;

                overlapKeys[firstKey] = true;
                overlapKeys[secondKey] = true;

                var marker = document.createElement('div');
                marker.className = 'ml-layout-overlap';
                marker.style.left = overlap.x + 'px';
                marker.style.top = overlap.y + 'px';
                marker.style.width = overlap.width + 'px';
                marker.style.height = overlap.height + 'px';
                layer.appendChild(marker);
            }
        }

        for (var k = 0; k < ORDER.length; k++) {
            var key = ORDER[k];
            if (!overlapKeys[key]) continue;
            var card = board.querySelector('[data-layout-card="' + key + '"]');
            if (card) card.classList.add('ml-card-overlap');
        }
    }

    function createCardCloneMap(cards) {
        var clones = {};
        for (var i = 0; i < ORDER.length; i++) {
            var key = ORDER[i];
            clones[key] = cards[key] ? cards[key].cloneNode(true) : null;
        }
        return clones;
    }

    function prepareCardForBoard(card) {
        if (!card || card.getAttribute('data-layout-prepared') === '1') return;
        var isMetrics = card.classList && card.classList.contains('ml-metrics');
        var inner = document.createElement('div');
        inner.className = 'ml-card-inner' + (isMetrics ? ' ml-metrics' : '');
        while (card.firstChild) {
            inner.appendChild(card.firstChild);
        }
        if (isMetrics) {
            card.classList.remove('ml-metrics');
            inner.style.width = '100%';
            inner.style.height = '100%';
        }
        card.appendChild(inner);
        card.setAttribute('data-layout-prepared', '1');
    }

    function attachEditChrome(card, key) {
        var drag = document.createElement('div');
        drag.className = 'ml-edit-drag-handle';
        drag.setAttribute('data-layout-role', 'drag');
        drag.setAttribute('data-layout-key', key);

        card.appendChild(drag);

        var dirs = ['nw', 'ne', 'sw', 'se'];
        for (var i = 0; i < dirs.length; i++) {
            var dir = dirs[i];
            var resize = document.createElement('div');
            resize.className = 'ml-edit-resize ' + dir;
            resize.setAttribute('data-layout-role', 'resize');
            resize.setAttribute('data-layout-key', key);
            resize.setAttribute('data-layout-dir', dir);
            card.appendChild(resize);
        }
    }

    function applyCardStyle(card, rect) {
        card.style.position = 'absolute';
        card.style.left = rect.x + 'px';
        card.style.top = rect.y + 'px';
        card.style.width = rect.width + 'px';
        card.style.height = rect.height + 'px';
        card.style.margin = '0';
        card.style.boxSizing = 'border-box';
        card.style.maxWidth = 'none';
        card.style.minHeight = '0';
        card.style.overflow = 'visible';
    }

    function buildLayoutBoard(layout, editing) {
        var content = getContent();
        if (!content) return false;
        var originalCards = findCards(content);
        if (!allCardsPresent(originalCards)) return false;
        var clones = createCardCloneMap(originalCards);

        var boardWidth = Math.max(320, Math.round(content.getBoundingClientRect().width || content.clientWidth || 0));
        var boardHeight = Math.max(180, Math.round(content.getBoundingClientRect().height || content.clientHeight || 0));

        var safe = normalizeLayout(layout, state.defaultLayout, boardWidth, boardHeight);
        if (!safe) return false;

        var sourceWidth = Math.max(320, num(safe.__boardWidth, boardWidth));
        var sourceHeight = Math.max(180, num(safe.__boardHeight, estimateBoardHeight(safe) || boardHeight));

        var scaleX = boardWidth / sourceWidth;
        if (!isFinite(scaleX) || scaleX <= 0) scaleX = 1;

        var scaleY = 1;
        if (!isFinite(scaleY) || scaleY <= 0) scaleY = 1;

        if (Math.abs(scaleX - 1) < 0.035) scaleX = 1;

        content.innerHTML = '';
        content.className = 'ml-layout ml-layout-board-host';
        content.style.display = 'block';
        content.style.gridTemplateColumns = '';
        content.style.gap = '';
        content.style.overflowX = 'hidden';
        content.style.overflowY = editing ? 'auto' : 'hidden';
        content.style.boxSizing = 'border-box';
        content.style.paddingRight = '0';
        var bottomReserve = editing ? 120 : 0;
        content.style.paddingBottom = bottomReserve + 'px';
        content.style.height = '100%';

        state.editMode = 'move';
        var board = document.createElement('div');
        board.id = 'ml_char_stats_layout_board';
        board.className = 'ml-layout-board mode-move' + (editing ? ' is-editing' : '');
        board.style.minHeight = Math.max(180, estimateBoardHeight(safe) + (editing ? 50 : 0)) + 'px';
        content.appendChild(board);

        var snapLayer = document.createElement('div');
        snapLayer.id = 'ml_char_stats_snap_layer';
        snapLayer.style.cssText = 'position:absolute; top:0; left:0; right:0; bottom:0; pointer-events:none; z-index:9999;';
        board.appendChild(snapLayer);

        var nextLayout = cloneLayout(safe);

        for (var i = 0; i < ORDER.length; i++) {
            var key = ORDER[i];
            var card = clones[key];
            if (!card) continue;
            var rect = nextLayout[key];
            
            rect.x = Math.max(0, Math.round(rect.x * scaleX));
            rect.width = Math.max(160, Math.round(rect.width * scaleX));
            
            if (rect.x + rect.width > boardWidth) {
                rect.width = Math.max(160, boardWidth - rect.x);
            }
            if (rect.x < 0) rect.x = 0;
            if (rect.x + rect.width > boardWidth) {
                rect.x = Math.max(0, boardWidth - rect.width);
            }
            
            rect.y = Math.max(0, Math.round(rect.y * scaleY));
            rect.height = Math.max(90, Math.round(rect.height * scaleY));
            
            nextLayout[key] = rect;

            card.setAttribute('data-layout-card', key);
            prepareCardForBoard(card);
            applyCardStyle(card, rect);
            if (editing) {
                attachEditChrome(card, key);
            }
            board.appendChild(card);
        }

        nextLayout.__boardWidth = boardWidth;
        nextLayout.__boardHeight = Math.max(180, estimateBoardHeight(nextLayout));
        
        state.currentLayout = nextLayout;
        setToolbarVisible(editing);
        bindBoardHandles(board, editing);
        updateOverlapState();

        var itemState = window.mlCharStatsLoadItems ? window.mlCharStatsLoadItems() : {};

        document.querySelectorAll('#ml_char_stats_layout_board [data-id]').forEach(function(el) {
            var p = el.parentNode;
            while(p && p !== document) {
                if (p.hasAttribute('data-container')) {
                    el.setAttribute('data-original-container', p.getAttribute('data-container'));
                    break;
                }
                p = p.parentNode;
            }
        });

        if (editing) {
            var trash = document.getElementById('ml_char_stats_trash');
            if (!trash) {
                trash = document.createElement('div');
                trash.id = 'ml_char_stats_trash';
                trash.className = 'ml-trash-panel ml-no-drag';
                trash.innerHTML = '<div class="ml-trash-header">\u0421\u043a\u0440\u044b\u0442\u044b\u0435 \u044d\u043b\u0435\u043c\u0435\u043d\u0442\u044b</div><div class="ml-trash-content" id="ml_trash_content"></div>';
                content.appendChild(trash);
            }
            var trashContent = document.getElementById('ml_trash_content');

            if (itemState.hidden) {
                itemState.hidden.forEach(function(id) {
                    var el = document.querySelector('#ml_char_stats_layout_board [data-id="' + id + '"]');
                    if (el && trashContent) {
                        el.setAttribute('data-hidden', '1');
                        trashContent.appendChild(el);
                    }
                });
            }

            document.querySelectorAll('#ml_char_stats_layout_board [data-container]').forEach(function(c) {
                var k = c.getAttribute('data-container');
                if (itemState[k]) {
                    itemState[k].forEach(function(id) {
                        var child = null;
                        for(var idx=0; idx<c.children.length; idx++) {
                            if (c.children[idx].getAttribute('data-id') === id) { child = c.children[idx]; break; }
                        }
                        if (child) c.appendChild(child);
                    });
                }
            });

            document.querySelectorAll('#ml_char_stats_layout_board .ml-row, #ml_char_stats_layout_board .ml-stat-chip, #ml_char_stats_trash .ml-row, #ml_char_stats_trash .ml-stat-chip').forEach(function(el) {
                if (el.querySelector('.ml-item-controls')) return;
                var ctrl = document.createElement('div');
                ctrl.className = 'ml-item-controls ml-no-drag';
                ctrl.innerHTML = '<div class="ml-item-btn up" data-action="up">\u25b2</div><div class="ml-item-btn down" data-action="down">\u25bc</div><div class="ml-item-btn hide" data-action="hide">\u2716</div><div class="ml-item-btn restore" data-action="restore">\u21b5</div>';
                el.appendChild(ctrl);

                ctrl.addEventListener('mousedown', function(e) {
                    e.stopPropagation(); e.preventDefault();
                    var btn = e.target.closest('.ml-item-btn');
                    if (!btn) return;
                    var action = btn.getAttribute('data-action');
                    var parent = el.parentNode;
                    if (action === 'up') {
                        var prev = el.previousElementSibling;
                        if (prev) parent.insertBefore(el, prev);
                    } else if (action === 'down') {
                        var next = el.nextElementSibling;
                        if (next) parent.insertBefore(el, next.nextElementSibling);
                    } else if (action === 'hide') {
                        el.setAttribute('data-hidden', '1');
                        document.getElementById('ml_trash_content').appendChild(el);
                    } else if (action === 'restore') {
                        el.removeAttribute('data-hidden');
                        var tId = el.getAttribute('data-original-container');
                        var t = document.querySelector('#ml_char_stats_layout_board [data-container="' + tId + '"]');
                        if (t) t.appendChild(el);
                    }
                    updateTrashCount();
                });
                ctrl.addEventListener('click', function(e) { e.stopPropagation(); e.preventDefault(); });
            });
            
            var modeBtn = document.getElementById('ml_editor_mode_btn');
            if (modeBtn) modeBtn.textContent = '\u0420\u0435\u0436\u0438\u043c: \u041f\u0435\u0440\u0435\u043c\u0435\u0449\u0435\u043d\u0438\u0435';
            updateTrashCount();

        } else {
            var trashNode = document.getElementById('ml_char_stats_trash');
            if (trashNode) trashNode.remove();

            document.querySelectorAll('#ml_char_stats_layout_board [data-container]').forEach(function(c) {
                var k = c.getAttribute('data-container');
                if (itemState[k]) {
                    itemState[k].forEach(function(id) {
                        var child = null;
                        for(var idx=0; idx<c.children.length; idx++) {
                            if (c.children[idx].getAttribute('data-id') === id) { child = c.children[idx]; break; }
                        }
                        if (child) c.appendChild(child);
                    });
                }
            });

            document.querySelectorAll('#ml_char_stats_layout_board [data-id]').forEach(function(el) {
                var id = el.getAttribute('data-id');
                if (itemState.hidden && itemState.hidden.indexOf(id) !== -1) {
                    el.style.display = 'none';
                } else {
                    el.style.display = '';
                }
            });
        }

        return true;
    }

    function refreshBoardHeight() {
        var board = document.getElementById('ml_char_stats_layout_board');
        if (!board || !state.currentLayout) return;
        state.currentLayout.__boardHeight = Math.max(estimateBoardHeight(state.currentLayout), 180);
        board.style.minHeight = state.currentLayout.__boardHeight + 'px';
    }

    function updateCardElement(key) {
        var board = document.getElementById('ml_char_stats_layout_board');
        if (!board || !state.currentLayout || !state.currentLayout[key]) return;
        var card = board.querySelector('[data-layout-card="' + key + '"]');
        if (!card) return;
        applyCardStyle(card, state.currentLayout[key]);
        updateOverlapState();
    }

    function bindBoardHandles(board, editing) {
        if (!board || !editing || board.getAttribute('data-editor-bound') === '1') return;
        board.setAttribute('data-editor-bound', '1');

        var handles = board.querySelectorAll('.ml-edit-drag-handle, .ml-edit-resize');
        for (var i = 0; i < handles.length; i++) {
            handles[i].addEventListener('mousedown', function (event) {
                if (event.button !== 0) return;
                var role = this.getAttribute('data-layout-role');
                var key = this.getAttribute('data-layout-key');
                var dir = this.getAttribute('data-layout-dir') || '';
                startPointer(role, key, event, dir);
            });
        }
    }

    function stopPointer() {
        if (state.pointer) {
            var board = document.getElementById('ml_char_stats_layout_board');
            if (board) {
                var cards = board.querySelectorAll('[data-layout-card]');
                for (var i = 0; i < cards.length; i++) {
                    cards[i].classList.remove('is-dragging');
                }
            }
        }
        var layer = document.getElementById('ml_char_stats_snap_layer');
        if (layer) layer.innerHTML = '';
        
        state.pointer = null;
        document.body.style.userSelect = '';
        document.body.style.cursor = '';
        updateOverlapState();
        if (state.editing && state.currentLayout) {
            flushLayoutSave(state.currentLayout);
        }
    }

    function startPointer(kind, key, event, dir) {
        stopPointer();
        var board = document.getElementById('ml_char_stats_layout_board');
        if (!board || !state.currentLayout || !state.currentLayout[key]) return;
        
        var card = board.querySelector('[data-layout-card="' + key + '"]');
        if (card) card.classList.add('is-dragging');

        var rect = state.currentLayout[key];
        var safeDir = String(dir || 'se').toLowerCase();
        state.pointer = {
            kind: kind,
            dir: safeDir,
            key: key,
            startX: event.clientX,
            startY: event.clientY,
            boardWidth: Math.round(board.getBoundingClientRect().width || board.clientWidth || 0),
            boardHeight: Math.round(board.getBoundingClientRect().height || board.clientHeight || 0),
            rect: {
                x: rect.x,
                y: rect.y,
                width: rect.width,
                height: rect.height
            }
        };
        document.body.style.userSelect = 'none';
        if (kind === 'resize') {
            if (safeDir === 'ne' || safeDir === 'sw') {
                document.body.style.cursor = 'nesw-resize';
            } else {
                document.body.style.cursor = 'nwse-resize';
            }
        } else {
            document.body.style.cursor = 'grabbing';
        }
        if (event.stopImmediatePropagation) event.stopImmediatePropagation();
        event.preventDefault();
        event.stopPropagation();
    }

    function onPointerMove(event) {
        if (!state.pointer || !state.currentLayout) return;
        var ptr = state.pointer;
        var rect = state.currentLayout[ptr.key];
        if (!rect) return;

        var dx = Math.round(event.clientX - ptr.startX);
        var dy = Math.round(event.clientY - ptr.startY);
        var minWidth = 160;
        var minHeight = 90;
        var startRight = ptr.rect.x + ptr.rect.width;
        var startBottom = ptr.rect.y + ptr.rect.height;
        var next = {
            x: ptr.rect.x,
            y: ptr.rect.y,
            width: ptr.rect.width,
            height: ptr.rect.height
        };

        var guidesX = [0, ptr.boardWidth];
        var guidesY = [0, ptr.boardHeight];
        for (var i = 0; i < ORDER.length; i++) {
            var k = ORDER[i];
            if (k === ptr.key || !state.currentLayout[k]) continue;
            var r = state.currentLayout[k];
            guidesX.push(r.x, r.x + r.width, r.x + Math.round(r.width / 2));
            guidesY.push(r.y, r.y + r.height, r.y + Math.round(r.height / 2));
        }

        function findSnap(val, guides) {
            var closest = val;
            var minDiff = 12;
            for (var i = 0; i < guides.length; i++) {
                var diff = Math.abs(val - guides[i]);
                if (diff < minDiff) { minDiff = diff; closest = guides[i]; }
            }
            return { snapped: minDiff < 12, val: closest };
        }

        var snapXLine = null;
        var snapYLine = null;

        if (ptr.kind === 'drag') {
            next.x = ptr.rect.x + dx;
            next.y = ptr.rect.y + dy;

            var snapLeft = findSnap(next.x, guidesX);
            var snapRight = findSnap(next.x + next.width, guidesX);
            var snapCenter = findSnap(next.x + Math.round(next.width / 2), guidesX);

            if (snapLeft.snapped) { next.x = snapLeft.val; snapXLine = snapLeft.val; }
            else if (snapRight.snapped) { next.x = snapRight.val - next.width; snapXLine = snapRight.val; }
            else if (snapCenter.snapped) { next.x = snapCenter.val - Math.round(next.width / 2); snapXLine = snapCenter.val; }

            var snapTop = findSnap(next.y, guidesY);
            var snapBottom = findSnap(next.y + next.height, guidesY);
            var snapMiddle = findSnap(next.y + Math.round(next.height / 2), guidesY);

            if (snapTop.snapped) { next.y = snapTop.val; snapYLine = snapTop.val; }
            else if (snapBottom.snapped) { next.y = snapBottom.val - next.height; snapYLine = snapBottom.val; }
            else if (snapMiddle.snapped) { next.y = snapMiddle.val - Math.round(next.height / 2); snapYLine = snapMiddle.val; }

            if (next.x < 0) next.x = 0;
            if (next.y < 0) next.y = 0;
            if (next.x + next.width > ptr.boardWidth) {
                next.x = Math.max(0, ptr.boardWidth - next.width);
            }
        } else {
            var dir = String(ptr.dir || 'se');
            if (dir.indexOf('w') !== -1) {
                next.x = ptr.rect.x + dx;
                var snapL = findSnap(next.x, guidesX);
                if (snapL.snapped && snapL.val <= startRight - minWidth) { next.x = snapL.val; snapXLine = snapL.val; }
                var maxX = startRight - minWidth;
                if (next.x < 0) next.x = 0;
                if (next.x > maxX) next.x = maxX;
                next.width = startRight - next.x;
            }
            if (dir.indexOf('e') !== -1) {
                var right = startRight + dx;
                var snapR = findSnap(right, guidesX);
                if (snapR.snapped && snapR.val >= ptr.rect.x + minWidth) { right = snapR.val; snapXLine = snapR.val; }
                var minRight = ptr.rect.x + minWidth;
                if (right < minRight) right = minRight;
                if (right > ptr.boardWidth) right = ptr.boardWidth;
                next.width = right - ptr.rect.x;
            }
            if (dir.indexOf('n') !== -1) {
                next.y = ptr.rect.y + dy;
                var snapT = findSnap(next.y, guidesY);
                if (snapT.snapped && snapT.val <= startBottom - minHeight) { next.y = snapT.val; snapYLine = snapT.val; }
                var maxY = startBottom - minHeight;
                if (next.y < 0) next.y = 0;
                if (next.y > maxY) next.y = maxY;
                next.height = startBottom - next.y;
            }
            if (dir.indexOf('s') !== -1) {
                var bottom = startBottom + dy;
                var snapB = findSnap(bottom, guidesY);
                if (snapB.snapped && snapB.val >= ptr.rect.y + minHeight) { bottom = snapB.val; snapYLine = snapB.val; }
                var minBottom = ptr.rect.y + minHeight;
                if (bottom < minBottom) bottom = minBottom;
                next.height = bottom - ptr.rect.y;
            }
            
            if (next.x + next.width > ptr.boardWidth) {
                if (dir.indexOf('w') !== -1) {
                    next.x = Math.max(0, ptr.boardWidth - next.width);
                } else {
                    next.width = Math.max(minWidth, ptr.boardWidth - next.x);
                }
            }
            if (next.width < minWidth) next.width = minWidth;
            if (next.height < minHeight) next.height = minHeight;
            if (next.x < 0) next.x = 0;
            if (next.y < 0) next.y = 0;
        }

        var layer = document.getElementById('ml_char_stats_snap_layer');
        if (layer) {
            layer.innerHTML = '';
            if (snapXLine !== null) {
                var lineX = document.createElement('div');
                lineX.style.cssText = 'position:absolute; top:0; bottom:0; left:' + snapXLine + 'px; width:1px; border-left:1px dashed #6FB7FF;';
                layer.appendChild(lineX);
            }
            if (snapYLine !== null) {
                var lineY = document.createElement('div');
                lineY.style.cssText = 'position:absolute; left:0; right:0; top:' + snapYLine + 'px; height:1px; border-top:1px dashed #6FB7FF;';
                layer.appendChild(lineY);
            }
        }

        state.currentLayout[ptr.key] = next;
        updateCardElement(ptr.key);
        scheduleLayoutSave(state.currentLayout);
        event.preventDefault();
        event.stopPropagation();
    }

    function resetContentHostStyles() {
        var content = getContent();
        var root = document.getElementById('ml_char_stats_root');
        if (content) {
            content.className = 'ml-layout';
            content.style.display = '';
            content.style.gridTemplateColumns = '';
            content.style.gap = '';
            content.style.overflowY = '';
            content.style.paddingRight = '';
            content.style.paddingBottom = '';
            content.style.height = '';
            content.style.minHeight = '';
        }
        if (root && root.classList) {
            root.classList.remove('editing');
        }
    }

    function restoreOriginalContent() {
        if (!state.contentHtml) return;
        resetContentHostStyles();
        baseSetContent.call(base, state.contentHtml);
        resetContentHostStyles();
        ensureStyles();
        ensureToolbar();
        ensureEditorButton();
        state.defaultLayout = captureDefaultLayout() || state.defaultLayout;
        state.lastPanelSig = panelSig();
    }

    function applySavedLayoutIfNeeded() {
        if (!state.contentHtml) return;
        var saved = loadLayout();
        if (saved) {
            restoreOriginalContent();
            buildLayoutBoard(saved, false);
        } else {
            restoreOriginalContent();
            setToolbarVisible(false);
            if (window.mlCharStatsApplyItemsToRaw) window.mlCharStatsApplyItemsToRaw();
        }
        state.lastPanelSig = panelSig();
    }

    function openEditor() {
        if (!state.contentHtml) return;
        hideSettingsPanel();
        restoreOriginalContent();
        var liveLayout = captureDefaultLayout();
        if (liveLayout) {
            state.defaultLayout = cloneLayout(liveLayout);
        }
        var savedLayout = loadLayout();
        state.editing = true;
        state.currentLayout = cloneLayout(savedLayout || liveLayout || state.defaultLayout);
        state.currentLayout = rectifyMetricsRect(state.currentLayout, liveLayout || state.defaultLayout);
        if (!state.currentLayout) {
            state.currentLayout = cloneLayout(state.defaultLayout);
        }
        buildLayoutBoard(state.currentLayout, true);
        state.lastPanelSig = panelSig();
    }

    function saveEditor() {
        if (!state.currentLayout) return;
        var saved = flushLayoutSave(state.currentLayout);

        var itemState = { hidden: [] };
        document.querySelectorAll('#ml_char_stats_layout_board [data-container]').forEach(function(c) {
            var key = c.getAttribute('data-container');
            var arr = [];
            for (var i = 0; i < c.children.length; i++) {
                if (c.children[i].hasAttribute('data-id') && c.children[i].getAttribute('data-hidden') !== '1') {
                    arr.push(c.children[i].getAttribute('data-id'));
                }
            }
            itemState[key] = arr;
        });
        var trash = document.getElementById('ml_trash_content');
        if (trash) {
            for (var j = 0; j < trash.children.length; j++) {
                if (trash.children[j].hasAttribute('data-id')) {
                    itemState.hidden.push(trash.children[j].getAttribute('data-id'));
                }
            }
        }
        if (window.mlCharStatsSaveItems) window.mlCharStatsSaveItems(itemState);

        state.editing = false;
        stopPointer();
        restoreOriginalContent();

        if (window.mlCharStatsApplyItemsToRaw) window.mlCharStatsApplyItemsToRaw();

        if (saved) {
            buildLayoutBoard(saved, false);
        }
        state.lastPanelSig = panelSig();
    }

    function cancelEditor() {
        state.editing = false;
        stopPointer();
        restoreOriginalContent();
        applySavedLayoutIfNeeded();
        state.lastPanelSig = panelSig();
    }

    function resetEditor() {
        state.editing = false;
        stopPointer();
        clearLayout();
        if(window.localStorage) window.localStorage.removeItem('ml_char_stats_items_v2');
        
        if (base.resetRect) {
            base.resetRect();
        } else {
            try { if (window.localStorage) window.localStorage.removeItem('ml_char_stats_rect_v2'); } catch (e) {}
        }
        restoreOriginalContent();
        state.defaultLayout = captureDefaultLayout() || state.defaultLayout;
        state.currentLayout = rectifyMetricsRect(cloneLayout(state.defaultLayout), state.defaultLayout);
        setToolbarVisible(false);
        if (state.currentLayout) {
            var resetLayout = flushLayoutSave(state.currentLayout);
            if (resetLayout) {
                state.currentLayout = cloneLayout(resetLayout);
                buildLayoutBoard(resetLayout, false);
            } else if (window.mlCharStatsApplyItemsToRaw) {
                window.mlCharStatsApplyItemsToRaw();
            }
        } else if (window.mlCharStatsApplyItemsToRaw) {
            window.mlCharStatsApplyItemsToRaw();
        }
        state.lastPanelSig = panelSig();
    }

    if (window.__mlCharStatsEditorMove) {
        window.removeEventListener('mousemove', window.__mlCharStatsEditorMove, true);
        window.removeEventListener('mouseup', window.__mlCharStatsEditorUp, true);
        window.removeEventListener('mouseleave', window.__mlCharStatsEditorUp, true);
        window.removeEventListener('blur', window.__mlCharStatsEditorUp, true);
    }
    
    window.__mlCharStatsEditorMove = onPointerMove;
    window.__mlCharStatsEditorUp = stopPointer;

    window.addEventListener('mousemove', window.__mlCharStatsEditorMove, true);
    window.addEventListener('mouseup', window.__mlCharStatsEditorUp, true);
    window.addEventListener('mouseleave', window.__mlCharStatsEditorUp, true);
    window.addEventListener('blur', window.__mlCharStatsEditorUp, true);

    if (window.__mlCharStatsEditorWatcherId) {
        window.clearInterval(window.__mlCharStatsEditorWatcherId);
    }

    window.__mlCharStatsEditorWatcherId = window.setInterval(function () {
        var panel = getPanel();
        if (!panel || !state.contentHtml) {
            state.lastPanelSig = '';
            return;
        }
        var sig = panelSig();
        if (sig === state.lastPanelSig) return;
        state.lastPanelSig = sig;
        if (state.editing && state.currentLayout) {
            restoreOriginalContent();
            buildLayoutBoard(state.currentLayout, true);
        } else {
            var saved = loadLayout();
            if (saved) {
                restoreOriginalContent();
                buildLayoutBoard(saved, false);
            }
        }
    }, 220);

    base.open = function () {
        var result = baseOpen.apply(base, arguments);
        ensureStyles();
        ensureToolbar();
        ensureEditorButton();
        state.lastPanelSig = panelSig();
        return result;
    };

    base.close = function () {
        if (state.currentLayout) {
            flushLayoutSave(state.currentLayout);
        }
        state.editing = false;
        stopPointer();
        setToolbarVisible(false);
        state.lastPanelSig = '';
        if (base.persistence && base.persistence.flush) {
            base.persistence.flush();
        }
        return baseClose.apply(base, arguments);
    };

    base.setContent = function (html) {
        state.contentHtml = String(html || '');
        baseSetContent.call(base, html);
        ensureStyles();
        ensureToolbar();
        ensureEditorButton();
        state.defaultLayout = captureDefaultLayout() || state.defaultLayout;

        if (state.editing) {
            state.currentLayout = cloneLayout(state.currentLayout || state.defaultLayout);
            if (state.currentLayout) {
                buildLayoutBoard(state.currentLayout, true);
            }
        } else {
            var saved = loadLayout();
            if (saved) {
                buildLayoutBoard(saved, false);
            } else {
                var defaultView = rectifyMetricsRect(cloneLayout(state.defaultLayout), state.defaultLayout);
                state.currentLayout = cloneLayout(defaultView || state.defaultLayout);
                if (defaultView) {
                    buildLayoutBoard(defaultView, false);
                } else {
                    setToolbarVisible(false);
                    if (window.mlCharStatsApplyItemsToRaw) window.mlCharStatsApplyItemsToRaw();
                }
            }
        }

        state.lastPanelSig = panelSig();
    };

    window.addEventListener('beforeunload', function () {
        if (state.currentLayout) {
            flushLayoutSave(state.currentLayout);
        }
        if (base.persistence && base.persistence.flush) {
            base.persistence.flush();
        }
    });

    window.mlCharStatsEditor = {
        ready: true,
        open: openEditor,
        save: saveEditor,
        cancel: cancelEditor,
        reset: resetEditor
    };
})();
]=]

local TILE_PALETTE_JS = [=[
(function () {
    try {
        if (window.mlCharStatsTilePalette && window.mlCharStatsTilePalette.ready) return;
        if (!window.mlCharStats || !window.mlCharStats.ready) return;

        var STORAGE_KEY = 'ml_char_stats_tile_accent_v2';
        var COOKIE_KEY = 'ml_char_stats_tile_accent_v2';
        var DEFAULT_TILE_ACCENT = '#595959';
        var base = window.mlCharStats;
        var baseOpen = base.open;
        var baseSetContent = base.setContent;
        var tilePickerHsv = null;
        var tilePickerDraggingArea = false;
        var tilePickerDraggingHue = false;
        var tileEventsBound = false;

        function trimText(value) {
            return String(value == null ? '' : value).replace(/^\s+|\s+$/g, '');
        }

        function safeHex(value, fallback) {
            value = trimText(value || '').toUpperCase();
            if (/^#[0-9A-F]{6}$/.test(value)) return value;
            return fallback || DEFAULT_TILE_ACCENT;
        }

        function clampByte(value) {
            value = Math.round(Number(value) || 0);
            if (value < 0) return 0;
            if (value > 255) return 255;
            return value;
        }

        function clampUnit(value) {
            value = Number(value);
            if (!Number.isFinite(value)) value = 0;
            if (value < 0) return 0;
            if (value > 1) return 1;
            return value;
        }

        function hexToRgb(hex) {
            hex = safeHex(hex, DEFAULT_TILE_ACCENT);
            var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? {
                r: parseInt(result[1], 16),
                g: parseInt(result[2], 16),
                b: parseInt(result[3], 16)
            } : { r: 89, g: 89, b: 89 };
        }

        function hsvToRgb(h, s, v) {
            var r, g, b;
            var i = Math.floor(h * 6);
            var f = h * 6 - i;
            var p = v * (1 - s);
            var q = v * (1 - f * s);
            var t = v * (1 - (1 - f) * s);
            switch (i % 6) {
                case 0: r = v; g = t; b = p; break;
                case 1: r = q; g = v; b = p; break;
                case 2: r = p; g = v; b = t; break;
                case 3: r = p; g = q; b = v; break;
                case 4: r = t; g = p; b = v; break;
                default: r = v; g = p; b = q; break;
            }
            return { r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255) };
        }

        function rgbToHsv(r, g, b) {
            r /= 255; g /= 255; b /= 255;
            var max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
            var h = 0;
            var s = max === 0 ? 0 : d / max;
            var v = max;
            if (max !== min) {
                switch (max) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                    case g: h = (b - r) / d + 2; break;
                    default: h = (r - g) / d + 4; break;
                }
                h /= 6;
            }
            return { h: h, s: s, v: v };
        }

        function rgbToHex(r, g, b) {
            return '#' + ((1 << 24) + (clampByte(r) << 16) + (clampByte(g) << 8) + clampByte(b)).toString(16).slice(1).toUpperCase().padStart(6, '0');
        }

        function buildPickerHsvFromColor(colorHex, fallbackHue) {
            var rgb = hexToRgb(colorHex || DEFAULT_TILE_ACCENT);
            var hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
            if ((!Number.isFinite(hsv.h) || hsv.s <= 0.0001 || hsv.v <= 0.0001) && Number.isFinite(fallbackHue)) {
                hsv.h = fallbackHue;
            }
            hsv.h = clampUnit(hsv.h);
            hsv.s = clampUnit(hsv.s);
            hsv.v = clampUnit(hsv.v);
            return hsv;
        }

        function readCookieValue(name) {
            try {
                var escaped = String(name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                var match = document.cookie.match(new RegExp('(?:^|; )' + escaped + '=([^;]*)'));
                return match ? decodeURIComponent(match[1]) : null;
            } catch (e) { return null; }
        }

        function writeCookieValue(name, value, days) {
            try {
                var maxAge = Math.max(0, Math.round((Number(days) || 0) * 86400));
                document.cookie = String(name) + '=' + encodeURIComponent(String(value || '')) + '; path=/; max-age=' + String(maxAge);
            } catch (e) {}
        }

        function getLuaStore() {
            try {
                var key = '__mlCharStatsLuaState';
                var store = window[key];
                if (!store || typeof store !== 'object') store = {};
                window[key] = store;
                return store;
            } catch (e) {
                return {};
            }
        }

        function loadTileColor() {
            var store = getLuaStore();
            var raw = safeHex(store.tileAccentColor, '');
            if (!raw || raw === '') {
                try { raw = safeHex(window.localStorage && window.localStorage.getItem(STORAGE_KEY), ''); } catch (e) { raw = ''; }
            }
            if (!raw || raw === '') raw = safeHex(readCookieValue(COOKIE_KEY), '');
            return safeHex(raw, DEFAULT_TILE_ACCENT);
        }

        function saveTileColor(color) {
            color = safeHex(color, DEFAULT_TILE_ACCENT);
            try {
                var store = getLuaStore();
                store.tileAccentColor = color;
            } catch (e) {}
            try {
                if (window.localStorage) window.localStorage.setItem(STORAGE_KEY, color);
            } catch (e) {}
            writeCookieValue(COOKIE_KEY, color, 3650);
            return color;
        }

        function buildPalette(colorHex) {
            var rgb = hexToRgb(colorHex || DEFAULT_TILE_ACCENT);
            return {
                top: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 0.14)',
                bottom: 'rgba(' + clampByte(rgb.r - 18) + ', ' + clampByte(rgb.g - 18) + ', ' + clampByte(rgb.b - 18) + ', 0.06)',
                border: 'rgba(' + clampByte(rgb.r + 36) + ', ' + clampByte(rgb.g + 36) + ', ' + clampByte(rgb.b + 36) + ', 0.16)',
                glowStrong: 'rgba(' + clampByte(rgb.r + 16) + ', ' + clampByte(rgb.g + 16) + ', ' + clampByte(rgb.b + 16) + ', 0.16)',
                glowSoft: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 0.10)'
            };
        }

        function ensureStyles() {
            if (document.getElementById('ml_char_stats_tile_palette_styles')) return;
            var style = document.createElement('style');
            style.id = 'ml_char_stats_tile_palette_styles';
            style.textContent = '' +
                '#ml_char_stats_root{' +
                    '--ml-tile-top:rgba(89,89,89,0.14);' +
                    '--ml-tile-bottom:rgba(71,71,71,0.06);' +
                    '--ml-tile-border:rgba(125,125,125,0.16);' +
                    '--ml-tile-glow-strong:rgba(105,105,105,0.16);' +
                    '--ml-tile-glow-soft:rgba(89,89,89,0.10);' +
                '}' +
                '#ml_char_stats_root .ml-settings-panel.ml-has-dual-palettes{' +
                    'width:540px;' +
                    'max-width:calc(100vw - 36px);' +
                '}' +
                '#ml_char_stats_root .ml-palette-pair{' +
                    'display:flex;' +
                    'gap:10px;' +
                    'align-items:flex-start;' +
                    'flex-wrap:nowrap;' +
                '}' +
                '#ml_char_stats_root .ml-palette-pair .ml-setting-row{' +
                    'flex:1 1 0;' +
                    'min-width:0;' +
                '}' +
                '#ml_char_stats_root .ml-palette-pair .ml-cp-container{' +
                    'width:100%;' +
                    'box-sizing:border-box;' +
                '}' +
                '#ml_char_stats_root .ml-pill,' +
                '#ml_char_stats_root .ml-chip,' +
                '#ml_char_stats_root .ml-stat-chip,' +
                '#ml_char_stats_root .ml-section{' +
                    'background:linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                    'border-color:var(--ml-tile-border) !important;' +
                '}' +
                '#ml_char_stats_root .ml-empty{' +
                    'background:linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                    'border-color:var(--ml-tile-border) !important;' +
                '}' +
                '#ml_char_stats_root .ml-hero{' +
                    'background:radial-gradient(circle at top right, var(--ml-tile-glow-strong), transparent 28%), radial-gradient(circle at bottom left, var(--ml-tile-glow-soft), transparent 24%), linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                    'border-color:var(--ml-tile-border) !important;' +
                '}' +
                '#ml_char_stats_root .ml-metric{' +
                    'background:linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                    'border-color:var(--ml-tile-border) !important;' +
                '}' +
                '#ml_char_stats_root .ml-metric.accent-green{' +
                    'background:radial-gradient(circle at top left, rgba(80,255,160,0.12), transparent 32%), linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                '}' +
                '#ml_char_stats_root .ml-metric.accent-blue{' +
                    'background:radial-gradient(circle at top left, rgba(80,170,255,0.14), transparent 32%), linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                '}' +
                '#ml_char_stats_root .ml-metric.accent-gold{' +
                    'background:radial-gradient(circle at top left, rgba(255,180,80,0.14), transparent 32%), linear-gradient(180deg, var(--ml-tile-top), var(--ml-tile-bottom)) !important;' +
                '}';
            document.head.appendChild(style);
        }

        function getTileArea() { return document.getElementById('ml_tile_cp_area'); }
        function getTileHue() { return document.getElementById('ml_tile_cp_hue'); }

        function syncTilePickerFromColor(color, keepCurrentHue) {
            var fallbackHue = keepCurrentHue && tilePickerHsv ? tilePickerHsv.h : undefined;
            tilePickerHsv = buildPickerHsvFromColor(color || loadTileColor(), fallbackHue);
            return tilePickerHsv;
        }

        function renderTileControls(color) {
            color = safeHex(color, loadTileColor());
            var rgb = hexToRgb(color);
            var hexInput = document.getElementById('ml_char_stats_tile_hex_input');
            var rInput = document.getElementById('ml_tile_cp_r');
            var gInput = document.getElementById('ml_tile_cp_g');
            var bInput = document.getElementById('ml_tile_cp_b');
            if (hexInput && document.activeElement !== hexInput) hexInput.value = color.toUpperCase();
            if (rInput && document.activeElement !== rInput) rInput.value = String(rgb.r);
            if (gInput && document.activeElement !== gInput) gInput.value = String(rgb.g);
            if (bInput && document.activeElement !== bInput) bInput.value = String(rgb.b);

            var hsv = (tilePickerDraggingArea || tilePickerDraggingHue) && tilePickerHsv
                ? tilePickerHsv
                : syncTilePickerFromColor(color, true);
            var area = getTileArea();
            var thumb = document.getElementById('ml_tile_cp_thumb');
            var hueThumb = document.getElementById('ml_tile_cp_hue_thumb');
            if (area) area.style.backgroundColor = 'hsl(' + Math.round(hsv.h * 360) + ', 100%, 50%)';
            if (thumb) {
                thumb.style.left = (hsv.s * 100) + '%';
                thumb.style.top = ((1 - hsv.v) * 100) + '%';
            }
            if (hueThumb) hueThumb.style.top = (hsv.h * 100) + '%';
        }

        function applyTileColor(color) {
            color = safeHex(color, loadTileColor());
            ensureStyles();
            var root = document.getElementById('ml_char_stats_root');
            if (!root) return color;
            var palette = buildPalette(color);
            root.style.setProperty('--ml-tile-top', palette.top);
            root.style.setProperty('--ml-tile-bottom', palette.bottom);
            root.style.setProperty('--ml-tile-border', palette.border);
            root.style.setProperty('--ml-tile-glow-strong', palette.glowStrong);
            root.style.setProperty('--ml-tile-glow-soft', palette.glowSoft);
            renderTileControls(color);
            return color;
        }

        function setTileColor(color, preserveHue) {
            color = saveTileColor(color);
            if (!(tilePickerDraggingArea || tilePickerDraggingHue)) {
                tilePickerHsv = buildPickerHsvFromColor(color, preserveHue && tilePickerHsv ? tilePickerHsv.h : undefined);
            }
            applyTileColor(color);
            return color;
        }

        function applyTilePickerFromMouse(e, isArea) {
            var hsv = tilePickerHsv ? { h: tilePickerHsv.h, s: tilePickerHsv.s, v: tilePickerHsv.v } : syncTilePickerFromColor(loadTileColor(), true);
            if (isArea) {
                var area = getTileArea();
                if (!area) return;
                var areaRect = area.getBoundingClientRect();
                var x = Math.max(0, Math.min(1, (e.clientX - areaRect.left) / areaRect.width));
                var y = Math.max(0, Math.min(1, (e.clientY - areaRect.top) / areaRect.height));
                hsv.s = x;
                hsv.v = 1 - y;
            } else {
                var hue = getTileHue();
                if (!hue) return;
                var hueRect = hue.getBoundingClientRect();
                var hy = Math.max(0, Math.min(1, (e.clientY - hueRect.top) / hueRect.height));
                hsv.h = hy;
            }
            tilePickerHsv = { h: clampUnit(hsv.h), s: clampUnit(hsv.s), v: clampUnit(hsv.v) };
            var nextRgb = hsvToRgb(tilePickerHsv.h, tilePickerHsv.s, tilePickerHsv.v);
            var nextColor = saveTileColor(rgbToHex(nextRgb.r, nextRgb.g, nextRgb.b));
            applyTileColor(nextColor);
        }

        function bindDocumentEvents() {
            if (tileEventsBound) return;
            tileEventsBound = true;
            document.addEventListener('mousemove', function (e) {
                if (tilePickerDraggingArea) applyTilePickerFromMouse(e, true);
                if (tilePickerDraggingHue) applyTilePickerFromMouse(e, false);
            });
            document.addEventListener('mouseup', function () {
                tilePickerDraggingArea = false;
                tilePickerDraggingHue = false;
            });
            window.addEventListener('blur', function () {
                tilePickerDraggingArea = false;
                tilePickerDraggingHue = false;
            });
        }

        function bindControl(row) {
            if (!row || row.getAttribute('data-ml-tile-bound') === '1') return;
            row.setAttribute('data-ml-tile-bound', '1');
            var cpArea = row.querySelector('#ml_tile_cp_area');
            var cpHue = row.querySelector('#ml_tile_cp_hue');
            var hexInput = row.querySelector('#ml_char_stats_tile_hex_input');
            var rInp = row.querySelector('#ml_tile_cp_r');
            var gInp = row.querySelector('#ml_tile_cp_g');
            var bInp = row.querySelector('#ml_tile_cp_b');

            if (cpArea) {
                cpArea.addEventListener('mousedown', function (e) {
                    tilePickerDraggingArea = true;
                    tilePickerDraggingHue = false;
                    applyTilePickerFromMouse(e, true);
                    e.preventDefault();
                    e.stopPropagation();
                });
            }
            if (cpHue) {
                cpHue.addEventListener('mousedown', function (e) {
                    tilePickerDraggingHue = true;
                    tilePickerDraggingArea = false;
                    applyTilePickerFromMouse(e, false);
                    e.preventDefault();
                    e.stopPropagation();
                });
            }
            if (hexInput) {
                hexInput.addEventListener('input', function (e) {
                    e.stopPropagation();
                    var value = trimText(hexInput.value).toUpperCase();
                    if (/^#[0-9A-F]{6}$/.test(value)) setTileColor(value, true);
                });
                hexInput.addEventListener('mousedown', function (e) { e.stopPropagation(); });
            }
            [rInp, gInp, bInp].forEach(function (inp) {
                if (!inp) return;
                inp.addEventListener('input', function (e) {
                    e.stopPropagation();
                    var r = clampByte(rInp && rInp.value);
                    var g = clampByte(gInp && gInp.value);
                    var b = clampByte(bInp && bInp.value);
                    setTileColor(rgbToHex(r, g, b), true);
                });
                inp.addEventListener('mousedown', function (e) { e.stopPropagation(); });
            });
            bindDocumentEvents();
        }

        function ensureResetHook(panel) {
            if (!panel) return;
            var reset = panel.querySelector('#ml_char_stats_visual_reset');
            if (!reset || reset.getAttribute('data-ml-tile-reset-bound') === '1') return;
            reset.setAttribute('data-ml-tile-reset-bound', '1');
            reset.addEventListener('click', function () {
                window.setTimeout(function () {
                    setTileColor(DEFAULT_TILE_ACCENT, false);
                }, 0);
            });
        }

        function ensureControl() {
            ensureStyles();
            var panel = document.getElementById('ml_char_stats_settings_panel');
            if (!panel) return;
            var stack = panel.querySelector('.ml-settings-stack');
            if (!stack) return;
            panel.classList.add('ml-has-dual-palettes');
            var baseRow = panel.querySelector('#ml_cp_area');
            baseRow = baseRow ? baseRow.closest('.ml-setting-row') : null;
            var pair = document.getElementById('ml_char_stats_palette_pair');
            if (!pair && baseRow) {
                pair = document.createElement('div');
                pair.id = 'ml_char_stats_palette_pair';
                pair.className = 'ml-palette-pair';
                stack.insertBefore(pair, baseRow);
                pair.appendChild(baseRow);
            }
            var row = document.getElementById('ml_char_stats_tile_setting_row');
            if (!row) {
                row = document.createElement('div');
                row.id = 'ml_char_stats_tile_setting_row';
                row.className = 'ml-setting-row';
                row.innerHTML = '' +
                    '<div class="ml-setting-top">' +
                        '<span class="ml-setting-label">\u0426\u0432\u0435\u0442 \u043f\u043b\u0430\u0448\u0435\u043a</span>' +
                    '</div>' +
                    '<div class="ml-cp-container">' +
                        '<div class="ml-cp-area" id="ml_tile_cp_area">' +
                            '<div class="ml-cp-bg"></div>' +
                            '<div class="ml-cp-thumb" id="ml_tile_cp_thumb"></div>' +
                        '</div>' +
                        '<div class="ml-cp-hue" id="ml_tile_cp_hue">' +
                            '<div class="ml-cp-hue-thumb" id="ml_tile_cp_hue_thumb"></div>' +
                        '</div>' +
                        '<div class="ml-cp-inputs">' +
                            '<div class="ml-cp-row"><span>R:</span><input type="text" id="ml_tile_cp_r" maxlength="3"></div>' +
                            '<div class="ml-cp-row"><span>G:</span><input type="text" id="ml_tile_cp_g" maxlength="3"></div>' +
                            '<div class="ml-cp-row"><span>B:</span><input type="text" id="ml_tile_cp_b" maxlength="3"></div>' +
                            '<div class="ml-cp-row" style="margin-top:2px;"><input type="text" id="ml_char_stats_tile_hex_input" maxlength="7" style="width:44px;"></div>' +
                        '</div>' +
                    '</div>';
            }
            if (pair) {
                if (pair.firstChild !== baseRow && baseRow) pair.insertBefore(baseRow, pair.firstChild || null);
                if (row.parentNode !== pair) pair.appendChild(row);
            } else if (row.parentNode !== stack) {
                stack.appendChild(row);
            }
            bindControl(row);
            ensureResetHook(panel);
            syncTilePickerFromColor(loadTileColor(), true);
            applyTileColor(loadTileColor());
        }

        base.open = function () {
            var result = baseOpen.apply(base, arguments);
            try { ensureControl(); } catch (e) {}
            return result;
        };

        base.setContent = function (html) {
            var result = baseSetContent.apply(base, arguments);
            try { ensureControl(); } catch (e) {}
            return result;
        };

        if (document.getElementById('ml_char_stats_root')) ensureControl();

        window.mlCharStatsTilePalette = {
            ready: true,
            get: function () { return loadTileColor(); },
            apply: function (color) { return setTileColor(color || loadTileColor(), true); }
        };
    } catch (e) {
        try { console.error('mlCharStatsTilePalette', e); } catch (_e) {}
    }
})();
]=]


local TEXT_PALETTE_JS = [=[
(function () {
    try {
        if (window.mlCharStatsTextPalette && window.mlCharStatsTextPalette.ready) return;
        if (!window.mlCharStats || !window.mlCharStats.ready) return;

        var STORAGE_KEY = 'ml_char_stats_text_color_v1';
        var COOKIE_KEY = 'ml_char_stats_text_color_v1';
        var DEFAULT_TEXT_COLOR = '#F5F7FF';
        var base = window.mlCharStats;
        var baseOpen = base.open;
        var baseSetContent = base.setContent;
        var textPickerHsv = null;
        var textPickerDraggingArea = false;
        var textPickerDraggingHue = false;
        var textEventsBound = false;

        function trimText(value) {
            return String(value == null ? '' : value).replace(/^\s+|\s+$/g, '');
        }

        function safeHex(value, fallback) {
            value = trimText(value || '').toUpperCase();
            if (/^#[0-9A-F]{6}$/.test(value)) return value;
            return fallback || DEFAULT_TEXT_COLOR;
        }

        function clampByte(value) {
            value = Math.round(Number(value) || 0);
            if (value < 0) return 0;
            if (value > 255) return 255;
            return value;
        }

        function clampUnit(value) {
            value = Number(value);
            if (!Number.isFinite(value)) value = 0;
            if (value < 0) return 0;
            if (value > 1) return 1;
            return value;
        }

        function hexToRgb(hex) {
            hex = safeHex(hex, DEFAULT_TEXT_COLOR);
            var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? {
                r: parseInt(result[1], 16),
                g: parseInt(result[2], 16),
                b: parseInt(result[3], 16)
            } : { r: 245, g: 247, b: 255 };
        }

        function hsvToRgb(h, s, v) {
            var r, g, b;
            var i = Math.floor(h * 6);
            var f = h * 6 - i;
            var p = v * (1 - s);
            var q = v * (1 - f * s);
            var t = v * (1 - (1 - f) * s);
            switch (i % 6) {
                case 0: r = v; g = t; b = p; break;
                case 1: r = q; g = v; b = p; break;
                case 2: r = p; g = v; b = t; break;
                case 3: r = p; g = q; b = v; break;
                case 4: r = t; g = p; b = v; break;
                default: r = v; g = p; b = q; break;
            }
            return { r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255) };
        }

        function rgbToHsv(r, g, b) {
            r /= 255; g /= 255; b /= 255;
            var max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
            var h = 0;
            var s = max === 0 ? 0 : d / max;
            var v = max;
            if (max !== min) {
                switch (max) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                    case g: h = (b - r) / d + 2; break;
                    default: h = (r - g) / d + 4; break;
                }
                h /= 6;
            }
            return { h: h, s: s, v: v };
        }

        function rgbToHex(r, g, b) {
            return '#' + ((1 << 24) + (clampByte(r) << 16) + (clampByte(g) << 8) + clampByte(b)).toString(16).slice(1).toUpperCase().padStart(6, '0');
        }

        function buildPickerHsvFromColor(colorHex, fallbackHue) {
            var rgb = hexToRgb(colorHex || DEFAULT_TEXT_COLOR);
            var hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
            if ((!Number.isFinite(hsv.h) || hsv.s <= 0.0001 || hsv.v <= 0.0001) && Number.isFinite(fallbackHue)) {
                hsv.h = fallbackHue;
            }
            hsv.h = clampUnit(hsv.h);
            hsv.s = clampUnit(hsv.s);
            hsv.v = clampUnit(hsv.v);
            return hsv;
        }

        function readCookieValue(name) {
            try {
                var escaped = String(name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                var match = document.cookie.match(new RegExp('(?:^|; )' + escaped + '=([^;]*)'));
                return match ? decodeURIComponent(match[1]) : null;
            } catch (e) { return null; }
        }

        function writeCookieValue(name, value, days) {
            try {
                var maxAge = Math.max(0, Math.round((Number(days) || 0) * 86400));
                document.cookie = String(name) + '=' + encodeURIComponent(String(value || '')) + '; path=/; max-age=' + String(maxAge);
            } catch (e) {}
        }

        function getLuaStore() {
            try {
                var key = '__mlCharStatsLuaState';
                var store = window[key];
                if (!store || typeof store !== 'object') store = {};
                window[key] = store;
                return store;
            } catch (e) {
                return {};
            }
        }

        function loadTextColor() {
            var store = getLuaStore();
            var raw = safeHex(store.textColor, '');
            if (!raw || raw === '') {
                try { raw = safeHex(window.localStorage && window.localStorage.getItem(STORAGE_KEY), ''); } catch (e) { raw = ''; }
            }
            if (!raw || raw === '') raw = safeHex(readCookieValue(COOKIE_KEY), '');
            return safeHex(raw, DEFAULT_TEXT_COLOR);
        }

        function saveTextColor(color) {
            color = safeHex(color, DEFAULT_TEXT_COLOR);
            try {
                var store = getLuaStore();
                store.textColor = color;
            } catch (e) {}
            try {
                if (window.localStorage) window.localStorage.setItem(STORAGE_KEY, color);
            } catch (e) {}
            writeCookieValue(COOKIE_KEY, color, 3650);
            return color;
        }

        function buildTextPalette(colorHex) {
            var rgb = hexToRgb(colorHex || DEFAULT_TEXT_COLOR);
            return {
                main: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 1)',
                soft: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 0.92)',
                label: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 0.78)',
                muted: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 0.64)',
                faint: 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', 0.50)'
            };
        }

        function ensureStyles() {
            if (document.getElementById('ml_char_stats_text_palette_styles')) return;
            var style = document.createElement('style');
            style.id = 'ml_char_stats_text_palette_styles';
            style.textContent = '' +
                '#ml_char_stats_root{' +
                    '--ml-text-main:rgba(245,247,255,1);' +
                    '--ml-text-soft:rgba(245,247,255,0.92);' +
                    '--ml-text-label:rgba(245,247,255,0.78);' +
                    '--ml-text-muted:rgba(245,247,255,0.64);' +
                    '--ml-text-faint:rgba(245,247,255,0.50);' +
                '}' +
                '#ml_char_stats_root .ml-text-setting-row{' +
                    'display:block !important;' +
                    'flex:none !important;' +
                    'width:255px;' +
                    'max-width:100%;' +
                    'margin-top:10px;' +
                '}' +
                '#ml_char_stats_root .ml-text-setting-row .ml-cp-container{' +
                    'width:255px;' +
                    'max-width:100%;' +
                    'box-sizing:border-box;' +
                '}' +
                '#ml_char_stats_root .ml-body .ml-hero-name,' +
                '#ml_char_stats_root .ml-body .ml-metric-value,' +
                '#ml_char_stats_root .ml-body .ml-section-title-main,' +
                '#ml_char_stats_root .ml-body .ml-stat-chip-value:not(.good):not(.bad):not(.gold){' +
                    'color:var(--ml-text-main) !important;' +
                '}' +
                '#ml_char_stats_root .ml-body .ml-pill,' +
                '#ml_char_stats_root .ml-body .ml-chip,' +
                '#ml_char_stats_root .ml-body .ml-value:not(.good):not(.bad):not(.gold){' +
                    'color:var(--ml-text-soft) !important;' +
                '}' +
                '#ml_char_stats_root .ml-body .ml-stat-chip-label{' +
                    'color:var(--ml-text-label) !important;' +
                '}' +
                '#ml_char_stats_root .ml-body .ml-label:not(.gold),' +
                '#ml_char_stats_root .ml-body .ml-empty{' +
                    'color:var(--ml-text-muted) !important;' +
                '}' +
                '#ml_char_stats_root .ml-body .ml-hero-kicker,' +
                '#ml_char_stats_root .ml-body .ml-metric-label,' +
                '#ml_char_stats_root .ml-body .ml-metric-note,' +
                '#ml_char_stats_root .ml-body .ml-section-title-sub{' +
                    'color:var(--ml-text-faint) !important;' +
                '}';
            document.head.appendChild(style);
        }

        function getTextArea() { return document.getElementById('ml_text_cp_area'); }
        function getTextHue() { return document.getElementById('ml_text_cp_hue'); }

        function syncTextPickerFromColor(color, keepCurrentHue) {
            var fallbackHue = keepCurrentHue && textPickerHsv ? textPickerHsv.h : undefined;
            textPickerHsv = buildPickerHsvFromColor(color || loadTextColor(), fallbackHue);
            return textPickerHsv;
        }

        function renderTextControls(color) {
            color = safeHex(color, loadTextColor());
            var rgb = hexToRgb(color);
            var hexInput = document.getElementById('ml_char_stats_text_hex_input');
            var rInput = document.getElementById('ml_text_cp_r');
            var gInput = document.getElementById('ml_text_cp_g');
            var bInput = document.getElementById('ml_text_cp_b');
            if (hexInput && document.activeElement !== hexInput) hexInput.value = color.toUpperCase();
            if (rInput && document.activeElement !== rInput) rInput.value = String(rgb.r);
            if (gInput && document.activeElement !== gInput) gInput.value = String(rgb.g);
            if (bInput && document.activeElement !== bInput) bInput.value = String(rgb.b);

            var hsv = (textPickerDraggingArea || textPickerDraggingHue) && textPickerHsv
                ? textPickerHsv
                : syncTextPickerFromColor(color, true);
            var area = getTextArea();
            var thumb = document.getElementById('ml_text_cp_thumb');
            var hueThumb = document.getElementById('ml_text_cp_hue_thumb');
            if (area) area.style.backgroundColor = 'hsl(' + Math.round(hsv.h * 360) + ', 100%, 50%)';
            if (thumb) {
                thumb.style.left = (hsv.s * 100) + '%';
                thumb.style.top = ((1 - hsv.v) * 100) + '%';
            }
            if (hueThumb) hueThumb.style.top = (hsv.h * 100) + '%';
        }

        function applyTextColor(color) {
            color = safeHex(color, loadTextColor());
            ensureStyles();
            var root = document.getElementById('ml_char_stats_root');
            if (!root) return color;
            var palette = buildTextPalette(color);
            root.style.setProperty('--ml-text-main', palette.main);
            root.style.setProperty('--ml-text-soft', palette.soft);
            root.style.setProperty('--ml-text-label', palette.label);
            root.style.setProperty('--ml-text-muted', palette.muted);
            root.style.setProperty('--ml-text-faint', palette.faint);
            renderTextControls(color);
            return color;
        }

        function setTextColor(color, preserveHue) {
            color = saveTextColor(color);
            if (!(textPickerDraggingArea || textPickerDraggingHue)) {
                textPickerHsv = buildPickerHsvFromColor(color, preserveHue && textPickerHsv ? textPickerHsv.h : undefined);
            }
            applyTextColor(color);
            return color;
        }

        function applyTextPickerFromMouse(e, isArea) {
            var hsv = textPickerHsv ? { h: textPickerHsv.h, s: textPickerHsv.s, v: textPickerHsv.v } : syncTextPickerFromColor(loadTextColor(), true);
            if (isArea) {
                var area = getTextArea();
                if (!area) return;
                var areaRect = area.getBoundingClientRect();
                var x = Math.max(0, Math.min(1, (e.clientX - areaRect.left) / areaRect.width));
                var y = Math.max(0, Math.min(1, (e.clientY - areaRect.top) / areaRect.height));
                hsv.s = x;
                hsv.v = 1 - y;
            } else {
                var hue = getTextHue();
                if (!hue) return;
                var hueRect = hue.getBoundingClientRect();
                var hy = Math.max(0, Math.min(1, (e.clientY - hueRect.top) / hueRect.height));
                hsv.h = hy;
            }
            textPickerHsv = { h: clampUnit(hsv.h), s: clampUnit(hsv.s), v: clampUnit(hsv.v) };
            var nextRgb = hsvToRgb(textPickerHsv.h, textPickerHsv.s, textPickerHsv.v);
            var nextColor = saveTextColor(rgbToHex(nextRgb.r, nextRgb.g, nextRgb.b));
            applyTextColor(nextColor);
        }

        function bindDocumentEvents() {
            if (textEventsBound) return;
            textEventsBound = true;
            document.addEventListener('mousemove', function (e) {
                if (textPickerDraggingArea) applyTextPickerFromMouse(e, true);
                if (textPickerDraggingHue) applyTextPickerFromMouse(e, false);
            });
            document.addEventListener('mouseup', function () {
                textPickerDraggingArea = false;
                textPickerDraggingHue = false;
            });
            window.addEventListener('blur', function () {
                textPickerDraggingArea = false;
                textPickerDraggingHue = false;
            });
        }

        function bindControl(row) {
            if (!row || row.getAttribute('data-ml-text-bound') === '1') return;
            row.setAttribute('data-ml-text-bound', '1');
            var cpArea = row.querySelector('#ml_text_cp_area');
            var cpHue = row.querySelector('#ml_text_cp_hue');
            var hexInput = row.querySelector('#ml_char_stats_text_hex_input');
            var rInp = row.querySelector('#ml_text_cp_r');
            var gInp = row.querySelector('#ml_text_cp_g');
            var bInp = row.querySelector('#ml_text_cp_b');

            if (cpArea) {
                cpArea.addEventListener('mousedown', function (e) {
                    textPickerDraggingArea = true;
                    textPickerDraggingHue = false;
                    applyTextPickerFromMouse(e, true);
                    e.preventDefault();
                    e.stopPropagation();
                });
            }
            if (cpHue) {
                cpHue.addEventListener('mousedown', function (e) {
                    textPickerDraggingHue = true;
                    textPickerDraggingArea = false;
                    applyTextPickerFromMouse(e, false);
                    e.preventDefault();
                    e.stopPropagation();
                });
            }
            if (hexInput) {
                hexInput.addEventListener('input', function (e) {
                    e.stopPropagation();
                    var value = trimText(hexInput.value).toUpperCase();
                    if (/^#[0-9A-F]{6}$/.test(value)) setTextColor(value, true);
                });
                hexInput.addEventListener('mousedown', function (e) { e.stopPropagation(); });
            }
            [rInp, gInp, bInp].forEach(function (inp) {
                if (!inp) return;
                inp.addEventListener('input', function (e) {
                    e.stopPropagation();
                    var r = clampByte(rInp && rInp.value);
                    var g = clampByte(gInp && gInp.value);
                    var b = clampByte(bInp && bInp.value);
                    setTextColor(rgbToHex(r, g, b), true);
                });
                inp.addEventListener('mousedown', function (e) { e.stopPropagation(); });
            });
            bindDocumentEvents();
        }

        function ensureResetHook(panel) {
            if (!panel) return;
            var reset = panel.querySelector('#ml_char_stats_visual_reset');
            if (!reset || reset.getAttribute('data-ml-text-reset-bound') === '1') return;
            reset.setAttribute('data-ml-text-reset-bound', '1');
            reset.addEventListener('click', function () {
                window.setTimeout(function () {
                    setTextColor(DEFAULT_TEXT_COLOR, false);
                }, 0);
            });
        }

        function ensureControl() {
            ensureStyles();
            var panel = document.getElementById('ml_char_stats_settings_panel');
            if (!panel) return;
            var stack = panel.querySelector('.ml-settings-stack');
            if (!stack) return;

            panel.classList.add('ml-has-dual-palettes');

            var baseRow = panel.querySelector('#ml_cp_area');
            baseRow = baseRow ? baseRow.closest('.ml-setting-row') : null;
            var tileRow = document.getElementById('ml_char_stats_tile_setting_row');
            var pair = document.getElementById('ml_char_stats_palette_pair');

            if (!pair && baseRow) {
                pair = document.createElement('div');
                pair.id = 'ml_char_stats_palette_pair';
                pair.className = 'ml-palette-pair';
                stack.insertBefore(pair, baseRow);
            }

            if (pair) {
                if (baseRow && baseRow.parentNode !== pair) pair.appendChild(baseRow);
                if (tileRow && tileRow.parentNode !== pair) pair.appendChild(tileRow);
                if (baseRow && pair.firstChild !== baseRow) pair.insertBefore(baseRow, pair.firstChild || null);
                if (tileRow && tileRow.parentNode === pair && (!baseRow || tileRow.previousElementSibling !== baseRow)) pair.appendChild(tileRow);
            }

            var row = document.getElementById('ml_char_stats_text_setting_row');
            if (!row) {
                row = document.createElement('div');
                row.id = 'ml_char_stats_text_setting_row';
                row.className = 'ml-setting-row ml-text-setting-row';
                row.innerHTML = '' +
                    '<div class="ml-setting-top">' +
                        '<span class="ml-setting-label">\u0426\u0432\u0435\u0442 \u0442\u0435\u043a\u0441\u0442\u0430</span>' +
                    '</div>' +
                    '<div class="ml-cp-container">' +
                        '<div class="ml-cp-area" id="ml_text_cp_area">' +
                            '<div class="ml-cp-bg"></div>' +
                            '<div class="ml-cp-thumb" id="ml_text_cp_thumb"></div>' +
                        '</div>' +
                        '<div class="ml-cp-hue" id="ml_text_cp_hue">' +
                            '<div class="ml-cp-hue-thumb" id="ml_text_cp_hue_thumb"></div>' +
                        '</div>' +
                        '<div class="ml-cp-inputs">' +
                            '<div class="ml-cp-row"><span>R:</span><input type="text" id="ml_text_cp_r" maxlength="3"></div>' +
                            '<div class="ml-cp-row"><span>G:</span><input type="text" id="ml_text_cp_g" maxlength="3"></div>' +
                            '<div class="ml-cp-row"><span>B:</span><input type="text" id="ml_text_cp_b" maxlength="3"></div>' +
                            '<div class="ml-cp-row" style="margin-top:2px;"><input type="text" id="ml_char_stats_text_hex_input" maxlength="7" style="width:44px;"></div>' +
                        '</div>' +
                    '</div>';
            }

            var anchor = pair || tileRow || baseRow;
            if (anchor && anchor.parentNode === stack) {
                if (row.parentNode !== stack || row.previousElementSibling !== anchor) {
                    stack.insertBefore(row, anchor.nextSibling || null);
                }
            } else if (row.parentNode !== stack) {
                stack.appendChild(row);
            }

            bindControl(row);
            ensureResetHook(panel);
            syncTextPickerFromColor(loadTextColor(), true);
            applyTextColor(loadTextColor());
        }

        function scheduleEnsureControl() {
            try { ensureControl(); } catch (e) {}
            try {
                window.setTimeout(function () {
                    try { ensureControl(); } catch (e) {}
                }, 0);
            } catch (e) {}
        }

        base.open = function () {
            var result = baseOpen.apply(base, arguments);
            scheduleEnsureControl();
            return result;
        };

        base.setContent = function (html) {
            var result = baseSetContent.apply(base, arguments);
            scheduleEnsureControl();
            return result;
        };

        if (document.getElementById('ml_char_stats_root')) scheduleEnsureControl();

        window.mlCharStatsTextPalette = {
            ready: true,
            get: function () { return loadTextColor(); },
            apply: function (color) { return setTextColor(color || loadTextColor(), true); }
        };
    } catch (e) {
        try { console.error('mlCharStatsTextPalette', e); } catch (_e) {}
    }
})();
]=]


local THEME_PRESETS_JS = [=[
(function () {
    try {
        if (window.mlCharStatsThemePresets && window.mlCharStatsThemePresets.ready) return;
        if (!window.mlCharStats || !window.mlCharStats.ready) return;

        var base = window.mlCharStats;
        var baseOpen = base.open;
        var baseSetContent = base.setContent;
        var uiHooksBound = false;
        var updateTimer = 0;

        var THEMES = [
            { id: 'default', name: '\u0411\u0430\u0437\u043E\u0432\u0430\u044F', window: '#000000', tile: '#595959', text: '#F5F7FF' },
            { id: 'emerald', name: '\u0418\u0437\u0443\u043C\u0440\u0443\u0434', window: '#07110E', tile: '#34544A', text: '#EAFBF2' },
            { id: 'burgundy', name: '\u0411\u0443\u0440\u0433\u0443\u043D\u0434\u0438', window: '#14090B', tile: '#5B3941', text: '#FBEAEC' },
            { id: 'sapphire', name: '\u0421\u0430\u043F\u0444\u0438\u0440', window: '#081018', tile: '#334A5E', text: '#EAF4FF' },
            { id: 'amethyst', name: '\u0410\u043C\u0435\u0442\u0438\u0441\u0442', window: '#120C18', tile: '#4F4462', text: '#F3ECFF' },
            { id: 'bronze', name: '\u0411\u0440\u043E\u043D\u0437\u0430', window: '#120E09', tile: '#5A493B', text: '#FFF0DE' }
        ];

        function normalizeHex(value, fallback) {
            value = String(value || '').trim().toUpperCase();
            if (/^#[0-9A-F]{6}$/.test(value)) return value;
            return String(fallback || '#000000').toUpperCase();
        }

        function findTheme(id) {
            for (var i = 0; i < THEMES.length; i++) {
                if (THEMES[i].id === id) return THEMES[i];
            }
            return null;
        }

        function getCurrentWindowColor() {
            var input = document.getElementById('ml_char_stats_hex_input');
            if (input && /^#[0-9A-F]{6}$/i.test(input.value || '')) return String(input.value).trim().toUpperCase();
            try {
                var visual = base && base.persistence && typeof base.persistence.getVisual === 'function' ? base.persistence.getVisual() : null;
                if (visual && visual.accentColor) return normalizeHex(visual.accentColor, '#000000');
            } catch (e) {}
            return '#000000';
        }

        function getCurrentTileColor() {
            try {
                if (window.mlCharStatsTilePalette && window.mlCharStatsTilePalette.ready && typeof window.mlCharStatsTilePalette.get === 'function') {
                    return normalizeHex(window.mlCharStatsTilePalette.get(), '#595959');
                }
            } catch (e) {}
            var input = document.getElementById('ml_char_stats_tile_hex_input');
            return normalizeHex(input && input.value, '#595959');
        }

        function getCurrentTextColor() {
            try {
                if (window.mlCharStatsTextPalette && window.mlCharStatsTextPalette.ready && typeof window.mlCharStatsTextPalette.get === 'function') {
                    return normalizeHex(window.mlCharStatsTextPalette.get(), '#F5F7FF');
                }
            } catch (e) {}
            var input = document.getElementById('ml_char_stats_text_hex_input');
            return normalizeHex(input && input.value, '#F5F7FF');
        }

        function applyWindowColor(color) {
            color = normalizeHex(color, '#000000');
            var input = document.getElementById('ml_char_stats_hex_input');
            if (input) {
                input.value = color;
                try {
                    input.dispatchEvent(new Event('input', { bubbles: true }));
                    return true;
                } catch (e) {}
            }
            try {
                var visual = base && base.persistence && typeof base.persistence.getVisual === 'function' ? (base.persistence.getVisual() || {}) : {};
                visual.accentColor = color;
                if (base && base.persistence && typeof base.persistence.setVisual === 'function') {
                    base.persistence.setVisual(visual);
                }
            } catch (e) {}
            return false;
        }

        function applyTheme(themeId) {
            var theme = typeof themeId === 'string' ? findTheme(themeId) : themeId;
            if (!theme) return false;
            applyWindowColor(theme.window);
            try {
                if (window.mlCharStatsTilePalette && window.mlCharStatsTilePalette.ready && typeof window.mlCharStatsTilePalette.apply === 'function') {
                    window.mlCharStatsTilePalette.apply(theme.tile);
                }
            } catch (e) {}
            try {
                if (window.mlCharStatsTextPalette && window.mlCharStatsTextPalette.ready && typeof window.mlCharStatsTextPalette.apply === 'function') {
                    window.mlCharStatsTextPalette.apply(theme.text);
                }
            } catch (e) {}
            scheduleActiveUpdate();
            return true;
        }

        function scheduleActiveUpdate() {
            if (updateTimer) clearTimeout(updateTimer);
            updateTimer = setTimeout(function () {
                updateTimer = 0;
                try { updateActiveState(); } catch (e) {}
            }, 0);
        }

        function updateActiveState() {
            var box = document.getElementById('ml_char_stats_theme_presets');
            if (!box) return;
            var currentWindow = getCurrentWindowColor();
            var currentTile = getCurrentTileColor();
            var currentText = getCurrentTextColor();
            var buttons = box.querySelectorAll('[data-ml-theme-id]');
            for (var i = 0; i < buttons.length; i++) {
                var btn = buttons[i];
                var theme = findTheme(btn.getAttribute('data-ml-theme-id'));
                var active = !!theme &&
                    currentWindow === normalizeHex(theme.window, '#000000') &&
                    currentTile === normalizeHex(theme.tile, '#595959') &&
                    currentText === normalizeHex(theme.text, '#F5F7FF');
                btn.classList.toggle('is-active', active);
            }
        }

        function ensureStyles() {
            if (document.getElementById('ml_char_stats_theme_presets_styles')) return;
            var style = document.createElement('style');
            style.id = 'ml_char_stats_theme_presets_styles';
            style.textContent = '' +
                '#ml_char_stats_root .ml-text-presets-row{' +
                    'display:flex;' +
                    'gap:10px;' +
                    'align-items:flex-start;' +
                    'justify-content:flex-start;' +
                    'flex-wrap:nowrap;' +
                    'width:100%;' +
                    'margin-top:10px;' +
                '}' +
                '#ml_char_stats_root .ml-text-presets-row .ml-text-setting-row{' +
                    'order:1;' +
                    'margin-top:0 !important;' +
                    'flex:0 0 255px;' +
                    'width:255px !important;' +
                    'max-width:255px !important;' +
                '}' +
                '#ml_char_stats_root .ml-text-presets-row .ml-theme-presets{' +
                    'order:2;' +
                    'margin-left:auto;' +
                    'flex:1 1 0;' +
                    'min-width:0;' +
                    'max-width:100%;' +
                    'box-sizing:border-box;' +
                    'padding:10px 10px 11px;' +
                    'border-radius:14px;' +
                    'border:1px solid rgba(255,255,255,0.09);' +
                    'background:linear-gradient(180deg, rgba(255,255,255,0.05), rgba(255,255,255,0.028));' +
                    'box-shadow:0 10px 28px rgba(0,0,0,0.22), inset 0 1px 0 rgba(255,255,255,0.03);' +
                '}' +
                '#ml_char_stats_root .ml-theme-presets-title{' +
                    'font-size:12px;' +
                    'font-weight:700;' +
                    'letter-spacing:0.04em;' +
                    'color:rgba(245,247,255,0.94);' +
                    'margin-bottom:4px;' +
                '}' +
                '#ml_char_stats_root .ml-theme-presets-sub{' +
                    'font-size:11px;' +
                    'line-height:1.3;' +
                    'color:rgba(245,247,255,0.62);' +
                    'margin-bottom:8px;' +
                '}' +
                '#ml_char_stats_root .ml-theme-presets-grid{' +
                    'display:grid;' +
                    'grid-template-columns:repeat(2, minmax(0, 1fr));' +
                    'gap:8px;' +
                '}' +
                '#ml_char_stats_root .ml-theme-preset-btn{' +
                    'display:flex;' +
                    'align-items:center;' +
                    'justify-content:space-between;' +
                    'gap:8px;' +
                    'width:100%;' +
                    'padding:8px 9px;' +
                    'border-radius:11px;' +
                    'border:1px solid rgba(255,255,255,0.09);' +
                    'background:linear-gradient(180deg, rgba(255,255,255,0.045), rgba(255,255,255,0.028));' +
                    'color:rgba(245,247,255,0.94);' +
                    'font-size:11px;' +
                    'font-weight:600;' +
                    'cursor:pointer;' +
                    'transition:background .12s ease, border-color .12s ease, transform .12s ease, box-shadow .12s ease;' +
                '}' +
                '#ml_char_stats_root .ml-theme-preset-btn:hover{' +
                    'background:linear-gradient(180deg, rgba(255,255,255,0.075), rgba(255,255,255,0.040));' +
                    'border-color:rgba(255,255,255,0.18);' +
                '}' +
                '#ml_char_stats_root .ml-theme-preset-btn.is-active{' +
                    'background:linear-gradient(180deg, rgba(255,255,255,0.10), rgba(255,255,255,0.055));' +
                    'border-color:rgba(255,255,255,0.24);' +
                    'box-shadow:0 0 0 1px rgba(255,255,255,0.06) inset, 0 8px 18px rgba(0,0,0,0.16);' +
                '}' +
                '#ml_char_stats_root .ml-theme-preset-name{' +
                    'min-width:0;' +
                    'overflow:hidden;' +
                    'text-overflow:ellipsis;' +
                    'white-space:nowrap;' +
                '}' +
                '#ml_char_stats_root .ml-theme-preset-swatches{' +
                    'display:inline-flex;' +
                    'align-items:center;' +
                    'gap:5px;' +
                    'flex:0 0 auto;' +
                '}' +
                '#ml_char_stats_root .ml-theme-preset-dot{' +
                    'width:11px;' +
                    'height:11px;' +
                    'border-radius:999px;' +
                    'border:1px solid rgba(255,255,255,0.22);' +
                    'box-shadow:0 1px 3px rgba(0,0,0,0.25);' +
                '}';
            document.head.appendChild(style);
        }

        function buildPresetMarkup() {
            var html = '' +
                '<div class="ml-theme-presets-title">\u0413\u043e\u0442\u043e\u0432\u044b\u0435 \u0442\u0435\u043c\u044b</div>' +
                '<div class="ml-theme-presets-sub">\u041e\u0434\u0438\u043d \u043a\u043b\u0438\u043a \u043C\u0435\u043D\u044F\u0435\u0442 \u0446\u0432\u0435\u0442 \u043E\u043A\u043D\u0430, \u043F\u043B\u0430\u0448\u0435\u043A \u0438 \u0442\u0435\u043A\u0441\u0442\u0430.</div>' +
                '<div class="ml-theme-presets-grid">';
            for (var i = 0; i < THEMES.length; i++) {
                var t = THEMES[i];
                html += '' +
                    '<button type="button" class="ml-theme-preset-btn ml-no-drag" data-ml-theme-id="' + t.id + '">' +
                        '<span class="ml-theme-preset-name">' + t.name + '</span>' +
                        '<span class="ml-theme-preset-swatches">' +
                            '<span class="ml-theme-preset-dot" style="background:' + t.window + ';"></span>' +
                            '<span class="ml-theme-preset-dot" style="background:' + t.tile + ';"></span>' +
                            '<span class="ml-theme-preset-dot" style="background:' + t.text + ';"></span>' +
                        '</span>' +
                    '</button>';
            }
            html += '</div>';
            return html;
        }

        function bindPresetPanel(panel) {
            if (!panel || panel.getAttribute('data-ml-theme-bound') === '1') return;
            panel.setAttribute('data-ml-theme-bound', '1');
            panel.addEventListener('click', function (event) {
                var btn = event.target && event.target.closest ? event.target.closest('[data-ml-theme-id]') : null;
                if (!btn) return;
                event.preventDefault();
                event.stopPropagation();
                applyTheme(btn.getAttribute('data-ml-theme-id'));
            });
            panel.addEventListener('mousedown', function (event) { event.stopPropagation(); });
        }

        function bindUiHooks() {
            if (uiHooksBound) return;
            uiHooksBound = true;
            document.addEventListener('input', function (event) {
                var id = event && event.target ? event.target.id : '';
                if (!id) return;
                if (id === 'ml_char_stats_hex_input' || id === 'ml_char_stats_tile_hex_input' || id === 'ml_char_stats_text_hex_input' ||
                    id === 'ml_cp_r' || id === 'ml_cp_g' || id === 'ml_cp_b' ||
                    id === 'ml_tile_cp_r' || id === 'ml_tile_cp_g' || id === 'ml_tile_cp_b' ||
                    id === 'ml_text_cp_r' || id === 'ml_text_cp_g' || id === 'ml_text_cp_b') {
                    scheduleActiveUpdate();
                }
            }, true);
            document.addEventListener('click', function (event) {
                var id = event && event.target ? event.target.id : '';
                if (id === 'ml_char_stats_visual_reset') {
                    setTimeout(function () { scheduleActiveUpdate(); }, 20);
                }
            }, true);
        }

        function ensureControl() {
            ensureStyles();
            var panel = document.getElementById('ml_char_stats_settings_panel');
            if (!panel) return;
            var stack = panel.querySelector('.ml-settings-stack');
            if (!stack) return;
            var textRow = document.getElementById('ml_char_stats_text_setting_row');
            if (!textRow) return;

            panel.classList.add('ml-has-theme-presets');

            var wrap = document.getElementById('ml_char_stats_text_presets_row');
            if (!wrap) {
                wrap = document.createElement('div');
                wrap.id = 'ml_char_stats_text_presets_row';
                wrap.className = 'ml-text-presets-row';
            }

            var anchor = document.getElementById('ml_char_stats_palette_pair');
            if (wrap.parentNode !== stack) {
                if (anchor && anchor.parentNode === stack) {
                    stack.insertBefore(wrap, anchor.nextSibling || null);
                } else {
                    stack.appendChild(wrap);
                }
            }

            if (textRow.parentNode !== wrap) {
                wrap.appendChild(textRow);
            }

            var presetBox = document.getElementById('ml_char_stats_theme_presets');
            if (!presetBox) {
                presetBox = document.createElement('div');
                presetBox.id = 'ml_char_stats_theme_presets';
                presetBox.className = 'ml-theme-presets';
                presetBox.innerHTML = buildPresetMarkup();
            }
            if (presetBox.parentNode !== wrap) {
                wrap.appendChild(presetBox);
            }

            bindPresetPanel(presetBox);
            bindUiHooks();
            scheduleActiveUpdate();
        }

        function scheduleEnsureControl() {
            try { ensureControl(); } catch (e) {}
            try {
                window.setTimeout(function () {
                    try { ensureControl(); } catch (e) {}
                }, 0);
            } catch (e) {}
        }

        base.open = function () {
            var result = baseOpen.apply(base, arguments);
            scheduleEnsureControl();
            return result;
        };

        base.setContent = function (html) {
            var result = baseSetContent.apply(base, arguments);
            scheduleEnsureControl();
            return result;
        };

        if (document.getElementById('ml_char_stats_root')) scheduleEnsureControl();

        window.mlCharStatsThemePresets = {
            ready: true,
            apply: applyTheme,
            list: function () { return THEMES.slice(); }
        };
    } catch (e) {
        try { console.error('mlCharStatsThemePresets', e); } catch (_e) {}
    }
})();
]=]


local function now()
    return os.clock()
end

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function splitLines(text)
    local lines = {}
    text = tostring(text or ""):gsub("\r", "")
    for line in text:gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    return lines
end

local function stripColorTags(text)
    local s = tostring(text or "")
    s = s:gsub("{%x%x%x%x%x%x}", "")
    s = s:gsub("{%x%x%x%x%x%x%x%x}", "")
    s = s:gsub("~r~", "")
    s = s:gsub("~g~", "")
    s = s:gsub("~b~", "")
    s = s:gsub("~y~", "")
    s = s:gsub("~p~", "")
    s = s:gsub("~w~", "")
    s = s:gsub("~s~", "")
    s = s:gsub("~h~", "")
    s = s:gsub("~n~", "\n")
    return s
end

local function normalizeStatsText(text)
    local s = tostring(text or "")
    s = s:gsub("\r", "")
    s = s:gsub("\t", " ")
    s = s:gsub(" +\n", "\n")
    s = s:gsub("\n\n\n+", "\n\n")
    return trim(s)
end

local function htmlEscape(text)
    local s = tostring(text or "")
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    s = s:gsub("'", "&#39;")
    return s
end

local function utf8ToJsUnicode(str)
    local out = {}
    local i = 1
    local len = #str

    while i <= len do
        local c = str:byte(i)
        local code = 0

        if c < 0x80 then
            code = c
            i = i + 1
        elseif c < 0xE0 then
            local c2 = str:byte(i + 1) or 0
            code = (c % 0x20) * 0x40 + (c2 % 0x40)
            i = i + 2
        elseif c < 0xF0 then
            local c2 = str:byte(i + 1) or 0
            local c3 = str:byte(i + 2) or 0
            code = (c % 0x10) * 0x1000 + (c2 % 0x40) * 0x40 + (c3 % 0x40)
            i = i + 3
        else
            local c2 = str:byte(i + 1) or 0
            local c3 = str:byte(i + 2) or 0
            local c4 = str:byte(i + 3) or 0
            code = (c % 0x08) * 0x40000 + (c2 % 0x40) * 0x1000 + (c3 % 0x40) * 0x40 + (c4 % 0x40)
            i = i + 4
        end

        if code <= 0xFFFF then
            out[#out + 1] = string.format("\\u%04X", code)
        else
            code = code - 0x10000
            local high = 0xD800 + math.floor(code / 0x400)
            local low = 0xDC00 + (code % 0x400)
            out[#out + 1] = string.format("\\u%04X\\u%04X", high, low)
        end
    end

    return table.concat(out)
end

local function cp1251ToJsUnicode(str)
    return utf8ToJsUnicode(u8(str or ""))
end

local function pathJoin(base, name)
    if not base or base == "" then
        return name
    end

    if base:sub(-1) == "\\" or base:sub(-1) == "/" then
        return base .. name
    end

    return base .. "\\" .. name
end

local function getScriptDirectory()
    local ok, script = pcall(function()
        return thisScript and thisScript()
    end)

    if ok and script and type(script.path) == "string" and script.path ~= "" then
        return script.path:match("^(.*)[/\\][^/\\]+$") or "."
    end

    if type(getWorkingDirectory) == "function" then
        local okWd, wd = pcall(getWorkingDirectory)
        if okWd and type(wd) == "string" and wd ~= "" then
            return wd
        end
    end

    return "."
end

local function getConfigDirectory()
    if type(CONFIG_DIRECTORY) == "string" and CONFIG_DIRECTORY ~= "" then
        return CONFIG_DIRECTORY
    end

    local okLocalAppData, localAppData = pcall(function()
        return os.getenv("LOCALAPPDATA")
    end)

    if okLocalAppData and type(localAppData) == "string" and localAppData ~= "" then
        return pathJoin(localAppData, "Programs\\Arizona Games Launcher\\bin\\arizona\\moonloader\\config")
    end

    return pathJoin(getScriptDirectory(), "config")
end

local function getLogPath()
    return ""
end

local logWriteBusy = false

local function safeToString(value)
    if value == nil then
        return "nil"
    end

    local ok, result = pcall(tostring, value)
    if ok then
        return result
    end

    return "<tostring failed>"
end

local function shortLogText(value, limit)
    local text = safeToString(value)
    text = text:gsub("[\r\n\t]+", " ")
    text = text:gsub(" +", " ")
    limit = tonumber(limit) or 140

    if #text > limit then
        return text:sub(1, limit) .. "..."
    end

    return text
end

local function buildTraceback(err, level)
    local message = safeToString(err)

    if debug and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, message, tonumber(level) or 2)
        if ok and trace and trace ~= "" then
            return trace
        end
    end

    return message
end

local function appendLogRaw(line)
    return false
end

local function logLine(level, message)
    return false
end

local function logError(tag, err)
    return false
end

local function logSection(title)
    return false
end

local function removeExistingLogFile()
    return false
end

local function countTableEntries(t)
    local count = 0
    for _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

local function cefEval(js, tag)
    local ok, err = xpcall(function()
        acef.eval(js)
    end, function(e)
        return buildTraceback(e, 2)
    end)

    if not ok then
        logLine("ERROR", "acef.eval failed [" .. safeToString(tag or "unknown") .. "]\n" .. safeToString(err))
        error(err)
    end
end

local function getUiStatePath()
    return pathJoin(getConfigDirectory(), STATE_FILE_NAME)
end

local function readTextFile(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end

    local data = file:read("*a")
    file:close()
    return data
end

local function writeTextFile(path, data)
    local file = io.open(path, "wb")
    if not file then
        return false
    end

    file:write(data or "")
    file:flush()
    file:close()
    return true
end

local function loadPersistedUiStateRaw()
    if lastPersistedUiStateRaw ~= nil then
        return lastPersistedUiStateRaw
    end

    lastPersistedUiStateRaw = readTextFile(getUiStatePath()) or ""
    if lastPersistedUiStateRaw ~= "" then
        logLine("INFO", "loadPersistedUiStateRaw: bytes=" .. tostring(#lastPersistedUiStateRaw))
    end
    return lastPersistedUiStateRaw
end

local function savePersistedUiStateRaw(raw)
    lastPersistedUiStateRaw = tostring(raw or "")
    local ok = writeTextFile(getUiStatePath(), lastPersistedUiStateRaw)
    if not ok then
        logLine("ERROR", "savePersistedUiStateRaw failed: path=" .. getUiStatePath())
    end
    return ok
end

local function sendHttpResponse(client, status, body, contentType)
    if not client then
        return
    end

    body = tostring(body or "")
    contentType = contentType or "text/plain; charset=UTF-8"

    local response = table.concat({
        "HTTP/1.1 " .. tostring(status or "200 OK"),
        "Content-Type: " .. contentType,
        "Content-Length: " .. tostring(#body),
        "Connection: close",
        "Access-Control-Allow-Origin: *",
        "Access-Control-Allow-Methods: GET, POST, OPTIONS",
        "Access-Control-Allow-Headers: Content-Type",
        "",
        body
    }, "\r\n")

    pcall(client.send, client, response)
end

local function urlDecode(value)
    value = tostring(value or "")
    value = value:gsub("+", " ")
    value = value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16) or 0)
    end)
    return value
end

local function parseQueryValue(path, key)
    local query = tostring(path or ""):match("%?(.*)$")
    if not query or query == "" then
        return nil
    end

    for pair in query:gmatch("[^&]+") do
        local name, value = pair:match("^([^=]+)=(.*)$")
        if name == key then
            return urlDecode(value or "")
        end
    end

    return nil
end

local function handleStateHttpClient(client)
    if not client then
        return
    end

    client:settimeout(0.20)

    local requestLine = client:receive("*l")
    if not requestLine or requestLine == "" then
        return
    end

    local method, path = requestLine:match("^(%u+)%s+([^%s]+)")
    local headers = {}

    while true do
        local line = client:receive("*l")
        if not line then
            return
        end

        if line == "" then
            break
        end

        local name, value = line:match("^([^:]+):%s*(.*)$")
        if name then
            headers[name:lower()] = value
        end
    end

    if method == "OPTIONS" then
        sendHttpResponse(client, "204 No Content", "")
        return
    end

    if method == "GET" then
        local data = parseQueryValue(path, "data")
        if data and data ~= "" then
            logLine("INFO", "state server GET save: bytes=" .. tostring(#data))
            savePersistedUiStateRaw(data)
            sendHttpResponse(client, "204 No Content", "")
        else
            sendHttpResponse(client, "200 OK", loadPersistedUiStateRaw() or "", "application/json; charset=UTF-8")
        end
        return
    end

    if method == "POST" then
        local contentLength = tonumber(headers["content-length"] or "0") or 0
        local body = ""
        if contentLength > 0 then
            body = client:receive(contentLength) or ""
        end

        if body ~= "" then
            logLine("INFO", "state server POST save: bytes=" .. tostring(#body))
            savePersistedUiStateRaw(body)
        end

        sendHttpResponse(client, "200 OK", "ok")
        return
    end

    sendHttpResponse(client, "405 Method Not Allowed", "")
end

local function startStateServer()
    if stateServer then
        return true
    end

    if not socket_ok or not socket then
        logLine("WARN", "startStateServer: LuaSocket unavailable: " .. shortLogText(socket, 220))
        return false, socket
    end

    local server, err = socket.bind(STATE_SERVER_HOST, STATE_SERVER_PORT)
    if not server then
        logLine("ERROR", "startStateServer: bind failed on " .. STATE_SERVER_HOST .. ":" .. tostring(STATE_SERVER_PORT) .. " | " .. safeToString(err))
        return false, err
    end

    server:settimeout(0)
    stateServer = server
    logLine("INFO", "startStateServer: listening on " .. STATE_SERVER_HOST .. ":" .. tostring(STATE_SERVER_PORT))

    stateServerThread = lua_thread.create(function()
        while stateServer do
            local client = stateServer:accept()
            if client then
                local ok, clientErr = xpcall(function()
                    handleStateHttpClient(client)
                end, function(e)
                    return buildTraceback(e, 2)
                end)

                if not ok then
                    logLine("ERROR", "state server client handler failed\n" .. safeToString(clientErr))
                end

                pcall(client.close, client)
            end
            wait(0)
        end
    end)

    return true
end

local function stopStateServer()
    if stateServer then
        logLine("INFO", "stopStateServer")
        pcall(stateServer.close, stateServer)
        stateServer = nil
    end
    stateServerThread = nil
end

local function pushPersistedUiStateToCef()
    local raw = loadPersistedUiStateRaw() or ""
    local js

    if raw ~= "" then
        js = "(function(){try{window.__mlCharStatsLuaPersistEndpoint='" .. STATE_SERVER_ENDPOINT .. "';window.__mlCharStatsLuaState=JSON.parse('" .. cp1251ToJsUnicode(raw) .. "');}catch(e){window.__mlCharStatsLuaPersistEndpoint='" .. STATE_SERVER_ENDPOINT .. "';window.__mlCharStatsLuaState={version:1};}})();"
    else
        js = "window.__mlCharStatsLuaPersistEndpoint='" .. STATE_SERVER_ENDPOINT .. "';window.__mlCharStatsLuaState=window.__mlCharStatsLuaState&&typeof window.__mlCharStatsLuaState==='object'?window.__mlCharStatsLuaState:{version:1};"
    end

    logLine("INFO", "pushPersistedUiStateToCef: rawLen=" .. tostring(#raw))
    cefEval(js, "pushPersistedUiStateToCef")
end

local function stripOuterBrackets(value)
    local s = trim(value or "")
    if s:match("^%b[]$") then
        s = s:sub(2, -2)
    end
    return s
end

local function valueOrDash(v)
    v = trim(stripOuterBrackets(v or ""))
    if v == "" then
        return "—"
    end
    return v
end

local function hasValue(v)
    return trim(stripOuterBrackets(v or "")) ~= ""
end

local function formatNumberDots(value)
    local s = tostring(value or ""):gsub("%D", "")
    if s == "" then
        return ""
    end

    if #s < 4 then
        return s
    end

    local rev = s:reverse():gsub("(%d%d%d)", "%1.")
    local out = rev:reverse()

    if out:sub(1, 1) == "." then
        out = out:sub(2)
    end

    return out
end

local function padLeftDigits(value, width)
    local s = tostring(value or ""):gsub("%D", "")
    if s == "" then
        s = "0"
    end

    while #s < width do
        s = "0" .. s
    end

    return s
end

local function normalizeMoneyDigits(value)
    local s = tostring(value or ""):gsub("%D", "")
    s = s:gsub("^0+", "")
    if s == "" then
        return "0"
    end
    return s
end

local function parseTaggedMoneyIntegerString(value)
    local s = trim(stripOuterBrackets(tostring(value or "")))
    if s == "" then
        return ""
    end

    local negative = s:match("^%s*%-") ~= nil

    s = s:gsub("^%s*[-+]", "")
    s = s:gsub("%[", " ")
    s = s:gsub("%]", " ")
    s = s:gsub(":M:%s*", " M ")
    s = s:gsub(":KK:%s*", " KK ")
    s = s:gsub(":K:%s*", " K ")
    s = s:gsub("%s+", " ")
    s = trim(s)

    local billions = s:match("%f[%a][Mm]%f[^%a]%s*([%d%.]+)")
    local millions = s:match("%f[%a][Kk][Kk]%f[^%a]%s*([%d%.]+)")
    local lower = s:match("%f[%a][Kk]%f[^%a]%s*([%d%.]+)")

    local digits = ""

    if billions or millions or lower then
        if billions then
            digits = normalizeMoneyDigits(billions)
                .. (millions and padLeftDigits(millions, 3) or "000")
                .. (lower and padLeftDigits(lower, 6) or "000000")
        elseif millions then
            digits = normalizeMoneyDigits(millions)
                .. (lower and padLeftDigits(lower, 6) or "000000")
        else
            digits = normalizeMoneyDigits(lower)
        end
    else
        digits = s:gsub("%D", "")
    end

    digits = digits:gsub("^0+", "")
    if digits == "" then
        digits = "0"
    end

    if negative and digits ~= "0" then
        return "-" .. digits
    end

    return digits
end

local function formatMoneyValue(value)
    local s = valueOrDash(value)
    if s == "—" then
        return s
    end

    local integerString = parseTaggedMoneyIntegerString(s)
    local negative = integerString:match("^%-") ~= nil
    local digits = integerString:gsub("%D", "")

    if digits == "" then
        return s
    end

    local formatted = formatNumberDots(digits)
    local sign = negative and "-" or ""

    return sign .. "$" .. formatted
end

local function formatPlainValue(value)
    local s = valueOrDash(value)
    if s == "—" then
        return s
    end

    local negative = s:match("^%s*%-") ~= nil
    local digits = s:gsub("%D", "")

    if digits == "" then
        return s
    end

    local formatted = formatNumberDots(digits)
    local sign = negative and "-" or ""

    return sign .. formatted
end

local function formatAzValue(value)
    local s = valueOrDash(value)
    if s == "—" then
        return s
    end

    local negative = s:match("^%s*%-") ~= nil
    local digits = s:gsub("%D", "")

    if digits == "" then
        return s
    end

    local formatted = formatNumberDots(digits)
    local sign = negative and "-" or ""

    return sign .. formatted
end

local function cleanFireRateValue(value)
    local s = valueOrDash(value)
    s = s:gsub("%s*[Сс]корострельности", "")
    s = trim(s)
    return valueOrDash(s)
end

local function cleanTrailerValue(value)
    local s = valueOrDash(value)
    s = s:gsub("%[/[Tt][Rr][Mm][Ee][Nn][Uu]%]", "")
    s = s:gsub("/[Tt][Rr][Mm][Ee][Nn][Uu]", "")
    s = s:gsub("%[%s*%]", "")
    s = s:gsub("%s+", " ")
    s = trim(s)
    return valueOrDash(s)
end

local function toneClass(value)
    local v = tostring(valueOrDash(value))

    if v:find("Имеется", 1, true)
    or v:find("Приобретена", 1, true)
    or v:find("Присутствует", 1, true)
    or v:find("Нет зависимости", 1, true) then
        return "good"
    end

    if v:find("Неактивен", 1, true)
    or v == "0"
    or v == "0%"
    or v == "[0]" then
        return "bad"
    end

    if v:find("AZ%-Coins")
    or v:find("PayDay", 1, true)
    or v:find("LV", 1, true)
    or v:find("Premium", 1, true)
    or v:find("Премиум", 1, true)
    or v:find("^AZ ", 1) then
        return "gold"
    end

    return ""
end

local function looksLikeTexture(text)
    local s = tostring(text or "")
    if s == "" or s == " " then return true end
    if s:find("LD_", 1, true) then return true end
    if s:find("ld_", 1, true) then return true end
    if s:find(".txd", 1, true) then return true end
    if s:find(".saa", 1, true) then return true end
    if s:find("preview", 1, true) then return true end
    if s:find("null", 1, true) then return true end
    return false
end

local function looksLikeStatsPiece(text)
    local s = stripColorTags(text or "")
    return s:find("Основная статистика", 1, true)
        or s:find("Номер аккаунта", 1, true)
        or s:find("Авторизация на сервере", 1, true)
        or s:find("Текущее состояние счета", 1, true)
        or s:find("Талон", 1, true)
        or s:find("Имя:", 1, true)
        or s:find("Пол:", 1, true)
        or s:find("Здоровье:", 1, true)
        or s:find("Уровень:", 1, true)
        or s:find("Работа:", 1, true)
        or s:find("Номер телефона", 1, true)
        or s:find("Уровень розыска:", 1, true)
        or s:find("Законопослушность:", 1, true)
        or s:find("Защита:", 1, true)
        or s:find("Регенерация:", 1, true)
        or s:find("Удача:", 1, true)
        or s:find("Предупреждения:", 1, true)
        or s:find("Семья:", 1, true)
        or s:find("Отель:", 1, true)
        or s:find("Трейлер:", 1, true)
        or s:find("Деньги на депозит", 1, true)
        or s:find("Деньги на депозите", 1, true)
        or s:find("AZ%-Coins", 1, true)
        or s:find("AZ Coins", 1, true)
        or s:find("Предметы", 1, true)
        or s:find("Закрыть", 1, true)
end

function cursor(toggle)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 25)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt8(bs, toggle and 128 or 0)
    raknetBitStreamWriteInt16(bs, 0)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

local function clearCollector()
    tdCollector = {}
    captureStarted = false
end



local ITEMS_PERSIST_PATCH_JS = [=[
(function () {
    if (window.__mlCharStatsItemsPersistPatchReady) return;
    window.__mlCharStatsItemsPersistPatchReady = true;

    var LUA_STATE_KEY = '__mlCharStatsLuaState';

    function clone(value) {
        if (value == null) return null;
        try { return JSON.parse(JSON.stringify(value)); } catch (e) { return null; }
    }

    function ensureStore() {
        var store = window[LUA_STATE_KEY];
        if (!store || typeof store !== 'object') store = {};
        if (!store.version || typeof store.version !== 'number') store.version = 1;
        window[LUA_STATE_KEY] = store;
        return store;
    }

    function flushPersistence() {
        try {
            var persistence = window.mlCharStatsPersistence;
            if (persistence && typeof persistence.flush === 'function') persistence.flush();
        } catch (e) {}
    }

    function readLocal() {
        try {
            var raw = window.localStorage.getItem('ml_char_stats_items_v2');
            return raw ? JSON.parse(raw) : {};
        } catch (e) { return {}; }
    }

    function writeLocal(state) {
        try {
            if (window.localStorage) window.localStorage.setItem('ml_char_stats_items_v2', JSON.stringify(state || {}));
        } catch (e) {}
    }

    function removeLocal() {
        try {
            if (window.localStorage) window.localStorage.removeItem('ml_char_stats_items_v2');
        } catch (e) {}
    }

    function hasContent(state) {
        if (!state || typeof state !== 'object') return false;
        for (var k in state) {
            if (!Object.prototype.hasOwnProperty.call(state, k)) continue;
            if (Array.isArray(state[k]) && state[k].length) return true;
        }
        return false;
    }

    function readPersisted() {
        var store = ensureStore();
        var persisted = clone(store.items);
        if (persisted && typeof persisted === 'object') return persisted;
        return null;
    }

    function writePersisted(state) {
        var store = ensureStore();
        store.items = clone(state || {});
        flushPersistence();
        return store.items;
    }

    function clearPersisted() {
        var store = ensureStore();
        delete store.items;
        flushPersistence();
    }

    var originalLoadItems = window.mlCharStatsLoadItems;
    var originalSaveItems = window.mlCharStatsSaveItems;
    var originalReset = window.mlCharStatsEditor && window.mlCharStatsEditor.reset;

    window.mlCharStatsLoadItems = function () {
        var persisted = readPersisted();
        if (persisted && typeof persisted === 'object') return persisted;

        var local = readLocal();
        if (hasContent(local)) {
            writePersisted(local);
            return local;
        }

        try {
            if (typeof originalLoadItems === 'function') {
                var fallback = originalLoadItems();
                if (fallback && typeof fallback === 'object') {
                    if (hasContent(fallback)) writePersisted(fallback);
                    return fallback;
                }
            }
        } catch (e) {}

        return {};
    };

    window.mlCharStatsSaveItems = function (state) {
        var safeState = clone(state || {}) || {};
        try {
            if (typeof originalSaveItems === 'function') originalSaveItems(safeState); else writeLocal(safeState);
        } catch (e) {
            writeLocal(safeState);
        }
        writePersisted(safeState);
        return safeState;
    };

    window.mlCharStatsClearItems = function () {
        removeLocal();
        clearPersisted();
    };

    if (originalReset && !originalReset.__mlItemsWrapped) {
        var wrappedReset = function () {
            try { window.mlCharStatsClearItems(); } catch (e) {}
            return originalReset.apply(this, arguments);
        };
        wrappedReset.__mlItemsWrapped = true;
        window.mlCharStatsEditor.reset = wrappedReset;
    }

    try {
        var bootState = readLocal();
        if (!readPersisted() && hasContent(bootState)) writePersisted(bootState);
    } catch (e) {}
})();
]=]


local FACTORY_DEFAULTS_PATCH_JS = [=[
(function () {
    if (window.__mlCharStatsFactoryDefaultsPatchReady) return;
    window.__mlCharStatsFactoryDefaultsPatchReady = true;

    var LUA_STATE_KEY = '__mlCharStatsLuaState';
    var RECT_KEYS = ['ml_char_stats_rect_v7', 'ml_char_stats_rect_v7_backup', 'ml_char_stats_rect_v6', 'ml_char_stats_rect_v5'];
    var LAYOUT_KEY = 'ml_char_stats_layout_overlay_v6';
    var ITEMS_KEY = 'ml_char_stats_items_v2';
    var BOOT_FLAG = 'factoryGeometryBootV1';

    function clone(value) {
        if (value == null) return null;
        try { return JSON.parse(JSON.stringify(value)); } catch (e) { return null; }
    }

    function ensureStore() {
        var store = window[LUA_STATE_KEY];
        if (!store || typeof store !== 'object') store = {};
        if (!store.version || typeof store.version !== 'number') store.version = 1;
        window[LUA_STATE_KEY] = store;
        return store;
    }

    function flushPersistence() {
        try {
            var persistence = window.mlCharStatsPersistence;
            if (persistence && typeof persistence.flush === 'function') persistence.flush();
        } catch (e) {}
    }

    function hasObjectContent(obj) {
        if (!obj || typeof obj !== 'object') return false;
        for (var key in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, key)) return true;
        }
        return false;
    }

    function hasArrayContent(obj) {
        if (!obj || typeof obj !== 'object') return false;
        for (var key in obj) {
            if (!Object.prototype.hasOwnProperty.call(obj, key)) continue;
            var value = obj[key];
            if (Array.isArray(value) && value.length) return true;
        }
        return false;
    }

    function hasPersistedRect() {
        try {
            var persistence = window.mlCharStatsPersistence;
            if (persistence && typeof persistence.getRectEntry === 'function') {
                var entry = persistence.getRectEntry();
                if (entry && typeof entry === 'object') return true;
            }
        } catch (e) {}

        try {
            if (window.localStorage) {
                for (var i = 0; i < RECT_KEYS.length; i++) {
                    if (window.localStorage.getItem(RECT_KEYS[i])) return true;
                }
            }
        } catch (e) {}

        try {
            if (typeof document !== 'undefined' && document.cookie && /(?:^|; )ml_char_stats_rect_v7=/.test(document.cookie)) return true;
        } catch (e) {}

        return false;
    }

    function hasPersistedLayout() {
        try {
            var persistence = window.mlCharStatsPersistence;
            if (persistence && typeof persistence.getLayout === 'function') {
                var layout = persistence.getLayout();
                if (layout && typeof layout === 'object') return true;
            }
        } catch (e) {}

        try {
            if (window.localStorage) {
                var raw = window.localStorage.getItem(LAYOUT_KEY);
                if (raw) {
                    var parsed = JSON.parse(raw);
                    if (parsed && typeof parsed === 'object') return true;
                }
            }
        } catch (e) {}

        return false;
    }

    function hasPersistedItems() {
        try {
            var store = ensureStore();
            if (hasArrayContent(store.items)) return true;
        } catch (e) {}

        try {
            if (window.localStorage) {
                var raw = window.localStorage.getItem(ITEMS_KEY);
                if (raw) {
                    var parsed = JSON.parse(raw);
                    if (hasArrayContent(parsed)) return true;
                }
            }
        } catch (e) {}

        return false;
    }

    function shouldBootstrap() {
        var store = ensureStore();
        if (store[BOOT_FLAG]) return false;
        if (hasPersistedRect()) return false;
        if (hasPersistedLayout()) return false;
        if (hasPersistedItems()) return false;
        return true;
    }

    function markBootstrapped() {
        var store = ensureStore();
        store[BOOT_FLAG] = true;
        flushPersistence();
    }

    function runBootstrap() {
        if (!shouldBootstrap()) return;
        var editor = window.mlCharStatsEditor;
        if (!editor || typeof editor.reset !== 'function') return;
        var root = document.getElementById('ml_char_stats_root');
        var content = document.getElementById('ml_char_stats_content');
        if (!root || !content) return;
        try {
            editor.reset();
            markBootstrapped();
        } catch (e) {}
    }

    var bootstrapTimer = 0;
    function scheduleBootstrap() {
        if (bootstrapTimer) clearTimeout(bootstrapTimer);
        bootstrapTimer = setTimeout(function () {
            bootstrapTimer = 0;
            runBootstrap();
            setTimeout(runBootstrap, 40);
        }, 0);
    }

    var base = window.mlCharStats;
    if (base) {
        var originalOpen = base.open;
        if (typeof originalOpen === 'function' && !originalOpen.__mlFactoryWrapped) {
            base.open = function () {
                var result = originalOpen.apply(this, arguments);
                scheduleBootstrap();
                return result;
            };
            base.open.__mlFactoryWrapped = true;
        }

        var originalSetContent = base.setContent;
        if (typeof originalSetContent === 'function' && !originalSetContent.__mlFactoryWrapped) {
            base.setContent = function () {
                var result = originalSetContent.apply(this, arguments);
                scheduleBootstrap();
                return result;
            };
            base.setContent.__mlFactoryWrapped = true;
        }
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        scheduleBootstrap();
    } else {
        window.addEventListener('DOMContentLoaded', scheduleBootstrap, { once: true });
    }
})();
]=]



local ICONS_TOGGLE_PATCH_JS = [=[
(function () {
    if (window.mlCharStatsIconsToggle && window.mlCharStatsIconsToggle.ready) return;
    if (!window.mlCharStats || !window.mlCharStats.ready) return;

    var STORAGE_KEY = 'ml_char_stats_icons_disabled_v1';
    var STYLE_ID = 'ml_char_stats_icons_toggle_style';
    var TOGGLE_ROW_ID = 'ml_char_stats_icons_toggle_row';
    var LUA_STATE_KEY = '__mlCharStatsLuaState';

    function ensureStore() {
        var store = window[LUA_STATE_KEY];
        if (!store || typeof store !== 'object') store = {};
        if (!store.version || typeof store.version !== 'number') store.version = 1;
        window[LUA_STATE_KEY] = store;
        return store;
    }

    function flushPersistence() {
        try {
            var persistence = window.mlCharStatsPersistence;
            if (persistence && typeof persistence.flush === 'function') persistence.flush();
        } catch (e) {}
    }

    function loadPersistedState() {
        try {
            var store = ensureStore();
            if (typeof store.iconsDisabled === 'boolean') return store.iconsDisabled;
        } catch (e) {}
        return null;
    }

    function savePersistedState(value) {
        try {
            var store = ensureStore();
            store.iconsDisabled = !!value;
            flushPersistence();
        } catch (e) {}
    }

    function loadLocalState() {
        try {
            if (!window.localStorage) return null;
            var raw = window.localStorage.getItem(STORAGE_KEY);
            if (raw == null) return null;
            return raw === '1';
        } catch (e) {}
        return null;
    }

    function saveLocalState(value) {
        try {
            if (window.localStorage) {
                if (value) window.localStorage.setItem(STORAGE_KEY, '1');
                else window.localStorage.removeItem(STORAGE_KEY);
            }
        } catch (e) {}
    }

    function loadState() {
        var persisted = loadPersistedState();
        if (typeof persisted === 'boolean') return persisted;
        var local = loadLocalState();
        if (typeof local === 'boolean') {
            savePersistedState(local);
            return local;
        }
        return false;
    }

    function saveState(value) {
        var safeValue = !!value;
        saveLocalState(safeValue);
        savePersistedState(safeValue);
        return safeValue;
    }

    function applyState(value) {
        var root = document.getElementById('ml_char_stats_root');
        if (!root) return;
        root.classList.toggle('ml-icons-disabled', !!value);
        var toggle = document.getElementById('ml_char_stats_icons_toggle');
        if (toggle) toggle.checked = !!value;
    }

    function injectStyle() {
        if (document.getElementById(STYLE_ID)) return;
        var style = document.createElement('style');
        style.id = STYLE_ID;
        style.textContent = [
            '#ml_char_stats_root.ml-icons-disabled .ml-label > span:first-child,',
            '#ml_char_stats_root.ml-icons-disabled .ml-section-title-main > span:first-child,',
            '#ml_char_stats_root.ml-icons-disabled .ml-metric-label > span:first-child,',
            '#ml_char_stats_root.ml-icons-disabled .ml-chip > span:first-child,',
            '#ml_char_stats_root.ml-icons-disabled .ml-stat-chip-label > span:first-child,',
            '#ml_char_stats_root.ml-icons-disabled .ml-hero-name > span:first-child {',
            'display:none !important;',
            '}',
            '#ml_char_stats_root .ml-icons-setting-row { margin-top:8px; margin-bottom:0; }',
            '#ml_char_stats_root .ml-icons-setting-row .ml-setting-top { display:flex; align-items:center; justify-content:space-between; gap:12px; }',
            '#ml_char_stats_root .ml-icons-setting-row .ml-setting-label { white-space:nowrap; }',
            '#ml_char_stats_root .ml-chip-id .ml-chip-id-fallback { display:none; font-weight:800; color:inherit; }',
            '#ml_char_stats_root .ml-chip-id .ml-chip-id-icon { display:inline-flex; }',
            '#ml_char_stats_root.ml-icons-disabled .ml-chip-id .ml-chip-id-icon { display:none !important; }',
            '#ml_char_stats_root.ml-icons-disabled .ml-chip-id .ml-chip-id-fallback { display:inline-flex !important; align-items:center; }',
            '#ml_char_stats_root .ml-setting-switch { position:relative; display:inline-flex; align-items:center; flex:0 0 auto; }',
            '#ml_char_stats_root .ml-setting-switch input { position:absolute; opacity:0; pointer-events:none; }',
            '#ml_char_stats_root .ml-setting-switch-ui { width:42px; height:24px; border-radius:999px; background:rgba(255,255,255,0.10); border:1px solid rgba(255,255,255,0.12); position:relative; transition:background .16s ease,border-color .16s ease; }',
            '#ml_char_stats_root .ml-setting-switch-ui::after { content:""; position:absolute; top:2px; left:2px; width:18px; height:18px; border-radius:50%; background:#fff; box-shadow:0 2px 8px rgba(0,0,0,0.25); transition:transform .16s ease; }',
            '#ml_char_stats_root .ml-setting-switch input:checked + .ml-setting-switch-ui { background:rgba(255,255,255,0.22); border-color:rgba(255,255,255,0.22); }',
            '#ml_char_stats_root .ml-setting-switch input:checked + .ml-setting-switch-ui::after { transform:translateX(18px); }'
        ].join('');
        document.head.appendChild(style);
    }

    function ensureControl() {
        var panel = document.getElementById('ml_char_stats_settings_panel');
        if (!panel) return false;
        injectStyle();
        var stack = panel.querySelector('.ml-settings-stack');
        if (!stack) return false;

        var row = document.getElementById(TOGGLE_ROW_ID);
        if (!row) {
            row = document.createElement('div');
            row.className = 'ml-setting-row ml-icons-setting-row';
            row.id = TOGGLE_ROW_ID;
            row.innerHTML = '' +
                '<div class="ml-setting-top">' +
                    '<span class="ml-setting-label">\u041e\u0442\u043a\u043b\u044e\u0447\u0438\u0442\u044c \u0438\u043a\u043e\u043d\u043a\u0438</span>' +
                    '<label class="ml-setting-switch ml-no-drag">' +
                        '<input type="checkbox" id="ml_char_stats_icons_toggle">' +
                        '<span class="ml-setting-switch-ui"></span>' +
                    '</label>' +
                '</div>';
        }

        var textRow = document.getElementById('ml_char_stats_text_setting_row');
        if (textRow) {
            var textContainer = textRow.querySelector('.ml-cp-container');
            if (textContainer) {
                if (row.parentNode !== textRow || row.previousElementSibling !== textContainer) {
                    textRow.appendChild(row);
                }
            } else if (textRow.parentNode === stack) {
                if (row.parentNode !== stack || textRow.nextElementSibling !== row) {
                    if (textRow.nextSibling) stack.insertBefore(row, textRow.nextSibling);
                    else stack.appendChild(row);
                }
            }
        } else if (row.parentNode !== stack) {
            stack.appendChild(row);
        }

        var toggle = document.getElementById('ml_char_stats_icons_toggle');
        if (toggle && toggle.dataset.mlBound !== '1') {
            toggle.dataset.mlBound = '1';
            toggle.checked = loadState();
            toggle.addEventListener('change', function (event) {
                event.stopPropagation();
                var value = saveState(!!toggle.checked);
                applyState(value);
            });
            toggle.addEventListener('mousedown', function (event) { event.stopPropagation(); });
            toggle.addEventListener('click', function (event) { event.stopPropagation(); });
        }

        var resetBtn = document.getElementById('ml_char_stats_visual_reset');
        if (resetBtn && resetBtn.dataset.mlIconsResetBound !== '1') {
            resetBtn.dataset.mlIconsResetBound = '1';
            resetBtn.addEventListener('click', function () {
                window.setTimeout(function () {
                    saveState(false);
                    applyState(false);
                }, 0);
            }, true);
        }

        applyState(loadState());
        return true;
    }

    function refresh() {
        ensureControl();
        applyState(loadState());
    }

    if (!window.mlCharStats.__iconsToggleWrappedOpen) {
        window.mlCharStats.__iconsToggleWrappedOpen = true;
        var originalOpen = window.mlCharStats.open;
        window.mlCharStats.open = function () {
            var result = originalOpen.apply(this, arguments);
            refresh();
            window.setTimeout(refresh, 0);
            window.setTimeout(refresh, 80);
            return result;
        };
    }

    if (!window.mlCharStats.__iconsToggleWrappedSetContent) {
        window.mlCharStats.__iconsToggleWrappedSetContent = true;
        var originalSetContent = window.mlCharStats.setContent;
        window.mlCharStats.setContent = function () {
            var result = originalSetContent.apply(this, arguments);
            refresh();
            return result;
        };
    }

    window.mlCharStatsIconsToggle = {
        ready: true,
        refresh: refresh,
        destroy: function () {
            var row = document.getElementById(TOGGLE_ROW_ID);
            if (row && row.parentNode) row.parentNode.removeChild(row);
            var style = document.getElementById(STYLE_ID);
            if (style && style.parentNode) style.parentNode.removeChild(style);
        }
    };

    refresh();
    window.setTimeout(refresh, 0);
    window.setTimeout(refresh, 80);
})();
]=]



local PROFILE_PANEL_PATCH_JS = string.format([=[
(function () {
    try {
        if (window.mlCharStatsProfilePanel && window.mlCharStatsProfilePanel.ready) return;
        if (!window.mlCharStats || !window.mlCharStats.ready) return;

        var base = window.mlCharStats;
        var baseOpen = base.open;
        var baseSetContent = base.setContent;
        var PROFILE_OK = %s;
        var EXPECTED_AUTHOR = %s;
        var EXPECTED_TELEGRAM_URL = %s;
        var EXPECTED_TELEGRAM_HANDLE = %s;

        function ensurePanel() {
            var root = document.getElementById('ml_char_stats_root');
            var settings = document.getElementById('ml_char_stats_settings_panel');
            var btn = document.getElementById('ml_char_stats_profile_stub');
            var settingsToggle = document.getElementById('ml_char_stats_settings_toggle');
            if (!root || !settings || !btn) return;

            var panel = document.getElementById('ml_char_stats_profile_panel');
            if (!panel) {
                panel = document.createElement('div');
                panel.id = 'ml_char_stats_profile_panel';
                panel.className = 'ml-settings-panel ml-no-drag';
                panel.style.display = 'none';
                panel.style.right = '18px';
                panel.style.width = '220px';
                if (PROFILE_OK) {
                    panel.innerHTML = '' +
                        '<div class="ml-settings-stack" style="text-align:center;align-items:center;">' +
                            '<div class="ml-setting-row" style="align-items:center;">' +
                                '<div class="ml-setting-top" style="justify-content:center;">' +
                                    '<span class="ml-setting-label" style="text-align:center;">Author: ' + EXPECTED_AUTHOR + '</span>' +
                                '</div>' +
                            '</div>' +
                            '<div class="ml-setting-row" style="align-items:center;">' +
                                '<div class="ml-setting-top" style="justify-content:center;">' +
                                    '<span class="ml-setting-label" style="text-align:center;">Telegram: <a href="' + EXPECTED_TELEGRAM_URL + '" target="_blank" rel="noopener noreferrer" style="color:inherit;text-decoration:none;cursor:pointer;">' + EXPECTED_TELEGRAM_HANDLE + '</a></span>' +
                                '</div>' +
                            '</div>' +
                        '</div>';
                } else {
                    panel.innerHTML = '' +
                        '<div class="ml-settings-stack" style="text-align:center;align-items:center;">' +
                            '<div class="ml-setting-row" style="align-items:center;">' +
                                '<div class="ml-setting-top" style="justify-content:center;">' +
                                    '<span class="ml-setting-label" style="text-align:center;">Integrity check failed</span>' +
                                '</div>' +
                            '</div>' +
                        '</div>';
                }
                settings.parentNode.insertBefore(panel, settings.nextSibling);
            }

            function closeProfile() {
                panel.style.display = 'none';
                btn.classList.remove('active');
            }

            function openProfile() {
                settings.style.display = 'none';
                if (settingsToggle) settingsToggle.classList.remove('active');
                panel.style.display = 'block';
                btn.classList.add('active');
            }

            function toggleProfile(ev) {
                if (ev) {
                    if (ev.preventDefault) ev.preventDefault();
                    if (ev.stopPropagation) ev.stopPropagation();
                }
                if (panel.style.display === 'block') closeProfile();
                else openProfile();
            }

            if (!btn.__mlProfileBound) {
                btn.__mlProfileBound = true;
                btn.addEventListener('click', toggleProfile);
            }

            if (settingsToggle && !settingsToggle.__mlProfileCloseBound) {
                settingsToggle.__mlProfileCloseBound = true;
                settingsToggle.addEventListener('click', function () {
                    closeProfile();
                });
            }

            if (!document.__mlProfileOutsideBound) {
                document.__mlProfileOutsideBound = true;
                document.addEventListener('mousedown', function (ev) {
                    var target = ev.target;
                    if (!target) return;
                    if (panel.style.display !== 'block') return;
                    if (panel.contains(target) || btn.contains(target)) return;
                    closeProfile();
                }, true);
            }
        }

        function refresh() {
            try { ensurePanel(); } catch (e) {}
        }

        base.open = function () {
            var result = baseOpen.apply(base, arguments);
            refresh();
            return result;
        };

        base.setContent = function (html) {
            var result = baseSetContent.apply(base, arguments);
            refresh();
            return result;
        };

        refresh();
        window.setTimeout(refresh, 0);
        window.setTimeout(refresh, 80);

        window.mlCharStatsProfilePanel = {
            ready: true,
            refresh: refresh,
            destroy: function () {
                try {
                    var panel = document.getElementById('ml_char_stats_profile_panel');
                    if (panel && panel.parentNode) panel.parentNode.removeChild(panel);
                } catch (e) {}
            }
        };
    } catch (e) {
        try { console.error('mlCharStatsProfilePanel', e); } catch (_e) {}
    }
})();
]=], isProfileMetaIntact() and "true" or "false", jsQuoted(AUTHOR_NAME), jsQuoted(TELEGRAM_URL), jsQuoted(TELEGRAM_HANDLE))
local function ensureWindow()
    logLine("INFO", "ensureWindow")
    startStateServer()
    pushPersistedUiStateToCef()
    cefEval(BASE_JS, "BASE_JS")
    cefEval(EDITOR_JS, "EDITOR_JS")
    cefEval(TILE_PALETTE_JS, "TILE_PALETTE_JS")
    cefEval(TEXT_PALETTE_JS, "TEXT_PALETTE_JS")
    cefEval(THEME_PRESETS_JS, "THEME_PRESETS_JS")
    cefEval(ITEMS_PERSIST_PATCH_JS, "ITEMS_PERSIST_PATCH_JS")
    cefEval(FACTORY_DEFAULTS_PATCH_JS, "FACTORY_DEFAULTS_PATCH_JS")
    cefEval(ICONS_TOGGLE_PATCH_JS, "ICONS_TOGGLE_PATCH_JS")
    cefEval(PROFILE_PANEL_PATCH_JS, "PROFILE_PANEL_PATCH_JS")
    cefEval("window.mlCharStats && window.mlCharStats.open && window.mlCharStats.open();", "window.open")
end

local function destroyWindow()
    logLine("INFO", "destroyWindow")
    cefEval("if (window.mlCharStatsIconsToggle && window.mlCharStatsIconsToggle.destroy) window.mlCharStatsIconsToggle.destroy(); if (window.mlCharStats && window.mlCharStats.close) window.mlCharStats.close(); window.mlCharStats = undefined; window.mlCharStatsEditor = undefined; window.mlCharStatsTilePalette = undefined; window.mlCharStatsTextPalette = undefined; window.mlCharStatsThemePresets = undefined; window.mlCharStatsIconsToggle = undefined; window.mlCharStatsProfilePanel = undefined; window.__mlCharStatsItemsPersistPatchReady = undefined; window.__mlCharStatsFactoryDefaultsPatchReady = undefined;", "window.close")
end

local function setWindowStatus(text)
    ensureWindow()
    logLine("INFO", "setWindowStatus: " .. shortLogText(text, 120))
    cefEval("window.mlCharStats && window.mlCharStats.setStatus && window.mlCharStats.setStatus('" .. cp1251ToJsUnicode(text or "") .. "');", "setStatus")
end

local function setWindowContent(html, status)
    ensureWindow()
    logLine("INFO", "setWindowContent: htmlLen=" .. tostring(#tostring(html or "")) .. ", status=" .. shortLogText(status or "", 80))
    cefEval("window.mlCharStats && window.mlCharStats.setContent && window.mlCharStats.setContent('" .. cp1251ToJsUnicode(html or "") .. "');", "setContent")
    if status and status ~= "" then
        setWindowStatus(status)
    end
end

local function renderRow(id, icon, label, value)
    local v = valueOrDash(value)
    local cls = toneClass(v)
    return '<div class="ml-row" data-id="' .. id .. '"><div class="ml-label"><span style="margin-right:6px;">' .. icon .. '</span>' .. htmlEscape(label) .. '</div><div class="ml-value ' .. cls .. '">' .. htmlEscape(v) .. '</div></div>'
end

local function renderRowWithClass(id, icon, label, value, labelClass, valueClass)
    local v = valueOrDash(value)
    local iconHtml = ""
    if icon and icon ~= "" then
        iconHtml = '<span style="margin-right:6px;">' .. icon .. '</span>'
    end
    return '<div class="ml-row" data-id="' .. id .. '"><div class="ml-label ' .. (labelClass or "") .. '">' .. iconHtml .. htmlEscape(label) .. '</div><div class="ml-value ' .. (valueClass or "") .. '">' .. htmlEscape(v) .. '</div></div>'
end

local function renderSection(containerId, icon, title, subtitle, inner, extraClass)
    if inner == "" then
        inner = '<div class="ml-empty">Нет данных</div>'
    end

    return [[
        <div class="ml-section">
            <div class="ml-section-title">
                <span class="ml-section-title-main"><span style="margin-right:8px;">]] .. icon .. [[</span>]] .. htmlEscape(title) .. [[</span>
                <span class="ml-section-title-sub">]] .. htmlEscape(subtitle or "") .. [[</span>
            </div>
            <div class="ml-section-list ]] .. (extraClass or "") .. [[" data-container="]] .. containerId .. [[">
            ]] .. inner .. [[
            </div>
        </div>
    ]]
end

local function renderMetric(id, icon, title, value, note, accent)
    local noteHtml = ""
    if note and note ~= "" then
        noteHtml = '<div class="ml-metric-note">' .. htmlEscape(note) .. '</div>'
    end

    return '<div class="ml-metric ' .. (accent or "") .. '" data-id="' .. id .. '"><div class="ml-metric-label"><span style="margin-right:6px;">' .. icon .. '</span>' .. htmlEscape(title) .. '</div><div class="ml-metric-value">' .. htmlEscape(valueOrDash(value)) .. '</div>' .. noteHtml .. '</div>'
end

local function renderTopChip(icon, text, extraClass, fallbackText)
    local className = 'ml-chip' .. ((extraClass and extraClass ~= '') and (' ' .. extraClass) or '')
    local iconClass = 'ml-chip-icon'
    local fallbackHtml = ''
    if fallbackText and fallbackText ~= '' then
        fallbackHtml = '<span class="ml-chip-id-fallback" style="display:none; margin-right:4px;">' .. htmlEscape(fallbackText) .. '</span>'
        iconClass = iconClass .. ' ml-chip-id-icon'
    end
    return '<div class="' .. className .. '"><span class="' .. iconClass .. '" style="margin-right:4px;">' .. icon .. '</span>' .. fallbackHtml .. htmlEscape(valueOrDash(text)) .. '</div>'
end

local function renderStatChip(id, icon, label, value)
    local v = valueOrDash(value)
    local cls = toneClass(v)
    return '<div class="ml-stat-chip" data-id="' .. id .. '"><div class="ml-stat-chip-label"><span style="margin-right:6px;">' .. icon .. '</span>' .. htmlEscape(label) .. '</div><div class="ml-stat-chip-value ' .. cls .. '">' .. htmlEscape(v) .. '</div></div>'
end

local function formatPaydayChipValue(value)
    local s = trim(tostring(value or ""))
    if s == "" then
        return s
    end

    if not s:match("^%d") and s:find(":", 1, true) then
        s = trim((s:gsub("^[^:]+:%s*", "", 1)))
    end

    return s
end

local function normalizeIntegerString(s)
    s = tostring(s or ""):gsub("%D", "")
    s = s:gsub("^0+", "")
    if s == "" then
        return "0"
    end
    return s
end

local function addPositiveIntegerStrings(a, b)
    a = normalizeIntegerString(a)
    b = normalizeIntegerString(b)

    local i = #a
    local j = #b
    local carry = 0
    local out = {}

    while i > 0 or j > 0 or carry > 0 do
        local da = 0
        local db = 0

        if i > 0 then
            da = tonumber(a:sub(i, i)) or 0
            i = i - 1
        end

        if j > 0 then
            db = tonumber(b:sub(j, j)) or 0
            j = j - 1
        end

        local sum = da + db + carry
        out[#out + 1] = tostring(sum % 10)
        carry = math.floor(sum / 10)
    end

    local res = table.concat(out):reverse()
    res = res:gsub("^0+", "")
    if res == "" then
        res = "0"
    end
    return res
end

local function formatMoneyBracket(value)
    if value == nil then
        return "—"
    end

    local s = normalizeIntegerString(value)
    return "$" .. formatNumberDots(s)
end

local function computeTotalAccountsAmount(parsed)
    local values = {
        parsed.acc1,
        parsed.acc2,
        parsed.acc3,
        parsed.acc4,
        parsed.acc5,
        parsed.acc6
    }

    local total = "0"
    local found = false

    for _, raw in ipairs(values) do
        if hasValue(raw) then
            local integerString = parseTaggedMoneyIntegerString(raw)
            local digits = tostring(integerString or ""):gsub("%D", "")
            if digits ~= "" then
                total = addPositiveIntegerStrings(total, digits)
                found = true
            end
        end
    end

    if not found then
        return ""
    end

    return formatMoneyBracket(total)
end

local function detectPaydayMultiplier(...)
    local parts = {...}

    local function normalizeProbe(part)
        local s = tostring(part or "")
        s = s:gsub("Ч", "x")
        s = s:gsub("Х", "x")
        s = s:gsub("х", "x")
        s = s:gsub("%s+", "")
        s = s:lower()
        return s
    end

    for _, part in ipairs(parts) do
        local s = normalizeProbe(part)
        if s:find("x3", 1, true) or s:find("3x", 1, true) or s:find("payday3", 1, true) or s:find("paydayx3", 1, true) then
            return "x3"
        end
        if s:find("x4", 1, true) or s:find("4x", 1, true) or s:find("payday4", 1, true) or s:find("paydayx4", 1, true) then
            return "x4"
        end
    end

    return ""
end

local function parseStats(rawText)
    local parsed = {
        accountNumber = "",
        authDate = "",
        accountState = "",
        x4Payday = "",
        x3Payday = "",

        name = "",
        gender = "",
        health = "",
        level = "",
        respect = "",

        cashSas = "",
        cashVcs = "",
        euro = "",
        btc = "",
        azCoins = "",
        phone = "",
        bank = "",
        acc1 = "",
        acc2 = "",
        acc3 = "",
        acc4 = "",
        acc5 = "",
        acc6 = "",
        moneyDay = "",
        totalAccountsAmount = "",

        job = "",
        org = "",
        position = "",
        status = "",
        citizenship = "",
        family = "",

        wanted = "",
        lawfulness = "",
        warnings = "",
        addiction = "",
        bankCard = "",

        protection = "",
        regen = "",
        damage = "",
        luck = "",
        maxHp = "",
        maxArmor = "",
        stunChance = "",
        bleedChance = "",
        dodgeChance = "",
        reflectDamage = "",
        blockDamage = "",
        fireRate = "",
        recoil = "",
        fruitStun = "",

        hotel = "",
        hotelRoom = "",
        trailer = "",

        extra = {}
    }

    local handled = {}

    local function mark(line)
        handled[line] = true
    end

    local function handleKeyValue(key, value, fullLine)
        local k = trim(key)
        local v = trim(value)
        local ok = true

        local accIndex = k:match("^Состояние личного счет[аё]%s*№%s*(%d+)$")
        if accIndex then
            accIndex = tonumber(accIndex)
            if accIndex and accIndex >= 1 and accIndex <= 6 then
                parsed["acc" .. tostring(accIndex)] = v
                mark(fullLine)
                return
            end
        end

        if k:find("Номер аккаунта", 1, true) then parsed.accountNumber = v
        elseif k:find("Авторизация на сервере", 1, true) then parsed.authDate = v
        elseif k:find("Текущее состояние счета", 1, true) then parsed.accountState = v
        elseif fullLine:find("PayDay", 1, true) or fullLine:find("PAYDAY", 1, true) or fullLine:find("payday", 1, true) then
            local paydayMultiplier = detectPaydayMultiplier(k, fullLine, v)
            if paydayMultiplier == "x3" then
                parsed.x3Payday = v
            elseif paydayMultiplier == "x4" then
                parsed.x4Payday = v
            else
                ok = false
            end

        elseif k == "Имя" then parsed.name = v
        elseif k == "Пол" then parsed.gender = v
        elseif k == "Здоровье" then parsed.health = v
        elseif k == "Уровень" then parsed.level = v
        elseif k == "Уважение" then parsed.respect = v

        elseif k:find("Наличные деньги %(SA%$%)") then parsed.cashSas = v
        elseif k:find("Наличные деньги %(VC%$%)") then parsed.cashVcs = v
        elseif k == "Евро" then parsed.euro = v
        elseif k == "BTC" then parsed.btc = v
        elseif k:find("AZ%-Coins", 1, true) or k:find("AZ Coins", 1, true) then parsed.azCoins = v
        elseif k == "Номер телефона" then parsed.phone = v
        elseif k == "Деньги в банке" then parsed.bank = v
        elseif k == "Деньги на депозит" or k == "Деньги на депозите" or k:find("Деньги на депозит", 1, true) or k:find("Деньги на депозите", 1, true) then parsed.moneyDay = v

        elseif k == "Работа" then parsed.job = v
        elseif k == "Организация" then parsed.org = v
        elseif k == "Должность" then parsed.position = v
        elseif k == "Статус" then parsed.status = v
        elseif k == "Гражданство" then parsed.citizenship = v
        elseif k == "Семья" then parsed.family = v

        elseif k == "Уровень розыска" then parsed.wanted = v
        elseif k == "Законопослушность" then parsed.lawfulness = v
        elseif k == "Предупреждения" then parsed.warnings = v
        elseif k:find("Зависимость от укропа", 1, true) then parsed.addiction = v
        elseif k == "Банковская карта" then parsed.bankCard = v

        elseif k == "Защита" then parsed.protection = v
        elseif k == "Регенерация" then parsed.regen = v
        elseif k == "Урон" then parsed.damage = v
        elseif k == "Удача" then parsed.luck = v
        elseif k == "Макс. HP" then parsed.maxHp = v
        elseif k == "Макс. Бронь" or k == "Макс. броня" or k == "Макс. брони" or ((k:find("Макс.", 1, true) or k:find("Макс", 1, true)) and (k:find("Брон", 1, true) or k:find("брон", 1, true))) then parsed.maxArmor = v
        elseif k == "Шанс оглушения" then parsed.stunChance = v
        elseif k == "Шанс опьянения" or k == "Шанс онемения" then parsed.bleedChance = v
        elseif k == "Шанс избежать оглушения" then parsed.dodgeChance = v
        elseif k == "Отражение урона" then parsed.reflectDamage = v
        elseif k == "Блокировка урона" then parsed.blockDamage = v
        elseif k == "Скорострельность" then parsed.fireRate = v
        elseif k == "Отдача" then parsed.recoil = v
        elseif k:find("Шанс оглушения %(оглушающий плод%)") then parsed.fruitStun = v
        elseif k == "Отель" then parsed.hotel = v
        elseif k == "Номер в отеле" then parsed.hotelRoom = v
        elseif k == "Трейлер" then parsed.trailer = v
        else
            ok = false
        end

        if ok then
            mark(fullLine)
        end
    end

    local lines = splitLines(normalizeStatsText(rawText))

    for _, line in ipairs(lines) do
        local clean = trim(stripColorTags(line))
        if clean ~= "" then
            local key, value = clean:match("^([^:]+):%s*(.*)$")
            if key then
                handleKeyValue(key, value, clean)
            else
                local armorValue = clean:match("^Макс%. Бронь%s+(.+)$")
                    or clean:match("^Макс%. броня%s+(.+)$")
                    or clean:match("^Макс%. брони%s+(.+)$")
                if armorValue then
                    parsed.maxArmor = trim(armorValue)
                    mark(clean)
                elseif clean ~= "Основная статистика"
                and clean ~= "Предметы"
                and clean ~= "Закрыть" then
                    parsed.extra[#parsed.extra + 1] = clean
                end
            end
        end
    end

    local uniqueExtra = {}
    local filteredExtra = {}

    for _, line in ipairs(parsed.extra) do
        local clean = trim(line)
        if clean ~= ""
        and not handled[clean]
        and not uniqueExtra[clean]
        and clean ~= "Основная статистика"
        and clean ~= "Предметы"
        and clean ~= "Закрыть" then
            uniqueExtra[clean] = true
            filteredExtra[#filteredExtra + 1] = clean
        end
    end

    parsed.extra = filteredExtra
    parsed.totalAccountsAmount = computeTotalAccountsAmount(parsed)

    return parsed
end

local function buildStatsHtml(parsed)
    local ICONS = {
        door = "&#x1F6AA;", star = "&#x2B50;", id = "&#x1F194;", chart = "&#x1F4C8;",
        sparkles = "&#x2728;", cash = "&#x1F4B5;", bank = "&#x1F3E6;", briefcase = "&#x1F4BC;",
        phone = "&#x1F4F1;", pickaxe = "&#x26CF;&#xFE0F;", gender = "&#x1F6BB;", heart = "&#x2764;&#xFE0F;",
        scales = "&#x2696;&#xFE0F;", family = "&#x1F465;", building = "&#x1F3E2;", tie = "&#x1F454;",
        warn = "&#x26A0;&#xFE0F;", gem = "&#x1F48E;", inbox = "&#x1F4E5;", card = "&#x1F4B3;",
        palm = "&#x1F334;", coin = "&#x1FA99;", euro = "&#x1F4B6;", shield = "&#x1F6E1;&#xFE0F;",
        regen = "&#x1F496;", swords = "&#x2694;&#xFE0F;", clover = "&#x1F340;", blood = "&#x1FA78;",
        vest = "&#x1F9BA;", dizzy = "&#x1F4AB;", woozy = "&#x1F974;", run = "&#x1F3C3;",
        mirror = "&#x1FA9E;", brick = "&#x1F9F1;", gun = "&#x1F52B;", target = "&#x1F3AF;",
        apple = "&#x1F34E;", hotel = "&#x1F3E8;", key = "&#x1F511;", van = "&#x1F690;",
        doc = "&#x1F4DD;", moneybag = "&#x1F4B0;", stats = "&#x1F4CA;", house = "&#x1F3E0;",
        user = "&#x1F464;"
    }

    local heroName = valueOrDash(parsed.name ~= "" and parsed.name or "Персонаж")

    local accountStateFormatted = formatAzValue(parsed.accountState)
    local cashSasFormatted = formatMoneyValue(parsed.cashSas)
    local cashVcsFormatted = formatMoneyValue(parsed.cashVcs)
    local bankFormatted = formatMoneyValue(parsed.bank)
    local depositFormatted = formatMoneyValue(parsed.moneyDay)
    local acc1Formatted = formatMoneyValue(parsed.acc1)
    local acc2Formatted = formatMoneyValue(parsed.acc2)
    local acc3Formatted = formatMoneyValue(parsed.acc3)
    local acc4Formatted = formatMoneyValue(parsed.acc4)
    local acc5Formatted = formatMoneyValue(parsed.acc5)
    local acc6Formatted = formatMoneyValue(parsed.acc6)
    local btcFormatted = formatPlainValue(parsed.btc)
    local euroFormatted = formatPlainValue(parsed.euro)
    local totalAccountsFormatted = parsed.totalAccountsAmount
    local fireRateFormatted = cleanFireRateValue(parsed.fireRate)
    local trailerFormatted = cleanTrailerValue(parsed.trailer)

    local topChips = ""
    topChips = topChips .. renderTopChip(ICONS.door, valueOrDash(parsed.authDate))
    if hasValue(parsed.x4Payday) then
        topChips = topChips .. renderTopChip(ICONS.star, "X4: " .. formatPaydayChipValue(parsed.x4Payday))
    end
    if hasValue(parsed.x3Payday) then
        topChips = topChips .. renderTopChip(ICONS.star, "X3: " .. formatPaydayChipValue(parsed.x3Payday))
    end
    topChips = topChips .. renderTopChip(ICONS.id, valueOrDash(parsed.accountNumber), "ml-chip-id", "ID")
    topChips = topChips .. renderTopChip(ICONS.chart, "Уровень: " .. valueOrDash(parsed.level))
    topChips = topChips .. renderTopChip(ICONS.sparkles, "EXP: " .. valueOrDash(parsed.respect))

    local hero = [[
        <div class="ml-hero">
            <div class="ml-hero-kicker">ПЕРСОНАЖ</div>
            <div class="ml-hero-name"><span style="margin-right:8px;">]] .. ICONS.user .. [[</span>]] .. htmlEscape(heroName) .. [[</div>
            <div class="ml-chip-wrap">]] .. topChips .. [[</div>
        </div>
    ]]

    local metrics = ""
    metrics = metrics .. renderMetric("metric_cash", ICONS.cash, "Наличные SA$", cashSasFormatted, "Основные деньги на руках", "accent-green")
    metrics = metrics .. renderMetric("metric_bank", ICONS.bank, "Банк", bankFormatted, "Основной банковский счёт", "accent-blue")
    metrics = metrics .. renderMetric("metric_accounts", ICONS.briefcase, "Все счета", totalAccountsFormatted, "Сумма личных счетов 1–6", "")

    local metricsContainer = [[
        <div class="ml-metrics" data-container="metrics_container">
            ]] .. metrics .. [[
        </div>
    ]]

    local leftMain = ""
    leftMain = leftMain .. renderRow("row_phone", ICONS.phone, "Номер телефона", parsed.phone)
    leftMain = leftMain .. renderRow("row_job", ICONS.pickaxe, "Работа", parsed.job)
    leftMain = leftMain .. renderRow("row_gender", ICONS.gender, "Пол", parsed.gender)
    leftMain = leftMain .. renderRow("row_health", ICONS.heart, "Здоровье", parsed.health)
    leftMain = leftMain .. renderRow("row_law", ICONS.scales, "Законопослушность", parsed.lawfulness)
    leftMain = leftMain .. renderRow("row_family", ICONS.family, "Семья", parsed.family)
    leftMain = leftMain .. renderRow("row_org", ICONS.building, "Организация", parsed.org)
    leftMain = leftMain .. renderRow("row_pos", ICONS.tie, "Должность", ((parsed.position or ""):gsub("^%s*%[([^%]]+)%]%s*", "%1 "):gsub("%s*%([^)]*%)%s*$", "")):gsub("%s+$", ""))
    leftMain = leftMain .. renderRow("row_warn", ICONS.warn, "Предупреждения", parsed.warnings)

    local leftFinance = ""
    leftFinance = leftFinance .. renderRowWithClass("row_az", "", "AZ-Coins", accountStateFormatted, "gold", "gold")
    leftFinance = leftFinance .. renderRow("row_dep", ICONS.inbox, "Депозит", depositFormatted)

    if hasValue(parsed.acc1) then leftFinance = leftFinance .. renderRow("row_acc1", ICONS.card, "Счёт №1", acc1Formatted) end
    if hasValue(parsed.acc2) then leftFinance = leftFinance .. renderRow("row_acc2", ICONS.card, "Счёт №2", acc2Formatted) end
    if hasValue(parsed.acc3) then leftFinance = leftFinance .. renderRow("row_acc3", ICONS.card, "Счёт №3", acc3Formatted) end
    if hasValue(parsed.acc4) then leftFinance = leftFinance .. renderRow("row_acc4", ICONS.card, "Счёт №4", acc4Formatted) end
    if hasValue(parsed.acc5) then leftFinance = leftFinance .. renderRow("row_acc5", ICONS.card, "Счёт №5", acc5Formatted) end
    if hasValue(parsed.acc6) then leftFinance = leftFinance .. renderRow("row_acc6", ICONS.card, "Счёт №6", acc6Formatted) end

    if hasValue(parsed.cashVcs) then leftFinance = leftFinance .. renderRow("row_vcs", ICONS.palm, "Наличные VC$", cashVcsFormatted) end
    if hasValue(parsed.btc) then leftFinance = leftFinance .. renderRow("row_btc", ICONS.coin, "BTC", btcFormatted) end
    if hasValue(parsed.euro) then leftFinance = leftFinance .. renderRow("row_euro", ICONS.euro, "Евро", euroFormatted) end

    local rightStats = ""
    rightStats = rightStats .. renderStatChip("stat_prot", ICONS.shield, "Защита", parsed.protection)
    rightStats = rightStats .. renderStatChip("stat_regen", ICONS.regen, "Регенерация", parsed.regen)
    rightStats = rightStats .. renderStatChip("stat_dmg", ICONS.swords, "Урон", parsed.damage)
    rightStats = rightStats .. renderStatChip("stat_luck", ICONS.clover, "Удача", parsed.luck)
    rightStats = rightStats .. renderStatChip("stat_hp", ICONS.blood, "Макс. HP", parsed.maxHp)
    rightStats = rightStats .. renderStatChip("stat_armor", ICONS.vest, "Макс. броня", parsed.maxArmor)
    rightStats = rightStats .. renderStatChip("stat_stun", ICONS.dizzy, "Шанс оглушения", parsed.stunChance)
    rightStats = rightStats .. renderStatChip("stat_bleed", ICONS.woozy, "Шанс опьянения", parsed.bleedChance)
    rightStats = rightStats .. renderStatChip("stat_dodge", ICONS.run, "Избежать оглушения", parsed.dodgeChance)
    rightStats = rightStats .. renderStatChip("stat_refl", ICONS.mirror, "Отражение урона", parsed.reflectDamage)
    rightStats = rightStats .. renderStatChip("stat_block", ICONS.brick, "Блокировка урона", parsed.blockDamage)
    rightStats = rightStats .. renderStatChip("stat_fire", ICONS.gun, "Скорострельность", fireRateFormatted)
    rightStats = rightStats .. renderStatChip("stat_rec", ICONS.target, "Отдача", parsed.recoil)
    rightStats = rightStats .. renderStatChip("stat_fruit", ICONS.apple, "Плод", parsed.fruitStun)

    local propertyBlock = ""
    propertyBlock = propertyBlock .. renderRow("prop_hotel", ICONS.hotel, "Отель", parsed.hotel)
    propertyBlock = propertyBlock .. renderRow("prop_room", ICONS.key, "Номер в отеле", parsed.hotelRoom)
    propertyBlock = propertyBlock .. renderRow("prop_trailer", ICONS.van, "Трейлер", trailerFormatted)

    local leftColumn = [[
        <div class="ml-col">
            <div class="ml-stack">
                ]] .. hero .. [[
                ]] .. metricsContainer .. [[
                <div class="ml-grid-two">
                    ]] .. renderSection("main_container", ICONS.doc, "Основные данные", "ПЕРСОНАЖ", leftMain) .. [[
                    ]] .. renderSection("finance_container", ICONS.moneybag, "Финансы", "СЧЕТА И ВАЛЮТЫ", leftFinance) .. [[
                </div>
            </div>
        </div>
    ]]

    local rightColumn = [[
        <div class="ml-col">
            <div class="ml-stack">
                ]] .. renderSection("stats_container", ICONS.stats, "Характеристики", "БОЕВЫЕ И ПАССИВНЫЕ БОНУСЫ", rightStats, "ml-chip-grid") .. [[
                ]] .. renderSection("prop_container", ICONS.house, "Имущество", "ОТЕЛЬ И ТРЕЙЛЕР", propertyBlock) .. [[
            </div>
        </div>
    ]]

    return leftColumn .. rightColumn
end

local function buildLoadingHtml(text)
    local msg = valueOrDash(text)
    return [[
        <div class="ml-col">
            <div class="ml-empty">]] .. htmlEscape(msg) .. [[</div>
        </div>
        <div class="ml-col"></div>
    ]]
end

local function buildTextFromCollector()
    local rowsMap = {}
    local rowKeys = {}

    for _, item in pairs(tdCollector) do
        local yKey = math.floor((item.y or 0) + 0.5)
        if not rowsMap[yKey] then
            rowsMap[yKey] = {}
            rowKeys[#rowKeys + 1] = yKey
        end
        rowsMap[yKey][#rowsMap[yKey] + 1] = item
    end

    table.sort(rowKeys)

    local lines = {}
    local seen = {}

    for _, yKey in ipairs(rowKeys) do
        local row = rowsMap[yKey]
        table.sort(row, function(a, b)
            return (a.x or 0) < (b.x or 0)
        end)

        local parts = {}
        for _, item in ipairs(row) do
            local t = trim(item.text)
            if t ~= "" then
                parts[#parts + 1] = t
            end
        end

        local line = table.concat(parts, " ")
        line = line:gsub(" +", " ")
        line = trim(line)

        if line ~= ""
        and line ~= "Предметы"
        and line ~= "Закрыть"
        and not seen[line] then
            seen[line] = true
            lines[#lines + 1] = line
        end
    end

    return table.concat(lines, "\n")
end

local function renderParsedStats(rawText)
    logLine("INFO", "renderParsedStats: rawLen=" .. tostring(#tostring(rawText or "")))
    local parsed = parseStats(rawText)
    local html = buildStatsHtml(parsed)
    local status = "Обновлено: " .. os.date("%H:%M:%S")
    setWindowContent(html, status)
end

local function finalizeTextdrawCapture()
    local collectedCount = countTableEntries(tdCollector)
    local raw = buildTextFromCollector()
    raw = normalizeStatsText(raw)

    logLine("INFO", "finalizeTextdrawCapture: items=" .. tostring(collectedCount) .. ", rawLen=" .. tostring(#raw))

    if raw ~= "" then
        lastRawStats = raw
        renderParsedStats(raw)
    end

    waitingStats = false
    clearCollector()
end

local function cacheStatsIfLooksValid(raw)
    local text = normalizeStatsText(stripColorTags(raw))
    if text == "" then
        return false
    end

    if text:find("Номер аккаунта", 1, true)
    or text:find("Имя:", 1, true)
    or text:find("Номер телефона", 1, true)
    or text:find("Работа:", 1, true)
    or text:find("Уровень розыска:", 1, true)
    or text:find("Защита:", 1, true)
    or text:find("Деньги на депозит", 1, true)
    or text:find("Деньги на депозите", 1, true)
    or text:find("AZ%-Coins", 1, true)
    or text:find("AZ Coins", 1, true) then
        logLine("INFO", "cacheStatsIfLooksValid: accepted, rawLen=" .. tostring(#text))
        lastRawStats = text
        if cefVisible then
            renderParsedStats(text)
        end
        return true
    end

    return false
end

local function requestStats()
    if not cefVisible then
        logLine("INFO", "requestStats skipped: window hidden")
        return
    end

    waitingStats = true
    lastRequestTime = now()
    lastTextdrawTime = now()
    clearCollector()

    logLine("INFO", "requestStats: /stats sent")
    setWindowStatus("Обновление статистики...")
    sampSendChat("/stats")
end

local function extractTextdrawPos(data)
    local x, y = 0, 0

    if type(data) == "table" then
        if type(data.position) == "table" then
            x = tonumber(data.position.x) or tonumber(data.position[1]) or x
            y = tonumber(data.position.y) or tonumber(data.position[2]) or y
        end

        if type(data.pos) == "table" then
            x = tonumber(data.pos.x) or tonumber(data.pos[1]) or x
            y = tonumber(data.pos.y) or tonumber(data.pos[2]) or y
        end

        x = tonumber(data.x) or x
        y = tonumber(data.y) or y
    end

    return x, y
end

local function openCefWindow()
    logLine("INFO", "openCefWindow: hasCachedStats=" .. tostring(lastRawStats ~= ""))
    cefVisible = true
    ensureWindow()

    if lastRawStats ~= "" then
        renderParsedStats(lastRawStats)
    else
        setWindowContent(buildLoadingHtml("Загрузка статистики..."), "Открытие окна...")
    end

    requestStats()
    cursor(true)
end

local function closeCefWindow()
    logLine("INFO", "closeCefWindow")
    cefVisible = false
    waitingStats = false
    clearCollector()
    destroyWindow()
    cursor(false)
end

addEventHandler("onWindowMessage", function (msg, wp, lp)
    if cefVisible and wp == VK_ESCAPE then
        if msg == 0x100 then
            consumeWindowMessage(true, false)
        elseif msg == 0x101 then
            closeCefWindow()
        end
    end
end)

local function handleShowDialog(dialogId, style, title, button1, button2, text)
    local tTitle = tostring(title or "")
    local tText = tostring(text or "")

    if tTitle:find("стат", 1, true)
    or tTitle:find("Стат", 1, true)
    or looksLikeStatsPiece(tText) then
        logLine("INFO", "onShowDialog stats candidate: title=" .. shortLogText(tTitle, 80) .. ", textLen=" .. tostring(#tText))
        if cacheStatsIfLooksValid(tText) then
            if waitingStats then
                logLine("INFO", "onShowDialog: stats accepted while waiting")
                waitingStats = false
                clearCollector()
                return false
            end
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    local results = {xpcall(function()
        return handleShowDialog(dialogId, style, title, button1, button2, text)
    end, function(e)
        return buildTraceback(e, 2)
    end)}

    local ok = table.remove(results, 1)
    if not ok then
        logLine("ERROR", "sampev.onShowDialog failed\n" .. safeToString(results[1]))
        error(results[1])
    end

    return unpack(results)
end

local function handleShowTextDraw(id, data)
    local rawText = tostring((data and data.text) or "")
    local cleanText = normalizeStatsText(stripColorTags(rawText))

    if cleanText == "" or looksLikeTexture(cleanText) then
        return
    end

    local x, y = extractTextdrawPos(data)
    local matched = looksLikeStatsPiece(cleanText)

    if matched and not captureStarted then
        logLine("INFO", "onShowTextDraw: capture started at id=" .. tostring(id) .. ", pos=(" .. tostring(x) .. "," .. tostring(y) .. "), text=" .. shortLogText(cleanText, 100))
        captureStarted = true
    elseif matched then
        captureStarted = true
    end

    local inStatsZone = x >= 0 and x <= 700 and y >= 0 and y <= 1100

    if (waitingStats or cefVisible) and (matched or (captureStarted and inStatsZone)) then
        tdCollector[id] = {
            id = id,
            x = x,
            y = y,
            text = cleanText
        }

        lastTextdrawTime = now()

        if waitingStats then
            return false
        end
    end
end

function sampev.onShowTextDraw(id, data)
    local results = {xpcall(function()
        return handleShowTextDraw(id, data)
    end, function(e)
        return buildTraceback(e, 2)
    end)}

    local ok = table.remove(results, 1)
    if not ok then
        logLine("ERROR", "sampev.onShowTextDraw failed\n" .. safeToString(results[1]))
        error(results[1])
    end

    return unpack(results)
end

function main()
    local ok, err = xpcall(function()
        removeExistingLogFile()
        logSection("session start")
        logLine("INFO", "scriptDir=" .. getScriptDirectory())
        logLine("INFO", "uiStatePath=" .. getUiStatePath())
        logLine("INFO", "logPath=" .. getLogPath())
        repeat wait(0) until isSampAvailable()
        logLine("INFO", "SAMP is available")
        startStateServer()

        sampRegisterChatCommand("cef", function()
            logLine("INFO", "chat command /cef")
            if cefVisible then
                closeCefWindow()
                return
            end

            openCefWindow()
        end)

        sampAddChatMessage("{66CCFF}[CEF] Загружено. Открыть статистику: /cef или F3", -1)

        while true do
            wait(0)

            if not sampIsChatInputActive() and not sampIsDialogActive() then
                if isKeyJustPressed(vkeys.VK_F3) then
                    logLine("INFO", "F3 pressed")
                    if cefVisible then
                        closeCefWindow()
                    else
                        openCefWindow()
                    end
                end
            end

            if waitingStats then
                if next(tdCollector) ~= nil and (now() - lastTextdrawTime) >= TD_COLLECT_DELAY then
                    finalizeTextdrawCapture()
                elseif (now() - lastRequestTime) >= REQUEST_TIMEOUT then
                    logLine("WARN", "stats request timeout: cached=" .. tostring(lastRawStats ~= "") .. ", cefVisible=" .. tostring(cefVisible))
                    waitingStats = false
                    clearCollector()

                    if lastRawStats ~= "" and cefVisible then
                        renderParsedStats(lastRawStats)
                    elseif cefVisible then
                        setWindowContent(
                            buildLoadingHtml("Не удалось поймать текст /stats. Возможно, на твоём сервере структура окна отличается."),
                            "Не удалось обновить"
                        )
                    end
                end
            end
        end
    end, function(e)
        return buildTraceback(e, 2)
    end)

    if not ok then
        logLine("FATAL", safeToString(err))
        error(err)
    end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        logSection("session terminate")
        logLine("INFO", "quitGame=" .. tostring(quitGame))
        destroyWindow()
        stopStateServer()
    end
end