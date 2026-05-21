script_author('forbes')
script_name('FamHouse-AutoPay')
script_properties('work-in-pause=')
script_version('1.1')

local keys = require 'lib.vkeys'
for k, v in pairs(keys) do
	if k:sub(1, 3) == 'VK_' then
		_G[k] = v
	end
end

local inicfg = require 'inicfg'
local iniFile = ('%s.ini'):format(thisScript().name)
local ini = inicfg.load({
    settings = {
        mode = 1,
        key = VK_U,
        cooldown = 5
    }
}, iniFile)
if not doesFileExist('moonloader/config/' .. iniFile) then
    print('Creating/updating the .ini file')
    inicfg.save(ini, iniFile)
end


function printChat(text) sampAddChatMessage(string.format('[{007882}%s{FFFFFF}]: %s', thisScript().name, text), -1) end

local await = false
local timer = 0

function sendCef(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('fpay', autoPay)

    sampRegisterChatCommand('fhmode', function(arg) 
        if not tonumber(arg) or tonumber(arg) < 1 or tonumber(arg) > 3 then
            printChat('Ошибка, используйте {007882}/fhmode [1-3]')
            printChat('{007882}1{ffffff} - автоматическая оплата семейной квартиры после PayDay')
            printChat(('{007882}2{ffffff} - оплата семейной квартиры по клавише {007882}%s{ffffff} в течение {007882}%s{ffffff} секунд после PayDay'):format(keys.id_to_name(ini.settings.key), ini.settings.cooldown))
            printChat('{007882}3{ffffff} - оплата семейной квартиры только в ручном режиме по команде {007882}/fpay')
            return
        end
        ini.settings.mode = tonumber(arg)
        inicfg.save(ini, iniFile)
        printChat(
            ini.settings.mode == 1 
            and 'Вы выбрали {007882}первый{ffffff} режим оплаты семейной квартиры - автоматически после PayDay' 
            or ini.settings.mode == 2 
            and ('Вы выбрали {007882}второй{ffffff} режим оплаты семейной квартиры - по клавише {007882}%s{ffffff} в течение {007882}%s{ffffff} секунд после PayDay'):format(keys.id_to_name(ini.settings.key), ini.settings.cooldown)
            or 'Вы выбрали {007882}третий{ffffff} режим оплаты семейной квартиры - только в ручном режиме по команде {007882}/fpay'
        )
    end)

    sampRegisterChatCommand('fhcd', function (arg)
        if not tonumber(arg) or tonumber(arg) < 1 or tonumber(arg) > 999 then
            return printChat(('Ошибка, используйте {007882}/fhcd [секунды 1-999]{ffffff}. Текущая задержка: {007882}%s{ffffff} секунд'):format(ini.settings.cooldown))
        end
        ini.settings.cooldown = tonumber(arg)
        inicfg.save(ini, iniFile)
        printChat(('Вы изменили время ожидания для оплаты семейной квартиры по нажатию клавиши {007882}%s{ffffff} на {007882}%s{ffffff} секунд после PayDay'):format(keys.id_to_name(ini.settings.key), ini.settings.cooldown))
    end)

    printChat(('Скрипт загружен, версия {007882}%s{ffffff}. Автор: {007882}CaJlaT'):format(thisScript().version))
    printChat(
            ini.settings.mode == 1 
            and 'На текущий момент выбран {007882}первый{ffffff} режим оплаты семейной квартиры - автоматически после PayDay' 
            or ini.settings.mode == 2 
            and('На текущий момент выбран {007882}второй{ffffff} режим оплаты семейной квартиры - по клавише {007882}%s{ffffff} в течение {007882}%s{ffffff} секунд после PayDay'):format(keys.id_to_name(ini.settings.key), ini.settings.cooldown)
            or 'На текущий момент выбран {007882}третий{ffffff} режим оплаты семейной квартиры - только в ручном режиме по команде {007882}/fpay'
    )
    printChat('Для смены режима оплаты используйте команду {007882}/fhmode')
    printChat('Для смены задержки второго режима используйте команду {007882}/fhcd')

    while true do
        wait(0)
        if timer - os.clock() > 0 then
            if ini.settings.mode == 1 then
                wait(1000)
                autoPay()
                timer = 0
            elseif ini.settings.mode == 2 then
                printStringNow(('Press~g~ %s ~w~to pay FamHouse~n~Waiting:~g~ %s~w~...'):format(keys.id_to_name(ini.settings.key), math.ceil(timer - os.clock())), 100)
            end
        end
    end
end

function autoPay()
    if not await then
        await = true
        sampSendChat('/fammenu')
        printChat('Оплачиваем семейную квартиру...')
        sendCef('familyMenu.changePage|5')
        sendCef('familyMenu.apart.payTax')
        sendCef('familyMenu.exit')
    else
        await = false
        printChat('Оплата семейной квартиры отменена')
    end
end

local samp = require 'samp.events'

function samp.onShowDialog(id, style, title, b1, b2, text)
    if await then
        -- 1. Окно ввода суммы налога
        if title:find('Оплата налога на семейную квартиру') then
            local cleanText = text:gsub('{.-}', '')
            
            -- Пытаемся найти сумму после $ или :K:
            local taxRaw = cleanText:match('%$(%s*[%d%s%.,]+)') or cleanText:match(':K:%s*(%s*[%d%s%.,]+)')
            local tax = nil

            if taxRaw then
                tax = taxRaw:gsub('%D', '')
            end

            -- Если по знакам не нашли, ищем самое длинное число (запасной вариант)
            if not tax or tonumber(tax) == 0 then
                local longTax = ""
                for digit in cleanText:gmatch('%d+') do
                    if #digit > #longTax then
                        longTax = digit
                    end
                end
                tax = longTax
            end

            -- Если в итоге нашли число больше 0 — отправляем
            if tax and tonumber(tax) and tonumber(tax) > 0 then
                sampSendDialogResponse(id, 1, 0, tostring(tax))
                return false
            end

            -- Если ничего не нашли
            await = false
            printChat('Оплата была отменена: не удалось определить сумму или налога нет')
            sampSendDialogResponse(id, 0)
            return false

        -- 2. Окно подтверждения оплаты
        elseif title:find('Информация') and (text:find('Теперь налог') or text:find('Вы оплатили')) then
            await = false
            local cleanInfo = text:gsub('{.-}', '')
            local payed = cleanInfo:match('Вы оплатили %$(%d+)') or "неизвестно"
            local remain = cleanInfo:match('составляет: %$(%d+)') or "0"
            
            printChat(string.format('Оплачено {007882}%s${ffffff} налога, остаток: {007882}%s$', payed, remain))
            sampSendDialogResponse(id, 0)
            return false
        end
    end
end


function samp.onServerMessage(color, text)
    if not await then
        if text:find('==========================================================================') then
            timer = os.clock() + ini.settings.cooldown
        end
    end
end

addEventHandler("onWindowMessage", function (msg, wp, lp)
	if wp == ini.settings.key and ini.settings.mode == 2 and timer - os.clock() > 0 then 
		autoPay()
        timer = 0
		consumeWindowMessage()
	end
end)