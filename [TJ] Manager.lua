script_name("Script Manager")
script_author("tarif_jan")

local imgui = require 'mimgui'
local encoding = require 'encoding'
local os = require 'os'
local ffi = require 'ffi' 
local dlstatus = require('moonloader').download_status
local vkeys = require 'vkeys' 

local fa = require 'fAwesome6'

encoding.default = 'CP1251'
local u8 = encoding.UTF8
local cjson = require 'cjson' 

local renderWindow = imgui.new.bool(false)
local scriptsCatalog = {}

local selectedScriptIdx = 1
local showOnlyInstalled = imgui.new.bool(false)

local catalogBaseUrl = "https://raw.githubusercontent.com/Tariffka/MySampScripts3/main/catalog.json"

-- Держим диапазоны в памяти
local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
-- Переменная для нашего объединенного шрифта
local myFont = nil 

function chat(text)
    sampAddChatMessage(u8:decode(text), -1)
end

imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    -- ЭТО САМОЕ ВАЖНОЕ: загружаем диапазон кириллицы
    config.GlyphRanges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    
    myFont = imgui.GetIO().Fonts:AddFontFromFileTTF(os.getenv('WINDIR') .. '\\phagspab.ttf', 14.0, config) 
    -- Примечание: если шрифт не найден, проверь путь. 
    -- Иногда лучше положить файл шрифта в папку moonloader/resource/fonts
    
    -- ... (далее идет код с иконками)

    local iconConfig = imgui.ImFontConfig()
    iconConfig.MergeMode = true 
    iconConfig.PixelSnapH = true
    -- Добавляем иконки ПОВЕРХ нашего myFont
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85('solid'), 14.0, iconConfig, iconRanges)

    local style = imgui.GetStyle()
    local colors = style.Colors
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[imgui.Col.Border] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.Button] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    colors[imgui.Col.Header] = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.45, 0.45, 0.45, 1.00)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    style.WindowRounding = 6.0
    style.ChildRounding = 4.0
    style.FrameRounding = 3.0
end)

function fileExists(name)
    local f = io.open(name, "r")
    if f ~= nil then io.close(f) return true else return false end
end

function findScriptByFilename(filename)
    for _, loadedScript in ipairs(script.list()) do
        if loadedScript.filename == filename then return loadedScript end
    end
    return nil
end

function loadCatalog()
    local randomId = os.time()
    local noCacheUrl = catalogBaseUrl .. "?nocache=" .. randomId
    local tempCatalogPath = getWorkingDirectory() .. "\\catalog_temp.json"
    
    downloadUrlToFile(noCacheUrl, tempCatalogPath, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local file = io.open(tempCatalogPath, "r")
            if file then
                local content = file:read("*a")
                file:close()
                os.remove(tempCatalogPath) 
                
                local success, result = pcall(cjson.decode, content)
                if success then
                    scriptsCatalog = result
                end
            end
        end
    end)
end

local function ColoredButton(text, color, size)
    imgui.PushStyleColor(imgui.Col.Button, color)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(color.x * 1.2, color.y * 1.2, color.z * 1.2, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(color.x * 0.8, color.y * 0.8, color.z * 0.8, 1.0))
    local clicked = imgui.Button(text, size or imgui.ImVec2(0, 0))
    imgui.PopStyleColor(3)
    return clicked
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    loadCatalog()

    sampRegisterChatCommand("tjm", function()
        renderWindow[0] = not renderWindow[0]
        if renderWindow[0] then 
            loadCatalog() 
        end
    end)
    
    while true do
        wait(0)
        if renderWindow[0] and wasKeyPressed(vkeys.VK_ESCAPE) then
            renderWindow[0] = false
        end
    end
