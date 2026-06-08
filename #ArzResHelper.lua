script_name("ResHelper")
script_authors("Ryder")
script_description("Helper for Farm & Mine Resources")
script_version("1.2.1")
script_properties("work-in-progress")
setver = 1

require "lib.sampfuncs"
require "lib.moonloader"
local mem = require "memory"
local vkeys = require "vkeys"
local requests = require("lib.requests")
local effil = require("effil")
local encoding = require "encoding"
local wm = require 'lib.windows.message'
encoding.default = "CP1251"
local u8 = encoding.UTF8
local dlstatus = require("moonloader").download_status
local SCRIPT_COLOR = 0xFF1AE591
local COLOR_MAIN = "{1AE591}"
local COLOR_SECONDARY = "{E5911A}"
local COLOR_WHITE = "{FFFFFF}"
local SCRIPT_PREFIX = COLOR_WHITE.."["..COLOR_MAIN.."ResHelper"..COLOR_WHITE.."]: "
local newversion = ""
local newdate = ""
local cachedTodayStats = nil
local cachedTodayTime = 0
local cachedWeekStats = nil
local cachedWeekTime = 0
local ignoreInventoryUntil = 0
local scanSlotCounts = {}
local scanSlots = {}
local logoArz = nil
local LOG_AGGREGATION_INTERVAL = 10 
local editingBindIdx = nil
local itemMarketLog = {}
local itemMarketTodayIncome = 0
local itemMarketWeekIncome = 0
local cachedIMWeekTime = 0
local datesExpanded = {}
local tgConfig = {
    enabled = false,
    botToken = "",
    chatId = "",
    itemMarketEnabled = true,
    dailyReportEnabled = false,
    weeklyReportEnabled = false,
    useReserveServer = true,
}

local sampfuncsNot = [[
 Не обнаружен файл SAMPFUNCS.asi в папке игры, вследствие чего
скрипту не удалось запуститься.

		Для решения проблемы:
1. Закройте игру;
2. Зайдите во вкладку "Моды" в лаунчере Аризоны.
Найдите во вкладке "Моды" установщик "Moonloader" и нажмите кнопку "Установить".
После завершения установки вновь запустите игру. Проблема исчезнет.

По проблемам заводите issue на GitHub. Ссылка есть на вкладке: О скрипте

Игра была свернута, поэтому можете продолжить играть. 
]]

local errorText = [[
		  Внимание! 
Не обнаружены некоторые важные файлы для работы скрипта.
В следствии чего, скрипт перестал работать.
	Список необнаруженных файлов:
		%s

		Для решения проблемы:
1. Закройте игру;
2. Зайдите во вкладку "Моды" в лаунчере Аризоны.
Найдите во вкладке "Моды" установщик "Moonloader" и нажмите кнопку "Установить".
После завершения установки вновь запустите игру. Проблема исчезнет.

По проблемам заводите issue на GitHub. Ссылка есть на вкладке: О скрипте

Игра была свернута, поэтому можете продолжить играть. 
]]

local files = {
"/lib/imgui.lua",
"/lib/samp/events.lua",
"/lib/rkeysFD.lua",
"/lib/faIcons.lua",
"/lib/crc32ffi.lua",
"/lib/bitex.lua",
"/lib/MoonImGui.dll",
"/lib/matrix3x3.lua"
}

if doesFileExist(getWorkingDirectory().."/lib/rkeysFD.lua") then
	print("{82E28C}Чтение библиотеки rkeysFD...")
	local f = io.open(getWorkingDirectory().."/lib/rkeysFD.lua")
	f:close()
else
	print("{F54A4A}Ошибка. Отсутствует библиотека rkeysFD {82E28C}Создание библиотеки rkeysFD...")
	local textrkeys = [[
local vkeys = require 'vkeys'

vkeys.key_names[vkeys.VK_LMENU] = "LAlt"
vkeys.key_names[vkeys.VK_RMENU] = "RAlt"
vkeys.key_names[vkeys.VK_LSHIFT] = "LShift"
vkeys.key_names[vkeys.VK_RSHIFT] = "RShift"
vkeys.key_names[vkeys.VK_LCONTROL] = "LCtrl"
vkeys.key_names[vkeys.VK_RCONTROL] = "RCtrl"

local tHotKey = {}
local tKeyList = {}
local tKeysCheck = {}
local iCountCheck = 0
local tBlockKeys = {[vkeys.VK_LMENU] = true, [vkeys.VK_RMENU] = true, [vkeys.VK_RSHIFT] = true, [vkeys.VK_LSHIFT] = true, [vkeys.VK_LCONTROL] = true, [vkeys.VK_RCONTROL] = true}
local tModKeys = {[vkeys.VK_MENU] = true, [vkeys.VK_SHIFT] = true, [vkeys.VK_CONTROL] = true}
local tBlockNext = {}
local module = {}
module._VERSION = "1.0.7"
module._MODKEYS = tModKeys
module._LOCKKEYS = false

local function getKeyNum(id)
   for k, v in pairs(tKeyList) do
      if v == id then
         return k
      end
   end
   return 0
end

function module.blockNextHotKey(keys)
   local bool = false
   if not module.isBlockedHotKey(keys) then
      tBlockNext[#tBlockNext + 1] = keys
      bool = true
   end
   return bool
end

function module.isHotKeyHotKey(keys, keys2)
   local bool
   for k, v in pairs(keys) do
      local lBool = true
      for i = 1, #keys2 do
         if v ~= keys2[i] then
            lBool = false
            break
         end
      end
      if lBool then
         bool = true
         break
      end
   end
   return bool
end

function module.isBlockedHotKey(keys)
   local bool, hkId = false, -1
   for k, v in pairs(tBlockNext) do
      if module.isHotKeyHotKey(keys, v) then
         bool = true
         hkId = k
         break
      end
   end
   return bool, hkId
end

function module.unBlockNextHotKey(keys)
   local result = false
   local count = 0
   while module.isBlockedHotKey(keys) do
      local _, id = module.isBlockedHotKey(keys)
      tHotKey[id] = nil
      result = true
      count = count + 1
   end
   local id = 1
   for k, v in pairs(tBlockNext) do
      tBlockNext[id] = v
      id = id + 1
   end
   return result, count
end

function module.isKeyModified(id)
   return (tModKeys[id] or false) or (tBlockKeys[id] or false)
end

function module.isModifiedDown()
   local bool = false
   for k, v in pairs(tModKeys) do
      if isKeyDown(k) then
         bool = true
         break
      end
   end
   return bool
end

lua_thread.create(function ()
   while true do
      wait(0)
      local tDownKeys = module.getCurrentHotKey()
      for k, v in pairs(tHotKey) do
         if #v.keys > 0 then
            local bool = true
            for i = 1, #v.keys do
               if i ~= #v.keys and (getKeyNum(v.keys[i]) > getKeyNum(v.keys[i + 1]) or getKeyNum(v.keys[i]) == 0) then
                  bool = false
                  break
               elseif i == #v.keys and (v.pressed and not wasKeyPressed(v.keys[i]) or not v.pressed and not isKeyDown(v.keys[i])) or (#v.keys == 1 and module.isModifiedDown()) then
                  bool = false
                  break
               end
            end
            if bool and ((module.onHotKey and module.onHotKey(k, v.keys) ~= false) or module.onHotKey == nil) then
               local result, id = module.isBlockedHotKey(v.keys)
               if not result then
                  v.callback(k, v.keys)
               else
                  tBlockNext[id] = nil
               end
            end
         end
      end
   end
end)

function module.registerHotKey(keys, pressed, callback)
   tHotKey[#tHotKey + 1] = {keys = keys, pressed = pressed, callback = callback}
   return true, #tHotKey
end

function module.getAllHotKey()
   return tHotKey
end

function module.unRegisterHotKey(keys)
   local result = false
   local count = 0
   while module.isHotKeyDefined(keys) do
      local _, id = module.isHotKeyDefined(keys)
      tHotKey[id] = nil
      result = true
      count = count + 1
   end
   local id = 1
   local tNewHotKey = {}
   for k, v in pairs(tHotKey) do
      tNewHotKey[id] = v
      id = id + 1
   end
   tHotKey = tNewHotKey
   return result, count
end

function module.isHotKeyDefined(keys)
   local bool, hkId = false, -1
   for k, v in pairs(tHotKey) do
      if module.isHotKeyHotKey(keys, v.keys) then
         bool = true
         hkId = k
         break
      end
   end
   return bool, hkId
end

function module.getKeysName(keys)
   local tKeysName = {}
   for k, v in ipairs(keys) do
      tKeysName[k] = vkeys.id_to_name(v)
   end
   return tKeysName
end

function module.getCurrentHotKey(type)
   local type = type or 0
   local tCurKeys = {}
   for k, v in pairs(vkeys) do
      if tBlockKeys[v] == nil then
         local num, down = getKeyNum(v), isKeyDown(v)
         if down and num == 0 then
            tKeyList[#tKeyList + 1] = v
         elseif num > 0 and not down then
            tKeyList[num] = nil
         end
      end
   end
   local i = 1
   for k, v in pairs(tKeyList) do
      tCurKeys[i] = type == 0 and v or vkeys.id_to_name(v)
      i = i + 1
   end
   return tCurKeys
end

return module
]]
	local f = io.open(getWorkingDirectory().."/lib/rkeysFD.lua", "w")
	f:write(textrkeys)
	f:close()			
end

local nofiles = {}
for i,v in ipairs(files) do
	if not doesFileExist(getWorkingDirectory()..v) then
		table.insert(nofiles, v)
	end
end

local ffi = require 'ffi'
ffi.cdef [[
		typedef int BOOL;
		typedef unsigned long HANDLE;
		typedef HANDLE HWND;
		typedef const char* LPCSTR;
		typedef unsigned UINT;
		
        void* __stdcall ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show_cmd);
        uint32_t __stdcall CoInitializeEx(void*, uint32_t);
		
		BOOL ShowWindow(HWND hWnd, int  nCmdShow);
		HWND GetActiveWindow();
		
		int MessageBoxA(
		  HWND   hWnd,
		  LPCSTR lpText,
		  LPCSTR lpCaption,
		  UINT   uType
		);
		
		short GetKeyState(int nVirtKey);
		bool GetKeyboardLayoutNameA(char* pwszKLID);
		int GetLocaleInfoA(int Locale, int LCType, char* lpLCData, int cchData);
  ]]

local shell32 = ffi.load 'Shell32'
local ole32 = ffi.load 'Ole32'
ole32.CoInitializeEx(nil, 2 + 4)

if not doesFileExist(getGameDirectory().."/SAMPFUNCS.asi") then
	ffi.C.ShowWindow(ffi.C.GetActiveWindow(), 6)
	ffi.C.MessageBoxA(0, sampfuncsNot, "ResHelper", 0x00000030 + 0x00010000) 
end
if #nofiles > 0 then
	ffi.C.ShowWindow(ffi.C.GetActiveWindow(), 6)
	ffi.C.MessageBoxA(0, errorText:format(table.concat(nofiles, "\n\t\t")), "ResHelper", 0x00000030 + 0x00010000) 
end

local res, hook = pcall(require, 'lib.samp.events')
assert(res, "Библиотека SAMP Event не найдена")
local res, imgui = pcall(require, "imgui")
assert(res, "Библиотека Imgui не найдена")
local tgTokenInput = imgui.ImBuffer(100)
local tgChatIdInput = imgui.ImBuffer(50)
local res, fa = pcall(require, 'faIcons')
assert(res, "Библиотека faIcons не найдена")
local res, rkeys = pcall(require, 'rkeysFD')
assert(res, "Библиотека Rkeys не найдена")

local imadd = nil
if doesFileExist(getWorkingDirectory() .. "/lib/imgui_addons.lua") then
    imadd = require "imgui_addons"
else

    imadd = {}
    function imadd.HotKey(label, bindTable, lastKeys, width)
        imgui.Text(u8("Клавиша: Н/Д (нет imgui_addons)"))
        return false
    end
end

vkeys.key_names[vkeys.VK_RBUTTON] = "RBut"
vkeys.key_names[vkeys.VK_XBUTTON1] = "XBut1"
vkeys.key_names[vkeys.VK_XBUTTON2] = 'XBut2'
vkeys.key_names[vkeys.VK_NUMPAD1] = 'Num 1'
vkeys.key_names[vkeys.VK_NUMPAD2] = 'Num 2'
vkeys.key_names[vkeys.VK_NUMPAD3] = 'Num 3'
vkeys.key_names[vkeys.VK_NUMPAD4] = 'Num 4'
vkeys.key_names[vkeys.VK_NUMPAD5] = 'Num 5'
vkeys.key_names[vkeys.VK_NUMPAD6] = 'Num 6'
vkeys.key_names[vkeys.VK_NUMPAD7] = 'Num 7'
vkeys.key_names[vkeys.VK_NUMPAD8] = 'Num 8'
vkeys.key_names[vkeys.VK_NUMPAD9] = 'Num 9'
vkeys.key_names[vkeys.VK_MULTIPLY] = 'Num *'
vkeys.key_names[vkeys.VK_ADD] = 'Num +'
vkeys.key_names[vkeys.VK_SEPARATOR] = 'Separator'
vkeys.key_names[vkeys.VK_SUBTRACT] = 'Num -'
vkeys.key_names[vkeys.VK_DECIMAL] = 'Num .Del'
vkeys.key_names[vkeys.VK_DIVIDE] = 'Num /'
vkeys.key_names[vkeys.VK_LEFT] = 'Ar.Left'
vkeys.key_names[vkeys.VK_UP] = 'Ar.Up'
vkeys.key_names[vkeys.VK_RIGHT] = 'Ar.Right'
vkeys.key_names[vkeys.VK_DOWN] = 'Ar.Down'

--- Файловая система
local deck = getFolderPath(0)
local doc = getFolderPath(5)
local dirml = getWorkingDirectory()
local dirGame = getGameDirectory()
local scr = thisScript()

local mainWin = imgui.ImBool(false)
local select_menu = {true, false, false, false, false, false, false, false, false, false, false}

-- ====== КОНФИГУРАЦИЯ БИНДЕРА ======
local binderDir = dirml .. "/ResHelper/binder/"
if not doesDirectoryExist(binderDir) then
    createDirectory(binderDir)
end
local binderDbPath = binderDir .. "binds.json"

local bindDatabase = { binds = {} }
if doesFileExist(binderDbPath) then
    local f = io.open(binderDbPath, "r")
    if f then
        bindDatabase = decodeJson(f:read("*a")) or { binds = {} }
        f:close()
    end
end

-- ImGui элементы для биндера
local editBindName = imgui.ImBuffer(30)
local editBindMultiline = imgui.ImBuffer(17000)
local addBindName = imgui.ImBuffer(30)
local addBindMultiline = imgui.ImBuffer(17000)
local lastKeys = {}

function saveBinderDatabase()
    local f = io.open(binderDbPath, "w")
    if f then
        f:write(encodeJson(bindDatabase))
        f:close()
    end
end

-- ====== Функция биндера ======
function binderStart()
    for key, val in pairs(bindDatabase.binds) do
        if val.v and #val.v > 0 then
            if isKeysDown(val.v) then
                for _, valText in ipairs(val.text) do
                    if tostring(valText):len() > 0 then
                        if valText:find("%{WAIT%-.*%}") or valText:find("%{wait%-.*%}") then
                            local timer = valText:match("%{WAIT%-(.*)%}") or valText:match("%{wait%-(.*)%}")
                            wait(timer * 1000)
                        else
                            local input = valText:match("(.)%{INPUT%}$") or valText:match("(.)%{input%}$")
                            if input then
                                sampSetChatInputText(replaceText(valText))
                                sampSetChatInputEnabled(true)
                            else
                                local scriptCmd = valText:match("(.)%{CMD%}$") or valText:match("(.)%{cmd%}$")
                                if scriptCmd then
                                    sampProcessChatInput(replaceText(valText))
                                else
                                    sampSendChat(replaceText(valText))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function replaceText(text)
    if text ~= nil then
        text = text:gsub("%{INPUT%}$", "")
        text = text:gsub("%{input%}$", "")
        text = text:gsub("%{CMD%}$", "")
        text = text:gsub("%{cmd%}$", "")
        local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
        if result then
            text = text:gsub("%{MY_NAME%}", sampGetPlayerNickname(id))
            text = text:gsub("%{my_name%}", sampGetPlayerNickname(id))
            text = text:gsub("%{MY_ID%}", tostring(id))
            text = text:gsub("%{my_id%}", tostring(id))
        end
    end
    return text
end

function isKeysDown(keylist)
    local tKeys = keylist
    local bool = false
    local key = #tKeys < 2 and tonumber(tKeys[1]) or tonumber(tKeys[#tKeys])
    if #tKeys < 2 then
        if not isKeyDown(VK_RMENU) and not isKeyDown(VK_LMENU) and not isKeyDown(VK_LSHIFT) and not isKeyDown(VK_RSHIFT) and not isKeyDown(VK_LCONTROL) and not isKeyDown(VK_RCONTROL) then
            if wasKeyPressed(key) then
                bool = true
            end
        end
    else
        if isKeyDown(tKeys[1])  then
            if isKeyDown(tKeys[2]) then
                if tKeys[3] ~= nil then
                    if isKeyDown(tKeys[3]) then
                        if tKeys[4] ~= nil then
                            if isKeyDown(tKeys[4]) then
                                if tKeys[5] ~= nil then
                                    if isKeyDown(tKeys[5]) then
                                        if wasKeyPressed(key) then
                                            bool = true
                                        end
                                    end
                                else
                                    if wasKeyPressed(key) then
                                        bool = true
                                    end
                                end
                            end
                        else
                            if wasKeyPressed(key) then
                                bool = true
                            end
                        end
                    end
                else
                    if wasKeyPressed(key) then
                        bool = true
                    end
                end
            end
        end
    end
    return bool
end

-- ====== КОНФИГУРАЦИЯ РЕСУРСОВ ======
local configDir = getWorkingDirectory() .. "\\config\\"
local configPath = configDir .. "united_resources.ini"
local farmGoalsProgressPath = configDir .. "farm_goals_progress.json"
local mineGoalsProgressPath = configDir .. "mine_goals_progress.json"
local soundsDir = getWorkingDirectory() .. "\\resource\\farm\\"
local farmPricesPath = configDir .. "farm_price.ini"
local minePricesPath = configDir .. "mine_price.ini"
local farmBasePath = configDir .. "farm_base.json"           
local mineBasePath = configDir .. "mine_base.json"        
local sawmillBasePath = configDir .. "sawmill_base.json"           
local sawmillPricesPath = configDir .. "sawmill_price.ini"
local sawmillGoalsProgressPath = configDir .. "sawmill_goals_progress.json"
local sawmillGoalsConfigPath = configDir .. "sawmill_goals.json" 
local totalIncomeGoalPath = configDir .. "total_income_goal.json"  
local tgReportStatePath = configDir .. "tg_report_state.json"
lbStatePath = configDir .. "lb_state.json"
pricesStatePath = configDir .. "prices_state.json"
leaderboardConfigPath = configDir .. "leaderboard_config.json"
LEADERBOARD_URL = "https://script.google.com/macros/s/AKfycbymtP5e8lhxgIGviOX0W2nZ3fSmFYWCceD4m5k1wqQkvrE8srrO3eQx9jL53EeO3ORO/exec"
LB_MODE_RESOURCES = {
    Farm = {"flax", "cotton", "rare_tkan", "water", "dye", "coal"},
    Mine = {"stone", "metal", "bronze", "silver", "gold", "diamond", "tkan", "splav", "materia", "azbox"},
    Sawmill = {"firewood", "quality_wood", "rare_box"}
}
leaderboardCache = {
    Income = {Daily = {}, Weekly = {}, Total = {}},
    Farm = {Daily = {}, Weekly = {}, Total = {}},
    Mine = {Daily = {}, Weekly = {}, Total = {}},
    Sawmill = {Daily = {}, Weekly = {}, Total = {}},
    IM = {Daily = {}, Weekly = {}, Total = {}}
}
pricesLoading = false
local farmGoalsConfigPath = configDir .. "farm_goals.json"
local mineGoalsConfigPath = configDir .. "mine_goals.json"
local themeConfigPath = configDir .. "theme_config.json"
local achievementsPath = configDir .. "achievements.json"
local itemMarketStatsPath = configDir .. "itemmarket_stats.json"

if not doesDirectoryExist(configDir) then createDirectory(configDir) end
if not doesDirectoryExist(soundsDir) then createDirectory(soundsDir) end

local WORK_TYPES = { FARM = 1, MINE = 2, SAWMILL = 3 }
local pendingScan = nil
local scannedThisSession = {
    [WORK_TYPES.FARM] = false,
    [WORK_TYPES.MINE] = false,
    [WORK_TYPES.SAWMILL] = false,
}

local FARM_ITEM_TO_RES = {
    [809] = "dye",
    [1692] = "rare_tkan",
    [3561] = "coal",
    [7795] = "water"
}

local FARM_RES_TO_ITEM = {}
for itemId, resKey in pairs(FARM_ITEM_TO_RES) do
    FARM_RES_TO_ITEM[resKey] = itemId
end

local MINE_ITEM_TO_RES = {
    [596] = "stone", [597] = "metal", [598] = "bronze", [599] = "silver", [600] = "gold",
    [7425] = "diamond", [7424] = "tkan", [7423] = "splav", [7281] = "materia", [7426] = "azbox"
}

local MINE_RES_TO_ITEM = {}
for itemId, resKey in pairs(MINE_ITEM_TO_RES) do
    MINE_RES_TO_ITEM[resKey] = itemId
end

local SAWMILL_ITEM_TO_RES = {
    [566] = "firewood",
    [4032] = "quality_wood"
}

local SAWMILL_RES_TO_ITEM = {}
for itemId, resKey in pairs(SAWMILL_ITEM_TO_RES) do
    SAWMILL_RES_TO_ITEM[resKey] = itemId
end

-- ====== ТЕМЫ ОФОРМЛЕНИЯ ======
local THEMES = {
    DEFAULT = 0,
    RED = 1,
    BLUE = 2,
    PURPLE = 3,
    ORANGE = 4,
    CYAN = 5,
}

local THEME_CONFIGS = {
    [THEMES.DEFAULT] = {
        name = "Стандартная",
        accent = 0xFF91E51A,
        accentHover = 0xFF66CC22,
        leftPanelBg = 0xFF0E0E0E,
        rightPanelBg = 0xFF141414,
        rightPanelHeader = 0xFF141414,
        buttonNormal = 0x00000000,
        buttonActive = 0xFF1E3D1E,
        buttonHover = 0xFF2A2A2A,
        borderColor = 0xFF333333,
        borderActive = 0xFF91E51A,
        borderHover = 0xFF555555,
        textNormal = 0xFF999999,
        textActive = 0xFF91E51A,
        textHover = 0xFFFFFFFF,
        headerTitle = 0xFF91E51A,
        titleBg = 0xFF0E0E0E,
        rightTitleBg = 0xFF141414,
        windowBg = 0xFF141414,
        childBg = 0xFF141414,
    },
    [THEMES.RED] = {
        name = "Красная",
        accent = 0xFFE53935,
        accentHover = 0xFF5053EF,
        leftPanelBg = 0xFF08081A,
        rightPanelBg = 0xFF12122D,
        rightPanelHeader = 0xFF12122D,
        buttonNormal = 0x00000000,
        buttonActive = 0xFF1A1A3D,
        buttonHover = 0xFF20203A,
        borderColor = 0xFF2A2A4A,
        borderActive = 0xFF3539E5,
        borderHover = 0xFF3A3A6A,
        textNormal = 0xFF9999CC,
        textActive = 0xFF3539E5,
        textHover = 0xFFFFFFFF,
        headerTitle = 0xFFE53935,
        titleBg = 0xFF08081A,
        rightTitleBg = 0xFF12122D,
        windowBg = 0xFF12122D,
        childBg = 0xFF12122D,
    },
    [THEMES.BLUE] = {
        name = "Синяя",
        accent = 0xFF3539E5,
        accentHover = 0xFFF5A542,
        leftPanelBg = 0xFF1A0A08,
        rightPanelBg = 0xFF251212,
        rightPanelHeader = 0xFF251212,
        buttonNormal = 0x00000000,
        buttonActive = 0xFF3D1A1A,
        buttonHover = 0xFF3A2020,
        borderColor = 0xFF4A2A2A,
        borderActive = 0xFFF39621,
        borderHover = 0xFF6A3A3A,
        textNormal = 0xFFCC9999,
        textActive = 0xFFF39621,
        textHover = 0xFFFFFFFF,
        headerTitle = 0xFF3539E5,
        titleBg = 0xFF1A0A08,
        rightTitleBg = 0xFF251212,
        windowBg = 0xFF251212,
        childBg = 0xFF251212,
    },
    [THEMES.PURPLE] = {
        name = "Фиолетовая",
        accent = 0xFFB0279C,
        accentHover = 0xFFBC47AB,
        leftPanelBg = 0xFF1A0A12,
        rightPanelBg = 0xFF25121F,
        rightPanelHeader = 0xFF25121F,
        buttonNormal = 0x00000000,
        buttonActive = 0xFF3D1E2E,
        buttonHover = 0xFF3A2A2D,
        borderColor = 0xFF4A333D,
        borderActive = 0xFFB0279C,
        borderHover = 0xFF6A4455,
        textNormal = 0xFFCC99BB,
        textActive = 0xFFB0279C,
        textHover = 0xFFFFFFFF,
        headerTitle = 0xFFB0279C,
        titleBg = 0xFF1A0A12,
        rightTitleBg = 0xFF25121F,
        windowBg = 0xFF25121F,
        childBg = 0xFF25121F,
    },
    [THEMES.ORANGE] = {
        name = "Оранжевая",
        accent = 0xFFF39621,
        accentHover = 0xFF26A7FF,
        leftPanelBg = 0xFF0A0E1A,
        rightPanelBg = 0xFF151825,
        rightPanelHeader = 0xFF151825,
        buttonNormal = 0x00000000,
        buttonActive = 0xFF1E2A3D,
        buttonHover = 0xFF202A3A,
        borderColor = 0xFF2A354A,
        borderActive = 0xFF0098FF,
        borderHover = 0xFF3A4A6A,
        textNormal = 0xFF9999BB,
        textActive = 0xFF0098FF,
        textHover = 0xFFFFFFFF,
        headerTitle = 0xFFF39621,
        titleBg = 0xFF0A0E1A,
        rightTitleBg = 0xFF151825,
        windowBg = 0xFF151825,
        childBg = 0xFF151825,
    },
    [THEMES.CYAN] = {
        name = "Бирюзовая",
        accent = 0xFF00BCD4,
        accentHover = 0xFFDAC626,
        leftPanelBg = 0xFF1A1A08,
        rightPanelBg = 0xFF252512,
        rightPanelHeader = 0xFF252512,
        buttonNormal = 0x00000000,
        buttonActive = 0xFF3D3D1A,
        buttonHover = 0xFF3A3A20,
        borderColor = 0xFF4A4A2A,
        borderActive = 0xFFD4BC00,
        borderHover = 0xFF6A6A3A,
        textNormal = 0xFFCCCC99,
        textActive = 0xFFD4BC00,
        textHover = 0xFFFFFFFF,
        headerTitle = 0xFF00BCD4,
        titleBg = 0xFF1A1A08,
        rightTitleBg = 0xFF252512,
        windowBg = 0xFF252512,
        childBg = 0xFF252512,
    },
}

local THEME_ORDER = {
    THEMES.DEFAULT,
    THEMES.RED,
    THEMES.BLUE,
    THEMES.PURPLE,
    THEMES.ORANGE,
    THEMES.CYAN,
}


-- ====== НАСТРОЙКА ТЕМЫ ======
local currentTheme = THEMES.DEFAULT 
local selectedThemeIdx = imgui.ImInt(0)  
local themeComboItems = ""  
local useCustomTheme = false
local cb_useCustomTheme = imgui.ImBool(false)

local CUSTOM_THEME = {
    accent = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    leftPanelBg = imgui.ImVec4(0.055, 0.055, 0.055, 1.0),
    rightPanelBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0),
    buttonActive = imgui.ImVec4(0.118, 0.239, 0.118, 1.0),
    buttonHover = imgui.ImVec4(0.165, 0.165, 0.165, 1.0),
    borderActive = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    textNormal = imgui.ImVec4(0.6, 0.6, 0.6, 1.0),
    textActive = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    textHover = imgui.ImVec4(1.0, 1.0, 1.0, 1.0),
    headerTitle = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    titleBg = imgui.ImVec4(0.055, 0.055, 0.055, 1.0),
    rightTitleBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0),
    windowBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0),
    childBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0),
    borderColor = imgui.ImVec4(0.165, 0.165, 0.165, 1.0),
 -- Текст в правой панели
    contentText = imgui.ImVec4(0.9, 0.9, 0.9, 1.0),
    contentTextHighlight = imgui.ImVec4(1.0, 0.8, 0.2, 1.0),
    contentTextGreen = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    
    -- Кнопки ImGui (обычные кнопки в правой панели)
    imguiButton = imgui.ImVec4(0.2, 0.2, 0.2, 0.6),
    imguiButtonHovered = imgui.ImVec4(0.26, 0.98, 0.26, 0.4),
    imguiButtonActive = imgui.ImVec4(0.26, 0.98, 0.26, 0.6),
    
    -- CollapsingHeader
    collapsingHeader = imgui.ImVec4(0.22, 0.22, 0.22, 0.5),
    collapsingHeaderHovered = imgui.ImVec4(0.26, 0.98, 0.26, 0.4),
    collapsingHeaderActive = imgui.ImVec4(0.26, 0.98, 0.26, 0.6),
    
    -- Separator
    separatorColor = imgui.ImVec4(0.2, 0.2, 0.2, 1.0),
    
    -- Прогресс-бар
    progressBar = imgui.ImVec4(0.26, 0.98, 0.26, 0.6),
    
    -- Чекбокс (галочка)
    checkMark = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    
    -- Слайдер
    sliderGrab = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    sliderGrabActive = imgui.ImVec4(0.26, 0.98, 0.26, 1.0),
    
    -- Фреймы (поля ввода)
    frameBg = imgui.ImVec4(0.2, 0.2, 0.2, 0.54),
    frameBgHovered = imgui.ImVec4(0.3, 0.3, 0.3, 0.4),
    frameBgActive = imgui.ImVec4(0.26, 0.98, 0.26, 0.3),
    
    -- Заголовки окон
    titleBgActive = imgui.ImVec4(0.1, 0.1, 0.1, 1.0),
    titleBgCollapsed = imgui.ImVec4(0.0, 0.0, 0.0, 0.51),
}

local customThemePath = configDir .. "custom_theme.json"

local configs = {
    [WORK_TYPES.FARM] = {
        name = "Ферма", prefix = "[ResHelherFarm]",
        resourceOrder = {"flax", "cotton", "rare_tkan", "water", "dye", "coal"},
        resourceNames = { flax = "Лён", cotton = "Хлопок", rare_tkan = "Кусок редкой ткани", water = "Вода для личных грядок", dye = "Краситель", coal = "Уголь" },
        defaultPrices = { flax = 15000, cotton = 20000, rare_tkan = 100000, water = 30000, dye = 50000, coal = 10000 },
        defaultGoals = { flax = 100, cotton = 100, rare_tkan = 50, water = 50, dye = 50, coal = 50 },
        rareResources = {"rare_tkan", "coal"},
        statsPath = configDir .. "farm_stats.json",
        scanNames = {
            ["Лён"] = "flax",
            ["Хлопок"] = "cotton",
            ["Кусок редкой ткани"] = "rare_tkan", ["Краситель"] = "dye",
            ["Уголь"] = "coal", ["Вода для личных грядок"] = "water"
        }
    },
    [WORK_TYPES.MINE] = {
        name = "Шахта", prefix = "[ResHelherMine]",
        resourceOrder = {"stone", "metal", "bronze", "silver", "gold", "diamond", "tkan", "splav", "materia", "azbox"},
        leftColumnOrder = {"stone", "tkan", "metal", "splav", "gold"},
        rightColumnOrder = {"diamond", "bronze", "materia", "silver", "azbox"},
        resourceNames = { stone = "Камень", metal = "Металл", bronze = "Бронза", silver = "Серебро", gold = "Золото", diamond = "Алмазный камень", tkan = "Прочная ткань", splav = "Шахтерский сплав", materia = "Темная материя", azbox = "Ларец с AZ-Монетами" },
        defaultPrices = { stone = 100000, metal = 320000, bronze = 11000, silver = 11000, gold = 45000, diamond = 1000000, tkan = 19000000, splav = 11000000, materia = 8000000, azbox = 1000000 },
        defaultGoals = { stone = 100, metal = 50, bronze = 50, silver = 30, gold = 20, diamond = 10, tkan = 5, splav = 5, materia = 3, azbox = 3 },
        rareResources = {"diamond", "tkan", "splav", "materia"},
        statsPath = configDir .. "mining_stats.json",
        scanNames = {
            ["Прочная ткань"] = "tkan", ["Шахтерский сплав"] = "splav", ["Алмазный камень"] = "diamond",
            ["Темная материя"] = "materia", ["Ларец с AZ-Монетами"] = "azbox",
            ["Камень"] = "stone", ["Металл"] = "metal", ["Золото"] = "gold",
            ["Бронза"] = "bronze", ["Серебро"] = "silver"
        }
    },
    [WORK_TYPES.SAWMILL] = {
        name = "Лесопилка", prefix = "[ResHelperSaw]",
        resourceOrder = {"firewood", "quality_wood", "rare_box"},
        resourceNames = { firewood = "Дрова", quality_wood = "Древесина высшего качества", rare_box = "Выпавшие ларцы" },
        defaultPrices = { firewood = 5000, quality_wood = 50000, rare_box = 0 },
        defaultGoals = { firewood = 200, quality_wood = 20, rare_box = 5 },
        rareResources = {"quality_wood", "rare_box"},
        statsPath = configDir .. "sawmill_stats.json",
        scanNames = {
            ["Дрова"] = "firewood",
            ["Древесина высшего качества"] = "quality_wood"
        }
    }
}	

local currentWork = WORK_TYPES.FARM
local config = configs[currentWork]

local resources = {}
local resourcePrices = {}
local goals = {}
local goalsReached = {}
local sessionResources = {}
local dailyResources = {}
local dailyTotal = 0
local totalDailyIncome = 0
local totalIncomeGoalReached = false
local totalIncomeCacheTime = 0
local sessionTotal = 0
local sessionStartTime = os.time()  
goalsExpandedFarm = false
goalsExpandedMine = false
goalsExpandedSaw = false
goalsExpandedGeneral = false
pricesExpandedFarm = false
statsExpandedFarm = false
pricesExpandedMine = false
statsExpandedMine = false
pricesExpandedSaw = false
statsExpandedSaw = false
settingsExpandedTheme = false
settingsExpandedCustomTheme = false
settingsExpandedTelegram = false
settingsExpandedMenuColors = false
settingsExpandedTextColors = false
settingsExpandedElements = false
settingsExpandedNotify = false
settingsExpandedSound = false
settingsExpandedOverlay = false
settingsExpandedTimer = false

local resourceLog = {}
local loadedLogs = false

local settings = {
    chatNotifyEnabled = false, goalSoundEnabled = true, pickupSoundEnabled = true,
    goalSoundVolume = 80, pickupSoundVolume = 80, rareSoundVolume = 80, coalSoundVolume = 80,
	pickupSoundFile = "pickup.wav",
    rareSoundFile = "rare.wav",
    coalSoundFile = "ugol.wav",
    achivSoundFile = "achiv.wav",
    farmOverlayEnabled = false, mineOverlayEnabled = false, sawmillOverlayEnabled = false,
    undermineEnabled = false, underminelavkaEnabled = false, regularmineEnabled = false, farmEnabled = false, sawmillEnabled = false,
    overlayTimerEnabled = false, totalIncomeGoal = 1000000
}

local inventoryCache = {}

local scanState = {
    active = false,
    scanning = false,
    foundResources = {},
    statusText = "",
    waitForInventory = false,
    scanned = false
}

local inventoryBase = {}
local lastServerMessageTime = {}  
local pendingResources = {}  
local changelogShown = false
changelogPath = configDir .. "changelog_shown.txt"
local changelogData = nil
changelogUrl = "https://raw.githubusercontent.com/Ryder8471/ArzResHelper/main/changelog.json"

local mineItemMappingByID = { ["596"] = "stone", ["597"] = "metal", ["598"] = "bronze", ["599"] = "silver", ["600"] = "gold", ["7425"] = "diamond", ["7424"] = "tkan", ["7423"] = "splav", ["7281"] = "materia", ["7426"] = "azbox" }
local mineItemAmounts = { stone = 6, metal = 3, bronze = 3, silver = 2, gold = 2, diamond = 1, tkan = 1, splav = 1, materia = 1, azbox = 1 }

local needSave = false
local needSaveColor = imgui.ImColor(250, 66, 66, 102):GetVec4()

local overlayConfigs = {
    [WORK_TYPES.FARM] = { x = 15, y = 300, w = 220, h = 160 },
    [WORK_TYPES.MINE] = { x = 15, y = 300, w = 280, h = 200 },
    [WORK_TYPES.SAWMILL] = { x = 15, y = 300, w = 220, h = 120 }
}

-- Таймер для оверлея
local overlayTimer = {
    enabled = false,
    running = false,
    startTime = 0,
    elapsed = 0,
    displayedTime = "00:00:00",
}
local cb_overlay_timer = imgui.ImBool(false)  
local totalGoalEdit = imgui.ImInt(0)

