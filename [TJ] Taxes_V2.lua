script_author('tarif_jan')
script_name('Taxes')
script_version('2.0')

require("moonloader")
local sampev = require("samp.events")
local inicfg = require("inicfg")

-- Единый конфигурационный файл для обоих скриптов
local iniFile = "Taxes_v2.ini"
local iniData = inicfg.load({
    main = {
        autoTaxes = false,
        autoFamHouse = false
    }
}, iniFile)

-- Флаги состояний (чтобы скрипт понимал, какой диалог сейчас обрабатывать)
local isPayingTaxes = false
local isPayingFamHouse = false

-- Удобная функция для вывода сообщений в чат с единым тегом
function chat(text)
    sampAddChatMessage("{ffa500}[Taxes v2]{ffffff}: " .. text, -1)
end

function main()
    repeat wait(0) until isSampAvailable()

    -- ================= КОМАНДЫ ================= --
    
    -- Ручные оплаты
    sampRegisterChatCommand('tx', function()
        chat("Запуск ручной оплаты налогов (телефон)...")
        toggleTaxesPay()
    end)

    sampRegisterChatCommand('th', function()
        toggleFamHousePay()
    end)

    -- Переключатели авто-оплаты
    sampRegisterChatCommand('txm', function()
        iniData.main.autoTaxes = not iniData.main.autoTaxes
        inicfg.save(iniData, iniFile)
        local status = iniData.main.autoTaxes and "{00ff00}Включена" or "{ff0000}Выключена"
        chat("Авто-оплата всех налогов теперь " .. status)
    end)

    sampRegisterChatCommand('thm', function()
        iniData.main.autoFamHouse = not iniData.main.autoFamHouse
        inicfg.save(iniData, iniFile)
        local status = iniData.main.autoFamHouse and "{00ff00}Включена" or "{ff0000}Выключена"
        chat("Авто-оплата семейной квартиры теперь " .. status)
    end)

    -- Меню помощи
    sampRegisterChatCommand('fhmode', function()
        chat("Список команд:")
        chat("{ffc0cb}/tx{ffffff} - Ручная оплата налогов дом/биз")
        chat("{ffc0cb}/th{ffffff} - Ручная оплата Фам.КВ")
        chat("{ffc0cb}/txm{ffffff} - Включить/Выключить авто-оплату налогов дом/биз")
        chat("{ffc0cb}/thm{ffffff} - Включить/Выключить авто-оплату Фам.КВ")
    end)

    chat("[TJ]Скрипт загружен. Введите {ffc0cb}/fhmode{ffffff} для справки.")
    wait(-1)
end

-- ================= ЛОГИКА ЗАПУСКА ОПЛАТЫ ================= --

function toggleTaxesPay()
    isPayingTaxes = true
    lua_thread.create(function()
        sampSendChat('/phone')
        wait(1000)
        sendCef('launchedApp|24')
        wait(300)
        sendCefRaw({220, 0, 27, 0})
        wait(500)
        sendCef('onSvelteAppInit')
    end)
end

function toggleFamHousePay()
    if not isPayingFamHouse then
        isPayingFamHouse = true
        sampSendChat('/fammenu')
        chat('Оплачиваем семейную квартиру...')
        sendCef('familyMenu.changePage|5')
        sendCef('familyMenu.apart.payTax')
        sendCef('familyMenu.exit')
    else
        isPayingFamHouse = false
        chat('Оплата семейной квартиры отменена (ручное прерывание).')
    end
end

-- ================= ОТПРАВКА CEF ПАКЕТОВ ================= --

function sendCefRaw(packet)
    local bs = raknetNewBitStream()
    for _, value in ipairs(packet) do
        raknetBitStreamWriteInt8(bs, value)
    end
    raknetSendBitStreamEx(bs, 1, 7, 1)
    raknetDeleteBitStream(bs)
end

function sendCef(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, string.len(str))
    raknetBitStreamWriteString(bs, str)
    raknetSendBitStreamEx(bs, 1, 7, 1)
    raknetDeleteBitStream(bs)
end

