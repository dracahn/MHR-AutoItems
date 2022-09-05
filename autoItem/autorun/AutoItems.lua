local modName = "AutoItems"
local version = "1.0.0"
local author = "dracahn"

local spawnVar = false
local startCombatHolder = false
local drawHolder = false
local doOnce = true
local death = false
local endQuest = false

local dbg = {}

dbg.counter = 0
dbg.actItemNo = -1
local dmp = {}

local modUtils = require(modName .. "/mod_utils")
local dracahnUtil = require(modName .. "/dracahn_util")
local language = require(modName .. "/Language")
local langList = {
    "en-us",
    "en-nn",
},

log.info(modName .. " loaded!")  -- Writes to game folder/re2_framework_log.txt
modUtils.info("Does the same as above, but puts [MODUTILS] at the beginning of the line, allowing you to find your logs among other logs easier")

local settings = modUtils.getConfigHandler({
    enabled = true,
    offlineOnly = false,
    message = true,
    consumeItems = false,
    isWindowOpen = true,
    userChoices = {},
    language = {
        current = "en-us",
        languages = {},
        sorted = {},
    }
}, modName)
-- Load the languages
language.init(settings)

--[[ item types:
    0 = apply all buff fields
    1 = sharpen
    2 = heal
    3 = Max Stanima up
]]

local foodList = {
    -- [itemId] = {title, types, effectId, {{buffFieldName, buffFieldValue}, .. }}
	[1] = {68157917, "Demondrug", {0}, 110, {{"_AtkUpAlive", "_DemondrugAtkUp", nil}}},
	[2] = {68157918, "MegaDemondrug", {0}, 110, {{"_AtkUpAlive", "_GreatDemondrugAtkUp", nil}}},
	[3] = {68157922, "Armorskin", {0}, 110, {{"_DefUpAlive", "_ArmorSkinDefUp", nil}}},
	[4] = {68157923, "MegaArmorskin", {0}, 110, {{"_DefUpAlive" , "_GreatArmorSkinDefUp", nil}}},
	[5] = {68157919, "MightSeed", {0}, 110, {{"_AtkUpBuffSecond", "_MightSeedAtkUp", nil}, {"_AtkUpBuffSecondTimer", "_MightSeedTimer", 60}}},
	[6] = {68157920, "DemonPowder", {0}, 110, {{"_AtkUpItemSecond", "_DemondrugPowderAtkUp", nil}, {"_AtkUpItemSecondTimer", "_DemondrugPowderTimer", 60}}},
	[7] = {68157924, "AdamantSeed", {0}, 110, {{"_DefUpBuffSecond", "_AdamantSeedDefUp", nil}, {"_DefUpBuffSecondTimer", "_AdamantSeedTimer", 60}}},
	[8] = {68157925, "HardshellPowder", {0}, 110, {{"_DefUpItemSecond", "_ArmorSkinPowderDefUp", nil}, {"_DefUpItemSecondTimer", "_ArmorSkinPowderTimer", 60}}},
	[10] = {68157909, "GourmetFish", {0}, 100, {{"_FishRegeneEnableTimer", "_WellDoneFishEnableTimer", 60}}},
	[11] = {68157911, "Immunizer", {0}, 102, {{"_VitalizerTimer", "_VitalizerTimer", 60}}},
	[9] = {68157913, "DashJuice", {0, 3}, 102, {{"_StaminaUpBuffSecondTimer", "_StaminaUpBuffSecond", 60}}},

    [12] = {0, "Whetstone", {1}, -1},
    [13] = {68157445, "MaxPotion", {2}, 100},
    [14] = {68157912, "Ration", {3}, -1},
}
local polishTime = {30, 60, 90}
local itemProlongerMultipliers = {1, 1.1, 1.25, 1.5}

for key,value in pairs(foodList) do
    local foodKey = key
    local itemName = value[2]
    --log.debug(tostring(foodKey))
    --log.debug(tostring(itemName))
    if (settings.data.userChoices[foodKey] == nil) then settings.data.userChoices[foodKey] = 1 end -- default settings to 1
end

local function getQuestManager()
    Quest_Obj = modUtils.getSingletonData("snow.QuestManager")
    if not Quest_Obj then
        return nil
    end
    return Quest_Obj
end

local function getQuestType(questManager)
    if not questManager then
        questManager = getQuestManager()
    end
    if not questManager  then
       return nil
    end
    return modUtils.getSingletonField(questManager, "_QuestType")
end

local function getQuestStatus(questManager)
    if not questManager then
        questManager = getQuestManager()
    end
    if not questManager  then
       return nil
    end
    return modUtils.getSingletonField(questManager, "_QuestStatus")
end

