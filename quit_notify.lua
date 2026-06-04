-- by Cosmo with <3
script_version('1.0')

local se = require("samp.events")
local Vector3D = require("vector3d")
local encoding = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local pool_3DTexts = {}
local pool_notifies = {}
local duration = 15
local quit_reasons = {
    [0] = u8:decode("Краш / Тайм-аут"),
    [1] = u8:decode("Вышел c сервера"),
    [2] = u8:decode("Кикнут сервером")
}

function se.onPlayerQuit(player_id, reason)
    local result, player_char = sampGetCharHandleBySampPlayerId(player_id)
    if not result then
        return nil
    end

    local px, py, pz = getCharCoordinates(player_char)
    local mx, my, mz = getCharCoordinates(PLAYER_PED)

    if getDistanceBetweenCoords3d(px, py, pz, mx, my, mz) <= 50 then
        local nickname = sampGetPlayerNickname(player_id)
        local message = table.concat({
            u8:decode(("Игрок %s(%d) покинул игру"):format(nickname, player_id)),
            "",
            quit_reasons[reason] or u8:decode("Неизвестная причина"),
            u8:decode(("Время: %s"):format(os.date("%H:%M:%S")))
        }, "\n")

        createQuitNotify(px, py, pz, message)
    end
end

function se.onCreate3DText(id, color, pos, dist, testLOS, playerID, vehicleID, text)
    pool_3DTexts[id] = true

    if pool_notifies[id] ~= nil then
        pool_notifies[id] = nil
    end
end

function se.onRemove3DTextLabel(id)
    pool_3DTexts[id] = nil

    if pool_notifies[id] ~= nil then
        return false
    end
end

function onScriptTerminate(script, isQuit)
    if script == thisScript() then
        for id, time in pairs(pool_notifies) do
            removeQuitNotify(id)
        end
    end
end

function createQuitNotify(x, y, z, text)
    -- Текст уже декодирован перед отправкой, поэтому используем его напрямую
    local id = sampCreate3dText(text, 0xAAFFFFFF, x, y, z, 25, false, 0xFFFF, 0xFFFF)
    pool_notifies[id] = os.clock() + duration

    lua_thread.create(function()
        while pool_notifies[id] and os.clock() < pool_notifies[id] do
            wait(0)
        end
        removeQuitNotify(id)
    end)
end

function removeQuitNotify(id)
    if pool_notifies[id] == nil then
        return nil
    end

    if sampIs3dTextDefined(id) then
        sampDestroy3dText(id)
    end

    pool_notifies[id] = nil
end

function sampCreate3dText(text, color, x, y, z, dist, testLOS, playerID, vehicleID)
    local free_id = -1
    for id = 2047, 0, -1 do
        if pool_3DTexts[id] == nil then
            free_id = id
            break
        end
    end

    if free_id == -1 then
        return nil
    end

    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, free_id)
    raknetBitStreamWriteInt32(bs, color)
    raknetBitStreamWriteFloat(bs, x)
    raknetBitStreamWriteFloat(bs, y)
    raknetBitStreamWriteFloat(bs, z)
    raknetBitStreamWriteFloat(bs, dist)
    raknetBitStreamWriteInt8(bs, testLOS and 1 or 0)
    raknetBitStreamWriteInt16(bs, playerID)
    raknetBitStreamWriteInt16(bs, vehicleID)
    raknetBitStreamEncodeString(bs, text) -- Текст уже переведен в нужную кодировку
    raknetEmulRpcReceiveBitStream(36, bs)
    raknetDeleteBitStream(bs)

    pool_3DTexts[free_id] = true

    return free_id
end

function sampDestroy3dText(id)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetEmulRpcReceiveBitStream(58, bs)
    raknetDeleteBitStream(bs)

    pool_3DTexts[id] = nil
end

function sampIs3dTextDefined(id)
    return pool_3DTexts[id] ~= nil
end