-- Настройки для GUI
local cb_farm = imgui.ImBool(false)
local cb_undermine = imgui.ImBool(false)
local cb_lavka = imgui.ImBool(false)
local cb_regular = imgui.ImBool(false)
local cb_chatNotify = imgui.ImBool(false)
local cb_goalSound = imgui.ImBool(false)
local cb_pickupSound = imgui.ImBool(false)
local cb_farm_overlay = imgui.ImBool(false)
local cb_mine_overlay = imgui.ImBool(false)
local cb_sawmill_overlay = imgui.ImBool(false)
local cb_sawmill = imgui.ImBool(false)
local goal_vol_slider = imgui.ImInt(80)
local pickup_vol_slider = imgui.ImInt(80)
local selectedDateIndexFarm = imgui.ImInt(0)
local selectedDateIndexMine = imgui.ImInt(0)
local farmStatsTab = imgui.ImInt(0)
local mineStatsTab = imgui.ImInt(0)
local achCategoryFilter = imgui.ImInt(0)
local lbTab = imgui.ImInt(0)
lbModeTab = imgui.ImInt(0)

local priceEdit = {}
local goalEdit = {}
local farmGoalEditCache = {}
local mineGoalEditCache = {}
local sawmillGoalEditCache = {}

-- ====== СИСТЕМА ДОСТИЖЕНИЙ ======

