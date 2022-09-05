
local util = {}

function util.getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

function util.arrayContains (array, val)
    for index, value in ipairs(array) do
        if value == val then
            return true
        end
    end

    return false
end
	
function util.message(messageText)
    if messageText then
        local chatManager = sdk.get_managed_singleton("snow.gui.ChatManager");
        chatManager:call("reqAddChatInfomation", messageText, 2289944406);
    end
end

function util.isWeaponSheathed()
    local player = sdk.get_managed_singleton("snow.player.PlayerManager"):call("findMasterPlayer")
    local playerAction = sdk.find_type_definition("snow.player.PlayerBase"):get_field("<RefPlayerAction>k__BackingField"):get_data(player)
    return sdk.find_type_definition("snow.player.PlayerAction"):get_field("_weaponFlag"):get_data(playerAction) == 0
end

function util.split(text, delim)
    -- returns an array of fields based on text and delimiter (one character only)
    local result = {}
    local magic = "().%+-*?[]^$"

    if delim == nil then
        delim = "%s"
    elseif string.find(delim, magic, 1, true) then
        delim = "%"..delim
    end

    local pattern = "[^"..delim.."]+"
    for w in string.gmatch(text, pattern) do
        table.insert(result, w)
    end
    return result
end

return util;