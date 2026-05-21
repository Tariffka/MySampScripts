local primaryColor = "#ff1c4a"
-- Черный переходит в темно-желтый сверху вниз
local backgroundColor = "rgba(0, 0, 0, .95)"
local activeColor = "rgba(54, 75, 132, .4)"

local jscode = [[const primaryColor = "%s";

for (let sheet of document.styleSheets) {
    const rules = sheet.cssRules || sheet.rules;
    for (let rule of rules) {
        switch (rule.selectorText) {
            case ".dialog":
                rule.style.background =
                    "linear-gradient(124.06deg,hsla(0,0%%,100%%,0) 28.6%%,hsla(0,0%%,100%%,.1) 123.45%%), %s";
                break;
            case ".dialog__button--primary":
                rule.style.background = primaryColor;
                break;
            case ".dialog-list__search:focus-within":
                rule.style.boxShadow = `inset 0 0 0 1px ${primaryColor}`;
                break;
            case ".dialog-input:focus-within":
                rule.style.boxShadow = `inset 0 0 0 1px ${primaryColor}`;
                break;
            case ".dialog-list__search:focus-within .dialog-list__search-icon":
                rule.style.color = primaryColor;
                break;
            case ".dialog-list-loop__list-item--active, .dialog-list-loop__list-item--active:hover, .dialog-list-loop__list-item--hovered, .dialog-list-loop__list-item--hovered:hover":
                rule.style.background = `%s`;
                break;
        }
    }
}]]

function onSendPacket(id, bs, priority, reliability, orderingChannel) 
    if id == 220 then
        id = raknetBitStreamReadInt8(bs)
        local packettype = raknetBitStreamReadInt8(bs)
        if packettype == 18 then
            local strlen = raknetBitStreamReadInt16(bs)
            local str = raknetBitStreamReadString(bs, strlen)
            if str:find("onSvelteAppVersion") then
                evalanon(jscode:format(primaryColor, backgroundColor, activeColor))
            end
        end
    end
end

function evalanon(code)
    evalcef(("(() => {%s})()"):format(code))
end

function evalcef(code, encoded)
    encoded = encoded or 0
    local bs = raknetNewBitStream();
    raknetBitStreamWriteInt8(bs, 17);
    raknetBitStreamWriteInt32(bs, 0);
    raknetBitStreamWriteInt16(bs, #code);
    raknetBitStreamWriteInt8(bs, encoded);
    raknetBitStreamWriteString(bs, code);
    raknetEmulPacketReceiveBitStream(220, bs);
    raknetDeleteBitStream(bs);
end