local ACHIEVEMENTS = {
    -- ====== ФЕРМА — ДНЕВНЫЕ ЦЕЛИ ======
    {
        id = "flax_goal",
        name = "Льняной магнат",
        desc = "Выполнить дневную цель по льну 20 раз",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["flax"] end,
    },
    {
        id = "cotton_goal",
        name = "Хлопковый барон",
        desc = "Выполнить дневную цель по хлопку 20 раз",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["cotton"] end,
    },
    {
        id = "water_goal",
        name = "Водяной",
        desc = "Выполнить дневную цель по воде 20 раз",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["water"] end,
    },
    {
        id = "dye_goal",
        name = "Красительщик",
        desc = "Выполнить дневную цель по красителю 20 раз",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["dye"] end,
    },
    {
        id = "rare_tkan_goal",
        name = "Тканевый охотник",
        desc = "Выполнить дневную цель по редкой ткани 20 раз",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["rare_tkan"] end,
    },
    {
        id = "coal_goal",
        name = "Угольный барон",
        desc = "Выполнить дневную цель по углю 20 раз",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["coal"] end,
    },
    
    -- ====== ШАХТА — ДНЕВНЫЕ ЦЕЛИ ======
    {
        id = "stone_goal",
        name = "Каменный человек",
        desc = "Выполнить дневную цель по камню 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["stone"] end,
    },
    {
        id = "metal_goal",
        name = "Металлург",
        desc = "Выполнить дневную цель по металлу 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["metal"] end,
    },
    {
        id = "bronze_goal",
        name = "Бронзовых дел мастер",
        desc = "Выполнить дневную цель по бронзе 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["bronze"] end,
    },
    {
        id = "silver_goal",
        name = "Серебряный стрелок",
        desc = "Выполнить дневную цель по серебру 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["silver"] end,
    },
    {
        id = "gold_goal",
        name = "Золотоискатель",
        desc = "Выполнить дневную цель по золоту 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["gold"] end,
    },
    {
        id = "diamond_goal",
        name = "Алмазный охотник",
        desc = "Выполнить дневную цель по алмазным камням 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["diamond"] end,
    },
    {
        id = "tkan_goal",
        name = "Тканевый шахтёр",
        desc = "Выполнить дневную цель по прочной ткани 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["tkan"] end,
    },
    {
        id = "splav_goal",
        name = "Сплавщик",
        desc = "Выполнить дневную цель по шахтёрскому сплаву 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["splav"] end,
    },
    {
        id = "materia_goal",
        name = "Тёмный маг",
        desc = "Выполнить дневную цель по тёмной материи 10 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 10,
        progress = 0,
        completed = false,
        check = function() return goalsReached["materia"] end,
    },
    {
        id = "azbox_goal",
        name = "Ларечный охотник",
        desc = "Выполнить дневную цель по ларцам с AZ-монетами 20 раз",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["azbox"] end,
    },
    
    -- ====== ЛЕСОПИЛКА — ДНЕВНЫЕ ЦЕЛИ ======
    {
        id = "firewood_goal",
        name = "Дровосек",
        desc = "Выполнить дневную цель по дровам 20 раз",
        icon = fa.ICON_TREE,
        category = "Лесопилка",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["firewood"] end,
    },
    {
        id = "quality_wood_goal",
        name = "Краснодеревщик",
        desc = "Выполнить дневную цель по древесине высшего качества 20 раз",
        icon = fa.ICON_TREE,
        category = "Лесопилка",
        target = 20,
        progress = 0,
        completed = false,
        check = function() return goalsReached["quality_wood"] end,
    },
    
    -- ====== КОЛЛЕКЦИОНЕРЫ — ФЕРМА ======
    {
        id = "flax_collector",
        name = "Льняной коллекционер",
        desc = "Добыть 100.000 льна за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 100000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "cotton_collector",
        name = "Хлопковый сборщик",
        desc = "Добыть 100.000 хлопка за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 100000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "rare_tkan_collector",
        name = "Тканевый накопитель",
        desc = "Добыть 10.000 редкой ткани за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 10000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "water_collector",
        name = "Водонос",
        desc = "Добыть 5.000 воды за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 5000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "dye_collector",
        name = "Красильный цех",
        desc = "Добыть 5.000 красителя за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 5000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "coal_collector",
        name = "Угольный король",
        desc = "Добыть 2.500 угля за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 2500,
        progress = 0,
        completed = false,
        check = nil,
    },
    
    -- ====== КОЛЛЕКЦИОНЕРЫ — ШАХТА ======
    {
        id = "stone_collector",
        name = "Каменный гигант",
        desc = "Добыть 10.000 камня за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 10000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "metal_collector",
        name = "Металлический запас",
        desc = "Добыть 7.500 металла за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 7500,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "bronze_collector",
        name = "Бронзовая коллекция",
        desc = "Добыть 5.000 бронзы за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 5000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "silver_collector",
        name = "Серебряный запас",
        desc = "Добыть 3.000 серебра за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 3000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "gold_collector",
        name = "Золотой запас",
        desc = "Добыть 3.000 золота за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 3000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "diamond_collector",
        name = "Алмазный фонд",
        desc = "Добыть 1.000 алмазных камней за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 1000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "tkan_collector",
        name = "Прочная коллекция",
        desc = "Добыть 100 прочной ткани за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 100,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "splav_collector",
        name = "Сплавной запас",
        desc = "Добыть 100 шахтёрского сплава за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 100,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "materia_collector",
        name = "Тёмный резерв",
        desc = "Добыть 60 тёмной материи за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 60,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "azbox_collector",
        name = "Ларечный склад",
        desc = "Добыть 100 ларцов с AZ-монетами за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 100,
        progress = 0,
        completed = false,
        check = nil,
    },
    
    -- ====== КОЛЛЕКЦИОНЕРЫ — ЛЕСОПИЛКА ======
    {
        id = "firewood_collector",
        name = "Дровяной склад",
        desc = "Нарубить 200.000.000 дров за всё время",
        icon = fa.ICON_TREE,
        category = "Лесопилка",
        target = 200000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "quality_wood_collector",
        name = "Элитный лесоруб",
        desc = "Добыть 10.000 древесины высшего качества за всё время",
        icon = fa.ICON_TREE,
        category = "Лесопилка",
        target = 10000,
        progress = 0,
        completed = false,
        check = nil,
    },
    
    -- ====== ЗАРАБОТОК ======
    {
        id = "farmer_pro",
        name = "Фермер-профессионал",
        desc = "Заработать 7.500.000.000$ на ферме за всё время",
        icon = fa.ICON_LEAF,
        category = "Ферма",
        target = 7500000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "miner_pro",
        name = "Шахтёр-профессионал",
        desc = "Заработать 10.000.000.000$ в шахте за всё время",
        icon = fa.ICON_GAVEL,
        category = "Шахта",
        target = 10000000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "sawmill_pro",
        name = "Лесопилка-профи",
        desc = "Заработать 5.000.000.000$ на лесопилке за всё время",
        icon = fa.ICON_TREE,
        category = "Лесопилка",
        target = 5000000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    
	    -- ====== ITEM MARKET ======
    {
        id = "im_1b",
        name = "Бизнесмен",
        desc = "Заработать 1.000.000.000$ на аренде предметов",
        icon = fa.ICON_SHOPPING_CART,
        category = "Item Market",
        target = 1000000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "im_2_5b",
        name = "Магнат",
        desc = "Заработать 2.500.000.000$ на аренде предметов",
        icon = fa.ICON_SHOPPING_CART,
        category = "Item Market",
        target = 2500000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "im_5b",
        name = "Олигарх",
        desc = "Заработать 5.000.000.000$ на аренде предметов",
        icon = fa.ICON_SHOPPING_CART,
        category = "Item Market",
        target = 5000000000,
        progress = 0,
        completed = false,
        check = nil,
    },
	
    -- ====== ОБЩИЕ ======
    {
        id = "millionaire",
        name = "Миллиардер",
        desc = "Общий доход 15.000.000.000$",
        icon = fa.ICON_BULLSEYE,
        category = "Общие",
        target = 15000000000,
        progress = 0,
        completed = false,
        check = nil,
    },
    {
        id = "goal_hunter",
        name = "Охотник за целями",
        desc = "Выполнить 100 любых дневных целей",
        icon = fa.ICON_BULLSEYE,
        category = "Общие",
        target = 100,
        progress = 0,
        completed = false,
        check = nil,
    },
}

-- Переменная для отслеживания выполненных целей (всех)
local totalCompletedGoals = 0

-- ====== ФУНКЦИИ ДЛЯ РАБОТЫ С РЕСУРСАМИ ======
local function formatNumber(num)
    if not num then return "0" end
    return tostring(math.floor(num)):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function getFileHash(filepath)
    local file = io.open(filepath, "r")
    if not file then return "" end
    local content = file:read("*all")
    file:close()
    local hash = 0
    for i = 1, #content do
        hash = (hash * 31 + string.byte(content, i)) % 4294967296
    end
    return tostring(hash)
end

local tgConfigPath = configDir .. "telegram_config.json"

local function saveTgConfig()
    local file = io.open(tgConfigPath, "w")
    if file then
        file:write(encodeJson(tgConfig))
        file:close()
    end
end

local function loadTgConfig()
    local file = io.open(tgConfigPath, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if data then
        tgConfig.enabled = data.enabled or false
        tgConfig.botToken = data.botToken or ""
        tgConfig.chatId = data.chatId or ""
        tgConfig.itemMarketEnabled = data.itemMarketEnabled or true
        tgConfig.dailyReportEnabled = data.dailyReportEnabled or false
		tgConfig.weeklyReportEnabled = data.weeklyReportEnabled or false
		tgConfig.useReserveServer = data.useReserveServer
    if tgConfig.useReserveServer == nil then tgConfig.useReserveServer = true end
    end
    tgTokenInput.v = u8(tgConfig.botToken)
    tgChatIdInput.v = u8(tgConfig.chatId)
end


playingSounds = {}
local function playSoundFile(fn, vol)
    local sf = soundsDir .. fn
    if doesFileExist(sf) then 
        local a = loadAudioStream(sf)
        if a then 
            setAudioStreamVolume(a, vol / 100)
            setAudioStreamState(a, 1)
            table.insert(playingSounds, a)
            -- Удаляем из таблицы после проигрывания
            lua_thread.create(function()
                wait(5000)
                for i, s in ipairs(playingSounds) do
                    if s == a then table.remove(playingSounds, i); break end
                end
            end)
        end
    end
end

local function playGoalSound() 
    if settings.goalSoundEnabled and settings.goalSoundVolume > 0 then 
        playSoundFile(settings.achivSoundFile, settings.goalSoundVolume) 
    end 
end

local cachedWavFiles = nil
function getWavFiles()
    if cachedWavFiles then return cachedWavFiles end
    
    local files = {}
    local dir = soundsDir
    
    local defaults = {"pickup.wav", "rare.wav", "ugol.wav", "achiv.wav"}
    for _, f in ipairs(defaults) do
        if doesFileExist(dir .. f) then
            table.insert(files, f)
        end
    end
    
    local hasLfs, lfs = pcall(require, "lfs")
    if hasLfs and lfs then
        for file in lfs.dir(dir) do
            if file:match("%.wav$") then
                local alreadyExists = false
                for _, existing in ipairs(files) do
                    if existing == file then alreadyExists = true; break end
                end
                if not alreadyExists then
                    table.insert(files, file)
                end
            end
        end
    end
    
    table.sort(files)
    cachedWavFiles = files
    return files
end

local function playPickupSound(rn)
    if not settings.pickupSoundEnabled then return end
    if rn == "coal" or rn == "tkan" or rn == "splav" or rn == "materia" then
        if settings.coalSoundVolume > 0 then
            playSoundFile(settings.coalSoundFile, settings.coalSoundVolume)
        end
        return
    end
    if config.rareResources then 
        for _, r in ipairs(config.rareResources) do 
            if rn == r then 
                if settings.rareSoundVolume > 0 then
                    playSoundFile(settings.rareSoundFile, settings.rareSoundVolume)
                end
                return 
            end 
        end 
    end
    if settings.pickupSoundVolume > 0 then
        playSoundFile(settings.pickupSoundFile, settings.pickupSoundVolume)
    end
end

local function checkGoalReached(rn)
    local ca = dailyResources[rn] or 0
    local g = goals[rn] or 1
    if ca >= g and not goalsReached[rn] then 
        goalsReached[rn] = true
        totalCompletedGoals = totalCompletedGoals + 1
        saveAchievements()
        playGoalSound()
        checkAchievements()
        if settings.chatNotifyEnabled then 
            sampAddChatMessage("{00FF00}" .. config.prefix .. " {FFFFFF}Цель достигнута! " .. config.resourceNames[rn] .. ": " .. formatNumber(ca) .. " / " .. formatNumber(g), -1) 
        end
    end
end

function getMoscowTime(timestamp)
    local utcTime

    if timestamp then
        utcTime = timestamp
    else
        utcTime = os.time(os.date("!*t"))
    end

    return utcTime + 10800
end

local function getGameDate(timestamp)
    local t = timestamp or os.time()
    -- Приводим к МСК: добавляем 3 часа
    local msk = t + 10800
    -- Игровой день начинается в 05:00 МСК
    -- Если время < 5 часов, откатываем на день назад
    local dayStart = 5 * 3600  -- 5 часов в секундах
    local secondsSinceMidnight = msk % 86400
    if secondsSinceMidnight < dayStart then
        msk = msk - 86400
    end
    -- Получаем Y-m-d через деление
    local days = math.floor(msk / 86400)
    -- Переводим дни в дату
    local y = 1970
    local remaining = days
    while true do
        local daysInYear = (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) and 366 or 365
        if remaining < daysInYear then break end
        remaining = remaining - daysInYear
        y = y + 1
    end
    local monthDays = {31, (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    local m = 1
    while remaining >= monthDays[m] do
        remaining = remaining - monthDays[m]
        m = m + 1
    end
    local d = remaining + 1
    return string.format("%04d-%02d-%02d", y, m, d)
end

local function getDayStats(dateStr)
    local result = {total = 0}
    for _, k in ipairs(config.resourceOrder) do result[k] = 0 end
    for _, log in ipairs(resourceLog) do
        if getGameDate(log.time) == dateStr then
            result[log.resource] = (result[log.resource] or 0) + log.amount
        end
    end
    result.total = 0
    for _, k in ipairs(config.resourceOrder) do
        local price = resourcePrices[k] or config.defaultPrices[k] or 0
        result.total = result.total + (result[k] * price)
    end
    return result
end

local function getTodayStats()
    if cachedTodayStats and os.time() - cachedTodayTime < 1 then
        return cachedTodayStats
    end
    cachedTodayStats = getDayStats(getGameDate())
    cachedTodayTime = os.time()
    return cachedTodayStats
end

local function getWeekStats()
    if cachedWeekStats and os.time() - cachedWeekTime < 5 then
        return cachedWeekStats
    end
    
    local todayDate = getGameDate()
    local year, month, day = todayDate:match("(%d+)-(%d+)-(%d+)")
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    
    local mskTime = getMoscowTime()
local mskHour = tonumber(os.date("%H", mskTime))
local currentDay = tonumber(os.date("%w", mskTime))
    if currentDay == 0 then currentDay = 7 end 
    
    if mskHour < 5 then
        currentDay = currentDay - 1
        if currentDay == 0 then currentDay = 7 end
    end
    
    local result = {total = 0}
    for _, k in ipairs(config.resourceOrder) do result[k] = 0 end
    
    for i = 0, currentDay - 1 do
        local date = getGameDate(os.time() - i * 86400)
        local dayData = getDayStats(date)
        for _, k in ipairs(config.resourceOrder) do 
            result[k] = result[k] + (dayData[k] or 0) 
        end
        result.total = result.total + dayData.total
    end
    
    cachedWeekStats = result
    cachedWeekTime = os.time()
    return result
end

local function getAvailableDates()
    local dates = {}
    local seen = {}
    for _, log in ipairs(resourceLog) do
        local d = getGameDate(log.time)
        if not seen[d] then seen[d] = true; table.insert(dates, d) end
    end
    local today = getGameDate()
    if not seen[today] then table.insert(dates, today) end
    table.sort(dates, function(a, b) return a > b end)
    return dates
end

local function checkTotalIncomeGoal()
    if settings.totalIncomeGoal > 0 and totalDailyIncome >= settings.totalIncomeGoal and not totalIncomeGoalReached then
        totalIncomeGoalReached = true
        saveTotalIncomeGoal()
        if settings.goalSoundEnabled then playGoalSound() end
        if settings.chatNotifyEnabled then
            sampAddChatMessage(SCRIPT_PREFIX .. "Цель общего дохода достигнута! " .. formatNumber(totalDailyIncome) .. "$ / " .. formatNumber(settings.totalIncomeGoal) .. "$", SCRIPT_COLOR)
        end
    end
end

local function addToStats(resourceName, amount, skipSound)
    if not sessionResources[resourceName] then return end
    local price = resourcePrices[resourceName] or config.defaultPrices[resourceName] or 0
    local value = amount * price
    sessionResources[resourceName] = sessionResources[resourceName] + amount
    sessionTotal = sessionTotal + value
    dailyResources[resourceName] = (dailyResources[resourceName] or 0) + amount
    dailyTotal = dailyTotal + value
    
    -- Оптимизированное логирование
    local now = os.time()
    
    -- Интервал агрегации: для обычных ресурсов дольше, для редких короче
    local isRare = false
    if config.rareResources then
        for _, r in ipairs(config.rareResources) do
            if r == resourceName then isRare = true; break end
        end
    end
    local aggregationInterval = isRare and 600 or 600 
    
    local lastLog = nil
    for i = #resourceLog, 1, -1 do
        if resourceLog[i].resource == resourceName then
            lastLog = resourceLog[i]
            break
        end
    end
    
    if lastLog and (now - lastLog.time) <= aggregationInterval then
        if overlayTimer.running and lastLog.time < overlayTimer.startTime then
            table.insert(resourceLog, {
                time = now, 
                resource = resourceName, 
                amount = amount, 
                value = value
            })
        else
            lastLog.amount = lastLog.amount + amount
            lastLog.value = lastLog.value + value
            lastLog.time = now
        end
    else
        table.insert(resourceLog, {
            time = now, 
            resource = resourceName, 
            amount = amount, 
            value = value
        })
    end
    
    saveStats()
    if not skipSound then
        playPickupSound(resourceName)
    end
    checkGoalReached(resourceName)
    saveGoalsProgress()
    totalDailyIncome = totalDailyIncome + value
    saveTotalIncomeGoal()
    checkTotalIncomeGoal()
end

local function addResource(resourceName, amount, skipSound)
    if not resources[resourceName] then return false end
    resources[resourceName] = resources[resourceName] + amount
    addToStats(resourceName, amount, skipSound)
    return true
end

local function removeResource(resourceName, amount)
    if resources[resourceName] then 
        resources[resourceName] = math.max(0, resources[resourceName] - amount)
        local price = resourcePrices[resourceName] or config.defaultPrices[resourceName] or 0
        totalDailyIncome = math.max(0, totalDailyIncome - (amount * price))
        saveTotalIncomeGoal()
        return true 
    end
    return false
end

-- Сохранение/загрузка состояния отправки отчётов
local function saveTgReportState(dailyDate, weeklyKey)
    local data = {
        lastDailyDate = dailyDate or "",
        lastWeeklyKey = weeklyKey or ""
    }
    local file = io.open(tgReportStatePath, "w")
    if file then
        file:write(encodeJson(data))
        file:close()
    end
end

local function loadTgReportState()
    local file = io.open(tgReportStatePath, "r")
    if not file then return "", "" end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if data then
        return data.lastDailyDate or "", data.lastWeeklyKey or ""
    end
    return "", ""
end

function saveLbState(dailyDate, weeklyKey)
    local data = {
        lastDailyDate = dailyDate or "",
        lastWeeklyKey = weeklyKey or ""
    }
    local file = io.open(lbStatePath, "w")
    if file then file:write(encodeJson(data)); file:close() end
end

function loadLbState()
    local file = io.open(lbStatePath, "r")
    if not file then return "", "" end
    local data = decodeJson(file:read("*all"))
    file:close()
    if data then return data.lastDailyDate or "", data.lastWeeklyKey or "" end
    return "", ""
end

-- Сбор статистики для любого типа работ за период
local function getStatsForWorkType(workType, period)
    local cfg = configs[workType]
    local prices = {}
    local pricesPath = workType == WORK_TYPES.FARM and farmPricesPath or 
                       workType == WORK_TYPES.MINE and minePricesPath or sawmillPricesPath
    
    local pf = io.open(pricesPath, "r")
    if pf then
        for line in pf:lines() do
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then prices[k] = tonumber(v) end
        end
        pf:close()
    end
    
    local result = {total = 0}
    for _, k in ipairs(cfg.resourceOrder) do result[k] = 0 end
    
    local sf = io.open(cfg.statsPath, "r")
    if not sf then return result end
    local content = sf:read("*all")
    sf:close()
    
    if period == "daily" then
        local yesterdayDate = getGameDate(os.time() - 86400)
        for time, resource, amount in content:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            if getGameDate(tonumber(time)) == yesterdayDate then
                result[resource] = (result[resource] or 0) + tonumber(amount)
            end
        end
    elseif period == "week" then
        local mskTime = getMoscowTime()
        local mskWday = tonumber(os.date("%w", mskTime))
        if mskWday == 0 then mskWday = 7 end
        local lastSundayTime = os.time() - (mskWday * 86400)
        local lastSunday = getGameDate(lastSundayTime)
        local lastMondayTime = lastSundayTime - (6 * 86400)
        local lastMonday = getGameDate(lastMondayTime)
        
        for time, resource, amount in content:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            local logDate = getGameDate(tonumber(time))
            if logDate >= lastMonday and logDate <= lastSunday then
                result[resource] = (result[resource] or 0) + tonumber(amount)
            end
        end
    end
    
    for _, k in ipairs(cfg.resourceOrder) do
        local price = prices[k] or cfg.defaultPrices[k] or 0
        result.total = result.total + (result[k] * price)
    end
    
    return result
end

-- Генерация отчёта
local function generateReport(period)
    local mskTime = getMoscowTime()
    local timeStr = os.date("%H:%M", mskTime)
    local currentDateStr = os.date("%d.%m.%Y", mskTime)
    
    local report
    local farmData = getStatsForWorkType(WORK_TYPES.FARM, period)
    local mineData = getStatsForWorkType(WORK_TYPES.MINE, period)
    local sawmillData = getStatsForWorkType(WORK_TYPES.SAWMILL, period)
    
    if period == "daily" then
        local yesterdayTime = os.time() - 86400
        local yesterdayDate = os.date("%d.%m.%Y", yesterdayTime)
        report = "<b>Ежедневный отчёт ResHelper</b>\n"
        report = report .. "Дата: " .. yesterdayDate .. "\n"
        report = report .. "Отправлено: " .. currentDateStr .. " | " .. timeStr .. " (МСК)\n\n"
    else
        local mskWday = tonumber(os.date("%w", mskTime))
        if mskWday == 0 then mskWday = 7 end
        local lastSundayTime = os.time() - (mskWday * 86400)
        local lastMondayTime = lastSundayTime - (6 * 86400)
        local lastMonday = os.date("%d.%m.%Y", lastMondayTime)
        local lastSunday = os.date("%d.%m.%Y", lastSundayTime)
        report = "<b>Недельный отчёт ResHelper</b>\n"
        report = report .. "Период: " .. lastMonday .. " - " .. lastSunday .. "\n"
        report = report .. "Отправлено: " .. currentDateStr .. " | " .. timeStr .. " (МСК)\n\n"
    end
    
    local totalAll = 0
    
    report = report .. "<b>[Ферма]</b>\n"
    for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
        report = report .. "- " .. configs[WORK_TYPES.FARM].resourceNames[k] .. ": <b>" .. formatNumber(farmData[k] or 0) .. " шт.</b>\n"
    end
    report = report .. "Доход: <b>" .. formatNumber(farmData.total) .. "$</b>\n\n"
    totalAll = totalAll + farmData.total
    
    report = report .. "<b>[Шахта]</b>\n"
    for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
        report = report .. "- " .. configs[WORK_TYPES.MINE].resourceNames[k] .. ": <b>" .. formatNumber(mineData[k] or 0) .. " шт.</b>\n"
    end
    report = report .. "Доход: <b>" .. formatNumber(mineData.total) .. "$</b>\n\n"
    totalAll = totalAll + mineData.total
    
    report = report .. "<b>[Лесопилка]</b>\n"
    for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
        report = report .. "- " .. configs[WORK_TYPES.SAWMILL].resourceNames[k] .. ": <b>" .. formatNumber(sawmillData[k] or 0) .. " шт.</b>\n"
    end
    report = report .. "Доход: <b>" .. formatNumber(sawmillData.total) .. "$</b>\n\n"
    totalAll = totalAll + sawmillData.total
    
    -- Item Market
    local imAmount = 0
    if period == "daily" then
        local yesterdayDate = getGameDate(os.time() - 86400)
        for _, log in ipairs(itemMarketLog) do
            if getGameDate(log.time) == yesterdayDate then
                imAmount = imAmount + log.amount
            end
        end
    else
        local mskWday = tonumber(os.date("%w", mskTime))
        if mskWday == 0 then mskWday = 7 end
        local lastSundayTime = os.time() - (mskWday * 86400)
        local lastMondayTime = lastSundayTime - (6 * 86400)
        for _, log in ipairs(itemMarketLog) do
            local logDate = getGameDate(log.time)
            if logDate >= getGameDate(lastMondayTime) and logDate <= getGameDate(lastSundayTime) then
                imAmount = imAmount + log.amount
            end
        end
    end
    
    report = report .. "<b>[Item Market]</b>\n"
    report = report .. "Доход: <b>" .. formatNumber(imAmount) .. "$</b>\n\n"
    totalAll = totalAll + imAmount
    
    report = report .. "<b>Общий доход: " .. formatNumber(totalAll) .. "$</b>"
    
    return report
end

local function processInventoryLine(line)
    if not line then return end
    local cleanLine = line:gsub("{[%a%d]+}", "")
    local slot, name, count = cleanLine:match("%[слот (%d+)%]%s*(.-)%s*%[(%d+) шт%]")
    if not slot then
        name, count = cleanLine:match("(%S.+)%s*%[(%d+) шт%]")
    end
    if name and count then
        count = tonumber(count)
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if config.scanNames then
            for scanName, resKey in pairs(config.scanNames) do
                if name:find(scanName, 1, true) then
                    if not scanSlots[resKey] then scanSlots[resKey] = {} end
                    table.insert(scanSlots[resKey], count)
                    scanState.foundResources[resKey] = (scanState.foundResources[resKey] or 0) + count
                    return true
                end
            end
        end
    end
    return false
end

local function getMaxStack(resKey)
    local maxStacks = {
        flax = 6000, cotton = 6000, rare_tkan = 5000, water = 1000, dye = 100, coal = 5000,
        stone = 6000, metal = 6000, bronze = 6000, silver = 6000, gold = 6000,
        diamond = 200, tkan = 200, splav = 200, materia = 50, azbox = 100,
        firewood = 1000000, quality_wood = 500
    }
    return maxStacks[resKey] or 100
end

local function startInventoryScan()
    if scanState.active then
        sampAddChatMessage("{FFA500}[ResHelher] Сканирование уже выполняется...", -1)
        return
    end
    if not config.scanNames then
        sampAddChatMessage("{FFA500}[ResHelher] Для текущего типа работы нет настроек сканирования.", -1)
        return
    end
    scanState.active = true
    scanState.scanning = true
	scannedThisSession[currentWork] = true
    scanState.foundResources = {}
    scanState.statusText = "Открываю статистику..."
    scanState.waitForInventory = false
    sampAddChatMessage("{00FF00}[ResHelher] Запущено сканирование инвентаря...", -1)
    lua_thread.create(function()
        wait(15000)
        if scanState.active and scanState.scanning then
            sampAddChatMessage("{FFA500}[ResHelher] Сканирование прервано по таймауту.", -1)
            scanState.active = false
            scanState.scanning = false
            scanState.statusText = "Ошибка: таймаут"
        end
    end)
    sampSendChat("/stats")
end

local function finishScan()
    inventoryBase = {}
    for resKey, amount in pairs(scanState.foundResources) do
        inventoryBase[resKey] = amount
    end
    for resKey, slots in pairs(scanSlots) do
        local itemId
                if currentWork == WORK_TYPES.FARM then
            itemId = FARM_RES_TO_ITEM[resKey]
        elseif currentWork == WORK_TYPES.MINE then
            itemId = MINE_RES_TO_ITEM[resKey]
        elseif currentWork == WORK_TYPES.SAWMILL then
            itemId = SAWMILL_RES_TO_ITEM[resKey]
        end
        if itemId then
            inventoryCache[itemId] = {}
            for _, v in ipairs(slots) do
                table.insert(inventoryCache[itemId], v)
            end
        end
    end
    for _, resKey in ipairs(config.resourceOrder) do
        if not inventoryBase[resKey] then
            inventoryBase[resKey] = 0
        end
        local itemId
                if currentWork == WORK_TYPES.FARM then
            itemId = FARM_RES_TO_ITEM[resKey]
        elseif currentWork == WORK_TYPES.MINE then
            itemId = MINE_RES_TO_ITEM[resKey]
        elseif currentWork == WORK_TYPES.SAWMILL then
            itemId = SAWMILL_RES_TO_ITEM[resKey]
        end
        if itemId and not scanSlots[resKey] then
            inventoryCache[itemId] = {0}
        end
    end
    scanSlots = {}
    scanState.scanned = true
        local foundItems = {}
    for _, resKey in ipairs(config.resourceOrder) do
        if resKey ~= "rare_box" then
            local amount = inventoryBase[resKey] or 0
            table.insert(foundItems, config.resourceNames[resKey] .. ": " .. amount .. " шт.")
        end
    end
    sampAddChatMessage("{00FF00}[ResHelher] Сканирование завершено! Найдено в инвентаре:", -1)
    for _, msg in ipairs(foundItems) do
        sampAddChatMessage("{FFFFFF}  " .. msg, -1)
    end
    sampAddChatMessage("{FFA500}[ResHelher] База установлена. Учитывается только новая добыча.", -1)
    scanState.active = false
    scanState.scanning = false
    scanState.statusText = "Готово"
    ignoreInventoryUntil = os.time() + 3
    saveInventoryBase()
    sampCloseCurrentDialogWithButton(0)
end

-- ====== ФУНКЦИИ ДОСТИЖЕНИЙ ======
function saveAchievements()
    local data = {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        table.insert(data, {
            id = ach.id,
            progress = ach.progress,
            completed = ach.completed,
        })
    end
    local saveData = {
        achievements = data,
        totalCompletedGoals = totalCompletedGoals,
    }
    local file = io.open(achievementsPath, "w")
    if file then
        file:write(encodeJson(saveData))
        file:close()
    end
end

function loadAchievements()
    local file = io.open(achievementsPath, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if not data then return end
    
    if data.totalCompletedGoals then
        totalCompletedGoals = data.totalCompletedGoals
    end
    
    if data.achievements then
        for _, saved in ipairs(data.achievements) do
            for _, ach in ipairs(ACHIEVEMENTS) do
                if ach.id == saved.id then
                    ach.progress = saved.progress or 0
                    ach.completed = saved.completed or false
                    break
                end
            end
        end
    end
end

local processedGoalAchievements = {}

function checkAchievements()
    local earned = false

    for _, ach in ipairs(ACHIEVEMENTS) do
        if not ach.completed then
            local shouldProgress = false

            if ach.check then

                
                if ach.id:find("_goal") then
                    local goalName = ach.id:gsub("_goal","")

                    if ach.check() and not processedGoalAchievements[goalName] then
                        shouldProgress = true
                        processedGoalAchievements[goalName] = true
                    end

                else
                    
                    if ach.check() then
                        shouldProgress = true
                    end
                end
            end

            if shouldProgress then
                ach.progress = ach.progress + 1

                if ach.progress >= ach.target then
                    ach.completed = true
                    earned = true

                    if settings.goalSoundEnabled then
                        playSoundFile(
                            "achiv.wav",
                            settings.goalSoundVolume
                        )
                    end

                    if settings.chatNotifyEnabled then
                        sampAddChatMessage(
                            SCRIPT_PREFIX ..
                            "Достижение \"" ..
                            ach.name ..
                            "\" выполнено!",
                            SCRIPT_COLOR
                        )
                    end
                end

                saveAchievements()
            end
        end
    end

    return earned
end

function getTotalResource(resourceName)
    local total = 0

    local paths = {
        configs[WORK_TYPES.FARM].statsPath,
        configs[WORK_TYPES.MINE].statsPath,
        configs[WORK_TYPES.SAWMILL].statsPath,
    }
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local content = file:read("*all")
            file:close()
            for amount in content:gmatch('"resource":"' .. resourceName .. '","amount":(%d+)') do
                total = total + tonumber(amount)
            end
        end
    end
    return total
end

function updateProgressAchievements()
    for _, ach in ipairs(ACHIEVEMENTS) do
        if not ach.completed and ach.check == nil then
            local newProgress = 0
            
            if ach.id == "farmer_pro" then
                -- Сумма дохода с фермы за всё время (из файла статистики)
                local farmFile = io.open(configs[WORK_TYPES.FARM].statsPath, "r")
                if farmFile then
                    local content = farmFile:read("*all")
                    farmFile:close()
                    local farmPrices = {}
                    local pf = io.open(farmPricesPath, "r")
                    if pf then
                        for line in pf:lines() do
                            local k, v = line:match("^(.-)=(.*)$")
                            if k and v then farmPrices[k] = tonumber(v) end
                        end
                        pf:close()
                    end
                    for resource, amount in content:gmatch('"resource":"([^"]+)","amount":(%d+)') do
                        local price = farmPrices[resource] or configs[WORK_TYPES.FARM].defaultPrices[resource] or 0
                        newProgress = newProgress + (tonumber(amount) * price)
                    end
                end
            elseif ach.id == "miner_pro" then
                local mineFile = io.open(configs[WORK_TYPES.MINE].statsPath, "r")
                if mineFile then
                    local content = mineFile:read("*all")
                    mineFile:close()
                    local minePrices = {}
                    local pf = io.open(minePricesPath, "r")
                    if pf then
                        for line in pf:lines() do
                            local k, v = line:match("^(.-)=(.*)$")
                            if k and v then minePrices[k] = tonumber(v) end
                        end
                        pf:close()
                    end
                    for resource, amount in content:gmatch('"resource":"([^"]+)","amount":(%d+)') do
                        local price = minePrices[resource] or configs[WORK_TYPES.MINE].defaultPrices[resource] or 0
                        newProgress = newProgress + (tonumber(amount) * price)
                    end
                end
            elseif ach.id == "sawmill_pro" then
                local sawFile = io.open(configs[WORK_TYPES.SAWMILL].statsPath, "r")
                if sawFile then
                    local content = sawFile:read("*all")
                    sawFile:close()
                    local sawPrices = {}
                    local pf = io.open(sawmillPricesPath, "r")
                    if pf then
                        for line in pf:lines() do
                            local k, v = line:match("^(.-)=(.*)$")
                            if k and v then sawPrices[k] = tonumber(v) end
                        end
                        pf:close()
                    end
                    for resource, amount in content:gmatch('"resource":"([^"]+)","amount":(%d+)') do
                        local price = sawPrices[resource] or configs[WORK_TYPES.SAWMILL].defaultPrices[resource] or 0
                        newProgress = newProgress + (tonumber(amount) * price)
                    end
                end
                        elseif ach.id == "millionaire" then
                -- Суммируем доход со всех трёх работ
                local totalIncome = 0
                
                -- Ферма
                local farmFile = io.open(configs[WORK_TYPES.FARM].statsPath, "r")
                if farmFile then
                    local content = farmFile:read("*all")
                    farmFile:close()
                    local farmPrices = {}
                    local pf = io.open(farmPricesPath, "r")
                    if pf then
                        for line in pf:lines() do
                            local k, v = line:match("^(.-)=(.*)$")
                            if k and v then farmPrices[k] = tonumber(v) end
                        end
                        pf:close()
                    end
                    for resource, amount in content:gmatch('"resource":"([^"]+)","amount":(%d+)') do
                        local price = farmPrices[resource] or configs[WORK_TYPES.FARM].defaultPrices[resource] or 0
                        totalIncome = totalIncome + (tonumber(amount) * price)
                    end
                end
                
                -- Шахта
                local mineFile = io.open(configs[WORK_TYPES.MINE].statsPath, "r")
                if mineFile then
                    local content = mineFile:read("*all")
                    mineFile:close()
                    local minePrices = {}
                    local pf = io.open(minePricesPath, "r")
                    if pf then
                        for line in pf:lines() do
                            local k, v = line:match("^(.-)=(.*)$")
                            if k and v then minePrices[k] = tonumber(v) end
                        end
                        pf:close()
                    end
                    for resource, amount in content:gmatch('"resource":"([^"]+)","amount":(%d+)') do
                        local price = minePrices[resource] or configs[WORK_TYPES.MINE].defaultPrices[resource] or 0
                        totalIncome = totalIncome + (tonumber(amount) * price)
                    end
                end
                
                -- Лесопилка
                local sawFile = io.open(configs[WORK_TYPES.SAWMILL].statsPath, "r")
                if sawFile then
                    local content = sawFile:read("*all")
                    sawFile:close()
                    local sawPrices = {}
                    local pf = io.open(sawmillPricesPath, "r")
                    if pf then
                        for line in pf:lines() do
                            local k, v = line:match("^(.-)=(.*)$")
                            if k and v then sawPrices[k] = tonumber(v) end
                        end
                        pf:close()
                    end
                    for resource, amount in content:gmatch('"resource":"([^"]+)","amount":(%d+)') do
                        local price = sawPrices[resource] or configs[WORK_TYPES.SAWMILL].defaultPrices[resource] or 0
                        totalIncome = totalIncome + (tonumber(amount) * price)
                    end
                end
				
				-- Item Market
                for _, log in ipairs(itemMarketLog) do
                    totalIncome = totalIncome + log.amount
                end
                
                newProgress = totalIncome
            -- Коллекционеры — Ферма
            elseif ach.id == "flax_collector" then
                newProgress = getTotalResource("flax")
            elseif ach.id == "cotton_collector" then
                newProgress = getTotalResource("cotton")
            elseif ach.id == "rare_tkan_collector" then
                newProgress = getTotalResource("rare_tkan")
            elseif ach.id == "water_collector" then
                newProgress = getTotalResource("water")
            elseif ach.id == "dye_collector" then
                newProgress = getTotalResource("dye")
            elseif ach.id == "coal_collector" then
                newProgress = getTotalResource("coal")
            -- Коллекционеры — Шахта
            elseif ach.id == "stone_collector" then
                newProgress = getTotalResource("stone")
            elseif ach.id == "metal_collector" then
                newProgress = getTotalResource("metal")
            elseif ach.id == "bronze_collector" then
                newProgress = getTotalResource("bronze")
            elseif ach.id == "silver_collector" then
                newProgress = getTotalResource("silver")
            elseif ach.id == "gold_collector" then
                newProgress = getTotalResource("gold")
            elseif ach.id == "diamond_collector" then
                newProgress = getTotalResource("diamond")
            elseif ach.id == "tkan_collector" then
                newProgress = getTotalResource("tkan")
            elseif ach.id == "splav_collector" then
                newProgress = getTotalResource("splav")
            elseif ach.id == "materia_collector" then
                newProgress = getTotalResource("materia")
            elseif ach.id == "azbox_collector" then
                newProgress = getTotalResource("azbox")
            -- Коллекционеры — Лесопилка
            elseif ach.id == "firewood_collector" then
                newProgress = getTotalResource("firewood")
            elseif ach.id == "quality_wood_collector" then
                newProgress = getTotalResource("quality_wood")
			elseif ach.id == "im_1b" then
                newProgress = getTotalItemMarketIncome()
            elseif ach.id == "im_2_5b" then
                newProgress = getTotalItemMarketIncome()
            elseif ach.id == "im_5b" then
                newProgress = getTotalItemMarketIncome()
            elseif ach.id == "goal_hunter" then
                newProgress = totalCompletedGoals
            end
            
            ach.progress = newProgress
            if ach.progress >= ach.target and ach.target > 0 then
                ach.completed = true
                if settings.goalSoundEnabled then playSoundFile("achiv.wav", settings.goalSoundVolume) end
                if settings.chatNotifyEnabled then
                    sampAddChatMessage(SCRIPT_PREFIX .. "Достижение \"" .. ach.name .. "\" выполнено!", SCRIPT_COLOR)
                end
            end
            saveAchievements()
        end
    end
end

-- ====== СОХРАНЕНИЕ/ЗАГРУЗКА БАЗЫ ИНВЕНТАРЯ ======
function saveInventoryBase()
    local path
    if currentWork == WORK_TYPES.FARM then path = farmBasePath
    elseif currentWork == WORK_TYPES.MINE then path = mineBasePath
    else path = sawmillBasePath end
    local file = io.open(path, "w")
    if not file then return end
    file:write("{\n")
    local first = true
    for itemId, slots in pairs(inventoryCache) do
        if #slots > 0 then
            if not first then file:write(",\n") end
            first = false
            file:write('  "' .. itemId .. '": [')
            for i, amount in ipairs(slots) do
                if i > 1 then file:write(", ") end
                file:write(amount)
            end
            file:write(']')
        end
    end
    file:write('\n}')
    file:close()
end

function loadInventoryBase()
    local path
    if currentWork == WORK_TYPES.FARM then path = farmBasePath
    elseif currentWork == WORK_TYPES.MINE then path = mineBasePath
    else path = sawmillBasePath end
    local file = io.open(path, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    for itemId, amounts in content:gmatch('"(%d+)":%s*%[([^%]]+)%]') do
        local slots = {}
        for amount in amounts:gmatch("%d+") do
            table.insert(slots, tonumber(amount))
        end
        if #slots > 0 then
            inventoryCache[tonumber(itemId)] = slots
        end
    end
    scanState.scanned = true
    ignoreInventoryUntil = os.time() + 3
end

function saveThemeConfig()
    local data = { 
        theme = currentTheme,
        useCustom = useCustomTheme 
    }
    local file = io.open(themeConfigPath, "w")
    if file then
        file:write(encodeJson(data))
        file:close()
    end
end

function loadThemeConfig()
    local file = io.open(themeConfigPath, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if data then
        if data.theme then currentTheme = data.theme end
        if data.useCustom ~= nil then useCustomTheme = data.useCustom end
    end
end

function saveCustomTheme()
    local data = {}
    for k, v in pairs(CUSTOM_THEME) do
        data[k] = {v.x, v.y, v.z, v.w}
    end
    local file = io.open(customThemePath, "w")
    if file then
        file:write(encodeJson(data))
        file:close()
    end
end

function loadCustomTheme()
    local file = io.open(customThemePath, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if not data then return end
    for k, v in pairs(data) do
        if type(v) == "table" and #v == 4 then
            CUSTOM_THEME[k] = imgui.ImVec4(v[1], v[2], v[3], v[4])
        end
    end
end

function resetCustomTheme()
    CUSTOM_THEME.accent = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.leftPanelBg = imgui.ImVec4(0.055, 0.055, 0.055, 1.0)
    CUSTOM_THEME.rightPanelBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0)
    CUSTOM_THEME.buttonActive = imgui.ImVec4(0.118, 0.239, 0.118, 1.0)
    CUSTOM_THEME.buttonHover = imgui.ImVec4(0.165, 0.165, 0.165, 1.0)
    CUSTOM_THEME.borderActive = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.textNormal = imgui.ImVec4(0.6, 0.6, 0.6, 1.0)
    CUSTOM_THEME.textActive = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.textHover = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
    CUSTOM_THEME.headerTitle = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.titleBg = imgui.ImVec4(0.055, 0.055, 0.055, 1.0)
    CUSTOM_THEME.rightTitleBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0)
    CUSTOM_THEME.windowBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0)
    CUSTOM_THEME.childBg = imgui.ImVec4(0.078, 0.078, 0.078, 1.0)
    CUSTOM_THEME.borderColor = imgui.ImVec4(0.165, 0.165, 0.165, 1.0)
	CUSTOM_THEME.contentText = imgui.ImVec4(0.9, 0.9, 0.9, 1.0)
    CUSTOM_THEME.imguiButton = imgui.ImVec4(0.2, 0.2, 0.2, 0.6)
    CUSTOM_THEME.imguiButtonHovered = imgui.ImVec4(0.26, 0.98, 0.26, 0.4)
    CUSTOM_THEME.imguiButtonActive = imgui.ImVec4(0.26, 0.98, 0.26, 0.6)
    CUSTOM_THEME.collapsingHeader = imgui.ImVec4(0.22, 0.22, 0.22, 0.5)
    CUSTOM_THEME.collapsingHeaderHovered = imgui.ImVec4(0.26, 0.98, 0.26, 0.4)
    CUSTOM_THEME.collapsingHeaderActive = imgui.ImVec4(0.26, 0.98, 0.26, 0.6)
    CUSTOM_THEME.separatorColor = imgui.ImVec4(0.2, 0.2, 0.2, 1.0)
    CUSTOM_THEME.progressBar = imgui.ImVec4(0.26, 0.98, 0.26, 0.6)
    CUSTOM_THEME.checkMark = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.sliderGrab = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.sliderGrabActive = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
    CUSTOM_THEME.frameBg = imgui.ImVec4(0.2, 0.2, 0.2, 0.54)
    CUSTOM_THEME.frameBgHovered = imgui.ImVec4(0.3, 0.3, 0.3, 0.4)
    CUSTOM_THEME.frameBgActive = imgui.ImVec4(0.26, 0.98, 0.26, 0.3)
    CUSTOM_THEME.titleBgActive = imgui.ImVec4(0.1, 0.1, 0.1, 1.0)
    CUSTOM_THEME.titleBgCollapsed = imgui.ImVec4(0.0, 0.0, 0.0, 0.51)
end

-- Конвертация ImVec4 в HEX для drawList
local function imVec4ToHex(v)
    if type(v) == "number" then
        return v 
    end
    local a = math.floor(v.w * 255)
    local r = math.floor(v.x * 255)
    local g = math.floor(v.y * 255)
    local b = math.floor(v.z * 255)
    return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r
end

local function hexToImVec4(hex)
    local a = math.floor(hex / 0x1000000) / 255
    local r = math.floor((hex % 0x1000000) / 0x10000) / 255
    local g = math.floor((hex % 0x10000) / 0x100) / 255
    local b = math.floor(hex % 0x100) / 255
    return imgui.ImVec4(r, g, b, a)
end

function saveItemMarketStats()
    local file = io.open(itemMarketStatsPath, "w")
    if not file then return end
    file:write('{\n  "logs": [\n')
    for i, log in ipairs(itemMarketLog) do
        file:write('    {"time":' .. log.time .. ',"nick":"' .. log.nick .. '","amount":' .. log.amount .. '}')
        if i < #itemMarketLog then file:write(',\n') else file:write('\n') end
    end
    file:write('  ]\n}')
    file:close()
end

function loadItemMarketStats()
    itemMarketLog = {}
    local f = io.open(itemMarketStatsPath, "r")
    if not f then return end
    local content = f:read("*all")
    f:close()
    
    local cleaned = content:gsub("%s+", "")
    
    for time, nick, amount in cleaned:gmatch('{"time":(%d+),"nick":"([^"]+)","amount":(%d+)}') do
        table.insert(itemMarketLog, {time = tonumber(time), nick = nick, amount = tonumber(amount)})
    end
    
    table.sort(itemMarketLog, function(a, b) return a.time > b.time end)
    
    itemMarketTodayIncome = 0
    local gameDate = getGameDate()
    for _, log in ipairs(itemMarketLog) do
        if getGameDate(log.time) == gameDate then
            itemMarketTodayIncome = itemMarketTodayIncome + log.amount
        end
    end
end

function getItemMarketWeekIncome()
    if cachedIMWeekTime and os.time() - cachedIMWeekTime < 5 then
        return itemMarketWeekIncome
    end
    
    local mskTime = getMoscowTime()
    local mskWday = tonumber(os.date("%w", mskTime))
    if mskWday == 0 then mskWday = 7 end
    
    -- Понедельник текущей недели
    local daysSinceMonday = mskWday - 1
    local mondayTime = os.time() - (daysSinceMonday * 86400)
    local mondayDate = getGameDate(mondayTime)
    
    itemMarketWeekIncome = 0
    
    -- Считаем с понедельника по сегодня
    for i = 0, daysSinceMonday do
        local date = getGameDate(os.time() - i * 86400)
        for _, log in ipairs(itemMarketLog) do
            if getGameDate(log.time) == date then
                itemMarketWeekIncome = itemMarketWeekIncome + log.amount
            end
        end
    end
    
    cachedIMWeekTime = os.time()
    return itemMarketWeekIncome
end

function getTotalItemMarketIncome()
    local total = 0
    for _, log in ipairs(itemMarketLog) do
        total = total + log.amount
    end
    return total
end

-- ====== СОХРАНЕНИЕ/ЗАГРУЗКА ======
function saveStats()
    local file = io.open(config.statsPath, "w")
    if not file then return end
    file:write("{\n  \"logs\": [\n")
    for i, log in ipairs(resourceLog) do
        file:write('    {"time":' .. log.time .. ',"resource":"' .. log.resource .. '","amount":' .. log.amount .. ',"value":' .. log.value .. '}')
        if i < #resourceLog then file:write(',\n') else file:write('\n') end
    end
    file:write('  ]\n}')
    file:close()
    
    -- Сохраняем хеш для проверки целостности
    local hash = getFileHash(config.statsPath)
    local hashFile = io.open(config.statsPath .. ".hash", "w")
    if hashFile then hashFile:write(hash); hashFile:close() end
end

function loadStats()
    if loadedLogs then return end
    
    local file = io.open(config.statsPath, "r")
    if not file then loadedLogs = true; return end
    local content = file:read("*all")
    file:close()
    
    -- Проверяем целостность файла
    local hashFile = io.open(config.statsPath .. ".hash", "r")
    if hashFile then
        local savedHash = hashFile:read("*line") or ""
        hashFile:close()
        local currentHash = getFileHash(config.statsPath)
        if savedHash ~= "" and currentHash ~= savedHash then
            -- Файл изменён вручную!
            sampAddChatMessage(SCRIPT_PREFIX .. "Обнаружено вмешательство в файлы статистики! Подозрительные данные удалены.", SCRIPT_COLOR)
            resourceLog = {}
            saveStats()
            loadedLogs = true
            return
        end
    else
        -- Хеша нет — создаём (первый запуск с защитой)
        saveStats()
    end
    
    resourceLog = {}
    for time, resource, amount, value in content:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+),"value":(%d+)') do
        table.insert(resourceLog, {time = tonumber(time), resource = resource, amount = tonumber(amount), value = tonumber(value)})
    end
    loadedLogs = true
end

function saveGoals(workType)
    local cfg = configs[workType or currentWork]
    local path
    if workType == WORK_TYPES.FARM then
        path = farmGoalsConfigPath
    elseif workType == WORK_TYPES.MINE then
        path = mineGoalsConfigPath
    elseif workType == WORK_TYPES.SAWMILL then
        path = sawmillGoalsConfigPath
    else
        path = (currentWork == WORK_TYPES.FARM) and farmGoalsConfigPath or (currentWork == WORK_TYPES.MINE) and mineGoalsConfigPath or sawmillGoalsConfigPath
    end
    
    local data = {}
    for _, k in ipairs(cfg.resourceOrder) do
        data[k] = goalEdit[k] and goalEdit[k].v or cfg.defaultGoals[k]
    end
    
    local file = io.open(path, "w")
    if file then
        file:write(encodeJson(data))
        file:close()
    end
end

function loadGoals()
    local path
    if currentWork == WORK_TYPES.FARM then
        path = farmGoalsConfigPath
    elseif currentWork == WORK_TYPES.MINE then
        path = mineGoalsConfigPath
    else
        path = sawmillGoalsConfigPath
    end
    local cfg = config
    local file = io.open(path, "r")
    if not file then
        for _, k in ipairs(cfg.resourceOrder) do goals[k] = cfg.defaultGoals[k] end
        saveGoals()
        for _, k in ipairs(cfg.resourceOrder) do if goalEdit[k] then goalEdit[k].v = goals[k] end end
        return
    end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if not data then
        for _, k in ipairs(cfg.resourceOrder) do goals[k] = cfg.defaultGoals[k] end
    else
        for _, k in ipairs(cfg.resourceOrder) do
            goals[k] = data[k] or cfg.defaultGoals[k]
            if goalEdit[k] then goalEdit[k].v = goals[k] end
        end
    end
end

function loadGoalsForWorkType(workType)
    local cfg = configs[workType]
    local path
    if workType == WORK_TYPES.FARM then path = farmGoalsConfigPath
    elseif workType == WORK_TYPES.MINE then path = mineGoalsConfigPath
    else path = sawmillGoalsConfigPath end
    local file = io.open(path, "r")
    if not file then
        for _, k in ipairs(cfg.resourceOrder) do 
            goals[k] = cfg.defaultGoals[k]
            if not goalEdit[k] then goalEdit[k] = imgui.ImInt(cfg.defaultGoals[k]) end
            goalEdit[k].v = cfg.defaultGoals[k]
        end
        return
    end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if not data then
        for _, k in ipairs(cfg.resourceOrder) do 
            goals[k] = cfg.defaultGoals[k]
            if not goalEdit[k] then goalEdit[k] = imgui.ImInt(cfg.defaultGoals[k]) end
            goalEdit[k].v = cfg.defaultGoals[k]
        end
    else
        for _, k in ipairs(cfg.resourceOrder) do
            goals[k] = data[k] or cfg.defaultGoals[k]
            if not goalEdit[k] then goalEdit[k] = imgui.ImInt(goals[k]) end
            goalEdit[k].v = goals[k]
        end
    end
end


-- ====== СОХРАНЕНИЕ/ЗАГРУЗКА ПРОГРЕССА ЦЕЛЕЙ ======
function saveGoalsProgress()
    local path
    if currentWork == WORK_TYPES.FARM then path = farmGoalsProgressPath
    elseif currentWork == WORK_TYPES.MINE then path = mineGoalsProgressPath
    else path = sawmillGoalsProgressPath end
    local data = {}
    for _, k in ipairs(config.resourceOrder) do
        data[k] = {
            reached = goalsReached[k] or false,
            amount = dailyResources[k] or 0
        }
    end
    data.dailyTotal = dailyTotal or 0
    local file = io.open(path, "w")
    if file then
        file:write(encodeJson(data))
        file:close()
    end
end

function loadGoalsProgress()
    local path
    if currentWork == WORK_TYPES.FARM then path = farmGoalsProgressPath
    elseif currentWork == WORK_TYPES.MINE then path = mineGoalsProgressPath
    else path = sawmillGoalsProgressPath end
    local file = io.open(path, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if not data then return end
    for _, k in ipairs(config.resourceOrder) do
        if data[k] then
            goalsReached[k] = data[k].reached or false
            dailyResources[k] = data[k].amount or 0
        end
    end
    dailyTotal = data.dailyTotal or 0
end

function checkChangelog()
    local shownVersion = ""
    if doesFileExist(changelogPath) then
        local f = io.open(changelogPath, "r")
        if f then
            shownVersion = f:read("*line") or ""
            f:close()
        end
    end
    if shownVersion ~= scr.version then
        changelogShown = false
    else
        changelogShown = true
    end
end

function markChangelogAsShown()
    local f = io.open(changelogPath, "w")
    if f then
        f:write(scr.version)
        f:close()
    end
    changelogShown = true
end

local changelogMessageShown = false  

function downloadChangelog()
    local dir = getWorkingDirectory().."/ResHelper/files/changelog.json"
    local checked = false
    changelogMessageShown = false  
    downloadUrlToFile(changelogUrl, dir, function(id, status, p1, p2)
        if checked then return end
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            checked = true
            if doesFileExist(dir) then
                local f = io.open(dir, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    local converted = encoding.UTF8:decode(content)
                    changelogData = decodeJson(converted)
                    if changelogData then
                        if not changelogMessageShown then  
                            sampAddChatMessage(SCRIPT_PREFIX .. "Список изменений успешно загружен!", SCRIPT_COLOR)
                            changelogMessageShown = true  
                        end
                    else
                        if not changelogMessageShown then  
                            sampAddChatMessage(SCRIPT_PREFIX .. "Ошибка при чтении списка изменений!", SCRIPT_COLOR)
                            changelogMessageShown = true
                        end
                    end
                end
            end
        elseif status == dlstatus.STATUSEX_ENDDOWNLOAD then
            if not checked then
                checked = true
                if not changelogMessageShown then  
                    sampAddChatMessage(SCRIPT_PREFIX .. "Ошибка при загрузке списка изменений!", SCRIPT_COLOR)
                    changelogMessageShown = true  
                end
            end
        end
    end)
end

-- ====== СБРОС ЦЕЛЕЙ ======
function checkAndResetDaily()
    local mskTime = getMoscowTime()
local gameDate = getGameDate()
local mskHour = tonumber(os.date("%H", mskTime))
    
    local resetFile = configDir .. "last_reset_date.txt"
    local savedDate = ""
    if doesFileExist(resetFile) then
        local f = io.open(resetFile, "r")
        if f then
            savedDate = f:read("*line") or ""
            f:close()
        end
    end
    
    -- Сбрасываем только если игровая дата изменилась и время >= 05:00 МСК
    if savedDate ~= gameDate and mskHour >= 5 then
	 processedGoalAchievements = {}
        local f = io.open(resetFile, "w")
        if f then
            f:write(gameDate)
            f:close()
        end
        
        -- Сбрасываем цели для ВСЕХ типов работ
        -- Ферма
        local farmProgressPath = configDir .. "farm_goals_progress.json"
        local farmData = {}
        for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
            farmData[k] = {reached = false, amount = 0}
        end
        farmData.dailyTotal = 0
        local farmFile = io.open(farmProgressPath, "w")
        if farmFile then
            farmFile:write(encodeJson(farmData))
            farmFile:close()
        end
        
        -- Шахта
        local mineProgressPath = configDir .. "mine_goals_progress.json"
        local mineData = {}
        for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
            mineData[k] = {reached = false, amount = 0}
        end
        mineData.dailyTotal = 0
        local mineFile = io.open(mineProgressPath, "w")
        if mineFile then
            mineFile:write(encodeJson(mineData))
            mineFile:close()
        end
        
        -- Лесопилка
        local sawmillProgressPath = configDir .. "sawmill_goals_progress.json"
        local sawmillData = {}
        for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
            sawmillData[k] = {reached = false, amount = 0}
        end
        sawmillData.dailyTotal = 0
        local sawmillFile = io.open(sawmillProgressPath, "w")
        if sawmillFile then
            sawmillFile:write(encodeJson(sawmillData))
            sawmillFile:close()
        end
        
        -- Сбрасываем текущие значения в памяти для текущего типа работы
        for _, k in ipairs(config.resourceOrder) do
            goalsReached[k] = false
            sessionResources[k] = 0
            dailyResources[k] = 0
        end
        sessionTotal = 0
        dailyTotal = 0
        sessionStartTime = os.time()
        
        -- Сбрасываем общую цель дохода
        totalIncomeGoalReached = false
        totalDailyIncome = 0
        totalIncomeCacheTime = 0
        saveTotalIncomeGoal()
        
        -- Сбрасываем кэш статистики
        cachedTodayStats = nil
        cachedTodayTime = 0
        cachedWeekStats = nil
        cachedWeekTime = 0
        
		itemMarketTodayIncome = 0
        cachedIMWeekTime = 0
		
        saveGoalsProgress()
        sampAddChatMessage(SCRIPT_PREFIX .. "Новый день! Статистика и цели всех работ сброшены. (05:00 МСК)", SCRIPT_COLOR)
    end
    
    -- Если файла нет, создаем его с текущей игровой датой
    if not doesFileExist(resetFile) then
        local f = io.open(resetFile, "w")
        if f then
            f:write(gameDate)
            f:close()
        end
    end
end

function saveConfig()
    local file = io.open(configPath, "w")
    if not file then return end
    file:write("[Settings]\ncurrentWork=" .. currentWork .. "\n")
    file:write("chatNotifyEnabled=" .. (settings.chatNotifyEnabled and "1" or "0") .. "\n")
    file:write("goalSoundEnabled=" .. (settings.goalSoundEnabled and "1" or "0") .. "\n")
    file:write("pickupSoundEnabled=" .. (settings.pickupSoundEnabled and "1" or "0") .. "\n")
    file:write("goalSoundVolume=" .. settings.goalSoundVolume .. "\n")
    file:write("pickupSoundVolume=" .. settings.pickupSoundVolume .. "\n")
    file:write("farmOverlayEnabled=" .. (settings.farmOverlayEnabled and "1" or "0") .. "\n")
    file:write("mineOverlayEnabled=" .. (settings.mineOverlayEnabled and "1" or "0") .. "\n")
    file:write("farmEnabled=" .. (settings.farmEnabled and "1" or "0") .. "\n")
    file:write("undermineEnabled=" .. (settings.undermineEnabled and "1" or "0") .. "\n")
    file:write("underminelavkaEnabled=" .. (settings.underminelavkaEnabled and "1" or "0") .. "\n")
    file:write("regularmineEnabled=" .. (settings.regularmineEnabled and "1" or "0") .. "\n")
	file:write("overlayTimerEnabled=" .. (settings.overlayTimerEnabled and "1" or "0") .. "\n")
	file:write("totalIncomeGoal=" .. settings.totalIncomeGoal .. "\n")
	file:write("sawmillOverlayEnabled=" .. (settings.sawmillOverlayEnabled and "1" or "0") .. "\n")
    file:write("sawmillEnabled=" .. (settings.sawmillEnabled and "1" or "0") .. "\n")
	file:write("useCustomTheme=" .. (useCustomTheme and "1" or "0") .. "\n")
	file:write("pickupSoundFile=" .. (settings.pickupSoundFile or "pickup.wav") .. "\n")
file:write("rareSoundFile=" .. (settings.rareSoundFile or "rare.wav") .. "\n")
file:write("coalSoundFile=" .. (settings.coalSoundFile or "ugol.wav") .. "\n")
file:write("achivSoundFile=" .. (settings.achivSoundFile or "achiv.wav") .. "\n")
file:write("rareSoundVolume=" .. (settings.rareSoundVolume or 80) .. "\n")
file:write("coalSoundVolume=" .. (settings.coalSoundVolume or 80) .. "\n")
    file:close()
end

function loadConfig()
    local file = io.open(configPath, "r")
    if not file then
        for k, v in pairs(config.defaultPrices) do resourcePrices[k] = v; if not priceEdit[k] then priceEdit[k] = imgui.ImInt(v) else priceEdit[k].v = v end end
        saveConfig()
        return
    end
    local section = ""
    for line in file:lines() do
        local sec = line:match("^%[(.*)%]$")
        if sec then section = sec
        else
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then
                if section == "Settings" then
                    if k == "currentWork" then currentWork = tonumber(v) or WORK_TYPES.FARM
                    elseif k == "chatNotifyEnabled" then settings.chatNotifyEnabled = (v == "1")
                    elseif k == "goalSoundEnabled" then settings.goalSoundEnabled = (v == "1")
                    elseif k == "pickupSoundEnabled" then settings.pickupSoundEnabled = (v == "1")
                    elseif k == "goalSoundVolume" then settings.goalSoundVolume = tonumber(v) or 80
                    elseif k == "pickupSoundVolume" then settings.pickupSoundVolume = tonumber(v) or 80
                    elseif k == "farmOverlayEnabled" then settings.farmOverlayEnabled = (v == "1")
                    elseif k == "mineOverlayEnabled" then settings.mineOverlayEnabled = (v == "1")
                    elseif k == "farmEnabled" then settings.farmEnabled = (v == "1")
					elseif k == "pickupSoundFile" then settings.pickupSoundFile = v or "pickup.wav"
elseif k == "rareSoundFile" then settings.rareSoundFile = v or "rare.wav"
elseif k == "coalSoundFile" then settings.coalSoundFile = v or "ugol.wav"
elseif k == "achivSoundFile" then settings.achivSoundFile = v or "achiv.wav"
elseif k == "rareSoundVolume" then settings.rareSoundVolume = tonumber(v) or 80
elseif k == "coalSoundVolume" then settings.coalSoundVolume = tonumber(v) or 80
                    elseif k == "undermineEnabled" then settings.undermineEnabled = (v == "1")
                    elseif k == "underminelavkaEnabled" then settings.underminelavkaEnabled = (v == "1")
                    elseif k == "regularmineEnabled" then settings.regularmineEnabled = (v == "1") 
					elseif k == "overlayTimerEnabled" then settings.overlayTimerEnabled = (v == "1") 
					elseif k == "totalIncomeGoal" then settings.totalIncomeGoal = tonumber(v) or 1000000 
					elseif k == "sawmillOverlayEnabled" then settings.sawmillOverlayEnabled = (v == "1")
                    elseif k == "sawmillEnabled" then settings.sawmillEnabled = (v == "1") 
					elseif k == "useCustomTheme" then useCustomTheme = (v == "1") end
                end
            end
        end
    end
    file:close()
    switchWorkType(currentWork, true)
end

-- ====== НОВАЯ СИСТЕМА ЦЕН ======
function savePrices()
    if currentWork == WORK_TYPES.FARM then
        local file = io.open(farmPricesPath, "w")
        if file then
            for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
                file:write(k .. "=" .. (resourcePrices[k] or configs[WORK_TYPES.FARM].defaultPrices[k]) .. "\n")
            end
            file:close()
        end
    elseif currentWork == WORK_TYPES.MINE then
        local file = io.open(minePricesPath, "w")
        if file then
            for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
                file:write(k .. "=" .. (resourcePrices[k] or configs[WORK_TYPES.MINE].defaultPrices[k]) .. "\n")
            end
            file:close()
        end
    else
        local file = io.open(sawmillPricesPath, "w")
        if file then
            for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
                file:write(k .. "=" .. (resourcePrices[k] or configs[WORK_TYPES.SAWMILL].defaultPrices[k]) .. "\n")
            end
            file:close()
        end
    end
end

function loadConfigForCurrentWork()
    resourcePrices = {}
    for _, k in ipairs(config.resourceOrder) do
        resourcePrices[k] = config.defaultPrices[k]
    end
    local priceFile
    if currentWork == WORK_TYPES.FARM then priceFile = farmPricesPath
    elseif currentWork == WORK_TYPES.MINE then priceFile = minePricesPath
    else priceFile = sawmillPricesPath end
    local file = io.open(priceFile, "r")
    if not file then 
        for k, v in pairs(resourcePrices) do
            if priceEdit[k] then priceEdit[k].v = v end
        end
        return 
    end
    for line in file:lines() do
        local k, v = line:match("^(.-)=(.*)$")
        if k and v then
            local numValue = tonumber(v)
            if numValue and resourcePrices[k] ~= nil then
                resourcePrices[k] = numValue
            end
        end
    end
    file:close()
    for k, v in pairs(resourcePrices) do
        if priceEdit[k] then priceEdit[k].v = v end
    end
end

function initPricesFile()
    if not doesFileExist(farmPricesPath) then
        local file = io.open(farmPricesPath, "w")
        if file then
            for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
                file:write(k .. "=" .. configs[WORK_TYPES.FARM].defaultPrices[k] .. "\n")
            end
            file:close()
        end
    end
    if not doesFileExist(minePricesPath) then
        local file = io.open(minePricesPath, "w")
        if file then
            for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
                file:write(k .. "=" .. configs[WORK_TYPES.MINE].defaultPrices[k] .. "\n")
            end
            file:close()
        end
    end
    if not doesFileExist(sawmillPricesPath) then
        local file = io.open(sawmillPricesPath, "w")
        if file then
            for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
                file:write(k .. "=" .. configs[WORK_TYPES.SAWMILL].defaultPrices[k] .. "\n")
            end
            file:close()
        end
    end
end

function initGoalsFiles()
    if not doesFileExist(farmGoalsConfigPath) then
        local file = io.open(farmGoalsConfigPath, "w")
        if file then
            local data = {}
            for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
                data[k] = configs[WORK_TYPES.FARM].defaultGoals[k]
            end
            file:write(encodeJson(data))
            file:close()
        end
    end
    if not doesFileExist(mineGoalsConfigPath) then
        local file = io.open(mineGoalsConfigPath, "w")
        if file then
            local data = {}
            for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
                data[k] = configs[WORK_TYPES.MINE].defaultGoals[k]
            end
            file:write(encodeJson(data))
            file:close()
        end
    end
    if not doesFileExist(sawmillGoalsConfigPath) then
        local file = io.open(sawmillGoalsConfigPath, "w")
        if file then
            local data = {}
            for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
                data[k] = configs[WORK_TYPES.SAWMILL].defaultGoals[k]
            end
            file:write(encodeJson(data))
            file:close()
        end
    end
end

function switchWorkType(newWorkType, initialLoad)
    -- Блокируем смену режима во время автосканирования
if not initialLoad and scanState.active then
    sampAddChatMessage(SCRIPT_PREFIX .. "Дождитесь завершения сканирования!", SCRIPT_COLOR)
    return
end
    if currentWork == newWorkType and not initialLoad then return end
    if not initialLoad then 
        saveInventoryBase()
        saveStats()
        saveGoalsProgress()
    end
    currentWork = newWorkType
    config = configs[currentWork]
    resources = {}
    resourcePrices = {}
    goals = {}
    goalsReached = {}
    sessionResources = {}
    dailyResources = {}
    sessionTotal = 0
	sessionStartTime = os.time()  
    dailyTotal = 0
    resourceLog = {}
    loadedLogs = false
    inventoryCache = {}
    scanState.active = false
    scanState.scanning = false
    scanState.scanned = false
    inventoryBase = {}
    loadInventoryBase()
    for _, k in ipairs(config.resourceOrder) do
        resources[k] = 0
        resourcePrices[k] = config.defaultPrices[k]
        goals[k] = config.defaultGoals[k]
        goalsReached[k] = false
        sessionResources[k] = 0
        dailyResources[k] = 0
        if not priceEdit[k] then priceEdit[k] = imgui.ImInt(resourcePrices[k]) else priceEdit[k].v = resourcePrices[k] end
        if not goalEdit[k] then goalEdit[k] = imgui.ImInt(goals[k]) else goalEdit[k].v = goals[k] end
    end
	
    loadConfigForCurrentWork()
    
    -- Перезаписываем глобальными ценами, если они уже загружены
    if globalPrices and next(globalPrices) then
        for k, v in pairs(globalPrices) do
            resourcePrices[k] = v
            if priceEdit[k] then priceEdit[k].v = v end
        end
    end
	
    loadGoals()
    loadStats()
    loadGoalsProgress()
	sessionStartTime = os.time()  
	cb_sawmill.v = settings.sawmillEnabled
    cb_farm.v = settings.farmEnabled
    cb_undermine.v = settings.undermineEnabled
    cb_lavka.v = settings.underminelavkaEnabled
    cb_regular.v = settings.regularmineEnabled
    if not initialLoad then 
        sampAddChatMessage("{00FF00}"..config.prefix.." {FFFFFF}Режим работы изменен на: " .. config.name, -1) 
    end
end

-- === ПЕРЕХВАТ ПАКЕТОВ ===
function onReceivePacket(id, bs)
    if id == 220 then
        local origPos = raknetBitStreamGetReadOffset(bs)
        raknetBitStreamReadInt8(bs)
        if raknetBitStreamReadInt8(bs) == 17 then
            raknetBitStreamReadInt32(bs)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            if length > 0 then
                local text = (encoded ~= 0)
                    and raknetBitStreamDecodeString(bs, length + encoded)
                    or raknetBitStreamReadString(bs, length)
                if text:find("event.inventory.playerInventory") then
                    -- Пропускаем обработку на 3 секунды после сканирования
                    if os.time() < ignoreInventoryUntil then
                        for itemIdStr, newAmountStr in text:gmatch('"item":(%d+),"amount":(%d+)') do
                            local itemId = tonumber(itemIdStr)
                            local newAmount = tonumber(newAmountStr)
                            if inventoryCache[itemId] then
                                local slots = inventoryCache[itemId]
                                local found = false
                                for i, slotAmount in ipairs(slots) do
                                    if newAmount == slotAmount then found = true; break
                                    elseif math.abs(newAmount - slotAmount) <= 10 then slots[i] = newAmount; found = true; break end
                                end
                                if not found then table.insert(slots, newAmount) end
                            end
                        end
                        saveInventoryBase()
                        raknetBitStreamSetReadOffset(bs, origPos)
                        return
                    end
                    
                    -- Основная логика: засчитываем только ПРИРОСТ
                    for itemIdStr, newAmountStr in text:gmatch('"item":(%d+),"amount":(%d+)') do
                        local itemId = tonumber(itemIdStr)
                        local newAmount = tonumber(newAmountStr)
                        
                        -- Определяем тип ресурса
                        local resKey = nil
                        local maxStack = nil
                        if currentWork == WORK_TYPES.FARM then
                            resKey = FARM_ITEM_TO_RES[itemId]
                            maxStack = getMaxStack(resKey)
                        elseif currentWork == WORK_TYPES.MINE then
                            if settings.undermineEnabled or settings.underminelavkaEnabled then
                                resKey = MINE_ITEM_TO_RES[itemId]
                                maxStack = getMaxStack(resKey)
                            end
                        elseif currentWork == WORK_TYPES.SAWMILL then
                            resKey = SAWMILL_ITEM_TO_RES[itemId]
                            maxStack = getMaxStack(resKey)
                        end
                        
                        if resKey and maxStack then
                            -- Игнорируем аномально большие значения (баги/лаги)
                            if newAmount > maxStack * 2 then break end
                            
                            -- Инициализируем кэш если нужно
                            if not inventoryCache[itemId] then 
                                inventoryCache[itemId] = {} 
                            end
                            
                            local slots = inventoryCache[itemId]
                            
                            -- Ищем ближайший слот для этого количества
                            local bestSlot = nil
                            local bestDiff = math.huge
                            
                            for i, slotAmount in ipairs(slots) do
                                local diff = math.abs(newAmount - slotAmount)
                                if diff < bestDiff then
                                    bestDiff = diff
                                    bestSlot = i
                                end
                            end
                            
                            if bestSlot then
                                local oldAmount = slots[bestSlot]
                                
                                -- Количество УВЕЛИЧИЛОСЬ — это добыча
                                if newAmount > oldAmount then
                                    local added = newAmount - oldAmount
                                    -- Проверяем что прирост реалистичный (не больше стака)
                                    if added > 0 and added <= maxStack then
                                        pendingResources[resKey] = added
                                        slots[bestSlot] = newAmount
                                        saveInventoryBase()
                                    elseif added > maxStack then
                                        -- Аномальный прирост, просто обновляем слот без засчитывания
                                        slots[bestSlot] = newAmount
                                        saveInventoryBase()
                                    end
                                -- Количество УМЕНЬШИЛОСЬ — продажа/использование
                                elseif newAmount < oldAmount then
                                    slots[bestSlot] = newAmount
                                    saveInventoryBase()
                                end
                                -- Если равно — ничего не делаем
                            else
                                -- Новый слот (не было в кэше)
                                table.insert(slots, newAmount)
                                saveInventoryBase()
                            end
                        end
                    end
                end
            end
        end
        raknetBitStreamSetReadOffset(bs, origPos)
    end
end

-- ====== LEADERBOARD FUNCTIONS ======

function saveLbConfig(name, enabled)
    local data = {enabled = enabled or false}
    local file = io.open(leaderboardConfigPath, "w")
    if file then file:write(encodeJson(data)); file:close() end
end

function getLbEnabled()
    local file = io.open(leaderboardConfigPath, "r")
    if not file then return false end
    local data = decodeJson(file:read("*all"))
    file:close()
    if data then return data.enabled or false end
    return false
end

function sendToLeaderboard(period, mode)
    local _, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
local name = sampGetPlayerNickname(playerId)
if not name or name == "" then return end
    if not getLbEnabled() then return end
    
    local amount = 0
    local resources = {}
    
    if mode == "Income" then
        -- Доход с фермы, шахты и лесопилки
        for _, wc in pairs(configs) do
            local prices = loadPricesForWorkType(wc)
            local data = getResourcesForPeriod(wc.statsPath, period)
            for resKey, resAmount in pairs(data) do
                local price = prices[resKey] or wc.defaultPrices[resKey] or 0
                amount = amount + (resAmount * price)
            end
        end
        -- Добавляем доход с Item Market
        if period == "Daily" then
            local td = getGameDate(os.time() - 86400)
            for _, log in ipairs(itemMarketLog) do
                if getGameDate(log.time) == td then amount = amount + log.amount end
            end
        elseif period == "Weekly" then
            local mskTime = getMoscowTime()
            local mskWday = tonumber(os.date("%w", mskTime))
            if mskWday == 0 then mskWday = 7 end
            local lastSunday = os.time() - (mskWday * 86400)
            local lastMonday = lastSunday - (6 * 86400)
            for _, log in ipairs(itemMarketLog) do
                local logDate = getGameDate(log.time)
                if logDate >= getGameDate(lastMonday) and logDate <= getGameDate(lastSunday) then
                    amount = amount + log.amount
                end
            end
        elseif period == "Total" then
            for _, log in ipairs(itemMarketLog) do
                amount = amount + log.amount
            end
        end
    elseif mode == "Farm" or mode == "Mine" or mode == "Sawmill" then
        local workType = WORK_TYPES.FARM
        if mode == "Mine" then workType = WORK_TYPES.MINE
        elseif mode == "Sawmill" then workType = WORK_TYPES.SAWMILL end
        local wc = configs[workType]
        local prices = loadPricesForWorkType(wc)
        local data = getResourcesForPeriod(wc.statsPath, period)
        
        for resKey, resAmount in pairs(data) do
            local price = prices[resKey] or wc.defaultPrices[resKey] or 0
            amount = amount + (resAmount * price)
            -- Отправляем английские ключи
            resources[resKey] = resAmount
        end
    elseif mode == "IM" then
        if period == "Daily" then
            local td = getGameDate(os.time() - 86400)
            for _, log in ipairs(itemMarketLog) do
                if getGameDate(log.time) == td then amount = amount + log.amount end
            end
        elseif period == "Weekly" then
            local mskTime = getMoscowTime()
            local mskWday = tonumber(os.date("%w", mskTime))
            if mskWday == 0 then mskWday = 7 end
            local lastSunday = os.time() - (mskWday * 86400)
            local lastMonday = lastSunday - (6 * 86400)
            for _, log in ipairs(itemMarketLog) do
                local logDate = getGameDate(log.time)
                if logDate >= getGameDate(lastMonday) and logDate <= getGameDate(lastSunday) then
                    amount = amount + log.amount
                end
            end
        elseif period == "Total" then
            for _, log in ipairs(itemMarketLog) do
                amount = amount + log.amount
            end
        end
    end
    
    if amount <= 0 then return end
    
    -- Определяем сервер по IP
    local serverName = "Unknown"
    local host = sampGetCurrentServerAddress()
    if host and host ~= "" then
        local servers = {
            ["80.66.82.132"] = "Holiday", ["185.169.134.166"] = "Prescott", ["80.66.82.82"] = "Faraway",
            ["80.66.82.54"] = "Christmas", ["80.66.82.200"] = "Queen-Creek", ["80.66.82.191"] = "Gilbert",
            ["80.66.82.168"] = "Page", ["80.66.82.113"] = "Yava", ["185.169.134.109"] = "Surprise",
            ["80.66.82.128"] = "Wednesday", ["185.169.134.44"] = "Chandler", ["185.169.134.171"] = "Glendale",
            ["80.66.82.190"] = "Show Low", ["80.66.82.144"] = "Sedona", ["185.169.134.174"] = "Payson",
            ["185.169.134.5"] = "Saint-Rose", ["80.66.82.159"] = "Sun-City", ["185.169.134.172"] = "Kingman",
            ["185.169.134.173"] = "Winslow", ["185.169.134.43"] = "Scottdale", ["185.169.134.61"] = "Red-Rock",
            ["185.169.134.45"] = "Brainburg", ["80.66.82.39"] = "Mirage", ["185.169.134.3"] = "Phoenix",
            ["185.169.134.59"] = "Mesa", ["185.169.134.4"] = "Tucson", ["185.169.134.107"] = "Yuma",
            ["80.66.82.188"] = "Casa-Grande", ["80.66.82.87"] = "Bumble Bee", ["80.66.82.33"] = "Love",
            ["80.66.82.22"] = "Drake", ["80.66.82.199"] = "Space"
        }
        serverName = servers[host] or "Unknown"
    end
    
    local rawName = u8:encode(name)
    local encodedName = ""
    for i = 1, #rawName do
        local c = rawName:sub(i, i)
        if c:match("[%w%-%.%_%~]") then encodedName = encodedName .. c
        elseif c == " " then encodedName = encodedName .. "+"
        else encodedName = encodedName .. string.format("%%%02X", string.byte(c)) end
    end
    
    local encodedServer = urlEncode(serverName)
    
    local url = LEADERBOARD_URL .. "?name=" .. encodedName .. "&amount=" .. amount .. "&period=" .. period .. "&mode=" .. mode .. "&server=" .. encodedServer
    
    if next(resources) then
        local resJson = encodeJson(resources)
        url = url .. "&resources=" .. urlEncode(resJson)
    end
    
    local asyncReq = effil.thread(function(u)
        local req = require("requests")
        req.get(u)
    end)(url)
end

function loadGlobalPrices()
    pricesLoading = true
    
    local asyncReq = effil.thread(function(u)
        local req = require("requests")
        local ok, result = pcall(req.get, u)
        if ok and result then
            local text = result.text
            local redirectUrl = text:match('HREF="([^"]+)"')
            if redirectUrl then
                redirectUrl = redirectUrl:gsub("&amp;", "&")
                local ok2, result2 = pcall(req.get, redirectUrl)
                if ok2 and result2 then return result2.text end
            end
            return text
        end
        return nil
    end)(LEADERBOARD_URL .. "?action=prices")
    
    lua_thread.create(function()
        while true do
            local status, err = asyncReq:status()
            if status == "completed" then
                local text = asyncReq:get()
                if text then
                    local data = decodeJson(text)
                    if data and next(data) then
                        globalPrices = data
                        for k, v in pairs(globalPrices) do
                            if priceEdit[k] then priceEdit[k].v = v end
                            resourcePrices[k] = v
                        end
                        -- Сохраняем дату загрузки
                        local today = getGameDate()
                        local file = io.open(pricesStatePath, "w")
                        if file then file:write(today); file:close() end
                        if not pricesLoadedMsg then
                            pricesLoadedMsg = true
                            sampAddChatMessage(SCRIPT_PREFIX .. "Цены загружены из Google Таблицы!", SCRIPT_COLOR)
                        end
                    end
                end
                pricesLoading = false
                return
            elseif status == "canceled" then
                pricesLoading = false
                return
            end
            wait(0)
        end
    end)
end

function loadPricesForWorkType(wc)
    -- Сначала пробуем глобальные цены из Google таблицы
    if globalPrices and next(globalPrices) then
        return globalPrices
    end
    -- Иначе загружаем из локального файла
    local prices = {}
    local pricePath
    if wc.name == "Ферма" then pricePath = farmPricesPath
    elseif wc.name == "Шахта" then pricePath = minePricesPath
    else pricePath = sawmillPricesPath end
    local pf = io.open(pricePath, "r")
    if pf then
        for line in pf:lines() do
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then prices[k] = tonumber(v) end
        end
        pf:close()
    end
    return prices
end

function getResourcesForPeriod(statsPath, period)
    local result = {}
    local sf = io.open(statsPath, "r")
    if not sf then return result end
    local c = sf:read("*all")
    sf:close()
    
    if period == "Daily" then
        local td = getGameDate(os.time() - 86400)
        for t, r, a in c:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            if getGameDate(tonumber(t)) == td then
                result[r] = (result[r] or 0) + tonumber(a)
            end
        end
    elseif period == "Weekly" then
        local mskTime = getMoscowTime()
        local mskWday = tonumber(os.date("%w", mskTime))
        if mskWday == 0 then mskWday = 7 end
        local lastSunday = os.time() - (mskWday * 86400)
        local lastMonday = lastSunday - (6 * 86400)
        for t, r, a in c:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            local logDate = getGameDate(tonumber(t))
            if logDate >= getGameDate(lastMonday) and logDate <= getGameDate(lastSunday) then
                result[r] = (result[r] or 0) + tonumber(a)
            end
        end
    elseif period == "Total" then
        for t, r, a in c:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            result[r] = (result[r] or 0) + tonumber(a)
        end
    end
    return result
end

function loadLeaderboard(period, mode, silent)
    mode = mode or "Income"
    if not leaderboardCache[mode] then leaderboardCache[mode] = {} end
    leaderboardCache[mode][period] = {}
    
    local asyncReq = effil.thread(function(u)
        local req = require("requests")
        local ok, result = pcall(req.get, u)
        if ok and result then
            local text = result.text
            local redirectUrl = text:match('HREF="([^"]+)"')
            if redirectUrl then
                redirectUrl = redirectUrl:gsub("&amp;", "&")
                local ok2, result2 = pcall(req.get, redirectUrl)
                if ok2 and result2 then return result2.text end
            end
        end
        return nil
    end)(LEADERBOARD_URL .. "?period=" .. period .. "&mode=" .. mode)
    
    lua_thread.create(function()
        while true do
            local status, err = asyncReq:status()
            if status == "completed" then
                local result = asyncReq:get()
                if result then
                    local decoded = u8:decode(result)
                    local data = decodeJson(decoded)
                    if data then
                        leaderboardCache[mode][period] = data
                        if not silent then
                            sampAddChatMessage(SCRIPT_PREFIX .. "Рейтинг обновлён!", SCRIPT_COLOR)
                        end
                    end
                end
                return
            elseif status == "canceled" then return end
            wait(0)
        end
    end)
end

-- ====== TELEGRAM FUNCTIONS ======

local function urlencode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w ])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

local function encodeToUrl(str)
    return (urlencode(u8:encode(str, "CP1251")))
end

local function sendTelegramMessage(text)
    if not tgConfig.enabled or tgConfig.botToken == "" or tgConfig.chatId == "" then
        return
    end
    
    local botToken = tgConfig.botToken
    local chatId = tgConfig.chatId
    local messageText = text
    
    local params = {
        text = messageText,
        chat_id = chatId,
        parse_mode = "HTML",
        disable_web_page_preview = "true"
    }
    
    local queryString = ""
    for k, v in pairs(params) do
        queryString = queryString .. k .. "=" .. encodeToUrl(v) .. "&"
    end
    queryString = queryString:gsub("&$", "")
    
    local url
    local headers = {}
    
    if tgConfig.useReserveServer then
        url = "https://149.154.167.220/bot" .. botToken .. "/sendMessage?" .. queryString
        headers = {
            ["Host"] = "api.telegram.org"
        }
    else
        url = "https://api.telegram.org/bot" .. botToken .. "/sendMessage?" .. queryString
    end
    
    local asyncReq = effil.thread(function(reqUrl, reqHeaders)
        local req = require("requests")
        local ok, result = pcall(req.get, reqUrl, { headers = reqHeaders })
        if ok and result then
            return result.text
        else
            return nil
        end
    end)(url, headers)
    
    lua_thread.create(function()
        while true do
            local status, err = asyncReq:status()
            if not err then
                if status == "completed" then
                    local text = asyncReq:get()
                    if text then
                        local respOk = text:match('"ok":(%a+)')
                        if respOk ~= "true" then
                            print("TG: Ошибка отправки")
                        end
                    end
                    return
                elseif status == "canceled" then
                    return
                end
            else
                return
            end
            wait(0)
        end
    end)
end

function hook.onServerMessage(color, text)
    if not text then return end
    if text:match("^%[%d+%]") or text:match("^.*?:") or text:match("^.*сказал") then return end
	
	   -- Лесопилка: перехват сообщений хранилища (ларцы)
    if currentWork == WORK_TYPES.SAWMILL then
        if text:match("^%[Хранилище предметов%] Добавлен новый предмет") then
            addResource("rare_box", 1)
            return
        end
    end
	
    -- Item Market 
    if text:match("^%[Item Market%]") then
        local cleanText = text:gsub("{......}", "")
        local nick = cleanText:match("^%[Item Market%] (.+) арендовал")
        local amount = 0
        
        local afterNachisleno = cleanText:match("начислено (.+)$")
        if afterNachisleno then
            -- Собираем все цифры подряд
            local digits = ""
            for d in afterNachisleno:gmatch("%d") do
                digits = digits .. d
            end
            amount = tonumber(digits) or 0
            
            -- Если есть :KK: и нет :K: после него — чистые миллионы, умножаем
            if afterNachisleno:find(":KK:") and not afterNachisleno:find(":KK:.*:K:") then
                amount = amount * 1000000
            end
        end
        
        if nick and amount > 0 then
            table.insert(itemMarketLog, 1, {time = os.time(), nick = nick, amount = amount})
            if #itemMarketLog > 200 then
                itemMarketLog[#itemMarketLog] = nil
            end
            saveItemMarketStats()
			-- Обновляем сегодняшний доход
            itemMarketTodayIncome = itemMarketTodayIncome + amount
			
-- Telegram уведомление
if tgConfig.itemMarketEnabled and amount >= 0 then
    local mskTimestamp = os.time() + 10800
    local mskDate = os.date("!*t", mskTimestamp)
    local timeStr = string.format("%02d:%02d", mskDate.hour, mskDate.min)
    local dateStr = string.format("%02d.%02d.%04d", mskDate.day, mskDate.month, mskDate.year)
local msg = string.format(
    "<b>Item Market — Аренда</b>\n\n" ..
    "Игрок: <b>%s</b>\n" ..
    "Заработано: <b>%s$</b>\n" ..
    "Время: %s (МСК)\n" ..
    "Дата: %s\n\n" ..
    "Общий заработок за сегодня: <b>%s$</b>",
    nick, formatNumber(amount), timeStr, dateStr, formatNumber(itemMarketTodayIncome)
)
    sendTelegramMessage(msg)
end
			
            if settings.chatNotifyEnabled then
                sampAddChatMessage("{00FF00}[ResHelperIM] {FFFFFF}Аренда от " .. nick .. ": +" .. formatNumber(amount) .. "$", -1)
            end
        end
        return
    end
    
    -- Ферма и Шахта: засчитываем ресурс когда приходит сообщение
    if text:match("^Вам был добавлен предмет") then
        local itemId = text:match(":item(%d+):")
        if itemId then
            local id = tonumber(itemId)
            
            -- Ферма
            if currentWork == WORK_TYPES.FARM then
                local resKey = FARM_ITEM_TO_RES[id]
                if resKey then
                    local amount = pendingResources[resKey] or 0
                    addResource(resKey, amount)
                    pendingResources[resKey] = nil
                end
            end
            
            -- Шахта (подземная/лавка)
            if currentWork == WORK_TYPES.MINE then
                if settings.undermineEnabled or settings.underminelavkaEnabled then
                    -- Проверяем, не покупка ли это (для лавки)
                    if text:find("Вы купили") then
                        if settings.underminelavkaEnabled then
                            local resKey = MINE_ITEM_TO_RES[id]
                            if resKey then
                                local amount = text:match("%((%d+) шт%.%)")
                                local removeAmount = tonumber(amount) or mineItemAmounts[resKey] or 1
                                pcall(removeResource, resKey, removeAmount)
                            end
                        end
                    else
                        -- Добыча в подземной шахте
                        local resKey = MINE_ITEM_TO_RES[id]
                        if resKey then
                            local amount = pendingResources[resKey] or 0
                            addResource(resKey, amount)
                            pendingResources[resKey] = nil
                        end
                    end
                end
            end
            
            -- Лесопилка
            if currentWork == WORK_TYPES.SAWMILL then
                local resKey = SAWMILL_ITEM_TO_RES[id]
                if resKey then
                    local amount = pendingResources[resKey] or 0
                    addResource(resKey, amount)
                    pendingResources[resKey] = nil
                end
            end
        end
        return
    end
    
    return
end

function hook.onDisplayGameText(style, tm, text)
    if not text then return end
    if currentWork == WORK_TYPES.FARM then 
        if not settings.farmEnabled then return end
        local resType, amount = text:match("^(%a+) %+(%d+)$")
        if resType and amount then 
            amount = tonumber(amount) or 1
            resType = resType:lower()
            if resType == "linen" then addResource("flax", amount) 
            elseif resType == "cotton" then addResource("cotton", amount) end 
        end
    else 
        if not settings.regularmineEnabled then return end
        if type(text) ~= "string" then return end
        local resType, amount = text:match("^(%w+)%s%+%s?(%d+)$")
        if resType and amount then 
            amount = tonumber(amount)
            if not amount or amount <= 0 then return end
            local mapping = { stone = "stone", metal = "metal", gold = "gold", silver = "silver", bronze = "bronze" }
            if mapping[resType] then 
                local success, err = pcall(addResource, mapping[resType], amount)
                if not success then sampAddChatMessage("{FF0000}[ResHelherMine] Ошибка при добавлении ресурса: " .. tostring(err), -1) end 
            end
        end
    end
end

function hook.onShowDialog(id, style, title, button1, button2, text)
    if not scanState.active or not scanState.scanning then return end
    if title and title:find("Основная статистика") then
        scanState.statusText = "Статистика открыта, ищу кнопку инвентаря..."
        local inventoryButtonIndex = nil
        if button1 and button1:find("Инвентарь") then inventoryButtonIndex = 1
        elseif button2 and button2:find("Инвентарь") then inventoryButtonIndex = 0 end
        if inventoryButtonIndex then
            scanState.statusText = "Открываю инвентарь..."
            scanState.waitForInventory = true
            sampSendDialogResponse(id, inventoryButtonIndex)
        else
            scanState.statusText = "Пробую открыть инвентарь (кнопка 1)..."
            scanState.waitForInventory = true
            sampSendDialogResponse(id, 1)
        end
        return true
    end
    if scanState.waitForInventory then
        if title and title:find("%[ID:%d+%]") then
            scanState.waitForInventory = false
            scanState.statusText = "Сканирую страницу инвентаря..."
            for line in text:gmatch("[^\r\n]+") do processInventoryLine(line) end
            if text and text:find(">> Следующая страница") then
                scanState.statusText = "Перехожу на следующую страницу..."
                scanState.waitForInventory = true
                sampSendDialogResponse(id, 1)
                return true
            else
                scanState.statusText = "Завершаю сканирование..."
                sampSendDialogResponse(id, 0)
                lua_thread.create(function() wait(500); finishScan() end)
                return true
            end
        end
    end
end

-- ====== GUI STYLE ======
function styleWin()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ScrollbarSize = 15.0
    style.WindowRounding = 2.0
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 3.0
    style.FramePadding = imgui.ImVec2(5, 3)
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.FrameBg]                = ImVec4(0.20, 0.20, 0.20, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.30, 0.30, 0.30, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.98, 0.26, 0.30)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.98, 0.26, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.26, 0.98, 0.26, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.98, 0.26, 1.00)
    colors[clr.Button]                 = ImVec4(0.20, 0.20, 0.20, 0.60)
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.98, 0.26, 0.40)
    colors[clr.ButtonActive]           = ImVec4(0.26, 0.98, 0.26, 0.60)
    colors[clr.Header]                 = ImVec4(0.22, 0.22, 0.22, 0.50)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.98, 0.26, 0.40)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.98, 0.26, 0.60)
    colors[clr.Separator]              = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.98, 0.26, 0.40)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.98, 0.26, 0.60)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.98, 0.26, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.98, 0.26, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.98, 0.26, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.98, 0.26, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(0.09, 0.09, 0.09, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]                 = ImVec4(0.20, 0.20, 0.20, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.26, 0.98, 0.26, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.30, 0.30, 0.30, 0.50)
