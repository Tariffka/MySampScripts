script_author('tarif_jan')
script_name('Êàðòà Êëàäîâ')
script_version('1.0')

local sampev = require 'lib.samp.events'

local sName = '{368b55}[Êàðòà]{FFFFFF} – '
local zoneActive = false
local mapUsed = false
local kdcond = false
local endkd = 'Íåèçâåñòíî.'
local autoCopyEnabled = true -- Ôëàã äëÿ àâòîìàòè÷åñêîãî êîïèðîâàíèÿ

function main()
    while not isSampAvailable() do wait(0) end
    wait(100)
    sampAddChatMessage(sName .. 'Èñïîëüçóéòå êîìàíäû: /zonecopy, /zonepaste, /zonedel, /iskd, /autocopy', -1)
    
    -- Êîìàíäà äëÿ âêëþ÷åíèÿ/âûêëþ÷åíèÿ àâòî-êîïèðîâàíèÿ
    sampRegisterChatCommand('autocopy', function()
        autoCopyEnabled = not autoCopyEnabled
        sampAddChatMessage(sName .. (autoCopyEnabled and 'Àâòî-êîïèðîâàíèå âêëþ÷åíî!' or 'Àâòî-êîïèðîâàíèå âûêëþ÷åíî!'), -1)
    end)
    
    sampRegisterChatCommand('zonedel', function()
        removeGangZone(610)
        sampAddChatMessage(sName .. 'Ïðîøëàÿ òåððèòîðèÿ áûëà óäàëåíà!', -1)
    end)
    
    sampRegisterChatCommand('zonecopy', function()
        if mapUsed then
            setClipboardText('/zonepaste l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down)
            print('/zonepaste l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down .. ' - ñêîïèðîâàíî')
            sampAddChatMessage(sName .. 'Ñêîïèðîâàíî! Îòïðàâü ýòî ÷åëîâåêó, ñ êîòîðûì õî÷åøü ïîäåëèòüñÿ êîîðäèíàòàìè.', -1)
        else
            sampAddChatMessage(sName .. 'Àêòèâèðóé êàðòó êëàäîâ, ÷òîáû ñêîïèðîâàòü êîîðäèíàòû.', -1)
        end
    end)
    
    sampRegisterChatCommand('zonepaste', function(coord)
        zonepaste = not zonepaste
        if zonepaste then
            if #coord ~= 0 then
                if coord:match('l: (.*); u: (.*); r: (.*); d: (.*)') then
                    pLeft, pUp, pRight, pDown = coord:match('l: (.*); u: (.*); r: (.*); d: (.*)')
                    removeGangZone(610)
                    addGangZone(610, pLeft, pUp, pRight, pDown, -2130706433)
                    zoneActive = true
                    sampAddChatMessage(sName .. 'Òåððèòîðèÿ áûëà óñïåøíî äîáàâëåíà íà òâîþ êàðòó!', -1)
                else
                    sampAddChatMessage(sName .. 'Íå òîò ôîðìàò! Âñòàâü ñþäà êîîðäèíàòû, êîòîðûå òåáå îòïðàâèë äðóã ñ êàðòîé êëàäîâ.', -1)
                end
            else
                sampAddChatMessage(sName .. 'Òû íè÷åãî íå ââ¸ë! Âñòàâü ñþäà êîîðäèíàòû, êîòîðûå òåáå îòïðàâèë äðóã ñ êàðòîé êëàäîâ.', -1)
            end
        else
            if zoneActive then
                removeGangZone(610)
                zoneActive = false
                sampAddChatMessage(sName .. 'Òåððèòîðèÿ áûëà óäàëåíà. ×òîáû âåðíóòü, ââåäè êîîðäèíàòû åùå ðàç!', -1)
            else
                sampAddChatMessage(sName .. 'Íå òîò ôîðìàò! Âñòàâü ñþäà êîîðäèíàòû, êîòîðûå òåáå îòïðàâèë äðóã ñ êàðòîé êëàäîâ.', -1)
            end
        end
    end)
    
    sampRegisterChatCommand('iskd', function(arg)
        if kdcond == true then
            sampAddChatMessage('{FF0000}[Êàðòà]{FFFFFF} – Ó òåáÿ êóëäàóí. Òû íå ìîæåøü èñïîëüçîâàòü êàðòó! Òâîé êóëäàóí êîí÷èòñÿ ' .. endkd, -1)
        elseif kdcond == false then
            sampAddChatMessage('{3cb043}[Êàðòà]{FFFFFF} – Êóëäàóíà íåò. Ìîæíî èñïîëüçîâàòü êàðòó!', -1)
        end
    end)
    
    while true do
        wait(0)
        local timenow = os.date('%X')
        if timenow == endkd then
            printStyledString('~r~COOLDOWN END', 5000, 6)
            sampAddChatMessage('{3cb043}[Êàðòà]{FFFFFF} – Êóëäàóí ïðîøåë! Êàðòó ìîæíî èñïîëüçîâàòü!', -1)
            kdcond = false
            endkd = 'Íåèçâåñòíî.'
        end
    end
end


function sampev.onServerMessage(_, text)
    if autoCopyEnabled and text:find('Òåððèòîðèÿ íàéäåíà! Ïîñëå åå èñ÷åçíîâåíèÿ îíà áóäåò àâòîìàòè÷åñêè âîññòàíîâëåíà') then
        lua_thread.create(function()
            wait(200)
			sampAddChatMessage(sName .. 'Òåêñò áûë îáíàðóæåí, ïðîèçâîäèòñÿ àâòîìàòè÷åñêèé /zonecopy', -1)
			wait(400)
			sampProcessChatInput("/zonecopy")
        end)
    end
end


function sampev.onCreateGangZone(zoneId, squareStart, squareEnd, color)
    if color == -16776961 then
        mapUsed = true
        kladZone = zoneId
        left = squareStart.x
        up = squareStart.y
        right = squareEnd.x
        down = squareEnd.y
        print('l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down)
        sampAddChatMessage(sName .. 'Òåððèòîðèÿ íàéäåíà! Ïîñëå åå èñ÷åçíîâåíèÿ îíà áóäåò àâòîìàòè÷åñêè âîññòàíîâëåíà.', -1)
        sampAddChatMessage(sName .. '×òîáû ñêîïèðîâàòü åå êîîðäèíàòû, ïðîïèøè /zonecopy', -1)
    end
end

function sampev.onGangZoneDestroy(zoneId1)
    if zoneId1 == kladZone then 
        removeGangZone(610)
        addGangZone(610, left, up, right, down, -2130706433)
        zoneActive = true
        sampAddChatMessage(sName .. 'Òåððèòîðèÿ âîçâðàùåíà! Îòñ÷¸ò êóëäàóíà çàïóùåí!', -1)

        timekd = os.date('%X')
        hourkd, minutekd, secundkd = timekd:match('(%d+):(%d+):(%d+)')
        if minutekd + 30 < 60 then
            endkd = hourkd .. ':' .. tonumber(minutekd) + 30 .. ':' .. secundkd
        else
            endkd = hourkd + 1 .. ':' .. tonumber(minutekd) - 60 + 30 .. ':' .. secundkd
        end
        kdcond = true
    end
end

function addGangZone(id, left, up, right, down, color)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetBitStreamWriteFloat(bs, left)
    raknetBitStreamWriteFloat(bs, up)
    raknetBitStreamWriteFloat(bs, right)
    raknetBitStreamWriteFloat(bs, down)
    raknetBitStreamWriteInt32(bs, color)
    raknetEmulRpcReceiveBitStream(108, bs)
    raknetDeleteBitStream(bs)
end

function removeGangZone(id)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetEmulRpcReceiveBitStream(120, bs)
    raknetDeleteBitStream(bs)
end
