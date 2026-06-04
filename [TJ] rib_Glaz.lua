script_name('Ðûáèé ãëàç')
script_version("1.0")
script_author('tarif_jan')

local enabled = true
local locked = false
local currentFov = 101.0 -- Áàçîâîå çíà÷åíèå FOV ïðè çàïóñêå

function main()
	repeat wait(0) until isSampAvailable()
	
	--[[_______________COMMANDS_______________]]--
	sampRegisterChatCommand('glaz', function()
		enabled = not enabled
		if enabled then
			msg('Ýôôåêò {00FF00}âêëþ÷åí')
		else
			msg('Ýôôåêò {FF0000}âûêëþ÷åí')
			-- Âîçâðàùàåì ñòàíäàðòíûé FOV ïðè âûêëþ÷åíèè, ÷òîáû êàìåðà íå çàñòðåâàëà
			cameraSetLerpFov(70.0, 70.0, 1000, 1) 
		end
	end)

	sampRegisterChatCommand('fov', function(arg)
		local fovValue = tonumber(arg)
		-- Ïðîâåðÿåì, ÷òî ââåëè ÷èñëî è îíî â àäåêâàòíûõ ïðåäåëàõ (îò 10 äî 150)
		if fovValue and fovValue >= 10 and fovValue <= 150 then
			currentFov = fovValue
			msg('Çíà÷åíèå FOV óñïåøíî èçìåíåíî íà: {CD5C5C}' .. currentFov)
		else
			msg('Îøèáêà! Èñïîëüçóéòå: {CD5C5C}/fov [10 - 150]')
		end
	end)
	--[[_______________COMMANDS_______________]]--
	
	msg(string.format('Ñêðèïò ïîäãðóæåí. Âëàäåëåö: {CD5C5C}[%s]', thisScript().authors[1]))
	msg('Êîìàíäû: {CD5C5C}/glaz {ffffff}— âêë/âûêë, {CD5C5C}/fov [10-150] {ffffff}— óãîë îáçîðà')
	
	while true do
		wait(0)
		if enabled then
			-- 34 id îðóæèÿ - ýòî ñíàéïåðñêàÿ âèíòîâêà. Âîçâðàùàåì ñòàíäàðòíûé FOV â ïðèöåëå.
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
	sampAddChatMessage(string.format('[%s] {ffffff}%s', thisScript().name, text), 0xFFCD5C5C)
end
