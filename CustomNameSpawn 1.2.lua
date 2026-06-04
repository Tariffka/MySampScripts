script_name('{87c445}Custom Spawn')
script_version('1.2')
script_author('by yargoff')

local ev = require('lib.samp.events')

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

    sampAddChatMessage(tag.. ' Скрипт загружен!', -1)

    sampRegisterChatCommand('addcs', function (arg)
        local idhouse, cname = arg:match('(%d+) (.+)')

        if not idhouse or idhouse == '' then
            sampAddChatMessage(tag..' Впиши /addcs [ID дома] [Название]', -1)
            return
        end

        if not cname or cname == '' then
            sampAddChatMessage(tag..' Впиши /addcs [ID дома] [Название]', -1)
            return
        end

        if idhouse then
            if cname then
                
                local existingIndex = nil
                local checkOneName = false

                for index, nameHouse in ipairs(settings.customName) do
                    local idh, nameh = table.unpack(nameHouse)
                    if idh == idhouse then
                        existingIndex = index

                        if nameh == cname then
                            checkOneName = true
                        else
                            settings.customName[index] = {idhouse, cname}
                            local status, code = json('CustomHouseName.json'):Save(settings)
                            sampAddChatMessage(tag .. (status and ' Обновил кастом название для домика - ' .. idhouse or 'Не смог внести кастом название домику: '..code), -1)
                        end
                        break

                    end
                end

                if existingIndex then
                    if checkOneName then
                        sampAddChatMessage(tag.. ' Кастом нейм уже содержится на этом домике!', -1)
                    end
                    return true
                else
                    table.insert(settings.customName, {idhouse, cname})
                    local status, code = json('CustomHouseName.json'):Save(settings)
                    sampAddChatMessage(status and tag .. ' Ввёл кастом название для нового домика: "'..idhouse..'"' or tag .. ' Не смог добавить кастом название: '..code, -1)
                    return false -- новый бизнес
                end
            end
        end
    end)

    sampRegisterChatCommand('clearcs', function (args)
        -- Если аргументов нет — очищаем весь список
        if not args or args == '' then
            settings.customName = {}
            local status, code = json('CustomHouseName.json'):Save(settings)
            sampAddChatMessage(tag..' Весь список очищен', -1)
            return
        end

        local targetId = args

        -- Проверка: корректен ли ID (число)
        if not targetId then
            sampAddChatMessage(tag..' Ошибка: укажите корректный ID дома', -1)
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

        -- Если ID не найден
        if not foundIndex then
            sampAddChatMessage(tag..' '..string.format('Дом с ID %d не найден в списке', targetId), -1)
            return
        end

        -- Удаление найденного ID из списка
        table.remove(settings.customName, foundIndex)
        local status, code = json('CustomHouseName.json'):Save(settings)
        sampAddChatMessage(tag..' '..string.format('Нейм дома с ID %d успешно удален из списка', targetId), -1)

    end)

    while true do
        wait(0)
    end
end

function ev.onShowDialog(id, style, tit, b1, b2, text)
    if tit:match('{BFBBBA}Выбор места спавна') then
        local modifiedText = {}

        for n in text:gmatch('[^\r\n]+') do
            local idpunkta, namepunkt, idhouse = n:match('%{ae433d%}%[(%d+)%] %{ffffff%}(.+) №(%d+)')

            if idpunkta and namepunkt == 'Дом' and idhouse then
                local nameHouse = ''

                -- Поиск кастомного названия
                for i, hc in ipairs(settings.customName) do
                    local idhome, nameHome = table.unpack(hc)
                    if idhome == idhouse then
                        nameHouse = nameHome
                        break
                    end
                end

                if nameHouse ~= '' then
                    nameHouse = '{db9239}({a8e63e}'..nameHouse..'{db9239})'
                end

                local newLine = string.format(
                    '{ae433d}[%d] {ffffff}%s №%d %s',
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
