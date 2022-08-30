
local Utils = {}

local function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

local function arrayContains (array, val)
    for index, value in ipairs(array) do
        if value == val then
            return true
        end
    end

    return false
end
	
local function message(messageText)
    if messageText then
        local chatManager = sdk.get_managed_singleton("snow.gui.ChatManager");
        chatManager:call("reqAddChatInfomation", messageText, 2289944406);
    end
end

local function isWeaponSheathed()
    local player = sdk.get_managed_singleton("snow.player.PlayerManager"):call("findMasterPlayer")
    local playerAction = sdk.find_type_definition("snow.player.PlayerBase"):get_field("<RefPlayerAction>k__BackingField"):get_data(player)
    return sdk.find_type_definition("snow.player.PlayerAction"):get_field("_weaponFlag"):get_data(playerAction) == 0
end

Utils.getTableSize = getTableSize;
Utils.message = message;
Utils.isWeaponSheathed = isWeaponSheathed;
Utils.arrayContains = arrayContains;

return Utils;