end
styleWin()

function ButtonMenu(desk, bool)
    local retBool = false
    if bool then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(45, 230, 73, 220):GetVec4())
        retBool = imgui.Button(desk, imgui.ImVec2(140, 25))
        imgui.PopStyleColor(1)
    elseif not bool then
         retBool = imgui.Button(desk, imgui.ImVec2(140, 25))
    end
    return retBool
end

function ShowHelpMarker(stext)
    imgui.TextDisabled(u8("(?)"))
    if imgui.IsItemHovered() then
        imgui.SetTooltip(stext)
    end
end

local fa_font = nil
local fa_font_awesome = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
  if fa_font == nil then
    local font_config = imgui.ImFontConfig()
    font_config.MergeMode = true
    fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/ResHelper/files/font-icon.ttf', 15.0, font_config, fa_glyph_ranges)
  end
  if fa_font_awesome == nil then
    local faPath = getWorkingDirectory() .. "/ResHelper/files/fAwesome6.ttf"
    if doesFileExist(faPath) then
      local font_config = imgui.ImFontConfig()
      font_config.MergeMode = true
      fa_font_awesome = imgui.GetIO().Fonts:AddFontFromFileTTF(faPath, 15.0, font_config, fa_glyph_ranges)
    end
  end
end

function imgui.AchievementCard(ach)
    local width = imgui.GetWindowWidth() - 25
    local height = 80
    
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    
    -- Тень под карточкой
    drawList:AddRectFilled(
        imgui.ImVec2(pos.x + 2, pos.y + 2),
        imgui.ImVec2(pos.x + width + 2, pos.y + height + 2),
        0xAA000000, 6
    )
    
    -- Основной фон
    local bgColor = ach.completed and 0xFF1A2E1A or 0xFF1A1A1A
    drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + width, pos.y + height), bgColor, 6)
    
    -- Акцентная полоска слева
    local accentColor = ach.completed and 0xFF1AE591 or 0xFF333333
    drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + 4, pos.y + height), accentColor, 6, 1)
    
    -- Первая строка: иконка + название
    drawList:AddText(imgui.ImVec2(pos.x + 15, pos.y + 8), ach.completed and 0xFF1AE591 or 0xFFFFFFFF, ach.icon)
    drawList:AddText(imgui.ImVec2(pos.x + 50, pos.y + 8), ach.completed and 0xFF1AE591 or 0xFFFFFFFF, u8(ach.name))
    
    -- Кнопка сброса (правый верхний угол)
    local resetX = pos.x + width - 30
    local resetY = pos.y + 5
    local resetHovered = (imgui.GetMousePos().x >= resetX and imgui.GetMousePos().x <= resetX + 20 and 
                          imgui.GetMousePos().y >= resetY and imgui.GetMousePos().y <= resetY + 20)
    
    drawList:AddRectFilled(
        imgui.ImVec2(resetX, resetY),
        imgui.ImVec2(resetX + 20, resetY + 20),
        resetHovered and 0xFF3A3A3A or bgColor, 4
    )
    drawList:AddRect(
        imgui.ImVec2(resetX, resetY),
        imgui.ImVec2(resetX + 20, resetY + 20),
        0xFF444444, 4, 15, 1.0
    )
    drawList:AddText(imgui.ImVec2(resetX + 3, resetY + 2), 0xFF999999, fa.ICON_REPEAT)
    
    imgui.SetCursorScreenPos(imgui.ImVec2(resetX, resetY))
    if imgui.InvisibleButton("##reset_ach_" .. ach.id, imgui.ImVec2(20, 20)) then
        ach.progress = 0
        ach.completed = false
        saveAchievements()
        sampAddChatMessage(SCRIPT_PREFIX .. "Достижение \"" .. ach.name .. "\" сброшено!", SCRIPT_COLOR)
    end
    
    -- Вторая строка: категория + описание
    local categoryText = u8(ach.category) .. ": "
    local categoryWidth = imgui.CalcTextSize(categoryText).x
    drawList:AddText(imgui.ImVec2(pos.x + 15, pos.y + 26), 0xFFFFCC00, categoryText)
    drawList:AddText(imgui.ImVec2(pos.x + 15 + categoryWidth, pos.y + 26), 0xFF888888, u8(ach.desc))
    
    -- Прогресс-бар (третья строка)
    local barY = pos.y + 48
    local barWidth = width - 30
    local progress = ach.completed and 1.0 or math.min(ach.progress / ach.target, 1.0)
    
    drawList:AddRectFilled(imgui.ImVec2(pos.x + 15, barY), imgui.ImVec2(pos.x + 15 + barWidth, barY + 6), 0xFF333333, 3)
    
    if progress > 0 then
        drawList:AddRectFilled(imgui.ImVec2(pos.x + 15, barY), imgui.ImVec2(pos.x + 15 + barWidth * progress, barY + 6), ach.completed and 0xFF1AE591 or 0xFF1AE591, 3)
    end
    
    -- Текст прогресса под баром
    local progressText
    if ach.completed then
        progressText = "[OK] " .. u8("Выполнено")
    elseif ach.id == "farmer_pro" or ach.id == "miner_pro" or ach.id == "sawmill_pro" or ach.id == "millionaire" then
        progressText = formatNumber(ach.progress) .. "$ / " .. formatNumber(ach.target) .. "$"
    else
        progressText = formatNumber(ach.progress) .. " / " .. formatNumber(ach.target)
    end
    drawList:AddText(imgui.ImVec2(pos.x + 15, barY + 8), 0xFF999999, progressText)
    
    -- Отступ для следующего элемента
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + height + 4))
    imgui.Dummy(imgui.ImVec2(width, 0))
end

function imgui.BindCard(key, val, winW, theme)
    local width = imgui.GetWindowWidth() - 30
    local height = 38
    
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    
    -- Фон карточки
    drawList:AddRectFilled(
        imgui.ImVec2(pos.x, pos.y),
        imgui.ImVec2(pos.x + width, pos.y + height),
        0xFF1A1A1A, 6
    )
    -- Обводка карточки
    drawList:AddRect(
        imgui.ImVec2(pos.x, pos.y),
        imgui.ImVec2(pos.x + width, pos.y + height),
        0xFF333333, 6, 15, 1.0
    )
    
    -- Номер
    drawList:AddText(
        imgui.ImVec2(pos.x + 10, pos.y + 10),
        0xFF1AE591,
        "#" .. key
    )
    
    -- Название бинда
    drawList:AddText(
        imgui.ImVec2(pos.x + 40, pos.y + 10),
        0xFFFFFFFF,
        u8(val.name or "Без названия")
    )
    
    -- Клавиши (по центру)
    local keyNames = {}
    for _, vk in ipairs(val.v or {}) do table.insert(keyNames, vkeys.id_to_name(vk)) end
    local keyStr = #keyNames > 0 and table.concat(keyNames, " + ") or "НЕТ"
    local keyTextWidth = imgui.CalcTextSize(u8(keyStr)).x
    drawList:AddText(
        imgui.ImVec2(pos.x + width / 2 - keyTextWidth / 2, pos.y + 10),
        0xFFCCCCCC,
        u8(keyStr)
    )
    
    -- Кнопка редактирования
    local editX = pos.x + width - 95
    local editY = pos.y + 5
    local editHovered = (imgui.GetMousePos().x >= editX and imgui.GetMousePos().x <= editX + 30 and 
                         imgui.GetMousePos().y >= editY and imgui.GetMousePos().y <= editY + 28)
    
    drawList:AddRectFilled(
        imgui.ImVec2(editX, editY),
        imgui.ImVec2(editX + 30, editY + 28),
        editHovered and 0xFF3A3A3A or 0xFF2A2A2A, 4
    )
    local editIconW = imgui.CalcTextSize(fa.ICON_PENCIL_SQUARE_O).x
    local editIconH = imgui.CalcTextSize(fa.ICON_PENCIL_SQUARE_O).y
    drawList:AddText(imgui.ImVec2(editX + (30 - editIconW) / 2, editY + (28 - editIconH) / 2), 0xFFFFFFFF, fa.ICON_PENCIL_SQUARE_O)
    
    imgui.SetCursorScreenPos(imgui.ImVec2(editX, editY))
    if imgui.InvisibleButton("##edit_bind_" .. key, imgui.ImVec2(30, 28)) then
        editingBindIdx = key
        local temp = {}
        for _, v in ipairs(val.text) do table.insert(temp, v) end
        editBindMultiline.v = u8(table.concat(temp, "\n"))
        editBindName.v = u8(val.name)
        imgui.OpenPopup(u8("Редактирование бинда"))
    end
    
    -- Кнопка удаления
    local delX = pos.x + width - 55
    local delY = pos.y + 5
    local delHovered = (imgui.GetMousePos().x >= delX and imgui.GetMousePos().x <= delX + 30 and 
                        imgui.GetMousePos().y >= delY and imgui.GetMousePos().y <= delY + 28)
    
    drawList:AddRectFilled(
        imgui.ImVec2(delX, delY),
        imgui.ImVec2(delX + 30, delY + 28),
        delHovered and 0xFF3A3A3A or 0xFF2A2A2A, 4
    )
    local delIconW = imgui.CalcTextSize(fa.ICON_TRASH).x
    local delIconH = imgui.CalcTextSize(fa.ICON_TRASH).y
    drawList:AddText(imgui.ImVec2(delX + (30 - delIconW) / 2, delY + (28 - delIconH) / 2), 0xFFFFFFFF, fa.ICON_TRASH)
    
    imgui.SetCursorScreenPos(imgui.ImVec2(delX, delY))
    if imgui.InvisibleButton("##del_bind_" .. key, imgui.ImVec2(30, 28)) then
        sampAddChatMessage(SCRIPT_PREFIX .. "Бинд \"" .. val.name .. "\" удалён.", SCRIPT_COLOR)
        table.remove(bindDatabase.binds, key); saveBinderDatabase()
    end
    
    -- Отступ для следующего элемента
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + height + 1))
    imgui.Dummy(imgui.ImVec2(width, 0))
end

function StyleButton(label, icon, width)
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local btnW = width or (imgui.GetWindowWidth() - 25)
    local btnH = 28
    
    local hovered = (imgui.GetMousePos().x >= pos.x and imgui.GetMousePos().x <= pos.x + btnW and 
                    imgui.GetMousePos().y >= pos.y and imgui.GetMousePos().y <= pos.y + btnH)
    
    drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + btnW, pos.y + btnH), 
        hovered and 0xFF222222 or 0xFF1A1A1A, 4)
    drawList:AddRect(pos, imgui.ImVec2(pos.x + btnW, pos.y + btnH), 0xFF333333, 4, 15, 1.0)
    
    local textW = imgui.CalcTextSize(label).x
    local iconW = icon and 18 or 0
    local gap = icon and 4 or 0
    local totalW = iconW + gap + textW
    local startX = pos.x + (btnW - totalW) / 2
    
    if icon then
        drawList:AddText(imgui.ImVec2(startX, pos.y + 5), 0xFF1AE591, icon)
        drawList:AddText(imgui.ImVec2(startX + iconW + gap, pos.y + 5), 0xFF1AE591, label)
    else
        drawList:AddText(imgui.ImVec2(startX, pos.y + 5), 0xFF1AE591, label)
    end
    
    imgui.SetCursorScreenPos(pos)
    local clicked = imgui.InvisibleButton("##stylebtn_" .. label:gsub(" ", "_"), imgui.ImVec2(btnW, btnH))
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + btnH + 3))
    
    return clicked
end

local function ToggleSwitch(label, boolVar, helpText)
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local switchWidth = 36
    local switchHeight = 20
    local circleRadius = 8
    local totalWidth = switchWidth + 10 + imgui.CalcTextSize(label).x
    
    -- Фон переключателя
    local bgColor = boolVar.v and 0xFF1AE591 or 0xFF444444
    drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + switchWidth, pos.y + switchHeight), bgColor, 10)
    
    -- Кружок
    local circleX = boolVar.v and (pos.x + switchWidth - circleRadius - 3) or (pos.x + circleRadius + 3)
    drawList:AddCircleFilled(imgui.ImVec2(circleX, pos.y + switchHeight / 2), circleRadius, 0xFFFFFFFF)
    
    -- Текст
    local textColor = boolVar.v and 0xFF1AE591 or 0xFF888888
    drawList:AddText(imgui.ImVec2(pos.x + switchWidth + 10, pos.y + 2), textColor, label)
    
    -- Невидимая кнопка для клика
    imgui.SetCursorScreenPos(pos)
    local clicked = imgui.InvisibleButton("##toggle_" .. label:gsub(" ", "_"), imgui.ImVec2(totalWidth, switchHeight))
    
    if clicked then
        boolVar.v = not boolVar.v
        return true
    end
    
    -- Подсказка
    if helpText then
        imgui.SameLine()
        ShowHelpMarker(helpText)
    end
    
    return false
end

