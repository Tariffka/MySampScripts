local uninvite_offline = false
local uninvite_online = false
local players_to_kick = {}


function kick_online_players()
    lua_thread.create(function ()
        local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
        sampAddChatMessage(' {33AA33}[fcleaner] {FFFFFF}Начинаю увольнение онлайн-состава...', -1)
        
        for index, value in ipairs(players_to_kick) do
            if tonumber(value.id) ~= tonumber(myid) then -- 
                sampSendChat('/uninvite ' .. value.id .. ' Расформ')
                printStringNow('Онлайн: ' .. index .. '/' .. #players_to_kick, 1200)
                wait(1300) 
            end
        end
        
        uninvite_online = false
        sampAddChatMessage(' {33AA33}[fcleaner] {FFFFFF}Полный расформ (оффлайн и онлайн) завершен!', -1)
    end)
end


function kick_offline_players()
    lua_thread.create(function ()
        for index, value in ipairs(players_to_kick) do
            sampSendChat('/uninviteoff ' .. value.nickname)
            printStringNow('Оффлайн: ' .. index .. '/' .. #players_to_kick, 1200)
            wait(1300)
        end
        
        sampAddChatMessage(' {33AA33}[fcleaner] {FFFFFF}Оффлайн список пуст. Перехожу к /members...', -1)
        uninvite_offline = false
        players_to_kick = {} 
        wait(1000)
        
        uninvite_online = true
        sampSendChat('/members') 
    end)
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand('fcleaner', function ()
        players_to_kick = {}
        uninvite_offline = true
        sampSendChat('/lmenu')
        sampAddChatMessage(' {33AA33}[fcleaner] {FFFFFF}Запуск полного расформа...', -1)
    end)
end

require('samp.events').onShowDialog = function(dialogid, style, title, button1, button2, text)
  
    if uninvite_offline then
        if text:find('Управление членами организации') then
            sampSendDialogResponse(dialogid, 1, 1, 0)
            return false 
        end
        
        if text:find("Игроки оффлайн") then
            sampSendDialogResponse(dialogid, 1, 1, 0)
            return false 
        end

        if title:find('Увольнение') or text:find('дней') then
            local counter = -1
            for line in text:gmatch('([^\n\r]+)') do
                counter = counter + 1
                local clean = line:gsub('{......}', '')
                local nick = clean:match('^%s*([A-Za-z0-9_]+)')
                
                if nick and not clean:find('Ник') and not clean:find('Имя') then
                    table.insert(players_to_kick, {nickname = nick})
                elseif line:find('Вперед') then
                    sampSendDialogResponse(dialogid, 1, counter - 1, "")
                    return false
                end
            end 

            if #players_to_kick > 0 then
                kick_offline_players()
            else
                uninvite_offline = false
                uninvite_online = true
                sampSendChat('/members') 
            end
            sampSendDialogResponse(dialogid, 2, 0, 0)
            return false
        end

        if text:find("Укажите причину") then
            sampSendDialogResponse(dialogid, 1, 0, 'Расформ')
            return false
        end
    end

    -- ЧАСТЬ 2: ОНЛАЙН (через /members)
    if uninvite_online and (title:find('Члены организации') or text:find('Ранг')) then
        local counter = -1
        for line in text:gmatch('([^\n\r]+)') do
            counter = counter + 1
            local clean = line:gsub('{......}', '')
            
            
            local id = clean:match('%[(%d+)%]')
            
            if id then
                table.insert(players_to_kick, {id = id})
            end
        end

        if #players_to_kick > 0 then
            kick_online_players()
        else
            sampAddChatMessage(' {FF3333}[fcleaner] {FFFFFF}В онлайне никого не найдено.', -1)
            uninvite_online = false
        end
        
        sampSendDialogResponse(dialogid, 2, 0, 0) 
        return false
    end
end