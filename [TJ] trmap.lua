script_author('tarif_jan')
script_name('Карта Кладов')
script_version('1.1')

local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local sName = u8:decode('{368b55}[Карта]{FFFFFF} – ')
local zoneActive = false
local mapUsed = false
local kdcond = false
local endkd = u8:decode('Неизвестно.')
local autoCopyEnabled = true -- Флаг для автоматического копирования

-- Переменные для координат сделаем доступными для всего файла
local left, up, right, down = 0, 0, 0, 0
local kladZone = nil
local zonepaste = false

function main()
    while not isSampAvailable() do wait(0) end
    wait(100)
    sampAddChatMessage(sName .. u8:decode('Используйте команды: /zonecopy, /zonepaste, /zonedel, /iskd, /autocopy'), -1)
    
    -- Команда для включения/выключения авто-копирования
    sampRegisterChatCommand('autocopy', function()
        autoCopyEnabled = not autoCopyEnabled
        sampAddChatMessage(sName .. (autoCopyEnabled and u8:decode('Авто-копирование включено!') or u8:decode('Авто-копирование выключено!')), -1)
    end)
    
    sampRegisterChatCommand('zonedel', function()
        removeGangZone(610)
        sampAddChatMessage(sName .. u8:decode('Прошлая территория была удалена!'), -1)
    end)
    
    sampRegisterChatCommand('zonecopy', function()
        if mapUsed then
            setClipboardText('/zonepaste l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down)
            print('/zonepaste l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down .. u8:decode(' - скопировано'))
            sampAddChatMessage(sName .. u8:decode('Скопировано! Отправь это человеку, с которым хочешь поделиться координатами.'), -1)
        else
            sampAddChatMessage(sName .. u8:decode('Активируй карту кладов, чтобы скопировать координаты.'), -1)
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
                    sampAddChatMessage(sName .. u8:decode('Территория была успешно добавлена на твою карту!'), -1)
                else
                    sampAddChatMessage(sName .. u8:decode('Не тот формат! Вставь сюда координаты, которые тебе отправил друг с картой кладов.'), -1)
                end
            else
                sampAddChatMessage(sName .. u8:decode('Ты ничего не ввёл! Вставь сюда координаты, которые тебе отправил друг с картой кладов.'), -1)
            end
        else
            if zoneActive then
                removeGangZone(610)
                zoneActive = false
                sampAddChatMessage(sName .. u8:decode('Территория была удалена. Чтобы вернуть, введи координаты еще раз!'), -1)
            else
                sampAddChatMessage(sName .. u8:decode('Не тот формат! Вставь сюда координаты, которые тебе отправил друг с картой кладов.'), -1)
            end
        end
    end)
    
    sampRegisterChatCommand('iskd', function(arg)
        if kdcond == true then
            sampAddChatMessage(u8:decode('{FF0000}[Карта]{FFFFFF} – У тебя кулдаун. Ты не можешь использовать карту! Твой кулдаун кончится ') .. endkd, -1)
        elseif kdcond == false then
            sampAddChatMessage(u8:decode('{3cb043}[Карта]{FFFFFF} – Кулдауна нет. Можно использовать карту!'), -1)
        end
    end)
    
    while true do
        wait(0)
        local timenow = os.date('%X')
        if timenow == endkd then
            printStyledString(u8:decode('~r~COOLDOWN END'), 5000, 6)
            sampAddChatMessage(u8:decode('{3cb043}[Карта]{FFFFFF} – Кулдаун прошел! Карту можно использовать!'), -1)
            kdcond = false
            endkd = u8:decode('Неизвестно.')
        end
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
        
        sampAddChatMessage(sName .. u8:decode('Территория найдена! После ее исчезновения она будет автоматически восстановлена.'), -1)
        
        -- Если автокопирование включено, мгновенно заносим в буфер обмена
        if autoCopyEnabled then
            setClipboardText('/zonepaste l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down)
            sampAddChatMessage(sName .. u8:decode('{33CC33}Зона автоматически скопирована в буфер обмена!'), -1)
        else
            sampAddChatMessage(sName .. u8:decode('Чтобы скопировать ее координаты, пропиши /zonecopy'), -1)
        end
    end
end

function sampev.onGangZoneDestroy(zoneId1)
    if zoneId1 == kladZone then 
        removeGangZone(610)
        addGangZone(610, left, up, right, down, -2130706433)
        zoneActive = true
        sampAddChatMessage(sName .. u8:decode('Территория возвращена! Отсчёт кулдауна запущен!'), -1)

        timekd = os.date('%X')
        hourkd, minutekd, secundkd = timekd:match('(%d+):(%d+):(%d+)')
        if tonumber(minutekd) + 30 < 60 then
            endkd = hourkd .. ':' .. tonumber(minutekd) + 30 .. ':' .. secundkd
        else
            endkd = hourkd + 1 .. ':' .. tonumber(minutekd) - 30 .. ':' .. secundkd
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