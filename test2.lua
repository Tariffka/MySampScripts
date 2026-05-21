
script_author("deddosouru")
script_description('legal and fast C-BUG using. Just hold RMB and hit "R" button like cowboy hits his colts trigger')
script_dependencies("SampFuncs 5.3.3 release #19 (SA-MP 0.3.7)(tested), MoonLoader (lol)")
script_version_number(4)
--Скачав это говно вы автоматически соглашаетесь с тем что написано вот тут: http://deddosouru.ml/elua
local inicfg = require 'inicfg'
local memory = require 'memory'
local cfg = inicfg.load({set = {
iHaveReadedLicenseAgreement = false, 
noRecoilWithDynamicCrosshair = false, 
showGameCrosshairInstantly = true, 
noCamRestore = false, 
autoScroll = true, 
missChanceIs1to = 1, 
randomMisses = false, 
checkpt = false, 
secondarykey = 18}})
function main()
while not isSampLoaded and not isSampfuncsLoaded do wait(0) end
while not isSampAvailable do wait(0) end
wait(9000)
inicfg.save(cfg)
sampRegisterChatCommand("testing", SHOW_DLG)
sampfuncsRegisterConsoleCommand("mlgshootingdesu", easterEgg)
if cfg.set.showGameCrosshairInstantly then showCrosshairInstantlyPatch(true) end
if cfg.set.noRecoilWithDynamicCrosshair then noRecoilDynamicCrosshair(true) end
while true do
	wait(0)
	curweap = getCurrentCharWeapon(playerPed)
	if cfg.set.noCamRestore then
	if not isCharDead(playerPed) then cameraRestorePatch(true)
	else cameraRestorePatch(false) end end
		if isButtonPressed(PLAYER_HANDLE, 6) and isKeyJustPressed(cfg.set.secondarykey) then
			if cfg.set.autoScroll and getAmmoInClip() < 5 then giveWeaponToChar(playerPed, curweap, 0) end
			while cfg.set.checkpt and getAmmoInClip() == 0 do wait(0) end
			wait(0)
			if cfg.set.randomMisses then
				if math.random(0, cfg.set.missChanceIs1to ) == 1 then
					wait(math.random(17, 40) * 10)
					setGameKeyState(18, 255)
				end
			else
				sendKey(4)
				setGameKeyState(17, 255)
				wait(55)
				setGameKeyState(6, 0)
				sendKey(2)
				setGameKeyState(18, 255)
			end
		end
	end
end

--128 4 2

function sendKey(key)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local data = allocateMemory(68)
    sampStorePlayerOnfootData(myId, data)
    setStructElement(data, 4, 2, key, false)
    sampSendOnfootData(data)
    freeMemory(data)
end

function easterEgg()
eaegg = not eaegg
if eaegg then lua_thread.create(mlg) end
end

function mlg()
	while true do
		wait(0)
		if not eaegg then return end
		isTargetin, handle = getCharPlayerIsTargeting(playerHandle)
		if isCharShooting(playerPed) and isTargetin then
			trgx, trgy, trgz = getCharCoordinates(handle)
			addOneOffSound(trgx, trgy, trgz, 1159)
			shakeCam(100)
		end
	end
end

function get_screen_centure(szX, szY)
 	local X,Y = getScreenResolution()
	X = X/2 - szX
	Y = Y/2 - szY
	return X, Y
end

function SHOW_DLG()
	lua_thread.create(showCur)
	return
end

