script_name("Win1251 Test 2")
script_author("Tariffka")

function main()
    -- Чистый текст без u8:decode, так как файл в Windows-1251
    sampAddChatMessage("[Проверка] Второй скрипт успешно запущен из Windows-1251!", 0xFFFF00)
    
    while true do
        wait(0)
    end
end