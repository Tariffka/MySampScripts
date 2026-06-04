script_name('{87c445}Custom Spawn')
script_version('1.2')
script_author('by yargoff')

-- Подключаем нужные библиотеки
local ev = require 'lib.samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

function json(filePath)
    local filePath = getWorkingDirectory()..'\\config\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
    local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\config') then
        createDirectory(getWorkingDirectory()..'\\config')
    end
    
    function class:Save(tbl)
        if tbl then
            local F = io.open(filePath, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end

    function class:Load(defaultTable)
        if not doesFileExist(filePath) then
            class:Save(defaultTable or {})
        end
        local F = io.open(filePath, 'r+')
        local TABLE = decodeJson(F:read() or {})
        F:close()
        for def_k, def_v in next, defaultTable do
            if TABLE[def_k] == nil then
                TABLE[def_k] = def_v
            end
        end
        return TABLE
    end

    return class
end

local settings = json('CustomHouseName.json'):Load({
    customName = {}
})

local tag = '{87c445}[Custom Spawn]{ffffff}'

function main()
    while not isSampAvailable() do wait(0) end

    -- Оборачиваем русский хардкод в u8:decode
    sampAddChatMessage(tag.. u8:decode(' Скрипт загружен!'), -1)

    sampRegisterChatCommand('addcs', function (arg)
        local idhouse, cname = arg:match('(%d+) (.+)')

        if not idhouse or idhouse == '' or not cname or cname == '' then
            sampAddChatMessage(tag.. u8:decode(' Впиши /addcs [ID дома] [Название]'), -1)
            return
        end

        if idhouse and cname then
            -- Текст cname пришел из сампа (CP1251). Для JSON переводим в UTF-8
            local cname_utf8 = u8(cname) 
            local existingIndex = nil
            local checkOneName = false

            for index, nameHouse in ipairs(settings.customName) do
                local idh, nameh = table.unpack(nameHouse)
                if idh == idhouse then
                    existingIndex = index

                    if nameh == cname_utf8 then
                        checkOneName = true
                    else
                        settings.customName[index] = {idhouse, cname_utf8}
                        local status, code = json('CustomHouseName.json'):Save(settings)
                        sampAddChatMessage(tag .. (status and u8:decode(' Обновил кастом название для домика - ') .. idhouse or u8:decode('Не смог внести кастом название домику: ')..code), -1)
                    end
                    break
                end
            end

            if existingIndex then
                if checkOneName then
                    sampAddChatMessage(tag.. u8:decode(' Кастом нейм уже содержится на этом домике!'), -1)
                end
                return true
            else
                table.insert(settings.customName, {idhouse, cname_utf8})
                local status, code = json('CustomHouseName.json'):Save(settings)
                sampAddChatMessage(status and tag .. u8:decode(' Ввёл кастом название для нового домика: "')..idhouse..'"' or tag .. u8:decode(' Не смог добавить кастом название: ')..code, -1)
                return false
            end
        end
    end)

    sampRegisterChatCommand('clearcs', function (args)
        if not args or args == '' then
            settings.customName = {}
            local status, code = json('CustomHouseName.json'):Save(settings)
            sampAddChatMessage(tag.. u8:decode(' Весь список очищен'), -1)
            return
        end

        local targetId = args

        if not targetId then
            sampAddChatMessage(tag.. u8:decode(' Ошибка: укажите корректный ID дома'), -1)
            return
        end

        local foundIndex = nil
        for i, id in ipairs(settings.customName) do
            local idh, cname = table.unpack(id)
            if idh == targetId then
                foundIndex = i
                break
            end
        end

        if not foundIndex then
            sampAddChatMessage(tag..' '..string.format(u8:decode('Дом с ID %s не найден в списке'), targetId), -1)
            return
        end

        table.remove(settings.customName, foundIndex)
        local status, code = json('CustomHouseName.json'):Save(settings)
        sampAddChatMessage(tag..' '..string.format(u8:decode('Нейм дома с ID %s успешно удален из списка'), targetId), -1)
    end)

    while true do
        wait(0)
    end
end

function ev.onShowDialog(id, style, tit, b1, b2, text)
    -- Заголовок приходит в CP1251, поэтому строку для поиска тоже декодируем
    if tit:match(u8:decode('{BFBBBA}Выбор места спавна')) then
        local modifiedText = {}

        for n in text:gmatch('[^\r\n]+') do
            -- Паттерн поиска тоже нужно декодировать, так как там русское "№"
            local idpunkta, namepunkt, idhouse = n:match(u8:decode('%{ae433d%}%[(%d+)%] %{ffffff%}(.+) №(%d+)'))

            -- Сверяем с русским словом "Дом"
            if idpunkta and namepunkt == u8:decode('Дом') and idhouse then
                local nameHouse = ''

                for i, hc in ipairs(settings.customName) do
                    local idhome, nameHome = table.unpack(hc)
                    if idhome == idhouse then
                        -- В JSON лежит UTF-8. Для сампа декодируем обратно в CP1251
                        nameHouse = u8:decode(nameHome)
                        break
                    end
                end

                if nameHouse ~= '' then
                    nameHouse = '{db9239}({a8e63e}'..nameHouse..'{db9239})'
                end

                local newLine = string.format(
                    '{ae433d}[%s] {ffffff}%s '..u8:decode('№')..'%s %s',
                    idpunkta,
                    namepunkt,
                    idhouse,
                    nameHouse
                )
                table.insert(modifiedText, newLine)
            else
                table.insert(modifiedText, n)
            end
        end

        local resultText = table.concat(modifiedText, '\n')
        return {id, style, tit, b1, b2, resultText}
    end
end