function showCur()
	wait(0)
	if not dxutIsDialogExists(HND_DLG) then
		HND_DLG = dxutCreateDialog("{818384}LEGAL  {0094c8}C-BUG  {FFFFFF}Settings")
		local X, Y = get_screen_centure(155, 165)
		dxutSetDialogPos(HND_DLG, X, Y, 310, 330)
		dxutAddCheckbox(HND_DLG, 1, "iHaveReadedLicenseAgreement", 5, 5, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 1, cfg.set.iHaveReadedLicenseAgreement)
		dxutAddCheckbox(HND_DLG, 2, "showGameCrosshairInstantly", 5, 30, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 2, cfg.set.showGameCrosshairInstantly)
		dxutAddCheckbox(HND_DLG, 3, "noCamRestore", 5, 55, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 3, cfg.set.noCamRestore)
		dxutAddCheckbox(HND_DLG, 4, "autoScroll", 5, 80, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 4, cfg.set.autoScroll)
		dxutAddCheckbox(HND_DLG, 5, "noRecoilWithDynamicCrosshair", 5, 105, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 5, cfg.set.noRecoilWithDynamicCrosshair)
		dxutAddCheckbox(HND_DLG, 6, "checkpt", 5, 130, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 6, cfg.set.checkpt)
		dxutAddCheckbox(HND_DLG, 7, "randomMisses", 5, 155, 300, 20)
		dxutCheckboxSetChecked(HND_DLG, 7, cfg.set.randomMisses)
		dxutAddStatic(HND_DLG, 11, "Miss chance setting:", 5, 180, 300, 20)
		dxutAddEditbox(HND_DLG, 8, tostring(cfg.set.missChanceIs1to), 5, 200, 300, 35)
		dxutAddButton(HND_DLG, 9, string.format("change secondarykey. current: %s", cfg.set.secondarykey), 5, 245, 300, 20)
		dxutAddButton(HND_DLG, 10, "Save", 5, 290, 300, 20)
		dxutAddButton(HND_DLG, 12, "Close w/o saving to file", 5, 270, 300, 20)
		sampToggleCursor(true)
	else
		dxutSetDialogVisible(HND_DLG, (not dxutIsDialogVisible(HND_DLG)))
	end
	while true do
		wait(0)
		local RES, DLG_EVENT, DLG_CONTROL = dxutPopEvent(HND_DLG)
		if DLG_CONTROL == 10 --[[ "Save" button]] then
			wait(0)
			inicfg.save(cfg)
			dxutSetDialogVisible(HND_DLG, false)
			dxutDeleteDialog(HND_DLG)
			sampToggleCursor(false)
			break
		end
		if DLG_CONTROL == 1 --[[license agreement checkbox]] then
			cfg.set.iHaveReadedLicenseAgreement = not cfg.set.iHaveReadedLicenseAgreement
		end
		if DLG_CONTROL == 2 --[[crosshair patch]] then
			cfg.set.showGameCrosshairInstantly = not cfg.set.showGameCrosshairInstantly
			showCrosshairInstantlyPatch(cfg.set.showGameCrosshairInstantly)
		end
		if DLG_CONTROL == 3 --[[campatch]] then
			cfg.set.noCamRestore = not cfg.set.noCamRestore
			cameraRestorePatch(cfg.set.noCamRestore)
		end
		if DLG_CONTROL == 4 --[[autoScroll]] then
			cfg.set.autoScroll = not cfg.set.autoScroll
		end
		if DLG_CONTROL == 5 --[[no recoil]] then
			cfg.set.noRecoilWithDynamicCrosshair = not cfg.set.noRecoilWithDynamicCrosshair
			noRecoilDynamicCrosshair(cfg.set.noRecoilWithDynamicCrosshair)
		end
		if DLG_CONTROL == 6 --[[checkpt]] then
			cfg.set.checkpt = not cfg.set.checkpt
		end
		if DLG_CONTROL == 7 --[[randomMisses]] then
			cfg.set.randomMisses = not cfg.set.randomMisses
		end
		if DLG_CONTROL == 8 --[[misschance edit box]] and DLG_EVENT == 1537 --[[EVENT_EDITBOX_STRING]] then
			cfg.set.missChanceIs1to = tonumber(dxutGetControlText(HND_DLG, 8))
		end
		if DLG_CONTROL == 9 --[[set key button]] then
			dxutSetControlText(HND_DLG, 9, "press any key")
			repeat
				wait(0)
				repexit = false
				for btn = 0, 254 do
					if isKeyDown(btn) then
						repexit = true
						cfg.set.secondarykey = btn
						dxutSetControlText(HND_DLG, 9, string.format("change secondarykey. current: %s", cfg.set.secondarykey))
					end
				end
			until repexit
			repexit = false
		end
		if DLG_CONTROL == 12 --[[close w/o saving]] then
			wait(0)
			dxutSetDialogVisible(HND_DLG, false)
			sampToggleCursor(false)
			dxutDeleteDialog(HND_DLG)
			break
		end
	end
end


function getAmmoInClip() --4el0ve4ik
  local struct = getCharPointer(playerPed)
  local prisv = struct + 0x0718
  local prisv = memory.getint8(prisv, false)
  local prisv = prisv * 0x1C
  local prisv2 = struct + 0x5A0
  local prisv2 = prisv2 + prisv
  local prisv2 = prisv2 + 0x8
  local ammo = memory.getint32(prisv2, false)
  return ammo
end

function cameraRestorePatch(qqq) --by FYP
	if qqq then
		if not patch_cameraRestore then
			patch_cameraRestore1 = memory.read(0x5109AC, 1, true)
			patch_cameraRestore2 = memory.read(0x5109C5, 1, true)
			patch_cameraRestore3 = memory.read(0x5231A6, 1, true)
			patch_cameraRestore4 = memory.read(0x52322D, 1, true)
			patch_cameraRestore5 = memory.read(0x5233BA, 1, true)
		end
		memory.write(0x5109AC, 235, 1, true)
		memory.write(0x5109C5, 235, 1, true)
		memory.write(0x5231A6, 235, 1, true)
		memory.write(0x52322D, 235, 1, true)
		memory.write(0x5233BA, 235, 1, true)
	elseif patch_cameraRestore1 ~= nil then
		memory.write(0x5109AC, patch_cameraRestore1, 1, true)
		memory.write(0x5109C5, patch_cameraRestore2, 1, true)
		memory.write(0x5231A6, patch_cameraRestore3, 1, true)
		memory.write(0x52322D, patch_cameraRestore4, 1, true)
		memory.write(0x5233BA, patch_cameraRestore5, 1, true)
		patch_cameraRestore1 = nil
	end
end

function showCrosshairInstantlyPatch(enable) --by FYP
	if enable then
		if not patch_showCrosshairInstantly then
			patch_showCrosshairInstantly = memory.read(0x0058E1D9, 1, true)
		end
		memory.write(0x0058E1D9, 0xEB, 1, true)
	elseif patch_showCrosshairInstantly ~= nil then
		memory.write(0x0058E1D9, patch_showCrosshairInstantly, 1, true)
		patch_showCrosshairInstantly = nil
	end
end

function noRecoilDynamicCrosshair(qq) --by SR_Team
	if qq then
		if not patch_noRecoilDynamicCrosshair then
			patch_noRecoilDynamicCrosshair = memory.read(0x00740460, 1, true)
		end
		memory.write(0x00740460, 0x90, 1, true)
	elseif patch_noRecoilDynamicCrosshair ~= nil then
		memory.write(0x00740460, patch_noRecoilDynamicCrosshair, 1, true)
		patch_noRecoilDynamicCrosshair = nil
	end
end

function onExitScript()
	if cfg.set.crosshairPatch then
		showCrosshairInstantlyPatch(false)
	end
	if cfg.set.noRecoilWithDynamicCrosshair then
		noRecoilDynamicCrosshair(false)
	end
	if cfg.set.noCamRestore then
		cameraRestorePatch(false)
	end
end