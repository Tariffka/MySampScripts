script_authors('TG @Qwestonsz')
script_url('https://www.blast.hk/members/464512/')

require('lib.moonloader')
local imgui = require 'mimgui'
local encoding = require 'encoding'
local sampev = require 'samp.events'
local inicfg = require 'inicfg'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new

local mainIni = inicfg.load({
    main = {
        
    }
}, "Fast-rec.ini")

local win_mimgui = new.bool(true)

imgui.OnFrame(function() return win_mimgui[0] end, function(player)
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 25, sh / 2.3), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0)) 
    imgui.Begin(u8''..thisScript().filename, win_mimgui, imgui.WindowFlags.NoResize+imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoTitleBar+imgui.WindowFlags.AlwaysAutoResize)
    
    if mainIni and mainIni.main then
        local sorted_keys = {}

        for key, _ in pairs(mainIni.main) do
            local index = tonumber(key:match("line_(%d+)"))
            if index then
                table.insert(sorted_keys, index)
            end
        end
        table.sort(sorted_keys)

        for _, index in ipairs(sorted_keys) do
            local name = mainIni.main["line_" .. index]
            if name then
                local max_length = 12
                local truncated_name = name:sub(1, max_length)
                if imgui.Button(u8(truncated_name)) then
                    selectedPlace = name
                    sampProcessChatInput('/rec')
                end
            end
        end
    end
    
    imgui.End()
    imgui.PopStyleColor()
end).HideCursor = true


function main()
    while not isSampAvailable() do wait(100) end
    while true do wait(0)      
    end
end


function sampev.onShowDialog(id, style, title, button1, button2, text)
    if title:find('{BFBBBA}Выбор места спавна') then
        local parsed_dialog = {}
        local unique_entries = {} 

        for n in text:gmatch('[^\r\n]+') do
            local clean_line = n:match('%[%d+%] %{ffffff%}%s*(.+)') or n
            
            if not unique_entries[clean_line] then
                table.insert(parsed_dialog, clean_line)
                unique_entries[clean_line] = true 
            end
        end

        for key in pairs(mainIni.main) do
            mainIni.main[key] = nil
        end

        for dialog_line_index = 1, #parsed_dialog do
            mainIni.main["line_" .. dialog_line_index] = parsed_dialog[dialog_line_index]
        end
        
        inicfg.save(mainIni, "Fast-rec.ini")

        if selectedPlace then
            for dialog_line_index = 1, #parsed_dialog do
                if parsed_dialog[dialog_line_index] == selectedPlace then
                    sampSendDialogResponse(id, 1, dialog_line_index - 1, '')
                    selectedPlace = nil
                    return false
                end
            end
        end
    end
end

imgui.OnInitialize(function()
    local style = imgui.GetStyle()
    local colors = style.Colors
    style.WindowPadding = imgui.ImVec2(10.00, 10.00)
    style.FramePadding = imgui.ImVec2(12.00, 3.00)
    style.FrameRounding = 8.0
    style.FrameBorderSize = 2.0
    style.GrabRounding = 8.0
    style.TabRounding = 10.0
    style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50)
    colors[imgui.Col.Button] = imgui.ImVec4(0.10, 0.20, 0.30, 1.00)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.20, 0.30, 0.40, 1.00)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.30, 0.40, 0.50, 1.00)
end)