function drawSettingsTab()
    local drawList = imgui.GetWindowDrawList()
    local listW = imgui.GetWindowWidth() - 25
    local cardH = 38
    
    -- ====== ОФОРМЛЕНИЕ ======
    local cardY = imgui.GetCursorScreenPos().y
    local cardX = imgui.GetCursorScreenPos().x
    local hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and 
                    imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
        hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_STAR)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Оформление"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not settingsExpandedTheme then settingsExpandedTheme = false end
    if imgui.InvisibleButton("##settings_theme", imgui.ImVec2(listW, cardH)) then settingsExpandedTheme = not settingsExpandedTheme end
    if settingsExpandedTheme then
        imgui.Spacing()
        if ToggleSwitch(u8("Использовать кастомную тему"), cb_useCustomTheme) then
            useCustomTheme = cb_useCustomTheme.v; saveThemeConfig(); needSave = true
        end
        if useCustomTheme then
            cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
            hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_COG)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Редактор кастомной темы"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not settingsExpandedCustomTheme then settingsExpandedCustomTheme = false end
            if imgui.InvisibleButton("##settings_custom_theme", imgui.ImVec2(listW, cardH)) then settingsExpandedCustomTheme = not settingsExpandedCustomTheme end
            if settingsExpandedCustomTheme then
                imgui.Spacing()
                local function ColorEdit4Helper(label, tbl, key)
                    imgui.Text(label)
                    local pos = imgui.GetCursorScreenPos()
                    drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + 30, pos.y + 20), imVec4ToHex(tbl[key]))
                    drawList:AddRect(pos, imgui.ImVec2(pos.x + 30, pos.y + 20), 0xFFFFFFFF, 0, 15, 1.5)
                    imgui.SetCursorScreenPos(pos)
                    imgui.InvisibleButton("##colorpreview_" .. key, imgui.ImVec2(30, 20))
                    if imgui.IsItemClicked(0) then imgui.OpenPopup("ColorPicker##" .. key) end
                    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x + 35, pos.y))
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    if imgui.BeginPopup("ColorPicker##" .. key) then
                        local col = imgui.ImFloat4(tbl[key].x, tbl[key].y, tbl[key].z, tbl[key].w)
                        if imgui.ColorPicker4("##picker" .. key, col, imgui.ColorEditFlags.NoSidePreview) then
                            tbl[key] = imgui.ImVec4(col.v[1], col.v[2], col.v[3], col.v[4])
                            if key == "leftPanelBg" then CUSTOM_THEME.titleBg = imgui.ImVec4(col.v[1], col.v[2], col.v[3], col.v[4])
                            elseif key == "rightPanelBg" then CUSTOM_THEME.windowBg = imgui.ImVec4(col.v[1], col.v[2], col.v[3], col.v[4]); CUSTOM_THEME.childBg = imgui.ImVec4(col.v[1], col.v[2], col.v[3], col.v[4]); CUSTOM_THEME.rightTitleBg = imgui.ImVec4(col.v[1], col.v[2], col.v[3], col.v[4]) end
                            saveCustomTheme()
                        end
                        imgui.EndPopup()
                    end
                    imgui.Spacing()
                end
                
                -- Цвета меню
                cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
                hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
                drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
                drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
                drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_DESKTOP)
                drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цвета меню"))
                imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
                if not settingsExpandedMenuColors then settingsExpandedMenuColors = false end
                if imgui.InvisibleButton("##settings_menu_colors", imgui.ImVec2(listW, cardH)) then settingsExpandedMenuColors = not settingsExpandedMenuColors end
                if settingsExpandedMenuColors then
                    imgui.Spacing()
                    ColorEdit4Helper(u8("Акцентный цвет"), CUSTOM_THEME, "accent"); ColorEdit4Helper(u8("Левая панель"), CUSTOM_THEME, "leftPanelBg")
                    ColorEdit4Helper(u8("Правая панель"), CUSTOM_THEME, "rightPanelBg"); ColorEdit4Helper(u8("Цвет заголовка"), CUSTOM_THEME, "headerTitle")
                    ColorEdit4Helper(u8("Текст в правой панели"), CUSTOM_THEME, "contentText"); ColorEdit4Helper(u8("Фон активной кнопки"), CUSTOM_THEME, "buttonActive")
                    ColorEdit4Helper(u8("Фон кнопки (наведение)"), CUSTOM_THEME, "buttonHover"); ColorEdit4Helper(u8("Обводка активной кнопки"), CUSTOM_THEME, "borderActive")
                    ColorEdit4Helper(u8("Цвет разделителей"), CUSTOM_THEME, "borderColor")
                    imgui.Spacing()
                end
                
                -- Цвета текста
                cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
                hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
                drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
                drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
                drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_FONT)
                drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цвета текста"))
                imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
                if not settingsExpandedTextColors then settingsExpandedTextColors = false end
                if imgui.InvisibleButton("##settings_text_colors", imgui.ImVec2(listW, cardH)) then settingsExpandedTextColors = not settingsExpandedTextColors end
                if settingsExpandedTextColors then
                    imgui.Spacing()
                    ColorEdit4Helper(u8("Цвет текста (обычный)"), CUSTOM_THEME, "textNormal"); ColorEdit4Helper(u8("Цвет текста (активный)"), CUSTOM_THEME, "textActive")
                    ColorEdit4Helper(u8("Цвет текста (наведение)"), CUSTOM_THEME, "textHover")
                    imgui.Spacing()
                end
                
                -- Кнопки и элементы
                cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
                hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
                drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
                drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
                drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_KEYBOARD_O)
                drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Кнопки и элементы"))
                imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
                if not settingsExpandedElements then settingsExpandedElements = false end
                if imgui.InvisibleButton("##settings_elements", imgui.ImVec2(listW, cardH)) then settingsExpandedElements = not settingsExpandedElements end
                if settingsExpandedElements then
                    imgui.Spacing()
                    ColorEdit4Helper(u8("Кнопки ImGui"), CUSTOM_THEME, "imguiButton"); ColorEdit4Helper(u8("Кнопки (наведение)"), CUSTOM_THEME, "imguiButtonHovered")
                    ColorEdit4Helper(u8("Кнопки (активные)"), CUSTOM_THEME, "imguiButtonActive"); ColorEdit4Helper(u8("Заголовки разделов"), CUSTOM_THEME, "collapsingHeader")
                    ColorEdit4Helper(u8("Заголовки (наведение)"), CUSTOM_THEME, "collapsingHeaderHovered"); ColorEdit4Helper(u8("Заголовки (активные)"), CUSTOM_THEME, "collapsingHeaderActive")
                    ColorEdit4Helper(u8("Прогресс-бар"), CUSTOM_THEME, "progressBar"); ColorEdit4Helper(u8("Поля ввода"), CUSTOM_THEME, "frameBg")
                    ColorEdit4Helper(u8("Поля ввода (наведение)"), CUSTOM_THEME, "frameBgHovered"); ColorEdit4Helper(u8("Поля ввода (активные)"), CUSTOM_THEME, "frameBgActive")
                    imgui.Spacing()
                end
                imgui.Spacing()
                if imgui.Button(u8("Сбросить тему на стандартную"), imgui.ImVec2(-1, 25)) then resetCustomTheme(); saveCustomTheme() end
                imgui.Spacing()
            end
        else
            imgui.Spacing()
            imgui.Text(u8("Цветовая тема:")); imgui.PushItemWidth(200)
            if imgui.Combo(u8("##theme_select"), selectedThemeIdx, themeComboItems) then currentTheme = THEME_ORDER[selectedThemeIdx.v + 1]; saveThemeConfig(); needSave = true end
            imgui.PopItemWidth(); imgui.SameLine(); ShowHelpMarker(u8("Меняет цветовое оформление главного меню"))
            imgui.Spacing()
        end
        imgui.Spacing()
    end
    
    -- ====== УВЕДОМЛЕНИЯ И ЗВУКИ ======
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_MUSIC)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Уведомления и звуки"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not settingsExpandedNotify then settingsExpandedNotify = false end
    if imgui.InvisibleButton("##settings_notify", imgui.ImVec2(listW, cardH)) then settingsExpandedNotify = not settingsExpandedNotify end
    if settingsExpandedNotify then
        imgui.Spacing()
        if ToggleSwitch(u8("Уведомления о целях в чат"), cb_chatNotify) then settings.chatNotifyEnabled = cb_chatNotify.v; saveConfig(); needSave = true end
        imgui.Spacing()
        
        -- Звук достижения
        if ToggleSwitch(u8("Звук при выполнении цели"), cb_goalSound) then settings.goalSoundEnabled = cb_goalSound.v; saveConfig(); needSave = true end
        if cb_goalSound.v then
            local wavFiles = getWavFiles()
            if not achivFileIdx then achivFileIdx = imgui.ImInt(0) end
            if achivFileIdx.v < 0 or achivFileIdx.v >= #wavFiles then achivFileIdx.v = 0 end
            for i, f in ipairs(wavFiles) do if f == (settings.achivSoundFile or "achiv.wav") then achivFileIdx.v = i - 1; break end end
            imgui.Text(u8("Достижение:"))
            imgui.SameLine(100)
            imgui.PushItemWidth(140)
            if imgui.Combo("##achiv_file", achivFileIdx, table.concat(wavFiles, "\0") .. "\0") then
                settings.achivSoundFile = wavFiles[achivFileIdx.v + 1]
                saveConfig()
            end
            imgui.PopItemWidth()
            imgui.SameLine(0, 5)
            if imgui.Button(fa.ICON_PLAY .. "##play_achiv", imgui.ImVec2(25, 20)) then
                playSoundFile(settings.achivSoundFile or "achiv.wav", settings.goalSoundVolume)
            end
            imgui.SameLine(0, 10)
            imgui.Text(u8("Громкость:"))
            imgui.SameLine(0, 5)
            imgui.PushItemWidth(80)
            if imgui.SliderInt("##goal_vol", goal_vol_slider, 0, 100) then settings.goalSoundVolume = goal_vol_slider.v; saveConfig() end
            imgui.PopItemWidth()
        end
        imgui.Spacing()
        
        -- Звуки добычи
        if ToggleSwitch(u8("Звуки при добыче ресурсов"), cb_pickupSound) then settings.pickupSoundEnabled = cb_pickupSound.v; saveConfig(); needSave = true end
        if cb_pickupSound.v then
            local wavFiles = getWavFiles()
            
            -- Обычный дроп
            if not pickupFileIdx then pickupFileIdx = imgui.ImInt(0) end
            if pickupFileIdx.v < 0 or pickupFileIdx.v >= #wavFiles then pickupFileIdx.v = 0 end
            for i, f in ipairs(wavFiles) do if f == (settings.pickupSoundFile or "pickup.wav") then pickupFileIdx.v = i - 1; break end end
            imgui.Text(u8("Обычный:"))
            imgui.SameLine(65)
            ShowHelpMarker(u8("Лён, Хлопок, Вода, Краситель, Камень, Металл, Бронза, Серебро, Золото, Дрова"))
            imgui.SameLine(100)
            imgui.PushItemWidth(140)
            if imgui.Combo("##pickup_file", pickupFileIdx, table.concat(wavFiles, "\0") .. "\0") then
                settings.pickupSoundFile = wavFiles[pickupFileIdx.v + 1]
                saveConfig()
            end
            imgui.PopItemWidth()
            imgui.SameLine(0, 5)
            if imgui.Button(fa.ICON_PLAY .. "##play_pickup", imgui.ImVec2(25, 20)) then
                playSoundFile(settings.pickupSoundFile or "pickup.wav", settings.pickupSoundVolume)
            end
            imgui.SameLine(0, 10)
            imgui.Text(u8("Громкость:"))
            imgui.SameLine(0, 5)
            imgui.PushItemWidth(80)
            if imgui.SliderInt("##pickup_vol", pickup_vol_slider, 0, 100) then settings.pickupSoundVolume = pickup_vol_slider.v; saveConfig() end
            imgui.PopItemWidth()
            
            -- Редкий дроп
            if not rareFileIdx then rareFileIdx = imgui.ImInt(0) end
            if rareFileIdx.v < 0 or rareFileIdx.v >= #wavFiles then rareFileIdx.v = 0 end
            for i, f in ipairs(wavFiles) do if f == (settings.rareSoundFile or "rare.wav") then rareFileIdx.v = i - 1; break end end
            imgui.Text(u8("Редкий:"))
            imgui.SameLine(65)
            ShowHelpMarker(u8("Алмаз, Кусок редкой ткани, Древесина высшего качества"))
            imgui.SameLine(100)
            imgui.PushItemWidth(140)
            if imgui.Combo("##rare_file", rareFileIdx, table.concat(wavFiles, "\0") .. "\0") then
                settings.rareSoundFile = wavFiles[rareFileIdx.v + 1]
                saveConfig()
            end
            imgui.PopItemWidth()
            imgui.SameLine(0, 5)
            if imgui.Button(fa.ICON_PLAY .. "##play_rare", imgui.ImVec2(25, 20)) then
                playSoundFile(settings.rareSoundFile or "rare.wav", settings.rareSoundVolume or 80)
            end
            imgui.SameLine(0, 10)
            imgui.Text(u8("Громкость:"))
            imgui.SameLine(0, 5)
            imgui.PushItemWidth(80)
            local rareVol = imgui.ImInt(settings.rareSoundVolume or 80)
            if imgui.SliderInt("##rare_vol", rareVol, 0, 100) then settings.rareSoundVolume = rareVol.v; saveConfig() end
            imgui.PopItemWidth()
            
            -- Очень редкие
            if not coalFileIdx then coalFileIdx = imgui.ImInt(0) end
            if coalFileIdx.v < 0 or coalFileIdx.v >= #wavFiles then coalFileIdx.v = 0 end
            for i, f in ipairs(wavFiles) do if f == (settings.coalSoundFile or "ugol.wav") then coalFileIdx.v = i - 1; break end end
            imgui.Text(u8("Оч.редкие:"))
            imgui.SameLine(65)
            ShowHelpMarker(u8("Уголь, Прочная ткань, Шахтёрский сплав, Тёмная материя"))
            imgui.SameLine(100)
            imgui.PushItemWidth(140)
            if imgui.Combo("##coal_file", coalFileIdx, table.concat(wavFiles, "\0") .. "\0") then
                settings.coalSoundFile = wavFiles[coalFileIdx.v + 1]
                saveConfig()
            end
            imgui.PopItemWidth()
            imgui.SameLine(0, 5)
            if imgui.Button(fa.ICON_PLAY .. "##play_coal", imgui.ImVec2(25, 20)) then
                playSoundFile(settings.coalSoundFile or "ugol.wav", settings.coalSoundVolume or 80)
            end
            imgui.SameLine(0, 10)
            imgui.Text(u8("Громкость:"))
            imgui.SameLine(0, 5)
            imgui.PushItemWidth(80)
            local coalVol = imgui.ImInt(settings.coalSoundVolume or 80)
            if imgui.SliderInt("##coal_vol", coalVol, 0, 100) then settings.coalSoundVolume = coalVol.v; saveConfig() end
            imgui.PopItemWidth()
        end
        
        imgui.Spacing()
        if StyleButton(u8("Обновить список звуков"), fa.ICON_REPEAT, nil) then
            cachedWavFiles = nil
            achivFileIdx = nil; pickupFileIdx = nil; rareFileIdx = nil; coalFileIdx = nil
        end
        imgui.Spacing()
        if StyleButton(u8("Открыть папку со звуками"), fa.ICON_FOLDER_OPEN, nil) then
            shell32.ShellExecuteA(nil, "open", soundsDir, nil, nil, 1)
        end
        imgui.Spacing()
    end
	    
    -- ====== TELEGRAM УВЕДОМЛЕНИЯ ======
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_PAPER_PLANE)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Telegram уведомления"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not settingsExpandedTelegram then settingsExpandedTelegram = false end
    if imgui.InvisibleButton("##settings_telegram", imgui.ImVec2(listW, cardH)) then settingsExpandedTelegram = not settingsExpandedTelegram end
    if settingsExpandedTelegram then
        imgui.Spacing()
        
        if ToggleSwitch(u8("Включить TG уведомления"), imgui.ImBool(tgConfig.enabled or false)) then
            tgConfig.enabled = not tgConfig.enabled
            saveTgConfig()
            needSave = true
        end
        imgui.Spacing()
        
        -- Токен бота
        imgui.Text(u8("Токен бота:"))
        imgui.PushItemWidth(-1)
        if imgui.InputText("##tg_token", tgTokenInput) then
            tgConfig.botToken = u8:decode(tgTokenInput.v)
            saveTgConfig()
        end
        imgui.PopItemWidth()
        imgui.SameLine()
        ShowHelpMarker(u8("Получить у @BotFather в Telegram. Команда /newbot"))
        imgui.Spacing()
        
        -- Chat ID
        imgui.Text(u8("Chat ID:"))
        imgui.PushItemWidth(-1)
        if imgui.InputText("##tg_chatid", tgChatIdInput) then
            tgConfig.chatId = u8:decode(tgChatIdInput.v)
            saveTgConfig()
        end
        imgui.PopItemWidth()
        imgui.SameLine()
        ShowHelpMarker(u8("Получить у @chatIDrobot в Telegram"))
        imgui.Spacing()
        
        imgui.Separator()
        imgui.Spacing()
        
        -- Переключатель резервного сервера
        if ToggleSwitch(u8("Резервный сервер (для России)"), imgui.ImBool(tgConfig.useReserveServer or false)) then
            tgConfig.useReserveServer = not tgConfig.useReserveServer
            saveTgConfig()
            needSave = true
        end
        imgui.SameLine()
        ShowHelpMarker(u8("Включите если Telegram заблокирован в вашем регионе"))
        imgui.Spacing()
        
        imgui.Separator()
        imgui.Spacing()
        
        if ToggleSwitch(u8("Уведомления об аренде (Item Market)"), imgui.ImBool(tgConfig.itemMarketEnabled or false)) then
            tgConfig.itemMarketEnabled = not tgConfig.itemMarketEnabled
            saveTgConfig()
            needSave = true
        end
        imgui.Spacing()

if ToggleSwitch(u8("Ежедневный отчёт"), imgui.ImBool(tgConfig.dailyReportEnabled or false)) then
    tgConfig.dailyReportEnabled = not tgConfig.dailyReportEnabled
    saveTgConfig()
    needSave = true
end
imgui.SameLine()
ShowHelpMarker(u8("Отправляет отчёт за прошедший игровой день, на следующий день когда вы зайдете первый раз в игру"))
imgui.Spacing()

if ToggleSwitch(u8("Еженедельный отчёт"), imgui.ImBool(tgConfig.weeklyReportEnabled or false)) then
    tgConfig.weeklyReportEnabled = not tgConfig.weeklyReportEnabled
    saveTgConfig()
    needSave = true
end
imgui.SameLine()
ShowHelpMarker(u8("Отправляет отчёт за прошедшую игровую неделю, в понедельник когда вызайдете первый раз в игру"))
imgui.Spacing()
		
        -- Кнопка видео-обучения
        if StyleButton(u8("Видео-обучение"), fa.ICON_TELEVISION) then
            shell32.ShellExecuteA(nil, "open", "https://youtu.be/WdWKGkxLNdU", nil, nil, 0)
        end
        imgui.Spacing()
        
        -- Кнопка проверки
        if StyleButton(u8("Проверить подключение"), fa.ICON_CHECK) then
            if tgConfig.botToken ~= "" and tgConfig.chatId ~= "" then
                local now = os.time() + 10800
                local timeStr = string.format("%02d:%02d", math.floor((now % 86400) / 3600), math.floor((now % 3600) / 60))
                local dateStr = getGameDate()
                local msg = string.format(
                    "<b>ResHelper подключен!</b>\n" ..
                    "Уведомления о аренде включены.\n" ..
                    "Время: %s (МСК)\n" ..
                    "Дата: %s",
                    timeStr, dateStr
                )
                sendTelegramMessage(msg)
                sampAddChatMessage(SCRIPT_PREFIX .. "Тестовое сообщение отправлено в Telegram!", SCRIPT_COLOR)
            else
                sampAddChatMessage(SCRIPT_PREFIX .. "Укажите токен и Chat ID!", SCRIPT_COLOR)
            end
        end
        imgui.Spacing()
    end
    
-- ====== РЕЙТИНГ ======
cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_TROPHY)
drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Рейтинг (лидерборд)"))
imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
if not settingsExpandedLeaderboard then settingsExpandedLeaderboard = false end
if imgui.InvisibleButton("##settings_lb", imgui.ImVec2(listW, cardH)) then settingsExpandedLeaderboard = not settingsExpandedLeaderboard end
if settingsExpandedLeaderboard then
    imgui.Spacing()
    local lbEn = imgui.ImBool(getLbEnabled())
    if ToggleSwitch(u8("Участвовать в рейтинге"), lbEn) then
        saveLbConfig("", lbEn.v)
    end
    imgui.Spacing()
    local _, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local serverNick = sampGetPlayerNickname(playerId) or ""
    local host = sampGetCurrentServerAddress()
    local serverDisplay = ""
    if host and host ~= "" then
        local servers = {
            ["80.66.82.132"] = "Holiday", ["185.169.134.166"] = "Prescott", ["80.66.82.82"] = "Faraway",
            ["80.66.82.54"] = "Christmas", ["80.66.82.200"] = "Queen-Creek", ["80.66.82.191"] = "Gilbert",
            ["80.66.82.168"] = "Page", ["80.66.82.113"] = "Yava", ["185.169.134.109"] = "Surprise",
            ["80.66.82.128"] = "Wednesday", ["185.169.134.44"] = "Chandler", ["185.169.134.171"] = "Glendale",
            ["80.66.82.190"] = "Show Low", ["80.66.82.144"] = "Sedona", ["185.169.134.174"] = "Payson",
            ["185.169.134.5"] = "Saint-Rose", ["80.66.82.159"] = "Sun-City", ["185.169.134.172"] = "Kingman",
            ["185.169.134.173"] = "Winslow", ["185.169.134.43"] = "Scottdale", ["185.169.134.61"] = "Red-Rock",
            ["185.169.134.45"] = "Brainburg", ["80.66.82.39"] = "Mirage", ["185.169.134.3"] = "Phoenix",
            ["185.169.134.59"] = "Mesa", ["185.169.134.4"] = "Tucson", ["185.169.134.107"] = "Yuma",
            ["80.66.82.188"] = "Casa-Grande", ["80.66.82.87"] = "Bumble Bee", ["80.66.82.33"] = "Love",
            ["80.66.82.22"] = "Drake", ["80.66.82.199"] = "Space"
        }
        serverDisplay = servers[host] or ""
    end
    imgui.Text(u8("Ваш ник: ") .. serverNick)
    if serverDisplay ~= "" then
        imgui.Text(u8("Сервер: ") .. serverDisplay)
    end
    if serverNick == "" then
        imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.2, 1), u8("Ник не определён. Зайдите на сервер!"))
    end
    imgui.Spacing()
end
	
    -- ====== ОВЕРЛЕИ ======
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_TELEVISION)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Оверлеи"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not settingsExpandedOverlay then settingsExpandedOverlay = false end
    if imgui.InvisibleButton("##settings_overlay", imgui.ImVec2(listW, cardH)) then settingsExpandedOverlay = not settingsExpandedOverlay end
if settingsExpandedOverlay then
    imgui.Spacing()
    
    -- Оверлей фермы
    if ToggleSwitch(u8("Оверлей фермы"), cb_farm_overlay) then
        if cb_farm_overlay.v then
            settings.farmOverlayEnabled = true
            settings.mineOverlayEnabled = false
            settings.sawmillOverlayEnabled = false
            cb_mine_overlay.v = false
            cb_sawmill_overlay.v = false
            if currentWork ~= WORK_TYPES.FARM then
                switchWorkType(WORK_TYPES.FARM)
                if not scannedThisSession[WORK_TYPES.FARM] then
                    pendingScan = WORK_TYPES.FARM
                end
            end
        else
            settings.farmOverlayEnabled = false
        end
        saveConfig(); needSave = true
    end
    
    -- Оверлей шахты
    if ToggleSwitch(u8("Оверлей шахты"), cb_mine_overlay) then
        if cb_mine_overlay.v then
            settings.mineOverlayEnabled = true
            settings.farmOverlayEnabled = false
            settings.sawmillOverlayEnabled = false
            cb_farm_overlay.v = false
            cb_sawmill_overlay.v = false
            if currentWork ~= WORK_TYPES.MINE then
                switchWorkType(WORK_TYPES.MINE)
                if not scannedThisSession[WORK_TYPES.MINE] then
                    pendingScan = WORK_TYPES.MINE
                end
            end
        else
            settings.mineOverlayEnabled = false
        end
        saveConfig(); needSave = true
    end
    
    -- Оверлей лесопилки
    if ToggleSwitch(u8("Оверлей лесопилки"), cb_sawmill_overlay) then
        if cb_sawmill_overlay.v then
            settings.sawmillOverlayEnabled = true
            settings.farmOverlayEnabled = false
            settings.mineOverlayEnabled = false
            cb_farm_overlay.v = false
            cb_mine_overlay.v = false
            if currentWork ~= WORK_TYPES.SAWMILL then
                switchWorkType(WORK_TYPES.SAWMILL)
                if not scannedThisSession[WORK_TYPES.SAWMILL] then
                    pendingScan = WORK_TYPES.SAWMILL
                end
            end
        else
            settings.sawmillOverlayEnabled = false
        end
        saveConfig(); needSave = true
    end
    
    imgui.Spacing()
end

    -- ====== ТАЙМЕР ======
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_CLOCK_O)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Таймер"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not settingsExpandedTimer then settingsExpandedTimer = false end
    if imgui.InvisibleButton("##settings_timer", imgui.ImVec2(listW, cardH)) then settingsExpandedTimer = not settingsExpandedTimer end
    if settingsExpandedTimer then
        imgui.Spacing()
        if ToggleSwitch(u8("Таймер в оверлее"), cb_overlay_timer) then settings.overlayTimerEnabled = cb_overlay_timer.v; if not cb_overlay_timer.v then overlayTimer.running = false; overlayTimer.elapsed = 0; overlayTimer.displayedTime = "00:00:00" end; saveConfig(); needSave = true end
        if settings.overlayTimerEnabled then
            imgui.Spacing()
            if not overlayTimer.running then
                if imgui.Button(u8("Запустить таймер"), imgui.ImVec2(200, 25)) then overlayTimer.running = true; overlayTimer.startTime = os.time(); overlayTimer.elapsed = 0; overlayTimer.displayedTime = "00:00:00" end
            else
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.3, 0.3, 1.0)); imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 0.2, 0.2, 1.0)); imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.9, 0.1, 0.1, 1.0))
                if imgui.Button(u8("Остановить таймер"), imgui.ImVec2(200, 25)) then overlayTimer.running = false; overlayTimer.elapsed = os.time() - overlayTimer.startTime; overlayTimer.displayedTime = formatTime(overlayTimer.elapsed); sampAddChatMessage(SCRIPT_PREFIX .. "Таймер остановлен. Время работы: " .. overlayTimer.displayedTime, SCRIPT_COLOR) end
                imgui.PopStyleColor(3); imgui.SameLine(); imgui.TextColored(imgui.ImVec4(0.3, 1.0, 1.0, 1), u8("Текущее время: " .. overlayTimer.displayedTime))
            end
        end
        imgui.Spacing()
    end
    
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.PushStyleColor(imgui.Col.Button, needSaveColor)
        if StyleButton(u8("Сохранить все настройки"), fa.ICON_FLOPPY_O) then saveConfig(); savePrices(); saveOverlayConfig(); saveGoals(); saveStats(); saveThemeConfig(); saveCustomTheme(); sampAddChatMessage(SCRIPT_PREFIX.."Настройки сохранены!", SCRIPT_COLOR); needSave = false end
    imgui.PopStyleColor(1)
end

function saveTotalIncomeGoal()
    local data = {
        goal = settings.totalIncomeGoal,
        reached = totalIncomeGoalReached,
        income = totalDailyIncome
    }
    local file = io.open(totalIncomeGoalPath, "w")
    if file then
        file:write(encodeJson(data))
        file:close()
    end
end