local function getStaminaBuffCage()
	local stamina = 0;
	local EquipDataManager = sdk.get_managed_singleton("snow.data.EquipDataManager");
	local ContentsIdDataManager = sdk.get_managed_singleton("snow.data.ContentsIdDataManager");
	local EquipList = EquipDataManager:get_field("<EquipDataList>k__BackingField"):get_elements();
	local buffCage = ContentsIdDataManager:get_field("_NormalData");
	local buffCageList = buffCage:get_field("_BaseUserData"):get_field("_Param"):get_elements()
	local getLvBuffCageData = EquipList[8]:call("getLvBuffCageData");
	local id = getLvBuffCageData:call("get_Id");
	local name = getLvBuffCageData:call("get_Name");
	
	for k, v in pairs(buffCageList) do
		local data = buffCageList[k]
		local dataId = data:get_field("_Id")
		local buffLimit = data:get_field("_StatusBuffLimit"):get_elements()
		
		if id == dataId then
			stamina = buffLimit[2]:get_field("mValue")
		end
	end
	
	return (stamina + 150) * 30;
end

local function increaseStamina(player)
    local didApply = false
    local stamina = player:get_field("_stamina");
    local staminaMax = player:get_field("_staminaMax");
    local initMax = staminaMax
    
    if getStaminaBuffCage() < (stamina + 1500) then
        stamina = getStaminaBuffCage();
    else
        stamina = (stamina + 1500);
    end
    
    if getStaminaBuffCage() < (staminaMax + 1500) then
        staminaMax = getStaminaBuffCage();
    else
        staminaMax = (staminaMax + 1500);
    end
    player:set_field("_stamina", stamina);
    player:set_field("_staminaMax", staminaMax);
    if staminaMax > initMax then didApply = true end
    return didApply
end

