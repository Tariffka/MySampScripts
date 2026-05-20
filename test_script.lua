script_name("Test Script")

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("[Test] Тестовый скрипт успешно скачан и запущен!", 0x00FF00)

    wait(-1)
end
