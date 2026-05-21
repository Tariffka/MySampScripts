script_name("Test Script")
script_author("Tariffka")

function main()
    -- Просто сразу выводим сообщение, так как игра уже запущена
    sampAddChatMessage("[Test] Этот скрипт был успешно запущен лаунчером на лету!", 0x33AAFF)
    
    -- Бесконечный цикл, чтобы скрипт не закрывался сразу после вывода сообщения
    while true do
        wait(0)
    end
end