-- ================= ПЕРЕХВАТ ДИАЛОГОВ ================= --

function sampev.onShowDialog(id, style, title, button1, button2, text)
    
    -- 1. Логика диалогов для Обычных Налогов (Телефон)
    if isPayingTaxes then
        if title == "{BFBBBA}" and text:find("{FFFFFF}1. Состояние основного счета") then
            if text:find("{ffff00}Оплата всех налогов{FFFFFF}") then
                local num = 0
                for line in text:gmatch("[^\r\n]+") do
                    if line == "{ffff00}Оплата всех налогов{FFFFFF}" then
                        sampSendDialogResponse(id, 1, num, line)
                        return false
                    end
                    num = num + 1
                end
            else
                sampSendDialogResponse(id, 0)
                chat("{ff0000}Ошибка.{ffffff} В меню нет пункта '{ffff00}Оплата всех налогов{ffffff}'.")
                isPayingTaxes = false
                return false
            end

        elseif title == "{BFBBBA}Оплата всех налогов" then
            sampSendDialogResponse(id, 1)
            isPayingTaxes = false

            if text == "{00ff00}-{ffffff} У Вас нет налогов, которые требуется оплатить!" then
                chat("У вас нет налогов (телефон), которые можно оплатить.")
            end
            return false
        end
    end

    -- 2. Логика диалогов для Семейной Квартиры
    if isPayingFamHouse then
        if title:find('Оплата налога на семейную квартиру') then
            local cleanText = text:gsub('{.-}', '')
            
            local taxRaw = cleanText:match('составляет%s*.-(%d[%d%s%.,]*)')
            local tax = nil

            if taxRaw then
                tax = taxRaw:gsub('%D', '')
            end

            if not tax or tonumber(tax) == 0 then
                local firstNum = cleanText:match('(%d[%d%s%.,]*)')
                if firstNum then
                    tax = firstNum:gsub('%D', '')
                end
            end

            if tax and tonumber(tax) and tonumber(tax) > 0 then
                sampSendDialogResponse(id, 1, 0, tostring(tax))
                return false
            end

            isPayingFamHouse = false
            chat('Оплата отменена: не удалось определить сумму или налога на квартиру нет.')
            sampSendDialogResponse(id, 0)
            return false

        elseif title:find('Информация') and (text:find('Теперь налог') or text:find('Вы оплатили')) then
            isPayingFamHouse = false
            local cleanInfo = text:gsub('{.-}', '')
            
            local payedRaw = cleanInfo:match('Вы оплатили%s*.-(%d[%d%s%.,]*)')
            local remainRaw = cleanInfo:match('составляет%s*.-(%d[%d%s%.,]*)') or cleanInfo:match('налог%s*.-(%d[%d%s%.,]*)')
            
            local payed = payedRaw and payedRaw:gsub('%D', '') or "неизвестно"
            local remain = remainRaw and remainRaw:gsub('%D', '') or "0"
            
            chat(string.format('Квартира оплачена: {007882}%s${ffffff}. Остаток: {007882}%s$', payed, remain))
            sampSendDialogResponse(id, 0)
            return false
        end
    end
end

-- ================= ПЕРЕХВАТ СООБЩЕНИЙ ЧАТА (PAYDAY) ================= --

function sampev.onServerMessage(color, text)
    -- Проверка на PayDay
    if text:find("==========================================================================") then
        
        if iniData.main.autoTaxes then
            chat("PayDay! Оплата обычных налогов начнется через 5 секунд...")
            lua_thread.create(function()
                wait(5000)
                toggleTaxesPay()
            end)
        end

        if iniData.main.autoFamHouse then
            chat("PayDay! Оплата семейной квартиры начнется через 10 секунд...")
            lua_thread.create(function()
                wait(10000) -- Ждем дольше, чтобы не сбить CEF меню телефона обычными диалогами!
                toggleFamHousePay()
            end)
        end
    end

    -- Уведомление об успешной оплате обычных налогов
    if text:find("^Вы оплатили все налоги на сумму") then
        chat("{00ff00}Налоги дом/биз оплачены!")
    end
end