local function hasItemInPouch(itemId)
    -- get inventory --
	local DataManager = sdk.get_managed_singleton("snow.data.DataManager");
	local inventory = DataManager:get_field("_ItemPouch"):get_field("<VirtualSortInventoryList>k__BackingField"):get_elements();
	local inventoryList = inventory[1]:get_field("mItems"):get_elements();
    --log.debug('inventory length' .. #inventoryList)
    for index = 1, #inventoryList do
        local loopItem = inventoryList[index];
        local pouchitemId = loopItem:call("getItemId");
        local quantity = loopItem:call("getNum")
        
        --log.debug('inventory item: id = ' .. pouchitemId .. '; quantity = ' .. quantity)
        if pouchitemId == itemId and quantity > 0 then
            return true
        end
    end

    return false
end

local function consumeItem(consumeId)
    sdk.find_type_definition("snow.data.DataShortcut"):get_method("consumeItemFromPouch"):call(nil, consumeId, 1)
end

local function applyBuff(foodKey, buffObject, overwrite)
    -- title, type, effectId, buffName, buffAmount, buffTimerName, buffTimerDuration
    local didApply = false
    local itemId = buffObject[1]
    local buffTitle = buffObject[2]
    local buffTypes = buffObject[3]
    local buffEffectId = buffObject[4]
    local buffArray = buffObject[5]
    --log.debug('trying to apply buff: ' .. buffTitle)
    
    -- these are useless for now, but I might implement an optional inventory usage feature later, so I'll leave it in.
	local DataManager = sdk.get_managed_singleton("snow.data.DataManager");
	local inventory = DataManager:get_field("_ItemPouch"):get_field("<VirtualSortInventoryList>k__BackingField"):get_elements();
	local NomalInventoryListData = inventory[1]:get_field("mItems"):get_elements();

	local playerDataManager = sdk.get_managed_singleton("snow.player.PlayerManager");
	local PlayerIndex = playerDataManager:call("findMasterPlayer"):call("getPlayerIndex");
	local playerList = playerDataManager:get_field("<PlayerData>k__BackingField"):get_elements();
	local player = playerDataManager:call("findMasterPlayer");
	local dataList = playerDataManager:get_field("_PlayerUserDataItemParameter");

    --handle itemProlonger skill --
    local itemProlongerLevel = playerDataManager:call("getHasPlayerSkillLvInQuestAndTrainingArea", PlayerIndex, 88)
    local itemProlongerMultiplier = itemProlongerMultipliers[itemProlongerLevel + 1]

    -- handle Wide Range --
    local wideRangeLevel = playerDataManager:call("getHasPlayerSkillLvInQuestAndTrainingArea", PlayerIndex, 89)

    -- handle Free Meal --
    local freeMealLevel = playerDataManager:call("getHasPlayerSkillLvInQuestAndTrainingArea", PlayerIndex, 90)
    local isFree = false
    if (freeMealLevel > 0 and settings.data.consumeItems) then
        math.randomseed(os.clock()*100000000000)
        local rng = math.random(100)
        local freeMealPercents = {10, 25, 45}
        local activePercent = freeMealPercents[freeMealLevel]
        if (activePercent > rng) then
            isFree = true
        end
    end

    -- consume the item if setting is turned on --
    if (settings.data.consumeItems) then -- if the setting to consume items is on
        if (itemId ~= 0) then -- skip this for non-consumable items like whetstone
            --log.debug('trying to consume: ' .. buffTitle .. '.' .. itemId)
            dbg.consumeOn = true
            if (not hasItemInPouch(itemId)) then -- and if there is not an item of that ID in the pouch --
                --log.debug('could not find ' .. buffTitle .. ' in player\'s pouch')
                return false -- return that we didn't apply it, and that skip the application of effects --
            else -- item is in the player's inventroy --
                --log.debug('consumingItem: ' .. buffTitle .. '.' .. itemId)
                if (not isFree) then -- if the player does not have free meal, or it wasn't activated --
                    --log.debug('was not free')
                    consumeItem(itemId) -- consume the item from the palyer's inventory
                end
            end
        end
    end

    -- handle stamina changers --
    if dracahnUtil.arrayContains(buffTypes, 3) then -- Stamina Up Item --
        didApply = increaseStamina(playerList[PlayerIndex + 1])
    end

    if (dracahnUtil.arrayContains(buffTypes, 1)) then -- Sharepen Item --
        local maxSharpness = player:get_field("<SharpnessGaugeMax>k__BackingField")
        local currentSharpness = player:get_field("<SharpnessGauge>k__BackingField")

        if (currentSharpness ~= maxSharpness) then
            -- check protective polish --
            local ppLevel = playerDataManager:call("getHasPlayerSkillLvInQuestAndTrainingArea", PlayerIndex, 25)
            if (ppLevel > 0) then
                didApply = true
                player:set_field("_SharpnessGaugeBoostTimer", polishTime[ppLevel] * 60 * itemProlongerMultiplier)
            end
            -- heal sharpness guage --
            player:set_field("<SharpnessGauge>k__BackingField", maxSharpness)
            didApply = true
        end
    end

    if (dracahnUtil.arrayContains(buffTypes, 2)) then -- Healing Item --
        didApply = true        
        local max = playerList[PlayerIndex + 1]:get_field("_vitalMax")

        local maxFloat = max + .0
        playerList[PlayerIndex + 1]:set_field("_r_Vital", max)
        playerList[PlayerIndex + 1]:call("set__vital", maxFloat)
    end 

    if (dracahnUtil.arrayContains(buffTypes, 0)) then -- Buff Item --
        for key, value in pairs(buffArray) do
            local buffName = value[1]
            if (overwrite or (playerList[PlayerIndex + 1]:get_field(buffName) == 0)) then
                didApply = true
                local val = dataList:get_field(value[2]);
                local multiplier = 1
                if (value[3] ~= nil) then
                    multiplier = value[3] * itemProlongerMultiplier
                end
                playerList[PlayerIndex + 1]:set_field(buffName, val * multiplier)
            end
        end
    end

    if (didApply and buffEffectId > 0) then player:call("setEffect", 100, buffEffectId) end
    return didApply, isFree
end

local function AutoConsume()
    -- get data
    local questStatus = getQuestStatus()
    local inQuest = questStatus == 2 -- 2 means the player is in a quest
    
    -- if I'm in a quest
    if (inQuest and not endQuest) then
        local inBattle = modUtils.checkIfInBattle()
        local InMultiplayer = modUtils.checkIfInMultiplayer()
        if (settings.data.offlineOnly and InMultiplayer) then
            return
        end
        local isWeaponSheathed = dracahnUtil.isWeaponSheathed()

        -- determine what level of items to activate and whether to activate
        -- set defaults
        local activateLevel = 5 -- default activateLevel of 'always'

        if (isWeaponSheathed) then
            drawHolder = true
        elseif drawHolder then
            if (death) then
                death = false
                spawnVar = true
            end -- turn the death flag off if you draw your weapon
            drawHolder = false
            activateLevel = 4
        end

        -- determine 'start of combat'
        if (inBattle) then -- if we're in battle
            if (startCombatHolder) then -- if we have not activated the 'start of combat' items 
                if (death) then 
                    death = false 
                    spawnVar = true
                end -- turn the death flag off once you get back in combat
                activateLevel = 3 -- set actiavet level to 3
                startCombatHolder = false -- mark that we have activated the 'start of combat' items
            end
        else
            startCombatHolder = true -- reset our startCombatHolder so we know to activate the 'start of combat' items next time combat starts
        end

        -- determine 'once per quest'
        if (spawnVar and not death) then -- if we have not activated the once per quest items
            activateLevel = 2  -- set the activate level to 2
            spawnVar = false -- mark that we have activate the 'once per quest' items
        end -- else we've already activated the 'once per quest' items


        dbg.activateLevel = activateLevel

        local activateEffects = {}
        for key,value in pairs(settings.data.userChoices) do
            if (value >= activateLevel) then
                activateEffects[#activateEffects+1] = foodList[key]
            end
        end

        dbg.actiavetEffects = activateEffects
        local appliedBuffs = {}
        for key,value in pairs(activateEffects) do
            local applied, wasFree = applyBuff(key, value, activateLevel ~= 5)
            if (applied) then
                local messageText = value[2]
                if wasFree then messageText = messageText .. "(free meal)" end
                appliedBuffs[#appliedBuffs+1] = messageText
            end
        end

        if (settings.data.message and #appliedBuffs > 0) then
            local message = "<COL RED>".. language.get("message.title") .. "</COL>";
            for key,value in pairs(appliedBuffs) do
                message = message .. "\n" .. value
            end
            local chatManager = sdk.get_managed_singleton("snow.gui.ChatManager");
            chatManager:call("reqAddChatInfomation", message, 2289944406);
        end
    else -- reset the quest var
        spawnVar = true
    end
end

re.on_frame(function()
    if (settings.data.enabled) then AutoConsume() end
end)


-- Event callback hook for behaviour updates
re.on_pre_application_entry("UpdateBehavior", function() -- unnamed/inline function definition
	local questManager = sdk.get_managed_singleton("snow.QuestManager");
    if not questManager then
        questManager = sdk.get_managed_singleton("snow.QuestManager");
        if not questManager then
            return nil
        end
    end

    -- getting Quest End state
    -- 0: still in quest, 1: ending countdown, 8: ending animation, 16: quest over
    local endFlow = questManager:get_field("_EndFlow")

    if endFlow > 0 then
        endQuest = true
    else
        endQuest = false
    end
end)

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("onQuestEnd"),
function(args)
	spawnVar = true;
end,
function(retval)
	return retval
end
);

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("notifyDeath"),
function(args)
	death = true;
end,
function(retval)
	return retval
end
);

local function uiDetails()
    local changedMessage, toggleMessage = imgui.checkbox(language.get("config.message"), settings.data.message)
    settings.handleChange(changedMessage, toggleMessage, "message")
    local changedConsumeItems, toggleConsumeItems = imgui.checkbox(language.get("config.consumeItems"), settings.data.consumeItems)
    settings.handleChange(changedConsumeItems, toggleConsumeItems, "consumeItems")
    imgui.text(language.get("descriptions.key"))
    
    local changed = false

    local triggerLabels = language.get("triggerLabels")
    imgui.text(tostring(triggerLabels[1]))

    for key,value in pairs(foodList) do
        local foodKey = key
        local effectName = value[2]
        changed, settings.data.userChoices[foodKey] = imgui.slider_int(language.get("foods." .. effectName), settings.data.userChoices[foodKey], 1, 5, triggerLabels[settings.data.userChoices[foodKey]])
        settings.handleChange(changed, settings.data.userChoices, "userChoices")
    end

    if imgui.tree_node(language.get("debug")) then
        if imgui.button("Toggle spawnVar") then
            spawnVar = not spawnVar
        end
        imgui.text("userChoices obj: " .. json.dump_string(settings.data.userChoices))
        imgui.text("spawnVar: " .. tostring(spawnVar))
        imgui.text("death: " .. tostring(death))
        imgui.text("dataDump:")
        imgui.text(json.dump_string(dbg))
        imgui.text(json.dump_string(dmp))
        -- modUtils.printDebugInfo()
        imgui.tree_pop()
    end

    if not settings.isSavingAvailable then
        imgui.text(
            language.get("descriptions.jsonWarning"))
    end
end

local function modUiDetails(modUi)
    modUi.Header(language.get("modUi.key"))
    modUi.Label(language.get("modUi.off"));
    modUi.Label(language.get("modUi.spawn"));
    modUi.Label(language.get("modUi.combat"));
    modUi.Label(language.get("modUi.draw"));
    modUi.Label(language.get("modUi.always"));
    modUi.Header(language.get("modUi.items"));
    for key,value in pairs(foodList) do
        local foodKey = key
        local effectName = value[2]
        local changed;
        changed, settings.data.userChoices[foodKey] = modUi.Slider(language.get("foods." .. effectName), settings.data.userChoices[foodKey], 1, 5, language.get("modUi.")"1 = off, 2 = On Quest Start \r\n3 = On Combat Start, 4 = On WeaponDraw\r\n5 = Always")
        settings.handleChange(changed, settings.data.userChoices, "userChoices")
    end

end

re.on_draw_ui(function()
    dracahnUtil.on_draw_ui(settings, language, langList, modName, version, uiDetails)
end)

dracahnUtil.modUi(settings, language, modUiDetails)