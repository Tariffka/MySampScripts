script_name('Рыбий глаз')
script_version('1.0')
script_author('tarif_jan')

-- Подключаем кодировку
local encoding = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local enabled = true
local locked = false
local currentFov = 101.0 -- Базовое значение FOV при запуске

function main()
	repeat wait(0) until isSampAvailable()
	
	--[[_______________COMMANDS_______________]]--
	sampRegisterChatCommand('glaz', function()
		enabled = not enabled
		if enabled then
			msg(u8:decode('Эффект {00FF00}включен'))
		else
			msg(u8:decode('Эффект {FF0000}выключен'))
			-- Возвращаем стандартный FOV при выключении, чтобы камера не застревала
			cameraSetLerpFov(70.0, 70.0, 1000, 1) 
		end
	end)

	sampRegisterChatCommand('fov', function(arg)
		local fovValue = tonumber(arg)
		-- Проверяем, что ввели число и оно в адекватных пределах (от 10 до 150)
		if fovValue and fovValue >= 10 and fovValue <= 150 then
			currentFov = fovValue
			msg(u8:decode('Значение FOV успешно изменено на: {CD5C5C}') .. currentFov)
		else
			msg(u8:decode('Ошибка! Используйте: {CD5C5C}/fov [10 - 150]'))
		end
	end)
	--[[_______________COMMANDS_______________]]--
	
	msg(u8:decode(string.format('Скрипт подгружен. Владелец: {CD5C5C}[%s]', thisScript().authors[1])))
	msg(u8:decode('Команды: {CD5C5C}/glaz {ffffff}— вкл/выкл, {CD5C5C}/fov [10-150] {ffffff}— угол обзора'))
	
	while true do
		wait(0)
		if enabled then
			-- 34 id оружия - это снайперская винтовка. Возвращаем стандартный FOV в прицеле.
			if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
				if not locked then 
					cameraSetLerpFov(70.0, 70.0, 1000, 1)
					locked = true
				end
			else
				cameraSetLerpFov(currentFov, currentFov, 1000, 1)
				locked = false
			end
		end
	end
end

function msg(text)
	-- Оборачиваем имя скрипта и текст в u8:decode для корректного вывода
	sampAddChatMessage(u8:decode(string.format('[%s] {ffffff}%s', thisScript().name, text)), 0xFFCD5C5C)
end
