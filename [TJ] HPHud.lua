script_author('tarif_jan')
script_name('hphud')
script_version('1.0')

require 'lib.moonloader'
local memory = require 'memory'

local razmer_teksta = 8
local cvet_hp       = 0xAAFF2222
local cvet_ap       = 0xFFFFFFFF
local sdvig_x       = 20 
local shrift        = 'Verdana'

-- Переменные для авто-определения максимума
local my_max_hp = 100
local my_max_ap = 100

local font_flag = require('moonloader').font_flag
local font      = renderCreateFont(shrift, razmer_teksta, font_flag.BOLD + font_flag.SHADOW)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    while true do
        wait(0)
        
        local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
        
        if isPointOnScreen(pX, pY, pZ, 0.0) then
            local ppX, ppY = convert3DCoordsToScreen(pX, pY, pZ)
            ppX = ppX - sdvig_x
            
            local hp = math.floor(getCharHealth(PLAYER_PED))
            local armor = math.floor(getCharArmour(PLAYER_PED))
            
            -- Авто-обновление максимума: если текущее выше запомненного, значит максимум вырос
            if hp > my_max_hp then my_max_hp = hp end
            if armor > my_max_ap then my_max_ap = armor end
            
            -- Отрисовка ХП
            if hp > 0 then
                renderFontDrawText(font, string.format("%d/%d", hp, my_max_hp), ppX, ppY, cvet_hp)
            end
            
            -- Отрисовка Брони
            if armor > 0 then
                renderFontDrawText(font, string.format("%d/%d", armor, my_max_ap), ppX, ppY + 12, cvet_ap)
            end
        end
    end
end