function loadTotalIncomeGoal()
    local file = io.open(totalIncomeGoalPath, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local data = decodeJson(content)
    if not data then return end
    settings.totalIncomeGoal = data.goal or 1000000
    totalIncomeGoalReached = data.reached or false
    totalDailyIncome = data.income or 0
    if totalGoalEdit then totalGoalEdit.v = settings.totalIncomeGoal end
end

function drawFarmGoals()
    local farmGoals = {}
    local farmDailyRes = {}
    
    local fgf = io.open(farmGoalsConfigPath, "r")
    if fgf then
        local data = decodeJson(fgf:read("*a"))
        fgf:close()
        if data then
            for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
                farmGoals[k] = data[k] or configs[WORK_TYPES.FARM].defaultGoals[k]
            end
        end
    else
        for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
            farmGoals[k] = configs[WORK_TYPES.FARM].defaultGoals[k]
        end
    end
    
    local fpf = io.open(farmGoalsProgressPath, "r")
    if fpf then
        local data = decodeJson(fpf:read("*a"))
        fpf:close()
        if data then
            for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
                if data[k] then
                    farmDailyRes[k] = data[k].amount or 0
                else
                    farmDailyRes[k] = 0
                end
            end
        end
    else
        for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
            farmDailyRes[k] = 0
        end
    end
    
    if currentWork == WORK_TYPES.FARM then
        for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
        farmGoals[k] = farmGoals[k] or goals[k]
            farmDailyRes[k] = dailyResources[k] or 0
        end
    end
    
    for _, k in ipairs(configs[WORK_TYPES.FARM].resourceOrder) do
        if not farmGoalEditCache[k] then
            farmGoalEditCache[k] = imgui.ImInt(farmGoals[k])
        end
    end
    
    imgui.Columns(2, "goals_farm_cols", false)
    imgui.SetColumnWidth(0, imgui.GetWindowWidth() * 0.5)
    local farmOrder = configs[WORK_TYPES.FARM].resourceOrder
    local halfFarm = math.ceil(#farmOrder / 2)
    for i = 1, halfFarm do
        local k = farmOrder[i]
        local cur = farmDailyRes[k] or 0
        local g = farmGoalEditCache[k].v
        local p = math.min(cur / g, 1.0)
        imgui.Text(u8(configs[WORK_TYPES.FARM].resourceNames[k] .. ": " .. formatNumber(cur) .. " / " .. formatNumber(g)))
        imgui.ProgressBar(p, imgui.ImVec2(-1, 15), u8(math.floor(p * 100) .. "%"))
        imgui.PushItemWidth(imgui.GetColumnWidth() - 10)
        imgui.InputInt("##goal_farm_global_" .. k, farmGoalEditCache[k], 10, 100)
        imgui.PopItemWidth()
        imgui.NextColumn()
    end
    imgui.SetColumnWidth(1, imgui.GetWindowWidth() * 0.5)
    for i = halfFarm + 1, #farmOrder do
        local k = farmOrder[i]
        local cur = farmDailyRes[k] or 0
        local g = farmGoalEditCache[k].v
        local p = math.min(cur / g, 1.0)
        imgui.Text(u8(configs[WORK_TYPES.FARM].resourceNames[k] .. ": " .. formatNumber(cur) .. " / " .. formatNumber(g)))
        imgui.ProgressBar(p, imgui.ImVec2(-1, 15), u8(math.floor(p * 100) .. "%"))
        imgui.PushItemWidth(imgui.GetColumnWidth() - 10)
        imgui.InputInt("##goal_farm_global_" .. k, farmGoalEditCache[k], 10, 100)
        imgui.PopItemWidth()
        if i < #farmOrder then imgui.NextColumn() end
    end
    imgui.Columns(1)
    imgui.Spacing()
    local btnWidth = imgui.GetWindowWidth() / 2 - 10
    if StyleButton(u8("Сохранить цели"), nil, btnWidth) then
        local saveData = {}
        for _, k in ipairs(farmOrder) do
            saveData[k] = farmGoalEditCache[k].v
        end
        local f = io.open(farmGoalsConfigPath, "w")
        if f then f:write(encodeJson(saveData)); f:close() end
        sampAddChatMessage(SCRIPT_PREFIX.."Цели фермы сохранены!", SCRIPT_COLOR)
    end
    imgui.SameLine()
    if StyleButton(u8("Сбросить прогресс"), nil, btnWidth) then
        local saveData = {}
        for _, k in ipairs(farmOrder) do
            saveData[k] = {reached = false, amount = 0}
        end
        saveData.dailyTotal = 0
        local f = io.open(farmGoalsProgressPath, "w")
        if f then f:write(encodeJson(saveData)); f:close() end
        if currentWork == WORK_TYPES.FARM then
            for _, k in ipairs(farmOrder) do
                goalsReached[k] = false; dailyResources[k] = 0
            end
            dailyTotal = 0
        end
        sampAddChatMessage(SCRIPT_PREFIX.."Прогресс целей фермы сброшен!", SCRIPT_COLOR)
    end
end

function drawMineGoals()
    local mineGoals = {}
    local mineDailyRes = {}
    
    local mgf = io.open(mineGoalsConfigPath, "r")
    if mgf then
        local data = decodeJson(mgf:read("*a"))
        mgf:close()
        if data then
            for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
                mineGoals[k] = data[k] or configs[WORK_TYPES.MINE].defaultGoals[k]
            end
        end
    else
        for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
            mineGoals[k] = configs[WORK_TYPES.MINE].defaultGoals[k]
        end
    end
    
    local mpf = io.open(mineGoalsProgressPath, "r")
    if mpf then
        local data = decodeJson(mpf:read("*a"))
        mpf:close()
        if data then
            for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
                if data[k] then
                    mineDailyRes[k] = data[k].amount or 0
                else
                    mineDailyRes[k] = 0
                end
            end
        end
    else
        for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
            mineDailyRes[k] = 0
        end
    end
    
    if currentWork == WORK_TYPES.MINE then
        for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
            mineGoals[k] = mineGoals[k] or goals[k]
            mineDailyRes[k] = dailyResources[k] or 0
        end
    end
    
    for _, k in ipairs(configs[WORK_TYPES.MINE].resourceOrder) do
        if not mineGoalEditCache[k] then
            mineGoalEditCache[k] = imgui.ImInt(mineGoals[k])
        end
    end
    
    imgui.Columns(2, "goals_mine_cols", false)
    imgui.SetColumnWidth(0, imgui.GetWindowWidth() * 0.5)
    local mineOrder = configs[WORK_TYPES.MINE].resourceOrder
    local halfMine = math.ceil(#mineOrder / 2)
    for i = 1, halfMine do
        local k = mineOrder[i]
        local cur = mineDailyRes[k] or 0
        local g = mineGoalEditCache[k].v
        local p = math.min(cur / g, 1.0)
        imgui.Text(u8(configs[WORK_TYPES.MINE].resourceNames[k] .. ": " .. formatNumber(cur) .. " / " .. formatNumber(g)))
        imgui.ProgressBar(p, imgui.ImVec2(-1, 15), u8(math.floor(p * 100) .. "%"))
        imgui.PushItemWidth(imgui.GetColumnWidth() - 10)
        imgui.InputInt("##goal_mine_global_" .. k, mineGoalEditCache[k], 10, 100)
        imgui.PopItemWidth()
        imgui.NextColumn()
    end
    imgui.SetColumnWidth(1, imgui.GetWindowWidth() * 0.5)
    for i = halfMine + 1, #mineOrder do
        local k = mineOrder[i]
        local cur = mineDailyRes[k] or 0
        local g = mineGoalEditCache[k].v
        local p = math.min(cur / g, 1.0)
        imgui.Text(u8(configs[WORK_TYPES.MINE].resourceNames[k] .. ": " .. formatNumber(cur) .. " / " .. formatNumber(g)))
        imgui.ProgressBar(p, imgui.ImVec2(-1, 15), u8(math.floor(p * 100) .. "%"))
        imgui.PushItemWidth(imgui.GetColumnWidth() - 10)
        imgui.InputInt("##goal_mine_global_" .. k, mineGoalEditCache[k], 10, 100)
        imgui.PopItemWidth()
        if i < #mineOrder then imgui.NextColumn() end
    end
    imgui.Columns(1)
    imgui.Spacing()
    local btnWidth = imgui.GetWindowWidth() / 2 - 10
    if StyleButton(u8("Сохранить цели"), nil, btnWidth) then
        local saveData = {}
        for _, k in ipairs(mineOrder) do
            saveData[k] = mineGoalEditCache[k].v
        end
        local f = io.open(mineGoalsConfigPath, "w")
        if f then f:write(encodeJson(saveData)); f:close() end
        sampAddChatMessage(SCRIPT_PREFIX.."Цели шахты сохранены!", SCRIPT_COLOR)
    end
    imgui.SameLine()
    if StyleButton(u8("Сбросить прогресс"), nil, btnWidth) then
        local saveData = {}
        for _, k in ipairs(mineOrder) do
            saveData[k] = {reached = false, amount = 0}
        end
        saveData.dailyTotal = 0
        local f = io.open(mineGoalsProgressPath, "w")
        if f then f:write(encodeJson(saveData)); f:close() end
        if currentWork == WORK_TYPES.MINE then
            for _, k in ipairs(mineOrder) do
                goalsReached[k] = false; dailyResources[k] = 0
            end
            dailyTotal = 0
        end
        sampAddChatMessage(SCRIPT_PREFIX.."Прогресс целей шахты сброшен!", SCRIPT_COLOR)
    end
end

function drawSawmillGoals()
    local sawGoals = {}
    local sawDailyRes = {}
    
    local sgf = io.open(sawmillGoalsConfigPath, "r")
    if sgf then
        local data = decodeJson(sgf:read("*a"))
        sgf:close()
        if data then
            for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
                sawGoals[k] = data[k] or configs[WORK_TYPES.SAWMILL].defaultGoals[k]
            end
        end
    else
        for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
            sawGoals[k] = configs[WORK_TYPES.SAWMILL].defaultGoals[k]
        end
    end
    
    local spf = io.open(sawmillGoalsProgressPath, "r")
    if spf then
        local data = decodeJson(spf:read("*a"))
        spf:close()
        if data then
            for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
                if data[k] then
                    sawDailyRes[k] = data[k].amount or 0
                else
                    sawDailyRes[k] = 0
                end
            end
        end
    else
        for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
            sawDailyRes[k] = 0
        end
    end
    
    if currentWork == WORK_TYPES.SAWMILL then
        for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
            sawGoals[k] = sawGoals[k] or goals[k]
            sawDailyRes[k] = dailyResources[k] or 0
        end
    end
    
    for _, k in ipairs(configs[WORK_TYPES.SAWMILL].resourceOrder) do
        if not sawmillGoalEditCache[k] then
            sawmillGoalEditCache[k] = imgui.ImInt(sawGoals[k])
        end
    end
    
    local sawOrder = configs[WORK_TYPES.SAWMILL].resourceOrder
    for _, k in ipairs(sawOrder) do
        local cur = sawDailyRes[k] or 0
        local g = sawmillGoalEditCache[k].v
        local p = math.min(cur / g, 1.0)
        imgui.Text(u8(configs[WORK_TYPES.SAWMILL].resourceNames[k] .. ": " .. formatNumber(cur) .. " / " .. formatNumber(g)))
        imgui.ProgressBar(p, imgui.ImVec2(-1, 15), u8(math.floor(p * 100) .. "%"))
        imgui.PushItemWidth(200)
        imgui.InputInt("##goal_saw_global_" .. k, sawmillGoalEditCache[k], 10, 100)
        imgui.PopItemWidth()
    end
    imgui.Spacing()
    local btnWidth = imgui.GetWindowWidth() / 2 - 10
    if StyleButton(u8("Сохранить цели"), nil, btnWidth) then
        local saveData = {}
        for _, k in ipairs(sawOrder) do
            saveData[k] = sawmillGoalEditCache[k].v
        end
        local f = io.open(sawmillGoalsConfigPath, "w")
        if f then f:write(encodeJson(saveData)); f:close() end
        sampAddChatMessage(SCRIPT_PREFIX.."Цели лесопилки сохранены!", SCRIPT_COLOR)
    end
    imgui.SameLine()
    if StyleButton(u8("Сбросить прогресс"), nil, btnWidth) then
        local saveData = {}
        for _, k in ipairs(sawOrder) do
            saveData[k] = {reached = false, amount = 0}
        end
        saveData.dailyTotal = 0
        local f = io.open(sawmillGoalsProgressPath, "w")
        if f then f:write(encodeJson(saveData)); f:close() end
        if currentWork == WORK_TYPES.SAWMILL then
            for _, k in ipairs(sawOrder) do
                goalsReached[k] = false; dailyResources[k] = 0
            end
            dailyTotal = 0
        end
        sampAddChatMessage(SCRIPT_PREFIX.."Прогресс целей лесопилки сброшен!", SCRIPT_COLOR)
    end
end

function drawItemMarketTab()
    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Item Market — Аренда предметов"))
    imgui.Separator()
    imgui.Spacing()
    
    local totalIM = 0
    local todayIM = 0
    local weekIM = 0
    local todayDate = getGameDate()
    
local mskTime = getMoscowTime()
local mskWday = tonumber(os.date("%w", mskTime))
if mskWday == 0 then mskWday = 7 end

for _, log in ipairs(itemMarketLog) do
    totalIM = totalIM + log.amount
    local ld = getGameDate(log.time)
    if ld == todayDate then todayIM = todayIM + log.amount end
end

-- Неделя с понедельника по сегодня
local daysSinceMonday = mskWday - 1
for i = 0, daysSinceMonday do
    local date = getGameDate(os.time() - i * 86400)
    for _, log in ipairs(itemMarketLog) do
        if getGameDate(log.time) == date then
            weekIM = weekIM + log.amount
        end
    end
end
    
    local drawList = imgui.GetWindowDrawList()
    local spacing = 8
    local cardWidth = (imgui.GetWindowWidth() - 25 - spacing * 2) / 3
    local cardHeight = 55
    local startPos = imgui.GetCursorScreenPos()
    
    -- Общий заработок
    drawList:AddRectFilled(startPos, imgui.ImVec2(startPos.x + cardWidth, startPos.y + cardHeight), 0xFF1A1A1A, 6)
    drawList:AddRect(startPos, imgui.ImVec2(startPos.x + cardWidth, startPos.y + cardHeight), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(startPos.x + 10, startPos.y + 8), 0xFF888888, u8("Общий заработок"))
    drawList:AddText(imgui.ImVec2(startPos.x + 10, startPos.y + 28), 0xFF1AE591, formatNumber(totalIM) .. "$")
    
    -- За сегодня
    local pos2 = imgui.ImVec2(startPos.x + cardWidth + spacing, startPos.y)
    drawList:AddRectFilled(pos2, imgui.ImVec2(pos2.x + cardWidth, pos2.y + cardHeight), 0xFF1A1A1A, 6)
    drawList:AddRect(pos2, imgui.ImVec2(pos2.x + cardWidth, pos2.y + cardHeight), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(pos2.x + 10, pos2.y + 8), 0xFF888888, u8("За сегодня"))
    drawList:AddText(imgui.ImVec2(pos2.x + 10, pos2.y + 28), 0xFFFFCC00, formatNumber(todayIM) .. "$")
    
    -- За неделю
    local pos3 = imgui.ImVec2(startPos.x + cardWidth * 2 + spacing * 2, startPos.y)
    drawList:AddRectFilled(pos3, imgui.ImVec2(pos3.x + cardWidth, pos3.y + cardHeight), 0xFF1A1A1A, 6)
    drawList:AddRect(pos3, imgui.ImVec2(pos3.x + cardWidth, pos3.y + cardHeight), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(pos3.x + 10, pos3.y + 8), 0xFF888888, u8("За неделю"))
    drawList:AddText(imgui.ImVec2(pos3.x + 10, pos3.y + 28), 0xFF33CCFF, formatNumber(weekIM) .. "$")
    
    imgui.SetCursorScreenPos(imgui.ImVec2(startPos.x, startPos.y + cardHeight))
    imgui.Dummy(imgui.ImVec2(imgui.GetWindowWidth() - 25, 0))
    
    imgui.Spacing()
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    
    -- Заголовок истории
    local headerText = u8("История аренд")
    local headerW = imgui.CalcTextSize(headerText).x
    imgui.SetCursorPosX((imgui.GetWindowWidth() - headerW) / 2)
    imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), headerText)
    imgui.Spacing()
    
    local listW = imgui.GetWindowWidth() - 25
    
    -- Группируем записи по датам
    local datesMap = {}
    local datesOrder = {}
    for i = 1, math.min(#itemMarketLog, 50) do
        local log = itemMarketLog[i]
        local msk = log.time + 10800
        local currentDate = os.date("!%d.%m.%Y", msk)
        if not datesMap[currentDate] then
            datesMap[currentDate] = {}
            table.insert(datesOrder, currentDate)
        end
        table.insert(datesMap[currentDate], log)
    end
    
    for _, dateStr in ipairs(datesOrder) do
        local logs = datesMap[dateStr]
        local daySum = 0
        for _, log in ipairs(logs) do daySum = daySum + log.amount end
        
        -- Карточка даты
        local dateCardY = imgui.GetCursorScreenPos().y
        local dateCardX = imgui.GetCursorScreenPos().x
        local dateCardH = 38
        local hovered = (imgui.GetMousePos().x >= dateCardX and imgui.GetMousePos().x <= dateCardX + listW and 
                        imgui.GetMousePos().y >= dateCardY and imgui.GetMousePos().y <= dateCardY + dateCardH)
        
        drawList:AddRectFilled(imgui.ImVec2(dateCardX, dateCardY), imgui.ImVec2(dateCardX + listW, dateCardY + dateCardH), 
            hovered and 0xFF222222 or 0xFF1A1A1A, 6)
        drawList:AddRect(imgui.ImVec2(dateCardX, dateCardY), imgui.ImVec2(dateCardX + listW, dateCardY + dateCardH), 
            0xFF333333, 6, 15, 1.0)
        drawList:AddText(imgui.ImVec2(dateCardX + 10, dateCardY + 10), 0xFF1AE591, fa.ICON_CALENDAR)
        drawList:AddText(imgui.ImVec2(dateCardX + 35, dateCardY + 4), 0xFF1AE591, dateStr)
        
        local infoText = formatNumber(daySum) .. "$  •  " .. #logs .. " " .. u8("аренд")
        drawList:AddText(imgui.ImVec2(dateCardX + 35, dateCardY + 20), 0xFF888888, infoText)
        
        imgui.SetCursorScreenPos(imgui.ImVec2(dateCardX, dateCardY))
        local clicked = imgui.InvisibleButton("##date_" .. dateStr, imgui.ImVec2(listW, dateCardH))
        
        if not datesExpanded then datesExpanded = {} end
        if datesExpanded[dateStr] == nil then datesExpanded[dateStr] = false end
        if clicked then datesExpanded[dateStr] = not datesExpanded[dateStr] end
        
        if datesExpanded[dateStr] then
            imgui.Spacing()
            
            -- Заголовки колонок
            local colCardY = imgui.GetCursorScreenPos().y
            local colCardX = imgui.GetCursorScreenPos().x
            local colCardH = 22
            drawList:AddRectFilled(imgui.ImVec2(colCardX, colCardY), imgui.ImVec2(colCardX + listW, colCardY + colCardH), 0xFF222222, 4)
            drawList:AddText(imgui.ImVec2(colCardX + 12, colCardY + 3), 0xFF888888, u8("Время"))
            local nickHdr = u8("Ник"); local nickHdrW = imgui.CalcTextSize(nickHdr).x
            drawList:AddText(imgui.ImVec2(colCardX + listW / 2 - nickHdrW / 2, colCardY + 3), 0xFF888888, nickHdr)
            local sumHdr = u8("Заработано"); local sumHdrW = imgui.CalcTextSize(sumHdr).x
            drawList:AddText(imgui.ImVec2(colCardX + listW - sumHdrW - 12, colCardY + 3), 0xFF888888, sumHdr)
            imgui.Dummy(imgui.ImVec2(listW, colCardH + 4))
            
            for _, log in ipairs(logs) do
                local msk = log.time + 10800
                local timeStr = os.date("!%H:%M", msk)
                local cardPos = imgui.GetCursorScreenPos()
                local listH = 38
                
                drawList:AddRectFilled(cardPos, imgui.ImVec2(cardPos.x + listW, cardPos.y + listH), 0xFF1A1A1A, 6)
                drawList:AddRect(cardPos, imgui.ImVec2(cardPos.x + listW, cardPos.y + listH), 0xFF333333, 6, 15, 1.0)
                drawList:AddText(imgui.ImVec2(cardPos.x + 12, cardPos.y + 10), 0xFFCCCCCC, timeStr)
                
                local nickW = imgui.CalcTextSize(log.nick).x
                drawList:AddText(imgui.ImVec2(cardPos.x + listW / 2 - nickW / 2, cardPos.y + 10), 0xFFFFFFFF, log.nick)
                
                local amtStr = formatNumber(log.amount) .. "$"; local amtW = imgui.CalcTextSize(amtStr).x
                drawList:AddText(imgui.ImVec2(cardPos.x + listW - amtW - 12, cardPos.y + 10), 0xFF1AE591, amtStr)
                
                imgui.SetCursorScreenPos(imgui.ImVec2(cardPos.x, cardPos.y + listH))
                imgui.Dummy(imgui.ImVec2(listW, 2))
            end
            imgui.Spacing()
        end
    end
    
    if #itemMarketLog == 0 then
        imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Нет записей об аренде"))
    end
    
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    if imgui.Button(u8("Сбросить историю"), imgui.ImVec2(-1, 25)) then
        itemMarketLog = {}; datesExpanded = {}; saveItemMarketStats()
        sampAddChatMessage(SCRIPT_PREFIX .. "История аренды сброшена!", SCRIPT_COLOR)
    end
end

function drawGoalsTab()
    local drawList = imgui.GetWindowDrawList()
    local listW = imgui.GetWindowWidth() - 25
    local cardH = 38
    
    -- Цели Фермы
    local cardY = imgui.GetCursorScreenPos().y
    local cardX = imgui.GetCursorScreenPos().x
    local hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and 
                    imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
        hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_LEAF)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цели на сегодня (Ферма)"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not goalsExpandedFarm then goalsExpandedFarm = false end
    if imgui.InvisibleButton("##goals_farm", imgui.ImVec2(listW, cardH)) then goalsExpandedFarm = not goalsExpandedFarm end
    if goalsExpandedFarm then imgui.Spacing(); drawFarmGoals(); imgui.Spacing() end
    
    -- Цели Шахты
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_GAVEL)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цели на сегодня (Шахта)"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not goalsExpandedMine then goalsExpandedMine = false end
    if imgui.InvisibleButton("##goals_mine", imgui.ImVec2(listW, cardH)) then goalsExpandedMine = not goalsExpandedMine end
    if goalsExpandedMine then imgui.Spacing(); drawMineGoals(); imgui.Spacing() end
    
    -- Цели Лесопилки
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_TREE)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цели на сегодня (Лесопилка)"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not goalsExpandedSaw then goalsExpandedSaw = false end
    if imgui.InvisibleButton("##goals_saw", imgui.ImVec2(listW, cardH)) then goalsExpandedSaw = not goalsExpandedSaw end
    if goalsExpandedSaw then imgui.Spacing(); drawSawmillGoals(); imgui.Spacing() end
    
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    
       -- Общие цели
    cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
    hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_BULLSEYE)
    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Общие цели"))
    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
    if not goalsExpandedGeneral then goalsExpandedGeneral = false end
    if imgui.InvisibleButton("##goals_general", imgui.ImVec2(listW, cardH)) then goalsExpandedGeneral = not goalsExpandedGeneral end
    if goalsExpandedGeneral then
        imgui.Spacing()
        local progress = settings.totalIncomeGoal > 0 and math.min(totalDailyIncome / settings.totalIncomeGoal, 1.0) or 0
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Общий доход за сегодня:"))
        imgui.Spacing()
        imgui.Text(u8("Доход: ")); imgui.SameLine(); imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(totalDailyIncome) .. "$")
        imgui.Text(u8("Цель: ")); imgui.SameLine(); imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(settings.totalIncomeGoal) .. "$")
        imgui.ProgressBar(progress, imgui.ImVec2(-1, 20), u8(math.floor(progress * 100) .. "%"))
        if totalIncomeGoalReached then imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), u8("Цель достигнута!")) end
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        imgui.Text(u8("Настройка цели:")); imgui.PushItemWidth(250)
        if imgui.InputInt("##total_income_goal", totalGoalEdit, 100000, 1000000) then
            if totalGoalEdit.v >= 0 then settings.totalIncomeGoal = totalGoalEdit.v; totalIncomeGoalReached = false; saveTotalIncomeGoal() end
        end
        imgui.PopItemWidth(); imgui.Spacing()
        local btnW2 = (imgui.GetWindowWidth() - 25 - 8) / 2
        if StyleButton(u8("Сохранить цель"), nil, btnW2) then saveTotalIncomeGoal(); sampAddChatMessage(SCRIPT_PREFIX .. "Общая цель дохода сохранена!", SCRIPT_COLOR) end
        imgui.SameLine()
        if StyleButton(u8("Сбросить"), nil, btnW2) then totalIncomeGoalReached = false; totalDailyIncome = 0; totalIncomeCacheTime = 0; saveTotalIncomeGoal(); sampAddChatMessage(SCRIPT_PREFIX .. "Прогресс общей цели сброшен!", SCRIPT_COLOR) end
        imgui.Spacing()
    end
end

function drawAchievementsTab()
    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Достижения"))
    imgui.Separator()
    imgui.Spacing()
    
    local categories = {u8("Все"), u8("Ферма"), u8("Шахта"), u8("Лесопилка"), u8("Item Market"), u8("Общие")}
    imgui.Text(u8("Категория:"))
    imgui.SameLine()
    imgui.PushItemWidth(150)
    if imgui.Combo("##ach_cat_filter", achCategoryFilter, table.concat(categories, "\0") .. "\0") then end
    imgui.PopItemWidth()
    imgui.Spacing()
    
    local completedCount = 0
    local totalCount = 0
    for _, ach in ipairs(ACHIEVEMENTS) do
        if achCategoryFilter.v == 0 or ach.category == u8:decode(categories[achCategoryFilter.v + 1]) then
            totalCount = totalCount + 1
            if ach.completed then completedCount = completedCount + 1 end
        end
    end
    local overallProgress = totalCount > 0 and (completedCount / totalCount) or 0
    imgui.Text(u8("Выполнено: ") .. completedCount .. " / " .. totalCount)
    imgui.ProgressBar(overallProgress, imgui.ImVec2(-1, 15), u8(math.floor(overallProgress * 100) .. "%"))
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    
    local sortedAchievements = {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        if achCategoryFilter.v == 0 or ach.category == u8:decode(categories[achCategoryFilter.v + 1]) then
            table.insert(sortedAchievements, ach)
        end
    end
    table.sort(sortedAchievements, function(a, b)
        local progressA = a.completed and 1.0 or math.min(a.progress / a.target, 1.0)
        local progressB = b.completed and 1.0 or math.min(b.progress / b.target, 1.0)
        return progressA > progressB
    end)
    
    for _, ach in ipairs(sortedAchievements) do
        imgui.AchievementCard(ach)
    end
end

function imgui.OnDrawFrame()
    if not mainWin.v and not settings.farmOverlayEnabled and not settings.mineOverlayEnabled and not settings.sawmillOverlayEnabled then return end
    
        local theme
    if useCustomTheme then
        theme = CUSTOM_THEME
    else
        theme = THEME_CONFIGS[currentTheme]
    end
    
    -- Оверлей фермы
    if settings.farmOverlayEnabled then
        local cfg = overlayConfigs[WORK_TYPES.FARM]
        imgui.SetNextWindowPos(imgui.ImVec2(cfg.x, cfg.y), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(cfg.w, cfg.h), imgui.Cond.FirstUseEver)
        
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0)
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 6))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGrip, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGripHovered, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGripActive, imgui.ImVec4(0, 0, 0, 0))
        
        imgui.Begin(u8("Добыча за сегодня (Ферма)"), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
        
        local winPos = imgui.GetWindowPos()
        local winSize = imgui.GetWindowSize()
        local drawList = imgui.GetWindowDrawList()
        
        -- Основной фон
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + winSize.y), 0xFF141414)
        
        -- Верхняя плашка (заголовок)
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + 22), 0xFF0E0E0E)
        
        -- Текст заголовка по центру
        local titleText = u8("Ферма")
        local titleWidth = imgui.CalcTextSize(titleText).x
        drawList:AddText(imgui.ImVec2(winPos.x + (winSize.x - titleWidth) / 2, winPos.y + 3), 0xFF1AE591, titleText)
        
        -- Тонкий разделитель под заголовком
        drawList:AddLine(imgui.ImVec2(winPos.x, winPos.y + 22), imgui.ImVec2(winPos.x + winSize.x, winPos.y + 22), 0xFF2A2A2A, 1.0)
        
        imgui.SetCursorPos(imgui.ImVec2(8, 28))
        if currentWork == WORK_TYPES.FARM then
            local todayData = getTodayStats()
            local todayTotal = todayData.total
            for _, k in ipairs(config.resourceOrder) do 
                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)) 
            end
            imgui.Spacing()
            -- Разделитель перед доходом
            local cursorY = imgui.GetCursorPosY()
            imgui.SetCursorPos(imgui.ImVec2(8, cursorY + 2))
            drawList:AddLine(imgui.ImVec2(winPos.x + 8, winPos.y + cursorY + 2), imgui.ImVec2(winPos.x + winSize.x - 8, winPos.y + cursorY + 2), 0xFF2A2A2A, 1.0)
            imgui.SetCursorPos(imgui.ImVec2(8, cursorY + 8))
            imgui.Text(u8("Доход: ")); imgui.SameLine(); 
            imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(todayTotal) .. "$")
            
            if settings.overlayTimerEnabled then
                imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
                imgui.Text(u8("Время работы: ")); imgui.SameLine(); 
                if overlayTimer.running then
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 1.0, 1), overlayTimer.displayedTime)
                else
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("00:00:00"))
                end
            end
        else 
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Переключитесь на ферму")) 
        end
        
        local pos, size = imgui.GetWindowPos(), imgui.GetWindowSize()
        if pos and pos.x > 0 and pos.y > 0 and (cfg.x ~= pos.x or cfg.y ~= pos.y or cfg.w ~= size.x or cfg.h ~= size.y) then 
            cfg.x, cfg.y, cfg.w, cfg.h = pos.x, pos.y, size.x, size.y; saveOverlayConfig()
        end
        
        imgui.End()
        imgui.PopStyleColor(5)
        imgui.PopStyleVar(2)
    end
    
    -- Оверлей шахты
    if settings.mineOverlayEnabled then
        local cfg = overlayConfigs[WORK_TYPES.MINE]
        imgui.SetNextWindowPos(imgui.ImVec2(cfg.x, cfg.y), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(cfg.w, cfg.h), imgui.Cond.FirstUseEver)
        
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0)
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 6))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGrip, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGripHovered, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGripActive, imgui.ImVec4(0, 0, 0, 0))
        
        imgui.Begin(u8("Добыча за сегодня (Шахта)"), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
        
        local winPos = imgui.GetWindowPos()
        local winSize = imgui.GetWindowSize()
        local drawList = imgui.GetWindowDrawList()
        
        -- Основной фон
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + winSize.y), 0xFF141414)
        
        -- Верхняя плашка (заголовок)
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + 22), 0xFF0E0E0E)
        
        -- Текст заголовка по центру
        local titleText = u8("Шахта")
        local titleWidth = imgui.CalcTextSize(titleText).x
        drawList:AddText(imgui.ImVec2(winPos.x + (winSize.x - titleWidth) / 2, winPos.y + 3), 0xFF1AE591, titleText)
        
        -- Тонкий разделитель под заголовком
        drawList:AddLine(imgui.ImVec2(winPos.x, winPos.y + 22), imgui.ImVec2(winPos.x + winSize.x, winPos.y + 22), 0xFF2A2A2A, 1.0)
        
        imgui.SetCursorPos(imgui.ImVec2(8, 28))
        if currentWork == WORK_TYPES.MINE then
            local todayData = getTodayStats()
            local todayTotal = todayData.total
            local contentWidth = winSize.x - 16
            local colWidth = contentWidth / 2
            
            imgui.Columns(2, "overlay_mine_cols", false)
            imgui.SetColumnWidth(0, colWidth - 24)
            for _, k in ipairs(config.leftColumnOrder) do 
                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)); imgui.NextColumn() 
            end
            imgui.SetColumnWidth(1, colWidth + 20)
            for _, k in ipairs(config.rightColumnOrder) do 
                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)); imgui.NextColumn() 
            end
            imgui.Columns(1)
            
            imgui.Spacing()
            local cursorY = imgui.GetCursorPosY()
            imgui.SetCursorPos(imgui.ImVec2(8, cursorY + 2))
            drawList:AddLine(imgui.ImVec2(winPos.x + 8, winPos.y + cursorY + 2), imgui.ImVec2(winPos.x + winSize.x - 8, winPos.y + cursorY + 2), 0xFF2A2A2A, 1.0)
            imgui.SetCursorPos(imgui.ImVec2(8, cursorY + 8))
            
            imgui.Text(u8("Доход: ")); imgui.SameLine(); 
            imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(todayTotal) .. "$")
            
            if settings.overlayTimerEnabled then
                imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
                imgui.Text(u8("Время работы: ")); imgui.SameLine(); 
                if overlayTimer.running then
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 1.0, 1), overlayTimer.displayedTime)
                else
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("00:00:00"))
                end
            end
        else 
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Переключитесь на шахту")) 
        end
        
        local pos, size = imgui.GetWindowPos(), imgui.GetWindowSize()
        if pos and pos.x > 0 and pos.y > 0 and (cfg.x ~= pos.x or cfg.y ~= pos.y or cfg.w ~= size.x or cfg.h ~= size.y) then 
            cfg.x, cfg.y, cfg.w, cfg.h = pos.x, pos.y, size.x, size.y; saveOverlayConfig()
        end
        
        imgui.End()
        imgui.PopStyleColor(5)
        imgui.PopStyleVar(2)
    end
    
    -- Оверлей лесопилки
    if settings.sawmillOverlayEnabled then
        local cfg = overlayConfigs[WORK_TYPES.SAWMILL]
        imgui.SetNextWindowPos(imgui.ImVec2(cfg.x, cfg.y), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(cfg.w, cfg.h), imgui.Cond.FirstUseEver)
        
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0)
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 6))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGrip, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGripHovered, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ResizeGripActive, imgui.ImVec4(0, 0, 0, 0))
        
        imgui.Begin(u8("Добыча за сегодня (Лесопилка)"), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
        
        local winPos = imgui.GetWindowPos()
        local winSize = imgui.GetWindowSize()
        local drawList = imgui.GetWindowDrawList()
        
        -- Основной фон
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + winSize.y), 0xFF141414)
        
        -- Верхняя плашка (заголовок)
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + 22), 0xFF0E0E0E)
        
        -- Текст заголовка по центру
        local titleText = u8("Лесопилка")
        local titleWidth = imgui.CalcTextSize(titleText).x
        drawList:AddText(imgui.ImVec2(winPos.x + (winSize.x - titleWidth) / 2, winPos.y + 3), 0xFF1AE591, titleText)
        
        -- Тонкий разделитель под заголовком
        drawList:AddLine(imgui.ImVec2(winPos.x, winPos.y + 22), imgui.ImVec2(winPos.x + winSize.x, winPos.y + 22), 0xFF2A2A2A, 1.0)
        
        imgui.SetCursorPos(imgui.ImVec2(8, 28))
        if currentWork == WORK_TYPES.SAWMILL then
            local todayData = getTodayStats()
            local todayTotal = todayData.total
            for _, k in ipairs(config.resourceOrder) do 
                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)) 
            end
            imgui.Spacing()
            local cursorY = imgui.GetCursorPosY()
            imgui.SetCursorPos(imgui.ImVec2(8, cursorY + 2))
            drawList:AddLine(imgui.ImVec2(winPos.x + 8, winPos.y + cursorY + 2), imgui.ImVec2(winPos.x + winSize.x - 8, winPos.y + cursorY + 2), 0xFF2A2A2A, 1.0)
            imgui.SetCursorPos(imgui.ImVec2(8, cursorY + 8))
            imgui.Text(u8("Доход: ")); imgui.SameLine(); 
            imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(todayTotal) .. "$")
            
            if settings.overlayTimerEnabled then
                imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
                imgui.Text(u8("Время работы: ")); imgui.SameLine(); 
                if overlayTimer.running then
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 1.0, 1), overlayTimer.displayedTime)
                else
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("00:00:00"))
                end
            end
        else 
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Переключитесь на лесопилку")) 
        end
        
        local pos, size = imgui.GetWindowPos(), imgui.GetWindowSize()
        if pos and pos.x > 0 and pos.y > 0 and (cfg.x ~= pos.x or cfg.y ~= pos.y or cfg.w ~= size.x or cfg.h ~= size.y) then 
            cfg.x, cfg.y, cfg.w, cfg.h = pos.x, pos.y, size.x, size.y; saveOverlayConfig()
        end
        
        imgui.End()
        imgui.PopStyleColor(5)
        imgui.PopStyleVar(2)
    end
    
    -- Главное меню в новом стиле
    if mainWin.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowSize(imgui.ImVec2(955, 550), imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        
        -- Убираем все рамки и отступы
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(4, 4))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        
        local title = u8("Resource Helper v" .. scr.version)
        if newversion ~= scr.version then
            title = title .. u8(" (обновление!)")
        end
        
        imgui.Begin(title, mainWin, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoBringToFrontOnFocus)
        
        -- Ченжлог попап
        if not changelogShown then
            if changelogData then
                imgui.SetNextWindowSizeConstraints(imgui.ImVec2(500, 200), imgui.ImVec2(600, 600))
                imgui.OpenPopup(u8("Что нового?##changelog"))
            else
                downloadChangelog()
            end
        end
        if imgui.BeginPopupModal(u8("Что нового?##changelog"), nil, imgui.WindowFlags.AlwaysAutoResize) then
            local winWidth = imgui.GetWindowWidth()
            local headerText = u8("Обновление до версии " .. scr.version)
            local headerWidth = imgui.CalcTextSize(headerText).x
            imgui.SetCursorPosX((winWidth - headerWidth) / 2)
            imgui.Text(headerText)
            imgui.Separator()
            imgui.Spacing()
            if changelogData and changelogData[scr.version] then
                for _, change in ipairs(changelogData[scr.version]) do
                    imgui.Bullet(); imgui.SameLine()
                    imgui.PushTextWrapPos()
                    imgui.TextWrapped(u8(change))
                    imgui.PopTextWrapPos()
                end
            else
                imgui.Text(u8("Список изменений загружается..."))
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            local btnW = 120
            imgui.SetCursorPosX((winWidth - btnW) / 2)
            if imgui.Button(u8("Понятно"), imgui.ImVec2(btnW, 25)) then
                markChangelogAsShown()
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end
        
        local winPos = imgui.GetWindowPos()
        local winSize = imgui.GetWindowSize()
        local drawList = imgui.GetWindowDrawList()
        
        -- Фон всего окна (тема)
        drawList:AddRectFilled(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + winSize.y), imVec4ToHex(theme.windowBg), 6)
        
        -- Левая панель (тема)
        local leftPanelWidth = 190
        drawList:AddRectFilled(
            imgui.ImVec2(winPos.x, winPos.y),
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y + winSize.y),
            imVec4ToHex(theme.leftPanelBg), 6, 9
        )
        -- Тонкая линия-разделитель между панелями (тема)
        drawList:AddLine(
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y),
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y + winSize.y),
            imVec4ToHex(theme.borderColor), 1.0
        )
        
        -- Верхняя панель - левая часть (тема)
        drawList:AddRectFilled(
            imgui.ImVec2(winPos.x + 6, winPos.y),
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y + 45),
            imVec4ToHex(theme.titleBg), 0, 0
        )
        -- Верхняя панель - правая часть (тема)
        drawList:AddRectFilled(
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y),
            imgui.ImVec2(winPos.x + winSize.x - 6, winPos.y + 45),
            imVec4ToHex(theme.rightTitleBg), 0, 6
        )
        
        -- Разделитель в заголовке между левой и правой частью (тема)
        drawList:AddLine(
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y + 8),
            imgui.ImVec2(winPos.x + leftPanelWidth, winPos.y + 37),
            imVec4ToHex(theme.borderColor), 1.0
        )
        
        -- Кнопка перезагрузки
        local reloadX = winPos.x + winSize.x - 70
        local reloadY = winPos.y + 10
        local reloadHovered = (imgui.GetMousePos().x >= reloadX and imgui.GetMousePos().x <= reloadX + 25 and 
                              imgui.GetMousePos().y >= reloadY and imgui.GetMousePos().y <= reloadY + 25)
        
        drawList:AddRectFilled(imgui.ImVec2(reloadX, reloadY), imgui.ImVec2(reloadX + 25, reloadY + 25), 
            reloadHovered and 0xFF3A3A3A or 0xFF222222, 4)
        drawList:AddRect(imgui.ImVec2(reloadX, reloadY), imgui.ImVec2(reloadX + 25, reloadY + 25), 
            0xFF444444, 4, 15, 1.0)
        
        local reloadIconW = imgui.CalcTextSize(fa.ICON_REPEAT).x
        local reloadIconH = imgui.CalcTextSize(fa.ICON_REPEAT).y
        drawList:AddText(imgui.ImVec2(reloadX + (25 - reloadIconW) / 2, reloadY + (25 - reloadIconH) / 2), 
            reloadHovered and 0xFFFFFFFF or 0xFF888888, fa.ICON_REPEAT)
        
        if reloadHovered and imgui.IsMouseClicked(0) then 
            consumeWindowMessage(true, false)
            showCursor(false); scr:reload() 
        end
        
        -- Кнопка закрытия
        local closeX = winPos.x + winSize.x - 35
        local closeY = winPos.y + 10
        local closeHovered = (imgui.GetMousePos().x >= closeX and imgui.GetMousePos().x <= closeX + 25 and 
                             imgui.GetMousePos().y >= closeY and imgui.GetMousePos().y <= closeY + 25)
        
        drawList:AddRectFilled(imgui.ImVec2(closeX, closeY), imgui.ImVec2(closeX + 25, closeY + 25), 
            closeHovered and 0xFF3A3A3A or 0xFF222222, 4)
        drawList:AddRect(imgui.ImVec2(closeX, closeY), imgui.ImVec2(closeX + 25, closeY + 25), 
            0xFF444444, 4, 15, 1.0)
        
        local closeIconW = imgui.CalcTextSize(fa.ICON_TIMES).x
        local closeIconH = imgui.CalcTextSize(fa.ICON_TIMES).y
        drawList:AddText(imgui.ImVec2(closeX + (25 - closeIconW) / 2, closeY + (25 - closeIconH) / 2), 
            closeHovered and 0xFFFFFFFF or 0xFF888888, fa.ICON_TIMES)
        
        if closeHovered and imgui.IsMouseReleased(0) then
            mainWin.v = false
            imgui.ShowCursor = false
        end
        
        -- Иконка в левом верхнем углу (тема)
        imgui.SetCursorPos(imgui.ImVec2(15, 15))
        if useCustomTheme then
    imgui.TextColored(theme.accent, fa.ICON_WRENCH .. "  Resource Helper")
else
    imgui.TextColored(hexToImVec4(theme.accent), fa.ICON_WRENCH .. "  Resource Helper")
end
        imgui.SetCursorPos(imgui.ImVec2(10, 40))
        imgui.Separator()
        imgui.Spacing()
        
        -- Кнопки навигации
        local menuItems = {
    {title = u8("Главная"), icon = fa.ICON_HOME, id = 1},
    {title = u8("Ферма"), icon = fa.ICON_LEAF, id = 2},
    {title = u8("Шахта"), icon = fa.ICON_GAVEL, id = 3},
    {title = u8("Лесопилка"), icon = fa.ICON_TREE, id = 4},
    {title = u8("Item Market"), icon = fa.ICON_SHOPPING_CART, id = 5},
    {title = u8("Рейтинг"), icon = fa.ICON_TROPHY, id = 6},
    {title = u8("Цели"), icon = fa.ICON_BULLSEYE, id = 7},
    {title = u8("Достижения"), icon = fa.ICON_STAR, id = 8},
    {title = u8("Биндер"), icon = fa.ICON_KEYBOARD_O, id = 9},
    {title = u8("Настройки"), icon = fa.ICON_WRENCH, id = 10},
    {title = u8("О скрипте"), icon = fa.ICON_SEARCH, id = 11},
}
        
        local currentMenuId = 1
        for i = 1, #menuItems do
            if select_menu[i] then currentMenuId = i; break end
        end
        
        -- Название текущего раздела в верхней панели (тема)
        imgui.SetCursorPos(imgui.ImVec2(leftPanelWidth + 20, 12))
        if useCustomTheme then
    imgui.TextColored(theme.headerTitle, menuItems[currentMenuId].icon .. "  " .. menuItems[currentMenuId].title)
else
    imgui.TextColored(hexToImVec4(theme.headerTitle), menuItems[currentMenuId].icon .. "  " .. menuItems[currentMenuId].title)
end
        
        -- Кнопки идут друг за другом без растягивания
        local topAreaEnd = winPos.y + 45
        local btnHeight = 38
        local spacing = 4  
        
        for idx, item in ipairs(menuItems) do
            local isActive = (idx == currentMenuId)
            local btnPosX = winPos.x + 7
            local btnPosY = topAreaEnd + spacing + (idx - 1) * (btnHeight + spacing)
            local btnHovered = (imgui.GetMousePos().x >= btnPosX and imgui.GetMousePos().x <= btnPosX + 178 and 
                               imgui.GetMousePos().y >= btnPosY and imgui.GetMousePos().y <= btnPosY + btnHeight)
            
            -- Фон кнопки (тема)
            local btnColor = nil
            if isActive then
                btnColor = theme.buttonActive
            elseif btnHovered then
                btnColor = theme.buttonHover
            end
            
            if btnColor then
    local valid = false
    if useCustomTheme then
        valid = (btnColor.w > 0)
    else
        valid = (btnColor ~= 0x00000000)
    end
    if valid then
        drawList:AddRectFilled(imgui.ImVec2(btnPosX, btnPosY), imgui.ImVec2(btnPosX + 178, btnPosY + btnHeight), imVec4ToHex(btnColor), 5)
    end
end
            
            -- Обводка только для активной кнопки
            if isActive then
                drawList:AddRect(imgui.ImVec2(btnPosX, btnPosY), imgui.ImVec2(btnPosX + 178, btnPosY + btnHeight), imVec4ToHex(theme.borderActive), 5, 15, 1.5)
            end
            
            -- Иконка и текст (тема)
            local textCol = theme.textNormal
            if isActive then
                textCol = theme.textActive
            elseif btnHovered then
                textCol = theme.textHover
            end
            drawList:AddText(imgui.ImVec2(btnPosX + 12, btnPosY + 9), imVec4ToHex(textCol), item.icon)
            drawList:AddText(imgui.ImVec2(btnPosX + 45, btnPosY + 9), imVec4ToHex(textCol), item.title)
            
            -- Обработка клика
if btnHovered and imgui.IsMouseClicked(0) then
    if scanState.active then

    else
        select_menu = {false, false, false, false, false, false, false, false, false, false}
        select_menu[idx] = true
        
        if idx == 2 then 
            switchWorkType(WORK_TYPES.FARM)
            if settings.mineOverlayEnabled or settings.sawmillOverlayEnabled then
                settings.farmOverlayEnabled = true
                settings.mineOverlayEnabled = false
                settings.sawmillOverlayEnabled = false
                cb_farm_overlay.v = true
                cb_mine_overlay.v = false
                cb_sawmill_overlay.v = false
                saveConfig()
            end
            if not scannedThisSession[WORK_TYPES.FARM] then
                pendingScan = WORK_TYPES.FARM
            end
            
        elseif idx == 3 then 
            switchWorkType(WORK_TYPES.MINE)
            if settings.farmOverlayEnabled or settings.sawmillOverlayEnabled then
                settings.mineOverlayEnabled = true
                settings.farmOverlayEnabled = false
                settings.sawmillOverlayEnabled = false
                cb_mine_overlay.v = true
                cb_farm_overlay.v = false
                cb_sawmill_overlay.v = false
                saveConfig()
            end
            if not scannedThisSession[WORK_TYPES.MINE] then
                pendingScan = WORK_TYPES.MINE
            end
            
        elseif idx == 4 then 
            switchWorkType(WORK_TYPES.SAWMILL)
            if settings.farmOverlayEnabled or settings.mineOverlayEnabled then
                settings.sawmillOverlayEnabled = true
                settings.farmOverlayEnabled = false
                settings.mineOverlayEnabled = false
                cb_sawmill_overlay.v = true
                cb_farm_overlay.v = false
                cb_mine_overlay.v = false
                saveConfig()
            end
            if not scannedThisSession[WORK_TYPES.SAWMILL] then
                pendingScan = WORK_TYPES.SAWMILL
            end
        end
    end