end

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        imgui.SetNextWindowSize(imgui.ImVec2(850, 400), imgui.Cond.Always)
        
        -- ВАЖНО: Принудительно включаем наш шрифт с иконками!
        if myFont then imgui.PushFont(myFont) end
        
        if imgui.Begin("##jpt_main", renderWindow, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
            
            imgui.Text(fa("CODE") .. " Script Manager")
            
            imgui.SameLine(imgui.GetWindowWidth() - 30)
            if imgui.Button(fa("XMARK"), imgui.ImVec2(20, 20)) then
                renderWindow[0] = false
            end
            
            imgui.Separator()
            
            imgui.BeginChild("LeftPanel", imgui.ImVec2(320, 0), true)
            
            imgui.Text("Список скриптов")
            imgui.SameLine(imgui.GetWindowWidth() - 100)
            if imgui.Button(fa("ROTATE") .. " Обновить") then loadCatalog() end 
            
            imgui.Checkbox("Показывать Установленные", showOnlyInstalled)
            imgui.Separator()
            
            for i, item in ipairs(scriptsCatalog) do
                local filePath = getWorkingDirectory() .. "\\" .. item.filename
                local isInstalled = fileExists(filePath)
                local matchInstalled = (not showOnlyInstalled[0]) or isInstalled
                
                if matchInstalled then
                    local prefix = isInstalled and (fa("CHECK") .. "  ") or "      "
                    
                    -- Слегка увеличиваем отступы элементов для красоты
                    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 8))
                    if imgui.Selectable(prefix .. item.name, selectedScriptIdx == i) then
                        selectedScriptIdx = i
                    end
                    imgui.PopStyleVar()
                end
            end
            imgui.EndChild()
            
            imgui.SameLine()
            
            imgui.BeginChild("RightPanel", imgui.ImVec2(0, 0), true)
            
            local activeScript = scriptsCatalog[selectedScriptIdx]
            if activeScript then
                local filePath = getWorkingDirectory() .. "\\" .. activeScript.filename
                local isInstalled = fileExists(filePath)
                local runningScript = findScriptByFilename(activeScript.filename)
                
                local rightPanelWidth = imgui.GetWindowWidth()
                local btnHeight = 30
                local topBtnColor = imgui.ImVec4(0.18, 0.18, 0.18, 1.0)
                
                if not isInstalled then
                    if ColoredButton(fa("WRENCH") .. " Установить скрипт", topBtnColor, imgui.ImVec2(rightPanelWidth - 15, btnHeight)) then
                        chat("{FF9900}Script Manager: {FFFFFF}Устанавливаю скрипт: {33CC33}" .. activeScript.filename)
                        
                        if runningScript then runningScript:unload() end
                        local scriptNoCacheUrl = activeScript.url .. "?nocache=" .. os.time()
                        downloadUrlToFile(scriptNoCacheUrl, filePath, function(id, status, p1, p2)
                            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                                script.load(filePath)
                                local cmdText = (activeScript.command and activeScript.command ~= "") and activeScript.command or "отсутствует"
                                chat("{FF9900}" .. activeScript.name .. ": {FFFFFF}Загружен. Команда: " .. cmdText .. ".")
                            end
                        end)
                    end
                else
                    local updateBtnWidth = rightPanelWidth - 50 - 15
                    if ColoredButton(fa("ROTATE") .. " Обновить скрипт", topBtnColor, imgui.ImVec2(updateBtnWidth, btnHeight)) then
                        chat("{FF9900}Script Manager: {FFFFFF}Обновляю скрипт: {33CC33}" .. activeScript.filename)
                        
                        if runningScript then runningScript:unload() end
                        local scriptNoCacheUrl = activeScript.url .. "?nocache=" .. os.time()
                        downloadUrlToFile(scriptNoCacheUrl, filePath, function(id, status, p1, p2)
                            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                                script.load(filePath)
                                local cmdText = (activeScript.command and activeScript.command ~= "") and activeScript.command or "отсутствует"
                                chat("{FF9900}" .. activeScript.name .. ": {FFFFFF}Успешно обновлен. Команда: " .. cmdText .. ".")
                            end
                        end)
                    end
                    
                    imgui.SameLine()
                    
                    if ColoredButton(fa("TRASH"), topBtnColor, imgui.ImVec2(40, btnHeight)) then
                        chat("{FF9900}Script Manager: {FFFFFF}Удаляю скрипт: {33CC33}" .. activeScript.filename)
                        
                        if runningScript then runningScript:unload() end
                        os.remove(filePath)
                    end
                end
                
                imgui.Separator()
                imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)
                
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "Название: ")
                imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(0.2, 0.8, 0.2, 1.0), activeScript.name)
                imgui.SameLine()
                imgui.TextDisabled("(имя файла: " .. activeScript.filename .. ")")
                
                -- Отступ перед кнопками
                imgui.Dummy(imgui.ImVec2(0, 15))
                imgui.Separator()
                imgui.Dummy(imgui.ImVec2(0, 10))

                -- Описание
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "Описание:")
                imgui.TextWrapped(activeScript.description or "Описание отсутствует.")
                imgui.Dummy(imgui.ImVec2(0, 10))
                
                -- Команды
                local cmdInfo = activeScript.command or ""
                if cmdInfo ~= "" then
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "Команды:")
                    -- Включаем желтый цвет (1, 1, 0 — это желтый в RGB)
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 0.0, 1.0)) 
                    imgui.TextWrapped(cmdInfo)
                    imgui.PopStyleColor() -- Выключаем (возвращаем старый цвет)
                    imgui.Dummy(imgui.ImVec2(0, 10))
                end

            else
                imgui.TextDisabled("Выберите скрипт из списка...")
            end
            
            imgui.EndChild()
            imgui.End()
        end
        
        -- ВАЖНО: Выключаем шрифт в конце отрисовки
        if myFont then imgui.PopFont() end
    end
)