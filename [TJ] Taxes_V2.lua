script_author('tarif_jan')
script_name('Taxes')
script_version('2.2')

require("moonloader")
local sampev = require("samp.events")
local inicfg = require("inicfg")

-- Подключаем библиотеку кодировок
local encoding = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8

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
    -- u8:decode применяется ко всей строке сразу, включая тег
    sampAddChatMessage(u8:decode("{ffa500}[Taxes v2]{ffffff}: " .. text), -1)
end

function main()
    repeat wait(0) until isSampAvailable()

    -- ================= КОМАНДЫ ================= --
    
    -- Ручные оплаты
    sampRegisterChatCommand('tx', function()
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
    
    -- ================= ЛОГИКА ЕЖЕЧАСНОГО СРАБАТЫВАНИЯ ================= --
    local paydayTriggered = false -- Флаг, чтобы не спамить запуск всю 00-ю минуту

    while true do
        wait(1000) -- Проверяем время раз в секунду
        
        -- Получаем текущие минуты
        local currentMinute = tonumber(os.date("%M"))

        if currentMinute == 0 then
            -- Если 00 минут и мы еще не запускали оплату в этом часу
            if not paydayTriggered then
                paydayTriggered = true
                
                lua_thread.create(function()
                    -- 1. Сначала запускаем оплату через телефон
                    if iniData.main.autoTaxes then
                        toggleTaxesPay()
                        
                        -- Ждем, пока флаг телефонной оплаты не перейдет в false
                        while isPayingTaxes do
                            wait(100)
                        end
                        wait(2000) -- Пауза между окнами
                    end

                    -- 2. Затем запускаем оплату семейной квартиры
                    if iniData.main.autoFamHouse then
                        toggleFamHousePay()
                    end
                end)
            end
        else
            -- Как только наступила 01 минута, сбрасываем флаг для следующего часа
            paydayTriggered = false
        end
    end
end

-- ================= ЛОГИКА ЗАПУСКА ОПЛАТЫ ================= --

function toggleTaxesPay()
    if isPayingTaxes then return end
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
        lua_thread.create(function()
            sampSendChat('/fammenu')
            wait(1200) -- Даем серверу время открыть меню перед отправкой CEF пакетов
            sendCef('familyMenu.changePage|5')
            wait(300)
            sendCef('familyMenu.apart.payTax')
            wait(300)
            sendCef('familyMenu.exit')
        end)
    else
        isPayingFamHouse = false
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
        if title == "{BFBBBA}" and text:find(u8:decode("{FFFFFF}1. Состояние основного счета")) then
            if text:find(u8:decode("{ffff00}Оплата всех налогов{FFFFFF}")) then
                local num = 0
                for line in text:gmatch("[^\r\n]+") do
                    if line == u8:decode("{ffff00}Оплата всех налогов{FFFFFF}") then
                        -- line уже в CP1251 от сервера, отправляем как есть
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

        elseif title == u8:decode("{BFBBBA}Оплата всех налогов") then
            sampSendDialogResponse(id, 1)
            isPayingTaxes = false

            if text == u8:decode("{00ff00}-{ffffff} У Вас нет налогов, которые требуется оплатить!") then
                chat("У вас нет налогов (телефон), которые можно оплатить.")
            end
            return false
        end
    end

    -- 2. Логика диалогов для Семейной Квартиры
    if isPayingFamHouse then
        -- Оборачиваем входящий текст в u8, чтобы .lower() корректно обработал русский язык
        local u8Title = u8(title):lower()
        local u8Text = u8(text):lower()

        -- Максимально гибкая проверка заголовка и текста на ключевые слова
        if u8Title:find('семейн') or u8Title:find('квартир') or u8Title:find('налог') or u8Text:find('семейную квартиру') then
            -- Очищаем текст уже в кодировке u8
            local cleanText = u8(text):gsub('{.-}', '')
            
            local taxRaw = cleanText:match('составляет%s*.-(%d[%d%s%.,]*)') or cleanText:match('налог%s*.-(%d[%d%s%.,]*)')
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

        elseif u8Title:find('информац') and (u8Text:find('теперь налог') or u8Text:find('вы оплатили')) then
            isPayingFamHouse = false
            local cleanInfo = u8(text):gsub('{.-}', '')
            
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
    -- Уведомление об успешной оплате обычных налогов
    if text:find(u8:decode("^Вы оплатили все налоги на сумму")) then
        chat("Налоги оплачены!")
    end
end