end
        end
        
        -- Версия внизу левой панели
        if newversion ~= "" and newversion ~= scr.version then
            drawList:AddText(imgui.ImVec2(winPos.x + 15, winPos.y + winSize.y - 40), 0xFF555555, "v" .. scr.version)
            local updateText = u8("Есть обновление v") .. newversion
            drawList:AddText(imgui.ImVec2(winPos.x + 15, winPos.y + winSize.y - 25), 0xFF1AE591, updateText)
        else
            drawList:AddText(imgui.ImVec2(winPos.x + 15, winPos.y + winSize.y - 25), 0xFF555555, "v" .. scr.version)
        end
        
        -- Правая панель (контент) с темой
        imgui.SetCursorPos(imgui.ImVec2(leftPanelWidth + 15, 55))
        
        local childX = winPos.x + leftPanelWidth + 15
        local childY = winPos.y + 55
        local childW = winSize.x - leftPanelWidth - 30
        local childH = winSize.y - 65
        drawList:AddRectFilled(
            imgui.ImVec2(childX, childY),
            imgui.ImVec2(childX + childW, childY + childH),
            imVec4ToHex(theme.childBg), 4
        )
        
        imgui.BeginChild("right_panel", imgui.ImVec2(childW, childH), false)
		
        if useCustomTheme then
            local style = imgui.GetStyle()
            local colors = style.Colors
            local clr = imgui.Col
            colors[clr.Text] = CUSTOM_THEME.contentText
            colors[clr.Button] = CUSTOM_THEME.imguiButton
            colors[clr.ButtonHovered] = CUSTOM_THEME.imguiButtonHovered
            colors[clr.ButtonActive] = CUSTOM_THEME.imguiButtonActive
            colors[clr.Header] = CUSTOM_THEME.collapsingHeader
            colors[clr.HeaderHovered] = CUSTOM_THEME.collapsingHeaderHovered
            colors[clr.HeaderActive] = CUSTOM_THEME.collapsingHeaderActive
            colors[clr.Separator] = CUSTOM_THEME.separatorColor
            colors[clr.CheckMark] = CUSTOM_THEME.checkMark
            colors[clr.SliderGrab] = CUSTOM_THEME.sliderGrab
            colors[clr.SliderGrabActive] = CUSTOM_THEME.sliderGrabActive
            colors[clr.FrameBg] = CUSTOM_THEME.frameBg
            colors[clr.FrameBgHovered] = CUSTOM_THEME.frameBgHovered
            colors[clr.FrameBgActive] = CUSTOM_THEME.frameBgActive
            colors[clr.TitleBgActive] = CUSTOM_THEME.titleBgActive
            colors[clr.TitleBgCollapsed] = CUSTOM_THEME.titleBgCollapsed
            colors[clr.PopupBg] = CUSTOM_THEME.childBg
        end
        
        imgui.Spacing()
		
        -- Содержимое разделов
        if select_menu[1] then
            if logoArz then
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 750) / 2)
                imgui.Image(logoArz, imgui.ImVec2(750, 224))
            end
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Добро пожаловать в Resource Helper!"))
            imgui.Spacing()
            imgui.TextWrapped(u8("Этот скрипт поможет вам отслеживать добычу ресурсов на ферме, шахте и лесопилке на проекте Arizona RP."))
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), u8("Возможности:"))
            imgui.BulletText(u8("Отслеживание добычи ресурсов в реальном времени"))
            imgui.BulletText(u8("Подсчет заработка за сессию"))
            imgui.BulletText(u8("Статистика за сегодня/неделю/все время"))
            imgui.BulletText(u8("Настройка целей и отслеживание прогресса"))
            imgui.BulletText(u8("Звуковые уведомления о редких ресурсах"))
            imgui.BulletText(u8("Оверлеи с информацией о добыче"))
            imgui.BulletText(u8("Биндер клавиш"))
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), u8("Текущий режим: " .. config.name))
            
        elseif select_menu[2] then
local scanBtnText
if scanState.active then 
    scanBtnText = u8("Сканирование...")
elseif scannedThisSession[currentWork] then 
    scanBtnText = u8("Пересканировать инвентарь")
else 
    scanBtnText = u8("Сканировать инвентарь") 
end

if scanState.active then
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    StyleButton(scanBtnText, fa.ICON_SEARCH)
    imgui.PopStyleColor(3)
else
    if StyleButton(scanBtnText, fa.ICON_SEARCH) then
        startInventoryScan()
    end
end
if scanState.active then 
    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Статус: " .. scanState.statusText))
elseif scannedThisSession[currentWork] then 
    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), u8("Инвентарь отсканирован"))
else 
    imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.2, 1), u8("Инвентарь не отсканирован!")) 
end
            imgui.Separator()
            if ToggleSwitch(u8("Считать ресурсы с фермы"), cb_farm) then settings.farmEnabled = cb_farm.v; saveConfig(); needSave = true end
            imgui.Separator()
            -- Цены за единицу (ферма)
            local drawList = imgui.GetWindowDrawList()
            local listW = imgui.GetWindowWidth() - 25
            local cardH = 38
            
            local cardY = imgui.GetCursorScreenPos().y
            local cardX = imgui.GetCursorScreenPos().x
            local hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and 
                            imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
                hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_MONEY)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цены за единицу"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not pricesExpandedFarm then pricesExpandedFarm = false end
            if imgui.InvisibleButton("##prices_farm", imgui.ImVec2(listW, cardH)) then 
                pricesExpandedFarm = not pricesExpandedFarm
                if pricesExpandedFarm and not pricesLoading then
                    loadGlobalPrices()
                end
            end
            if pricesExpandedFarm then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Цены средние по Vice City под SA. Авто-обновление раз в сутки."))
                imgui.Spacing()
				                if pricesLoading then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Цены обновляются..."))
                    imgui.Spacing()
                end
                if not globalPrices or not next(globalPrices) then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Цены загружаются..."))
                    imgui.Spacing()
                else
                local pos = imgui.GetCursorScreenPos()
                local tableWidth = imgui.GetWindowWidth() - 25
                local headerHeight = 28
                local rowHeight = 26
                local rows = #config.resourceOrder
                
                drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + rows * rowHeight), 0xFF141414, 6)
                drawList:AddRect(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + rows * rowHeight), 0xFF2A2A2A, 6, 15, 1.5)
                
                drawList:AddText(imgui.ImVec2(pos.x + 10, pos.y + 6), 0xFF1AE591, u8("Ресурс"))
                drawList:AddText(imgui.ImVec2(pos.x + tableWidth/2 + 10, pos.y + 6), 0xFF1AE591, u8("Цена"))
                
                drawList:AddLine(imgui.ImVec2(pos.x + 6, pos.y + headerHeight), imgui.ImVec2(pos.x + tableWidth - 6, pos.y + headerHeight), 0xFF2A2A2A, 1.5)
                drawList:AddLine(imgui.ImVec2(pos.x + tableWidth/2, pos.y + 8), imgui.ImVec2(pos.x + tableWidth/2, pos.y + headerHeight + rows * rowHeight - 4), 0xFF2A2A2A, 1.0)
                
                for i, k in ipairs(config.resourceOrder) do
                    local y = pos.y + headerHeight + (i - 1) * rowHeight
                    local bgColor = (i % 2 == 0) and 0xFF1E1E1E or 0xFF181818
                    drawList:AddRectFilled(imgui.ImVec2(pos.x + 2, y + 1), imgui.ImVec2(pos.x + tableWidth - 2, y + rowHeight - 1), bgColor)
                    if i > 1 then drawList:AddLine(imgui.ImVec2(pos.x + 6, y), imgui.ImVec2(pos.x + tableWidth - 6, y), 0xFF222222, 0.5) end
                    drawList:AddLine(imgui.ImVec2(pos.x + tableWidth/2, y + 2), imgui.ImVec2(pos.x + tableWidth/2, y + rowHeight - 2), 0xFF252525, 0.5)
                    
                    drawList:AddText(imgui.ImVec2(pos.x + 10, y + 5), 0xFFFFFFFF, u8(config.resourceNames[k]))
                    drawList:AddText(imgui.ImVec2(pos.x + tableWidth/2 + 10, y + 5), 0xFF33CC33, formatNumber(priceEdit[k].v) .. "$")
                end
                
                imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + headerHeight + rows * rowHeight + 8))
                imgui.Dummy(imgui.ImVec2(tableWidth, 0))
                end
                
                if StyleButton(u8("Обновить цены на актуальные"), fa.ICON_REPEAT) then
                    loadGlobalPrices()
                end
                imgui.Spacing()
            end
            
            -- Статистика (ферма)
            cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
            hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_LINE_CHART)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Статистика"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not statsExpandedFarm then statsExpandedFarm = false end
            if imgui.InvisibleButton("##stats_farm", imgui.ImVec2(listW, cardH)) then statsExpandedFarm = not statsExpandedFarm end
            if statsExpandedFarm then
                imgui.Spacing()
                local btnW3 = (imgui.GetWindowWidth() - 25 - 16) / 3
                if StyleButton(u8("Сегодня"), nil, btnW3) then farmStatsTab.v = 0 end; imgui.SameLine()
                if StyleButton(u8("Неделя"), nil, btnW3) then farmStatsTab.v = 1 end; imgui.SameLine()
                if StyleButton(u8("Все время"), nil, btnW3) then farmStatsTab.v = 2 end
                imgui.Separator()
                if farmStatsTab.v == 0 then
                    local todayData = getTodayStats()
                    for _, k in ipairs(config.resourceOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)) 
                    end
                    local todayTotal = 0
                    for _, k in ipairs(config.resourceOrder) do
                        local price = resourcePrices[k] or config.defaultPrices[k] or 0
                        todayTotal = todayTotal + ((todayData[k] or 0) * price)
                    end
                    imgui.Text(u8("Доход за сегодня: ")); imgui.SameLine(); 
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(todayTotal) .. "$")
                elseif farmStatsTab.v == 1 then
                    local weekData = getWeekStats()
                    for _, k in ipairs(config.resourceOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(weekData[k] or 0)) 
                    end
                    imgui.Text(u8("Доход за неделю: ")); imgui.SameLine(); 
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(weekData.total or 0) .. "$")
                elseif farmStatsTab.v == 2 then
                    local availableDates = getAvailableDates()
                    if #availableDates > 0 then
                        local comboStr = ""
                        for i, v in ipairs(availableDates) do 
                            if i > 1 then comboStr = comboStr .. "\0" end; comboStr = comboStr .. v 
                        end
                        comboStr = comboStr .. "\0"
                        imgui.Text(u8("Выберите дату:")); imgui.PushItemWidth(-1)
                        if imgui.Combo(u8("##date_select_farm"), selectedDateIndexFarm, comboStr) then end
                        imgui.PopItemWidth(); imgui.Separator()
                        local idx = selectedDateIndexFarm.v + 1
                        if idx <= #availableDates then
                            local selectedDate = availableDates[idx]
                            local dayData = getDayStats(selectedDate)
                            for _, k in ipairs(config.resourceOrder) do 
                                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(dayData[k] or 0)) 
                            end
                            imgui.Text(u8("Доход: ")); imgui.SameLine(); 
                            imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(dayData.total or 0) .. "$")
                        end
                    else imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.3, 1), u8("Нет данных")) end
                end
                imgui.Spacing()
            end
            
        elseif select_menu[3] then
local scanBtnText
if scanState.active then 
    scanBtnText = u8("Сканирование...")
elseif scannedThisSession[currentWork] then 
    scanBtnText = u8("Пересканировать инвентарь")
else 
    scanBtnText = u8("Сканировать инвентарь") 
end

if scanState.active then
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    StyleButton(scanBtnText, fa.ICON_SEARCH)
    imgui.PopStyleColor(3)
else
    if StyleButton(scanBtnText, fa.ICON_SEARCH) then
        startInventoryScan()
    end
end
            if scanState.active then 
    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Статус: " .. scanState.statusText))
elseif scannedThisSession[currentWork] then 
    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), u8("Инвентарь отсканирован"))
else 
    imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.2, 1), u8("Инвентарь не отсканирован!")) 
end
            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.3, 0.8, 0.3, 1), u8("Режимы счета:"))
            if ToggleSwitch(u8("Подземная шахта"), cb_undermine) then 
                settings.undermineEnabled = cb_undermine.v
                if cb_undermine.v then cb_regular.v = false; settings.regularmineEnabled = false end
                saveConfig(); needSave = true 
            end
            if ToggleSwitch(u8("Лавка (вычитает ресурсы)"), cb_lavka) then 
                settings.underminelavkaEnabled = cb_lavka.v
                if cb_lavka.v then cb_undermine.v = true; settings.undermineEnabled = true end
                saveConfig(); needSave = true 
            end
            if ToggleSwitch(u8("Обычная шахта"), cb_regular) then 
                settings.regularmineEnabled = cb_regular.v
                if cb_regular.v then cb_undermine.v = false; settings.undermineEnabled = false end
                saveConfig(); needSave = true 
            end
            imgui.Separator()
            -- Цены за единицу (шахта)
            local drawList = imgui.GetWindowDrawList()
            local listW = imgui.GetWindowWidth() - 25
            local cardH = 38
            
            local cardY = imgui.GetCursorScreenPos().y
            local cardX = imgui.GetCursorScreenPos().x
            local hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and 
                            imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
                hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_MONEY)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цены за единицу"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not pricesExpandedMine then pricesExpandedMine = false end
            if imgui.InvisibleButton("##prices_mine", imgui.ImVec2(listW, cardH)) then 
                pricesExpandedMine = not pricesExpandedMine
                if pricesExpandedMine and not pricesLoading then
                    loadGlobalPrices()
                end
            end
            if pricesExpandedMine then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Цены средние по Vice City под SA. Обновление раз в сутки."))
                imgui.Spacing()
				                if pricesLoading then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Цены обновляются..."))
                    imgui.Spacing()
                end
                if not globalPrices or not next(globalPrices) then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Цены загружаются..."))
                    imgui.Spacing()
                else
                local pos = imgui.GetCursorScreenPos()
                local tableWidth = imgui.GetWindowWidth() - 25
                local headerHeight = 28
                local rowHeight = 26
                local rows = #config.resourceOrder
                
                drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + rows * rowHeight), 0xFF141414, 6)
                drawList:AddRect(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + rows * rowHeight), 0xFF2A2A2A, 6, 15, 1.5)
                
                drawList:AddText(imgui.ImVec2(pos.x + 10, pos.y + 6), 0xFF1AE591, u8("Ресурс"))
                drawList:AddText(imgui.ImVec2(pos.x + tableWidth/2 + 10, pos.y + 6), 0xFF1AE591, u8("Цена"))
                
                drawList:AddLine(imgui.ImVec2(pos.x + 6, pos.y + headerHeight), imgui.ImVec2(pos.x + tableWidth - 6, pos.y + headerHeight), 0xFF2A2A2A, 1.5)
                drawList:AddLine(imgui.ImVec2(pos.x + tableWidth/2, pos.y + 8), imgui.ImVec2(pos.x + tableWidth/2, pos.y + headerHeight + rows * rowHeight - 4), 0xFF2A2A2A, 1.0)
                
                for i, k in ipairs(config.resourceOrder) do
                    local y = pos.y + headerHeight + (i - 1) * rowHeight
                    local bgColor = (i % 2 == 0) and 0xFF1E1E1E or 0xFF181818
                    drawList:AddRectFilled(imgui.ImVec2(pos.x + 2, y + 1), imgui.ImVec2(pos.x + tableWidth - 2, y + rowHeight - 1), bgColor)
                    if i > 1 then drawList:AddLine(imgui.ImVec2(pos.x + 6, y), imgui.ImVec2(pos.x + tableWidth - 6, y), 0xFF222222, 0.5) end
                    drawList:AddLine(imgui.ImVec2(pos.x + tableWidth/2, y + 2), imgui.ImVec2(pos.x + tableWidth/2, y + rowHeight - 2), 0xFF252525, 0.5)
                    
                    drawList:AddText(imgui.ImVec2(pos.x + 10, y + 5), 0xFFFFFFFF, u8(config.resourceNames[k]))
                    drawList:AddText(imgui.ImVec2(pos.x + tableWidth/2 + 10, y + 5), 0xFF33CC33, formatNumber(priceEdit[k].v) .. "$")
                end
                
                imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + headerHeight + rows * rowHeight + 8))
                imgui.Dummy(imgui.ImVec2(tableWidth, 0))
                end
                
                if StyleButton(u8("Обновить цены на актуальные"), fa.ICON_REPEAT) then
                    loadGlobalPrices()
                end
                imgui.Spacing()
            end
            
            -- Статистика (шахта)
            cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
            hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_LINE_CHART)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Статистика"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not statsExpandedMine then statsExpandedMine = false end
            if imgui.InvisibleButton("##stats_mine", imgui.ImVec2(listW, cardH)) then statsExpandedMine = not statsExpandedMine end
            if statsExpandedMine then
                imgui.Spacing()
                local btnW3 = (imgui.GetWindowWidth() - 25 - 16) / 3
                if StyleButton(u8("Сегодня"), nil, btnW3) then mineStatsTab.v = 0 end; imgui.SameLine()
                if StyleButton(u8("Неделя"), nil, btnW3) then mineStatsTab.v = 1 end; imgui.SameLine()
                if StyleButton(u8("Все время"), nil, btnW3) then mineStatsTab.v = 2 end
                imgui.Separator()
                if mineStatsTab.v == 0 then
                    local todayData = getTodayStats()
                    imgui.Columns(2, "mine_today_cols", false)
                    for _, k in ipairs(config.leftColumnOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)); imgui.NextColumn()
                    end
                    for _, k in ipairs(config.rightColumnOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)); imgui.NextColumn()
                    end
                    imgui.Columns(1)
                    local todayTotal = 0
                    for _, k in ipairs(config.resourceOrder) do
                        local price = resourcePrices[k] or config.defaultPrices[k] or 0
                        todayTotal = todayTotal + ((todayData[k] or 0) * price)
                    end
                    imgui.Text(u8("Доход за сегодня: ")); imgui.SameLine(); 
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(todayTotal) .. "$")
                elseif mineStatsTab.v == 1 then
                    local weekData = getWeekStats()
                    imgui.Columns(2, "mine_week_cols", false)
                    for _, k in ipairs(config.leftColumnOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(weekData[k] or 0)); imgui.NextColumn()
                    end
                    for _, k in ipairs(config.rightColumnOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(weekData[k] or 0)); imgui.NextColumn()
                    end
                    imgui.Columns(1)
                    imgui.Text(u8("Доход за неделю: ")); imgui.SameLine(); 
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(weekData.total or 0) .. "$")
                elseif mineStatsTab.v == 2 then
                    local availableDates = getAvailableDates()
                    if #availableDates > 0 then
                        local comboStr = ""
                        for i, v in ipairs(availableDates) do 
                            if i > 1 then comboStr = comboStr .. "\0" end; comboStr = comboStr .. v 
                        end
                        comboStr = comboStr .. "\0"
                        imgui.Text(u8("Выберите дату:")); imgui.PushItemWidth(-1)
                        if imgui.Combo(u8("##date_select_mine"), selectedDateIndexMine, comboStr) then end
                        imgui.PopItemWidth(); imgui.Separator()
                        local idx = selectedDateIndexMine.v + 1
                        if idx <= #availableDates then
                            local selectedDate = availableDates[idx]
                            local dayData = getDayStats(selectedDate)
                            imgui.Columns(2, "mine_date_cols", false)
                            for _, k in ipairs(config.leftColumnOrder) do 
                                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(dayData[k] or 0)); imgui.NextColumn()
                            end
                            for _, k in ipairs(config.rightColumnOrder) do 
                                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(dayData[k] or 0)); imgui.NextColumn()
                            end
                            imgui.Columns(1)
                            imgui.Text(u8("Доход: ")); imgui.SameLine(); 
                            imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(dayData.total or 0) .. "$")
                        end
                    else imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.3, 1), u8("Нет данных")) end
                end
                imgui.Spacing()
            end
            
        elseif select_menu[4] then
local scanBtnText
if scanState.active then 
    scanBtnText = u8("Сканирование...")
elseif scannedThisSession[currentWork] then 
    scanBtnText = u8("Пересканировать инвентарь")
else 
    scanBtnText = u8("Сканировать инвентарь") 
end

if scanState.active then
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 0.5))
    StyleButton(scanBtnText, fa.ICON_SEARCH)
    imgui.PopStyleColor(3)
else
    if StyleButton(scanBtnText, fa.ICON_SEARCH) then
        startInventoryScan()
    end
end
            if scanState.active then 
    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Статус: " .. scanState.statusText))
elseif scannedThisSession[currentWork] then 
    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), u8("Инвентарь отсканирован"))
else 
    imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.2, 1), u8("Инвентарь не отсканирован!")) 
end
            imgui.Separator()
            -- Цены за единицу (лесопилка)
            local drawList = imgui.GetWindowDrawList()
            local listW = imgui.GetWindowWidth() - 25
            local cardH = 38
            
            local cardY = imgui.GetCursorScreenPos().y
            local cardX = imgui.GetCursorScreenPos().x
            local hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and 
                            imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
                hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_MONEY)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Цены за единицу"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not pricesExpandedSaw then pricesExpandedSaw = false end
            if imgui.InvisibleButton("##prices_saw", imgui.ImVec2(listW, cardH)) then 
                pricesExpandedSaw = not pricesExpandedSaw
                if pricesExpandedSaw and not pricesLoading then
                    loadGlobalPrices()
                end
            end
            if pricesExpandedSaw then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Цены средние по Vice City под SA. Обновление раз в сутки."))
                imgui.Spacing()
				                if pricesLoading then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Цены обновляются..."))
                    imgui.Spacing()
                end
                if not globalPrices or not next(globalPrices) then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Цены загружаются..."))
                    imgui.Spacing()
                else
                local pos = imgui.GetCursorScreenPos()
                local tableWidth = imgui.GetWindowWidth() - 25
                local headerHeight = 28
                local rowHeight = 26
                local rows = #config.resourceOrder
                
                drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + rows * rowHeight), 0xFF141414, 6)
                drawList:AddRect(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + rows * rowHeight), 0xFF2A2A2A, 6, 15, 1.5)
                
                drawList:AddText(imgui.ImVec2(pos.x + 10, pos.y + 6), 0xFF1AE591, u8("Ресурс"))
                drawList:AddText(imgui.ImVec2(pos.x + tableWidth/2 + 10, pos.y + 6), 0xFF1AE591, u8("Цена"))
                
                drawList:AddLine(imgui.ImVec2(pos.x + 6, pos.y + headerHeight), imgui.ImVec2(pos.x + tableWidth - 6, pos.y + headerHeight), 0xFF2A2A2A, 1.5)
                drawList:AddLine(imgui.ImVec2(pos.x + tableWidth/2, pos.y + 8), imgui.ImVec2(pos.x + tableWidth/2, pos.y + headerHeight + rows * rowHeight - 4), 0xFF2A2A2A, 1.0)
                
                for i, k in ipairs(config.resourceOrder) do
                    local y = pos.y + headerHeight + (i - 1) * rowHeight
                    local bgColor = (i % 2 == 0) and 0xFF1E1E1E or 0xFF181818
                    drawList:AddRectFilled(imgui.ImVec2(pos.x + 2, y + 1), imgui.ImVec2(pos.x + tableWidth - 2, y + rowHeight - 1), bgColor)
                    if i > 1 then drawList:AddLine(imgui.ImVec2(pos.x + 6, y), imgui.ImVec2(pos.x + tableWidth - 6, y), 0xFF222222, 0.5) end
                    drawList:AddLine(imgui.ImVec2(pos.x + tableWidth/2, y + 2), imgui.ImVec2(pos.x + tableWidth/2, y + rowHeight - 2), 0xFF252525, 0.5)
                    
                    drawList:AddText(imgui.ImVec2(pos.x + 10, y + 5), 0xFFFFFFFF, u8(config.resourceNames[k]))
                    drawList:AddText(imgui.ImVec2(pos.x + tableWidth/2 + 10, y + 5), 0xFF33CC33, formatNumber(priceEdit[k].v) .. "$")
                end
                
                imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + headerHeight + rows * rowHeight + 8))
                imgui.Dummy(imgui.ImVec2(tableWidth, 0))
                end
                
                if StyleButton(u8("Обновить цены на актуальные"), fa.ICON_REPEAT) then
                    loadGlobalPrices()
                end
                imgui.Spacing()
            end
            
            -- Статистика (лесопилка)
            cardY = imgui.GetCursorScreenPos().y; cardX = imgui.GetCursorScreenPos().x
            hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
            drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), hovered and 0xFF222222 or 0xFF1A1A1A, 6)
            drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 0xFF333333, 6, 15, 1.0)
            drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 0xFF1AE591, fa.ICON_LINE_CHART)
            drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 0xFF1AE591, u8("Статистика"))
            imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
            if not statsExpandedSaw then statsExpandedSaw = false end
            if imgui.InvisibleButton("##stats_saw", imgui.ImVec2(listW, cardH)) then statsExpandedSaw = not statsExpandedSaw end
            if statsExpandedSaw then
                imgui.Spacing()
                local btnW3 = (imgui.GetWindowWidth() - 25 - 16) / 3
                if StyleButton(u8("Сегодня"), nil, btnW3) then farmStatsTab.v = 0 end; imgui.SameLine()
                if StyleButton(u8("Неделя"), nil, btnW3) then farmStatsTab.v = 1 end; imgui.SameLine()
                if StyleButton(u8("Все время"), nil, btnW3) then farmStatsTab.v = 2 end
                imgui.Separator()
                if farmStatsTab.v == 0 then
                    local todayData = getTodayStats()
                    for _, k in ipairs(config.resourceOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(todayData[k] or 0)) 
                    end
                    local todayTotal = 0
                    for _, k in ipairs(config.resourceOrder) do
                        local price = resourcePrices[k] or config.defaultPrices[k] or 0
                        todayTotal = todayTotal + ((todayData[k] or 0) * price)
                    end
                    imgui.Text(u8("Доход за сегодня: ")); imgui.SameLine(); 
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(todayTotal) .. "$")
                elseif farmStatsTab.v == 1 then
                    local weekData = getWeekStats()
                    for _, k in ipairs(config.resourceOrder) do 
                        imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(weekData[k] or 0)) 
                    end
                    imgui.Text(u8("Доход за неделю: ")); imgui.SameLine(); 
                    imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(weekData.total or 0) .. "$")
                elseif farmStatsTab.v == 2 then
                    local availableDates = getAvailableDates()
                    if #availableDates > 0 then
                        local comboStr = ""
                        for i, v in ipairs(availableDates) do 
                            if i > 1 then comboStr = comboStr .. "\0" end; comboStr = comboStr .. v 
                        end
                        comboStr = comboStr .. "\0"
                        imgui.Text(u8("Выберите дату:")); imgui.PushItemWidth(-1)
                        if imgui.Combo(u8("##date_select_saw"), selectedDateIndexFarm, comboStr) then end
                        imgui.PopItemWidth(); imgui.Separator()
                        local idx = selectedDateIndexFarm.v + 1
                        if idx <= #availableDates then
                            local selectedDate = availableDates[idx]
                            local dayData = getDayStats(selectedDate)
                            for _, k in ipairs(config.resourceOrder) do 
                                imgui.Text(u8(config.resourceNames[k] .. ": ")); imgui.SameLine(); 
                                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), formatNumber(dayData[k] or 0)) 
                            end
                            imgui.Text(u8("Доход: ")); imgui.SameLine(); 
                            imgui.TextColored(imgui.ImVec4(0.3, 1.0, 0.3, 1), formatNumber(dayData.total or 0) .. "$")
                        end
                    else imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.3, 1), u8("Нет данных")) end
                end
                imgui.Spacing()
            end
		            
                elseif select_menu[5] then
            drawItemMarketTab()
			
			        elseif select_menu[6] then
            imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Таблица лидеров"))
            imgui.Separator()
            imgui.Spacing()
            
            if not lbLoaded then
                lbLoaded = true
            end
            
            if not getLbEnabled() then
                imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.2, 1), u8("Включите рейтинг в настройках и укажите ник!"))
                imgui.Spacing()
                if imgui.Button(u8("Открыть настройки"), imgui.ImVec2(200, 25)) then
                    for i = 1, #select_menu do select_menu[i] = false end
                    select_menu[9] = true
                end
            else
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Выберите период и режим, затем нажмите \"Показать рейтинг\""))
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                local drawList = imgui.GetWindowDrawList()
                local periods = {u8("За день"), u8("За неделю"), u8("За все время")}
                local modes = {u8("Общий доход"), u8("Ферма"), u8("Шахта"), u8("Лесопилка"), u8("Item Market")}
                local periodsList = {"Daily", "Weekly", "Total"}
                local modesList = {"Income", "Farm", "Mine", "Sawmill", "IM"}
                
                -- Стильный выбор периода
                imgui.Text(u8("Период:"))
                imgui.SameLine()
                
                for i, periodName in ipairs(periods) do
                    if i > 1 then imgui.SameLine(0, 4) end
                    
                    local isActive = (lbTab.v == i - 1)
                    local btnW = 90
                    local btnH = 24
                    local btnPos = imgui.GetCursorScreenPos()
                    local hovered = (imgui.GetMousePos().x >= btnPos.x and imgui.GetMousePos().x <= btnPos.x + btnW and
                                    imgui.GetMousePos().y >= btnPos.y and imgui.GetMousePos().y <= btnPos.y + btnH)
                    
                    local bgColor = isActive and 0xFF1E3D1E or (hovered and 0xFF2A2A2A or 0xFF1A1A1A)
                    local borderColor = isActive and 0xFF1AE591 or (hovered and 0xFF555555 or 0xFF333333)
                    local textColor = isActive and 0xFF1AE591 or (hovered and 0xFFFFFFFF or 0xFF999999)
                    
                    drawList:AddRectFilled(btnPos, imgui.ImVec2(btnPos.x + btnW, btnPos.y + btnH), bgColor, 4)
                    drawList:AddRect(btnPos, imgui.ImVec2(btnPos.x + btnW, btnPos.y + btnH), borderColor, 4, 15, 1.5)
                    
                    local textW = imgui.CalcTextSize(periodName).x
                    drawList:AddText(imgui.ImVec2(btnPos.x + (btnW - textW) / 2, btnPos.y + 4), textColor, periodName)
                    
                    imgui.SetCursorScreenPos(btnPos)
                    if imgui.InvisibleButton("##period_" .. i, imgui.ImVec2(btnW, btnH)) then
                        lbTab.v = i - 1
                    end
                end
                
                imgui.Spacing()
                imgui.Spacing()
                
                -- Стильный выбор режима
                imgui.Text(u8("Режим:"))
                imgui.SameLine()
                
                for i, modeName in ipairs(modes) do
                    if i > 1 then imgui.SameLine(0, 4) end
                    
                    local isActive = (lbModeTab.v == i - 1)
                    local btnW = 90
                    local btnH = 24
                    local btnPos = imgui.GetCursorScreenPos()
                    local hovered = (imgui.GetMousePos().x >= btnPos.x and imgui.GetMousePos().x <= btnPos.x + btnW and
                                    imgui.GetMousePos().y >= btnPos.y and imgui.GetMousePos().y <= btnPos.y + btnH)
                    
                    local bgColor = isActive and 0xFF1E3D1E or (hovered and 0xFF2A2A2A or 0xFF1A1A1A)
                    local borderColor = isActive and 0xFF1AE591 or (hovered and 0xFF555555 or 0xFF333333)
                    local textColor = isActive and 0xFF1AE591 or (hovered and 0xFFFFFFFF or 0xFF999999)
                    
                    drawList:AddRectFilled(btnPos, imgui.ImVec2(btnPos.x + btnW, btnPos.y + btnH), bgColor, 4)
                    drawList:AddRect(btnPos, imgui.ImVec2(btnPos.x + btnW, btnPos.y + btnH), borderColor, 4, 15, 1.5)
                    
                    local textW = imgui.CalcTextSize(modeName).x
                    drawList:AddText(imgui.ImVec2(btnPos.x + (btnW - textW) / 2, btnPos.y + 4), textColor, modeName)
                    
                    imgui.SetCursorScreenPos(btnPos)
                    if imgui.InvisibleButton("##mode_" .. i, imgui.ImVec2(btnW, btnH)) then
                        lbModeTab.v = i - 1
                    end
                end
                
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                if StyleButton(u8("Показать рейтинг"), fa.ICON_SEARCH) then
                    local period = periodsList[lbTab.v + 1]
                    local mode = modesList[lbModeTab.v + 1]
                    loadLeaderboard(period, mode)
                    if mode == "Income" then
                        for _, m in ipairs({"Farm", "Mine", "Sawmill", "IM"}) do
                            loadLeaderboard(period, m, true)
                        end
                    end
                    showLoading = true
                end
                
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                local period = periodsList[lbTab.v + 1]
                local mode = modesList[lbModeTab.v + 1]
                local cache = leaderboardCache[mode] and leaderboardCache[mode][period]
                
                if showLoading and not (cache and #cache > 0) then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1), u8("Идёт загрузка таблицы. Ожидайте пару секунд..."))
                elseif cache and #cache > 0 then
                    showLoading = false
                    local hasResources = (mode == "Farm" or mode == "Mine" or mode == "Sawmill")
                    local drawList = imgui.GetWindowDrawList()
                    local pos = imgui.GetCursorScreenPos()
                    local tableWidth = imgui.GetWindowWidth() - 25
                    local headerHeight = 32
                    local rowHeight = 32
                    
                    if hasResources and cache[1].resources then
                        local resKeys = {}
                        for k, _ in pairs(cache[1].resources) do
                            resKeys[#resKeys + 1] = k
                        end
                        table.sort(resKeys)
                        
                        local maxServerLen = 5
                        for _, e in ipairs(cache) do
                            if e.server and #e.server > maxServerLen then maxServerLen = #e.server end
                        end
                        local serverColW = math.max(60, maxServerLen * 7 + 20)
                        local nickEnd = pos.x + 35 + 140
                        local serverEnd = nickEnd + serverColW
                        local incomeEnd = serverEnd + 100
                        local resEnd = incomeEnd + 110
                        local colX = {pos.x, pos.x + 35, nickEnd, serverEnd, incomeEnd, resEnd}
                        
                        drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + #cache * rowHeight), 0xFF141414, 6)
                        drawList:AddRect(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + #cache * rowHeight), 0xFF2A2A2A, 6, 15, 1.5)
                        
                        drawList:AddText(imgui.ImVec2(colX[1] + 10, pos.y + 7), 0xFF1AE591, u8("#"))
                        drawList:AddText(imgui.ImVec2(colX[2] + 10, pos.y + 7), 0xFF1AE591, u8("Ник"))
                        drawList:AddText(imgui.ImVec2(colX[3] + 10, pos.y + 7), 0xFF1AE591, u8("Сервер"))
                        drawList:AddText(imgui.ImVec2(colX[4] + 10, pos.y + 7), 0xFF1AE591, u8("Доход"))
                        drawList:AddText(imgui.ImVec2(colX[5] + 10, pos.y + 7), 0xFF1AE591, u8("Ресурсы"))
                        
                        drawList:AddLine(imgui.ImVec2(pos.x + 6, pos.y + headerHeight), imgui.ImVec2(pos.x + tableWidth - 6, pos.y + headerHeight), 0xFF2A2A2A, 1.5)
                        
                        for _, cx in ipairs({colX[2], colX[3], colX[4], colX[5]}) do
                            drawList:AddLine(imgui.ImVec2(cx, pos.y + 8), imgui.ImVec2(cx, pos.y + headerHeight + #cache * rowHeight - 4), 0xFF2A2A2A, 1.0)
                        end
                        
                        for i, entry in ipairs(cache) do
                            local y = pos.y + headerHeight + (i - 1) * rowHeight
                            local bgColor = (i % 2 == 0) and 0xFF1E1E1E or 0xFF181818
                            drawList:AddRectFilled(imgui.ImVec2(pos.x + 2, y + 1), imgui.ImVec2(pos.x + tableWidth - 2, y + rowHeight - 1), bgColor)
                            
                            if i > 1 then
                                drawList:AddLine(imgui.ImVec2(pos.x + 6, y), imgui.ImVec2(pos.x + tableWidth - 6, y), 0xFF222222, 0.5)
                            end
                            
                            for _, cx in ipairs({colX[2], colX[3], colX[4], colX[5]}) do
                                drawList:AddLine(imgui.ImVec2(cx, y + 2), imgui.ImVec2(cx, y + rowHeight - 2), 0xFF252525, 0.5)
                            end
                            
                            if i == 1 then
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFF00D7FF, fa.ICON_TROPHY)
                            elseif i == 2 then
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFFC0C0C0, fa.ICON_TROPHY)
                            elseif i == 3 then
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFF327FCD, fa.ICON_TROPHY)
                            else
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFFFFFFFF, tostring(i))
                            end
                            
                            local displayName = entry.name
                            if #displayName > 14 then displayName = displayName:sub(1, 11) .. "..." end
                            drawList:AddText(imgui.ImVec2(colX[2] + 10, y + 7), 0xFFFFFFFF, displayName)
                            drawList:AddText(imgui.ImVec2(colX[3] + 10, y + 7), 0xFF66CCFF, entry.server or "")
                            drawList:AddText(imgui.ImVec2(colX[4] + 10, y + 7), 0xFF33CC33, formatNumber(entry.amount) .. "$")
                            
                            local btnX = colX[5] + 10
                            local btnY = y + 5
                            local btnHovered = (imgui.GetMousePos().x >= btnX and imgui.GetMousePos().x <= btnX + 110 and 
                                               imgui.GetMousePos().y >= btnY and imgui.GetMousePos().y <= btnY + 22)
                            
                            drawList:AddRectFilled(imgui.ImVec2(btnX, btnY), imgui.ImVec2(btnX + 110, btnY + 22), 
                                btnHovered and 0xFF333333 or 0xFF252525, 4)
                            drawList:AddRect(imgui.ImVec2(btnX, btnY), imgui.ImVec2(btnX + 110, btnY + 22), 0xFF3A3A3A, 4, 15, 1.0)
                            
                            local detailText = u8("Подробнее")
                            local detailW = imgui.CalcTextSize(detailText).x
                            drawList:AddText(imgui.ImVec2(btnX + (110 - detailW) / 2, btnY + 3), 
                                btnHovered and 0xFFFFFFFF or 0xFF1AE591, detailText)
                            
                            imgui.SetCursorScreenPos(imgui.ImVec2(btnX, btnY))
                            imgui.InvisibleButton("##res_" .. i, imgui.ImVec2(110, 22))
                            
                            if imgui.IsItemHovered() then
                                imgui.BeginTooltip()
                                for _, rk in ipairs(resKeys) do
                                    imgui.Text(u8(rk .. ": " .. formatNumber(entry.resources[rk] or 0)))
                                end
                                imgui.EndTooltip()
                            end
                        end
                        
                        imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + headerHeight + #cache * rowHeight + 8))
                        imgui.Dummy(imgui.ImVec2(tableWidth, 0))
                    else
                        local isIncome = (mode == "Income")
                        local maxServerLen = 5
                        for _, e in ipairs(cache) do
                            if e.server and #e.server > maxServerLen then maxServerLen = #e.server end
                        end
                        local serverColW = math.max(60, maxServerLen * 7 + 20)
                        local nickEnd = pos.x + 35 + 120
                        local serverEnd = nickEnd + serverColW
                        local incomeEnd = serverEnd + 120
                        local colX = isIncome and {pos.x, pos.x + 35, nickEnd, serverEnd, incomeEnd} or {pos.x, pos.x + 35, nickEnd, serverEnd}
                        
                        drawList:AddRectFilled(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + #cache * rowHeight), 0xFF141414, 6)
                        drawList:AddRect(pos, imgui.ImVec2(pos.x + tableWidth, pos.y + headerHeight + #cache * rowHeight), 0xFF2A2A2A, 6, 15, 1.5)
                        
                        drawList:AddText(imgui.ImVec2(colX[1] + 10, pos.y + 7), 0xFF1AE591, u8("#"))
                        drawList:AddText(imgui.ImVec2(colX[2] + 10, pos.y + 7), 0xFF1AE591, u8("Ник"))
                        drawList:AddText(imgui.ImVec2(colX[3] + 10, pos.y + 7), 0xFF1AE591, u8("Сервер"))
                        drawList:AddText(imgui.ImVec2(colX[4] + 10, pos.y + 7), 0xFF1AE591, u8("Доход"))
                        if isIncome then
                            drawList:AddText(imgui.ImVec2(colX[5] + 10, pos.y + 7), 0xFF1AE591, u8("Подробнее"))
                        end
                        
                        drawList:AddLine(imgui.ImVec2(pos.x + 6, pos.y + headerHeight), imgui.ImVec2(pos.x + tableWidth - 6, pos.y + headerHeight), 0xFF2A2A2A, 1.5)
                        
                        local colsToDivide = isIncome and {colX[2], colX[3], colX[4], colX[5]} or {colX[2], colX[3], colX[4]}
                        for _, cx in ipairs(colsToDivide) do
                            drawList:AddLine(imgui.ImVec2(cx, pos.y + 8), imgui.ImVec2(cx, pos.y + headerHeight + #cache * rowHeight - 4), 0xFF2A2A2A, 1.0)
                        end
                        
                        for i, entry in ipairs(cache) do
                            local y = pos.y + headerHeight + (i - 1) * rowHeight
                            local bgColor = (i % 2 == 0) and 0xFF1E1E1E or 0xFF181818
                            drawList:AddRectFilled(imgui.ImVec2(pos.x + 2, y + 1), imgui.ImVec2(pos.x + tableWidth - 2, y + rowHeight - 1), bgColor)
                            
                            if i > 1 then
                                drawList:AddLine(imgui.ImVec2(pos.x + 6, y), imgui.ImVec2(pos.x + tableWidth - 6, y), 0xFF222222, 0.5)
                            end
                            
                            for _, cx in ipairs(colsToDivide) do
                                drawList:AddLine(imgui.ImVec2(cx, y + 2), imgui.ImVec2(cx, y + rowHeight - 2), 0xFF252525, 0.5)
                            end
                            
                            if i == 1 then
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFF00D7FF, fa.ICON_TROPHY)
                            elseif i == 2 then
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFFC0C0C0, fa.ICON_TROPHY)
                            elseif i == 3 then
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFF327FCD, fa.ICON_TROPHY)
                            else
                                drawList:AddText(imgui.ImVec2(colX[1] + 10, y + 7), 0xFFFFFFFF, tostring(i))
                            end
                            
                            local displayName = entry.name
                            if #displayName > 14 then displayName = displayName:sub(1, 11) .. "..." end
                            drawList:AddText(imgui.ImVec2(colX[2] + 10, y + 7), 0xFFFFFFFF, displayName)
                            drawList:AddText(imgui.ImVec2(colX[3] + 10, y + 7), 0xFF66CCFF, entry.server or "")
                            drawList:AddText(imgui.ImVec2(colX[4] + 10, y + 7), 0xFF33CC33, formatNumber(entry.amount) .. "$")
                            
                            if isIncome then
                                local btnX = colX[5] + 10
                                local btnY = y + 5
                                local btnHovered = (imgui.GetMousePos().x >= btnX and imgui.GetMousePos().x <= btnX + 110 and 
                                                   imgui.GetMousePos().y >= btnY and imgui.GetMousePos().y <= btnY + 22)
                                
                                drawList:AddRectFilled(imgui.ImVec2(btnX, btnY), imgui.ImVec2(btnX + 110, btnY + 22), 
                                    btnHovered and 0xFF333333 or 0xFF252525, 4)
                                drawList:AddRect(imgui.ImVec2(btnX, btnY), imgui.ImVec2(btnX + 110, btnY + 22), 0xFF3A3A3A, 4, 15, 1.0)
                                
                                local detailText = u8("Подробнее")
                                local detailW = imgui.CalcTextSize(detailText).x
                                drawList:AddText(imgui.ImVec2(btnX + (110 - detailW) / 2, btnY + 3), 
                                    btnHovered and 0xFFFFFFFF or 0xFF1AE591, detailText)
                                
                                imgui.SetCursorScreenPos(imgui.ImVec2(btnX, btnY))
                                if imgui.InvisibleButton("##detail_" .. i, imgui.ImVec2(110, 22)) then
                                    for _, m in ipairs({"Farm", "Mine", "Sawmill", "IM"}) do
                                        loadLeaderboard(period, m)
                                    end
                                end
                                
                                if imgui.IsItemHovered() then
                                    imgui.BeginTooltip()
                                    local name = entry.name
                                    local modeNames = {Farm = u8("Ферма"), Mine = u8("Шахта"), Sawmill = u8("Лесопилка"), IM = u8("Item Market")}
                                    for _, m in ipairs({"Farm", "Mine", "Sawmill", "IM"}) do
                                        local otherCache = leaderboardCache[m] and leaderboardCache[m][period]
                                        local found = false
                                        if otherCache then
                                            for _, e in ipairs(otherCache) do
                                                if e.name == name then
                                                    imgui.Text(modeNames[m] .. ": " .. formatNumber(e.amount) .. "$")
                                                    found = true
                                                    break
                                                end
                                            end
                                        end
                                        if not found then
                                            imgui.Text(modeNames[m] .. ": 0$")
                                        end
                                    end
                                    imgui.EndTooltip()
                                end
                            end
                        end
                        
                        imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + headerHeight + #cache * rowHeight + 8))
                        imgui.Dummy(imgui.ImVec2(tableWidth, 0))
                    end
                else
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Нажмите \"Показать рейтинг\" для загрузки данных"))
                end
            end
			
                elseif select_menu[7] then
            drawGoalsTab()
            
                elseif select_menu[8] then
            drawAchievementsTab()
			
                   elseif select_menu[9] then
            local winW = imgui.GetWindowWidth()
            local drawList = imgui.GetWindowDrawList()
            local listW = imgui.GetWindowWidth() - 25
            
            -- Заголовок
            local colCardH = 22
            local colCardY = imgui.GetCursorScreenPos().y
            local colCardX = imgui.GetCursorScreenPos().x
            
            drawList:AddRectFilled(imgui.ImVec2(colCardX, colCardY), imgui.ImVec2(colCardX + listW, colCardY + colCardH), 0xFF222222, 4)
            
            local headerNazvanie = u8("Название бинда")
            local headerKlavisha = u8("Клавиша")
            local headerUpravlenie = u8("Управление")
            
            local klavW = imgui.CalcTextSize(headerKlavisha).x
            local uprW = imgui.CalcTextSize(headerUpravlenie).x
            
            drawList:AddText(imgui.ImVec2(colCardX + 12, colCardY + 3), 0xFF888888, headerNazvanie)
            drawList:AddText(imgui.ImVec2(colCardX + listW / 2 - klavW / 2, colCardY + 3), 0xFF888888, headerKlavisha)
            drawList:AddText(imgui.ImVec2(colCardX + listW - 65 - uprW / 2, colCardY + 3), 0xFF888888, headerUpravlenie)
            
            imgui.Dummy(imgui.ImVec2(listW, colCardH + 4))
            
            if #bindDatabase.binds == 0 then
                imgui.Text(u8("Нет биндов. Создайте новый!"))
            else
                for key, val in ipairs(bindDatabase.binds) do
                    imgui.BindCard(key, val, winW, theme)
                end
            end
			
            -- Попап редактирования
            if imgui.BeginPopupModal(u8("Редактирование бинда"), nil, imgui.WindowFlags.AlwaysAutoResize) then
                if editingBindIdx and bindDatabase.binds[editingBindIdx] then
                    local val = bindDatabase.binds[editingBindIdx]
                    imgui.Text(u8("Название:")); imgui.PushItemWidth(350)
                    imgui.InputText("##editname", editBindName); imgui.PopItemWidth()
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                    if imadd.HotKey("##edithotkey", val, lastKeys, 100) then saveBinderDatabase() end
                    imgui.SameLine(); imgui.Text(u8("Клавиша(-и)"))
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                    if imgui.CollapsingHeader(u8("Подсказка по переменным")) then
                        imgui.BulletText(u8("{WAIT-5} — задержка 5 сек."))
                        imgui.BulletText(u8("{INPUT} в конце — ввод без отправки"))
                        imgui.BulletText(u8("{CMD} в конце — команда скрипта"))
                        imgui.BulletText(u8("{MY_NAME} / {MY_ID}"))
                    end
                    imgui.Spacing()
                    imgui.Text(u8("Текст бинда (каждая строка — отдельное сообщение):"))
                    imgui.InputTextMultiline("##edittext", editBindMultiline, imgui.ImVec2(400, 150))
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                    local winWidth = imgui.GetWindowWidth(); local btnW = 120
                    imgui.SetCursorPosX((winWidth - btnW * 2 - 10) / 2)
                    if imgui.Button(u8("Сохранить"), imgui.ImVec2(btnW, 25)) then
                        if editBindName.v ~= "" and editBindMultiline.v ~= "" then
                            val.name = u8:decode(editBindName.v); val.text = {}
                            for line in (u8:decode(editBindMultiline.v) .. "\n"):gmatch("(.-)\r?\n") do
                                if line ~= "" then table.insert(val.text, line) end
                            end
                            saveBinderDatabase(); imgui.CloseCurrentPopup()
                        else sampAddChatMessage(SCRIPT_PREFIX .. "Заполните все поля!", SCRIPT_COLOR) end
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Отмена"), imgui.ImVec2(btnW, 25)) then imgui.CloseCurrentPopup() end
                end
                imgui.EndPopup()
            end
			
            imgui.Spacing()
            if imgui.Button(fa.ICON_PLUS .. u8("  ДОБАВИТЬ БИНД"), imgui.ImVec2(-1, 25)) then
                bindDatabase.binds[#bindDatabase.binds + 1] = {name = "", text = {}, v = {}}
                imgui.OpenPopup(u8("Добавление бинда##add_popup"))
            end
            
            if imgui.BeginPopupModal(u8("Добавление бинда##add_popup"), nil, imgui.WindowFlags.AlwaysAutoResize) then
                imgui.Text(u8("Название:")); imgui.PushItemWidth(350)
                imgui.InputText("##addname", addBindName); imgui.PopItemWidth()
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                if imadd.HotKey("##addhotkey", bindDatabase.binds[#bindDatabase.binds], lastKeys, 120) then saveBinderDatabase() end
                imgui.SameLine(); imgui.Text(u8("Клавиша(-и)"))
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                if imgui.CollapsingHeader(u8("Подсказка по переменным")) then
                    imgui.BulletText(u8("{WAIT-5} — задержка 5 сек."))
                    imgui.BulletText(u8("{INPUT} в конце — ввод без отправки"))
                    imgui.BulletText(u8("{CMD} в конце — команда скрипта"))
                    imgui.BulletText(u8("{MY_NAME} / {MY_ID}"))
                end
                imgui.Spacing()
                imgui.Text(u8("Текст бинда (каждая строка — отдельное сообщение):"))
                imgui.InputTextMultiline("##addtext", addBindMultiline, imgui.ImVec2(400, 150))
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                local winWidth = imgui.GetWindowWidth(); local btnW = 120
                imgui.SetCursorPosX((winWidth - btnW * 2 - 10) / 2)
                if imgui.Button(u8("Добавить"), imgui.ImVec2(btnW, 25)) then
                    if addBindName.v ~= "" and addBindMultiline.v ~= "" then
                        local newBind = bindDatabase.binds[#bindDatabase.binds]
                        newBind.name = u8:decode(addBindName.v); newBind.text = {}
                        for line in (u8:decode(addBindMultiline.v) .. "\n"):gmatch("(.-)\r?\n") do
                            if line ~= "" then table.insert(newBind.text, line) end
                        end
                        saveBinderDatabase(); imgui.CloseCurrentPopup()
                        addBindName.v = ""; addBindMultiline.v = ""
                    else sampAddChatMessage(SCRIPT_PREFIX .. "Заполните все поля!", SCRIPT_COLOR) end
                end
                imgui.SameLine()
                if imgui.Button(u8("Отмена"), imgui.ImVec2(btnW, 25)) then
                    table.remove(bindDatabase.binds, #bindDatabase.binds); imgui.CloseCurrentPopup()
                end
                imgui.EndPopup()
            end
            
        elseif select_menu[10] then
            drawSettingsTab()
			
        elseif select_menu[11] then
            imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), u8("Информация о скрипте"))
            imgui.Spacing()
            imgui.Text(fa.ICON_LINK); imgui.SameLine()
            imgui.TextColoredRGB("Разработчик - {74BAF4}Ryder")
            imgui.Bullet(); imgui.TextColoredRGB("Скрипт для отслеживания добычи ресурсов")
            imgui.Bullet(); imgui.TextColoredRGB("Работает на проекте {FFB700}Arizona RP")
            imgui.Bullet(); imgui.TextColoredRGB("Поддерживает ферму, шахту и лесопилку")
            imgui.Spacing()
            if newversion ~= scr.version then
                imgui.Spacing()
if StyleButton(fa.ICON_DIAMOND .. u8(" Обновить до v"..newversion), nil, 200) then 
    updateScript() 
end
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
if StyleButton(u8("Загрузить список изменений"), fa.ICON_DOWNLOAD, 250) then
    downloadChangelog()
    sampAddChatMessage(SCRIPT_PREFIX .. "Загружаю список изменений...", SCRIPT_COLOR)
end
            imgui.Spacing()
            if changelogData then
                imgui.Spacing()
                local drawList = imgui.GetWindowDrawList()
                local listW = imgui.GetWindowWidth() - 25
                local cardH = 38
                
                local sortedVersions = {}
                for ver, _ in pairs(changelogData) do table.insert(sortedVersions, ver) end
                table.sort(sortedVersions, function(a, b) return a > b end)
                
                for _, ver in ipairs(sortedVersions) do
                    local isNewest = (ver == scr.version)
                    local label = "v" .. ver .. (isNewest and " (текущая)" or "")
                    
                    local cardY = imgui.GetCursorScreenPos().y
                    local cardX = imgui.GetCursorScreenPos().x
                    local hovered = (imgui.GetMousePos().x >= cardX and imgui.GetMousePos().x <= cardX + listW and 
                                    imgui.GetMousePos().y >= cardY and imgui.GetMousePos().y <= cardY + cardH)
                    
                    drawList:AddRectFilled(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
                        hovered and 0xFF222222 or 0xFF1A1A1A, 6)
                    drawList:AddRect(imgui.ImVec2(cardX, cardY), imgui.ImVec2(cardX + listW, cardY + cardH), 
                        0xFF333333, 6, 15, 1.0)
                    drawList:AddText(imgui.ImVec2(cardX + 10, cardY + 10), 
                        isNewest and 0xFF1AE591 or 0xFFFFCC00, fa.ICON_STAR)
                    drawList:AddText(imgui.ImVec2(cardX + 35, cardY + 10), 
                        isNewest and 0xFF1AE591 or 0xFFFFCC00, u8(label))
                    
                    imgui.SetCursorScreenPos(imgui.ImVec2(cardX, cardY))
                    if not changelogExpanded then changelogExpanded = {} end
                    if changelogExpanded[ver] == nil then changelogExpanded[ver] = false end
                    if imgui.InvisibleButton("##changelog_" .. ver, imgui.ImVec2(listW, cardH)) then changelogExpanded[ver] = not changelogExpanded[ver] end
                    
                    if changelogExpanded[ver] then
                        imgui.Spacing()
                        for _, change in ipairs(changelogData[ver]) do
                            imgui.Bullet(); imgui.SameLine()
                            imgui.PushTextWrapPos()
                            imgui.TextWrapped(u8(change))
                            imgui.PopTextWrapPos()
                        end
                        imgui.Spacing()
                    end
                end
            else
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), u8("Список изменений не загружен"))
            end
		end	
        
        imgui.EndChild()
        imgui.End()
        imgui.PopStyleColor(2)
        imgui.PopStyleVar(1)
    end
end

function imgui.TextColoredRGB(string)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local function color_imvec4(color)
        if color:upper():sub(1, 6) == 'SSSSSS' then return imgui.ImVec4(colors[clr.Text].x, colors[clr.Text].y, colors[clr.Text].z, tonumber(color:sub(7, 8), 16) and tonumber(color:sub(7, 8), 16)/255 or colors[clr.Text].w) end
        local color = type(color) == 'number' and ('%X'):format(color):upper() or color:upper()
        local rgb = {}
        for i = 1, #color/2 do rgb[#rgb+1] = tonumber(color:sub(2*i-1, 2*i), 16) end
        return imgui.ImVec4(rgb[1]/255, rgb[2]/255, rgb[3]/255, rgb[4] and rgb[4]/255 or colors[clr.Text].w)
    end
    local function render_text(string)
        for w in string:gmatch('[^\r\n]+') do
            local text, color = {}, {}
            local m = 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                if tonumber(w:sub(n+1, k-1), 16) or (w:sub(n+1, k-3):upper() == 'SSSSSS' and tonumber(w:sub(k-2, k-1), 16) or w:sub(k-2, k-1):upper() == 'SS') then
                    text[#text], text[#text+1] = w:sub(m, n-1), w:sub(k+1, #w)
                    color[#color+1] = color_imvec4(w:sub(n+1, k-1))
                    w = w:sub(1, n-1)..w:sub(k+1, #w); m = n
                else w = w:sub(1, n-1)..w:sub(n, k-3)..'}'..w:sub(k+1, #w) end
            end
            if text[0] then
                for i, k in pairs(text) do imgui.TextColored(color[i] or colors[clr.Text], u8(k)); imgui.SameLine(nil, 0) end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(string)
end

function updateScript()
    sampAddChatMessage(SCRIPT_PREFIX .."Скачиваю обновление...", SCRIPT_COLOR)
    local dir = getWorkingDirectory().."/#ArzResHelper.lua"
    local url = "https://raw.githubusercontent.com/Ryder8471/ArzResHelper/refs/heads/main/%23ArzResHelper.lua?t=" .. os.time()
    local checked = false
    downloadUrlToFile(url, dir, function(id, status, p1, p2)
        if checked then return end
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            checked = true
                        if doesFileExist(changelogPath) then os.remove(changelogPath) end
			sampAddChatMessage(SCRIPT_PREFIX .."Обновление скачано! Перезагружаю скрипт...", SCRIPT_COLOR)
            lua_thread.create(function() wait(500); showCursor(false); scr:reload() end)
        elseif status == dlstatus.STATUSEX_ENDDOWNLOAD then
            if not checked then checked = true; sampAddChatMessage(SCRIPT_PREFIX .."Ошибка при скачивании обновления.", SCRIPT_COLOR) end
        end
    end)
end

function updateCheck()
    sampAddChatMessage(SCRIPT_PREFIX .."Проверяем наличие обновлений...", SCRIPT_COLOR)
    local dir = getWorkingDirectory().."/ResHelper/files/info.upd"
    local url = "https://raw.githubusercontent.com/Ryder8471/ArzResHelper/refs/heads/main/info.upd?t=" .. os.time()
    local checked = false
    downloadUrlToFile(url, dir, function(id, status, p1, p2)
        if checked then return end
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            checked = true
            if doesFileExist(dir) then
                local f = io.open(dir, "r")
                if f then
                    local content = f:read("*a"); f:close()
                    local upd = decodeJson(content)
                    if upd and upd.version then
                        newversion = upd.version; newdate = upd.release_date
                        if upd.version ~= scr.version then
                            sampAddChatMessage(SCRIPT_PREFIX .."Доступна версия v"..newversion.."!", SCRIPT_COLOR)
                            sampAddChatMessage(SCRIPT_PREFIX .."Откройте /rh -> О скрипте -> Обновить до v"..newversion, SCRIPT_COLOR)
                        else sampAddChatMessage(SCRIPT_PREFIX .."У вас актуальная версия v"..scr.version, SCRIPT_COLOR) end
                    end
                end
            end
        elseif status == dlstatus.STATUSEX_ENDDOWNLOAD then
            if not checked then checked = true; sampAddChatMessage(SCRIPT_PREFIX .."Не удалось проверить обновления.", SCRIPT_COLOR) end
        end
    end)
end

function saveOverlayConfig()
    local file = io.open(configDir .. "overlay_config.ini", "w")
    if file then
        file:write("[Farm]\nx=" .. overlayConfigs[WORK_TYPES.FARM].x .. "\ny=" .. overlayConfigs[WORK_TYPES.FARM].y .. "\nw=" .. overlayConfigs[WORK_TYPES.FARM].w .. "\nh=" .. overlayConfigs[WORK_TYPES.FARM].h .. "\n")
        file:write("[Mine]\nx=" .. overlayConfigs[WORK_TYPES.MINE].x .. "\ny=" .. overlayConfigs[WORK_TYPES.MINE].y .. "\nw=" .. overlayConfigs[WORK_TYPES.MINE].w .. "\nh=" .. overlayConfigs[WORK_TYPES.MINE].h .. "\n")
        file:write("[Sawmill]\nx=" .. overlayConfigs[WORK_TYPES.SAWMILL].x .. "\ny=" .. overlayConfigs[WORK_TYPES.SAWMILL].y .. "\nw=" .. overlayConfigs[WORK_TYPES.SAWMILL].w .. "\nh=" .. overlayConfigs[WORK_TYPES.SAWMILL].h .. "\n")
        file:close()
    end
end

function loadOverlayConfig()
    local file = io.open(configDir .. "overlay_config.ini", "r")
    if not file then return end
    local section = ""
    for line in file:lines() do
        local sec = line:match("^%[(.*)%]$")
        if sec then section = sec
        else
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then
                local num = tonumber(v)
                if num then
                    if section == "Farm" then
                        if k == "x" then overlayConfigs[WORK_TYPES.FARM].x = num
                        elseif k == "y" then overlayConfigs[WORK_TYPES.FARM].y = num
                        elseif k == "w" then overlayConfigs[WORK_TYPES.FARM].w = num
                        elseif k == "h" then overlayConfigs[WORK_TYPES.FARM].h = num end
                    elseif section == "Mine" then
                        if k == "x" then overlayConfigs[WORK_TYPES.MINE].x = num
                        elseif k == "y" then overlayConfigs[WORK_TYPES.MINE].y = num
                        elseif k == "w" then overlayConfigs[WORK_TYPES.MINE].w = num
                        elseif k == "h" then overlayConfigs[WORK_TYPES.MINE].h = num end
                    elseif section == "Sawmill" then
                        if k == "x" then overlayConfigs[WORK_TYPES.SAWMILL].x = num
                        elseif k == "y" then overlayConfigs[WORK_TYPES.SAWMILL].y = num
                        elseif k == "w" then overlayConfigs[WORK_TYPES.SAWMILL].w = num
                        elseif k == "h" then overlayConfigs[WORK_TYPES.SAWMILL].h = num end
                    end
                end
            end
        end
    end
    file:close()
end

addEventHandler('onWindowMessage', function(msg, wparam, lparam)
    if wparam == 27 then
        if mainWin.v then
            if msg == wm.WM_KEYDOWN then consumeWindowMessage(true, false) end
            if msg == wm.WM_KEYUP then 
                mainWin.v = not mainWin.v
                imgui.ShowCursor = false 
                consumeWindowMessage(true, false)
            end
        end
    end
end)

function urlEncode(str)
    local result = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        local byte = string.byte(c)
        if c:match("[%w%.%-%_%~]") then
            result = result .. c
        elseif c == " " then
            result = result .. "+"
        else
            result = result .. string.format("%%%02X", byte)
        end
    end
    return result
end

function main()
    repeat wait(100) until isSampAvailable()
    local base = getModuleHandle("samp.dll")
    local sampVer = mem.tohex( base + 0xBABE, 10, true )
    if sampVer == "E86D9A0A0083C41C85C0" then
        sampIsLocalPlayerSpawned = function()
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
        end
    end
    if script.this.filename:find("%.luac") then os.rename(getWorkingDirectory().."\\ResHelper.luac", getWorkingDirectory().."\\ResHelper.lua") end
    if not doesDirectoryExist(dirml.."/ResHelper/files/") then createDirectory(dirml.."/ResHelper/files/") end
    print("{82E28C}Проверка изображений..")
    if not doesFileExist(dirml.."/ResHelper/files/logo-ArzResHelper.png") then print("{FF2525}Ошибка: {FFD825}Отсутствует изображение logo-ArzResHelper.png") end
    logoArz = imgui.CreateTextureFromFile(dirml.."/ResHelper/files/logo-ArzResHelper.png")
    loadConfig()
	loadTgConfig()
local lastDailyReportDate, lastWeeklyReportKey = loadTgReportState()
tgTokenInput.v = u8(tgConfig.botToken)
tgChatIdInput.v = u8(tgConfig.chatId)
    loadThemeConfig()
	loadCustomTheme()
    cb_useCustomTheme.v = useCustomTheme
    loadOverlayConfig()
    loadInventoryBase()
    initPricesFile()
    initGoalsFiles()
    loadGoalsProgress()
	loadAchievements()
	loadItemMarketStats()
	    -- Загружаем цены при старте, если сегодня ещё не загружали
    local today = getGameDate()
    local lastPricesDate = ""
    local pf = io.open(pricesStatePath, "r")
    if pf then lastPricesDate = pf:read("*line") or ""; pf:close() end
    if lastPricesDate ~= today then
        loadGlobalPrices()
    end
    loadTotalIncomeGoal()
    
    -- Собираем строку для комбобокса тем (с кодировкой u8)
    themeComboItems = ""
    for i, tid in ipairs(THEME_ORDER) do
        if i > 1 then themeComboItems = themeComboItems .. "\0" end
        themeComboItems = themeComboItems .. u8(THEME_CONFIGS[tid].name)
    end
    themeComboItems = themeComboItems .. "\0"
    -- Устанавливаем индекс текущей темы
    for i, tid in ipairs(THEME_ORDER) do
        if tid == currentTheme then
            selectedThemeIdx.v = i - 1
            break
        end
    end
    
    -- Пересчитываем общий доход за сегодня при загрузке
    local gameDate = getGameDate()
    totalDailyIncome = 0
    
    -- Загружаем цены фермы
    local farmPrices = {}
    local farmPriceFile = io.open(farmPricesPath, "r")
    if farmPriceFile then
        for line in farmPriceFile:lines() do
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then farmPrices[k] = tonumber(v) end
        end
        farmPriceFile:close()
    end
    
    -- Загружаем цены шахты
    local minePrices = {}
    local minePriceFile = io.open(minePricesPath, "r")
    if minePriceFile then
        for line in minePriceFile:lines() do
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then minePrices[k] = tonumber(v) end
        end
        minePriceFile:close()
    end
    
    -- Считаем доход фермы
    local farmLogPath = configs[WORK_TYPES.FARM].statsPath
    local farmFile = io.open(farmLogPath, "r")
    if farmFile then
        local content = farmFile:read("*all")
        farmFile:close()
        for time, resource, amount in content:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            if getGameDate(tonumber(time)) == gameDate then
                local price = farmPrices[resource] or configs[WORK_TYPES.FARM].defaultPrices[resource] or 0
                totalDailyIncome = totalDailyIncome + (tonumber(amount) * price)
            end
        end
    end
    
    -- Считаем доход шахты
    local mineLogPath = configs[WORK_TYPES.MINE].statsPath
    local mineFile = io.open(mineLogPath, "r")
    if mineFile then
        local content = mineFile:read("*all")
        mineFile:close()
        for time, resource, amount in content:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            if getGameDate(tonumber(time)) == gameDate then
                local price = minePrices[resource] or configs[WORK_TYPES.MINE].defaultPrices[resource] or 0
                totalDailyIncome = totalDailyIncome + (tonumber(amount) * price)
            end
        end
    end
    
    -- Считаем доход лесопилки
    local sawmillPrices = {}
    local sawmillPriceFile = io.open(sawmillPricesPath, "r")
    if sawmillPriceFile then
        for line in sawmillPriceFile:lines() do
            local k, v = line:match("^(.-)=(.*)$")
            if k and v then sawmillPrices[k] = tonumber(v) end
        end
        sawmillPriceFile:close()
    end
    
    local sawmillLogPath = configs[WORK_TYPES.SAWMILL].statsPath
    local sawmillFile = io.open(sawmillLogPath, "r")
    if sawmillFile then
        local content = sawmillFile:read("*all")
        sawmillFile:close()
        for time, resource, amount in content:gmatch('"time":(%d+),"resource":"([^"]+)","amount":(%d+)') do
            if getGameDate(tonumber(time)) == gameDate then
                local price = sawmillPrices[resource] or configs[WORK_TYPES.SAWMILL].defaultPrices[resource] or 0
                totalDailyIncome = totalDailyIncome + (tonumber(amount) * price)
            end
        end
    end
	
	-- Добавляем Item Market к общему доходу
    for _, log in ipairs(itemMarketLog) do
        if getGameDate(log.time) == gameDate then
            totalDailyIncome = totalDailyIncome + log.amount
        end
    end
    
    saveTotalIncomeGoal()
    
    sessionStartTime = os.time()
    checkChangelog()
    cb_farm.v = settings.farmEnabled
    cb_undermine.v = settings.undermineEnabled
    cb_lavka.v = settings.underminelavkaEnabled
    cb_regular.v = settings.regularmineEnabled
    cb_chatNotify.v = settings.chatNotifyEnabled
    cb_goalSound.v = settings.goalSoundEnabled
    cb_pickupSound.v = settings.pickupSoundEnabled
    cb_farm_overlay.v = settings.farmOverlayEnabled
    cb_mine_overlay.v = settings.mineOverlayEnabled
    cb_overlay_timer.v = settings.overlayTimerEnabled
    totalGoalEdit.v = settings.totalIncomeGoal
    cb_sawmill_overlay.v = settings.sawmillOverlayEnabled
    cb_sawmill.v = settings.sawmillEnabled
    goal_vol_slider.v = settings.goalSoundVolume
    pickup_vol_slider.v = settings.pickupSoundVolume
sampRegisterChatCommand("rh", function() 
    mainWin.v = not mainWin.v
    imgui.ShowCursor = mainWin.v
end)
    sampRegisterChatCommand("rhrl", function() scr:reload() end)
    sampRegisterChatCommand("rhreset", function()
        cachedTodayStats = nil; cachedTodayTime = 0; cachedWeekStats = nil; cachedWeekTime = 0
        sampAddChatMessage(SCRIPT_PREFIX .. "Кэш статистики сброшен! Данные пересчитаны по новым правилам (05:00 МСК).", SCRIPT_COLOR)
    end)
    sampRegisterChatCommand("rhtest", function()
        changelogShown = false
        sampAddChatMessage(SCRIPT_PREFIX .. "Окно изменений будет показано при следующем открытии /rh", SCRIPT_COLOR)
    end)
    checkAndResetDaily()
    repeat wait(100) until sampIsLocalPlayerSpawned()
    sampAddChatMessage(string.format(SCRIPT_PREFIX.."ResHelper загружен! /rh - меню. Версия: %s", scr.version), SCRIPT_COLOR)
    updateCheck()
    imgui.ShowCursor = false
	    globalPrices = {}
    loadGlobalPrices()
	    updateProgressAchievements()
    local lastResetCheck = 0
	local lastLbDailyDate, lastLbWeeklyDate = loadLbState()

while true do
    wait(0)
	
	if pendingScan and not scanState.active then
    local workToScan = pendingScan
    pendingScan = nil
    if currentWork == workToScan then
        startInventoryScan()
    end
end

-- Проверка ежедневного отчёта
if tgConfig.enabled and tgConfig.dailyReportEnabled then
    local mskTime = getMoscowTime()
    local mskHour = tonumber(os.date("%H", mskTime))
    local yesterdayDate = getGameDate(os.time() - 86400)
    
    if mskHour >= 5 and tostring(lastDailyReportDate) ~= yesterdayDate then
        lastDailyReportDate = yesterdayDate
        saveTgReportState(lastDailyReportDate, lastWeeklyReportKey)
        sampAddChatMessage(SCRIPT_PREFIX .. "Ежедневный отчёт отправлен в Telegram!", SCRIPT_COLOR)
        local report = generateReport("daily")
        sendTelegramMessage(report)
    end
end

-- Проверка недельного отчёта
if tgConfig.enabled and tgConfig.weeklyReportEnabled then
    local mskTime = getMoscowTime()
    local mskHour = tonumber(os.date("%H", mskTime))
    local mskWday = tonumber(os.date("%w", mskTime))
    
    if mskWday == 1 and mskHour >= 5 then
        local weekKey = os.date("%Y-%W", mskTime)
        if tostring(lastWeeklyReportKey) ~= weekKey then
            lastWeeklyReportKey = weekKey
            saveTgReportState(lastDailyReportDate, lastWeeklyReportKey)
            sampAddChatMessage(SCRIPT_PREFIX .. "Недельный отчёт отправлен в Telegram!", SCRIPT_COLOR)
            local report = generateReport("week")
            sendTelegramMessage(report)
        end
    end
end


-- Авто-отправка в рейтинг (за прошлый день)
if getLbEnabled() then
    local mskTime = getMoscowTime()
    local mskHour = tonumber(os.date("%H", mskTime))
    local yesterdayDate = getGameDate(os.time() - 86400)
    local allModes = {"Income", "Farm", "Mine", "Sawmill", "IM"}
    
    -- Ежедневная авто-отправка в 05:00+ МСК (если ещё не отправляли за вчера)
    if mskHour >= 5 and tostring(lastLbDailyDate) ~= yesterdayDate then
        lastLbDailyDate = yesterdayDate
        saveLbState(lastLbDailyDate, lastLbWeeklyDate)
        for _, mode in ipairs(allModes) do
            sendToLeaderboard("Daily", mode)
            sendToLeaderboard("Total", mode)
        end
        sampAddChatMessage(SCRIPT_PREFIX .. "Данные отправлены в рейтинг!", SCRIPT_COLOR)
    end
    
    -- Недельная авто-отправка
    if mskHour >= 5 then
        local mskWday = tonumber(os.date("%w", mskTime))
        if mskWday == 0 then mskWday = 7 end
        -- Ключ прошлой недели (понедельник прошлой недели)
        local lastMonday = os.time() - (mskWday + 6) * 86400
        local weekKey = os.date("%Y-%W", lastMonday)
        if tostring(lastLbWeeklyDate) ~= weekKey then
            lastLbWeeklyDate = weekKey
            saveLbState(lastLbDailyDate, lastLbWeeklyDate)
            for _, mode in ipairs(allModes) do
                sendToLeaderboard("Weekly", mode)
            end
            sampAddChatMessage(SCRIPT_PREFIX .. "Недельный рейтинг отправлен!", SCRIPT_COLOR)
        end
    end
end

    if os.time() - lastResetCheck >= 30 then
        lastResetCheck = os.time()
        checkAndResetDaily()
    end
        if isKeyDown(VK_LMENU) and isKeyJustPressed(VK_K) and not sampIsChatInputActive() then mainWin.v = not mainWin.v; imgui.ShowCursor = mainWin.v end
        if not mainWin.v and imgui.ShowCursor then imgui.ShowCursor = false end
        if not sampIsChatInputActive() and not sampIsDialogActive() then binderStart() end
        
        -- Обновление таймера (каждую секунду)
        if overlayTimer.running and os.time() ~= (overlayTimer.lastUpdate or 0) then
            overlayTimer.elapsed = os.time() - overlayTimer.startTime
            overlayTimer.displayedTime = formatTime(overlayTimer.elapsed)
            overlayTimer.lastUpdate = os.time()
        end
        
        local needRender = mainWin.v or settings.farmOverlayEnabled or settings.mineOverlayEnabled or settings.sawmillOverlayEnabled
        if imgui.Process ~= needRender then imgui.Process = needRender end
    end
end