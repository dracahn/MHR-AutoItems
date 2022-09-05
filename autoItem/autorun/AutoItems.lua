local modName = "AutoItems"
local version = "1.0.0"
local author = "dracahn"

local wasOpen = false
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
    message = true,
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

local itemList = {
	[1] = 68157917,
	[2] = 68157918,
	[3] = 68157922,
	[4] = 68157923,
	[5] = 68157919,
	[6] = 68157920,
	[7] = 68157924,
	[8] = 68157925,
	[9] = 68157913,
	[10] = 68157909,
	[11] = 68157911,

    [12] = 68157450,
    [13] = 68157450,
    [14] = 68157450,
}

--[[ item types:
    0 = apply all buff fields
    1 = sharpen
    2 = heal
    3 = Max Stanima up
]]

local foodList = {
    -- [itemId] = {title, types, effectId, {{buffFieldName, buffFieldValue}, .. }}
	[1] = {"Demondrug", {0}, 110, {{"_AtkUpAlive", "_DemondrugAtkUp", nil}}},
	[2] = {"MegaDemondrug", {0}, 110, {{"_AtkUpAlive", "_GreatDemondrugAtkUp", nil}}},
	[3] = {"Armorskin", {0}, 110, {{"_DefUpAlive", "_ArmorSkinDefUp", nil}}},
	[4] = {"MegaArmorskin", {0}, 110, {{"_DefUpAlive" , "_GreatArmorSkinDefUp", nil}}},
	[5] = {"MightSeed", {0}, 110, {{"_AtkUpBuffSecond", "_MightSeedAtkUp", nil}, {"_AtkUpBuffSecondTimer", "_MightSeedTimer", 60}}},
	[6] = {"DemonPowder", {0}, 110, {{"_AtkUpItemSecond", "_DemondrugPowderAtkUp", nil}, {"_AtkUpItemSecondTimer", "_DemondrugPowderTimer", 60}}},
	[7] = {"AdamantSeed", {0}, 110, {{"_DefUpBuffSecond", "_AdamantSeedDefUp", nil}, {"_DefUpBuffSecondTimer", "_AdamantSeedTimer", 60}}},
	[8] = {"HardshellPowder", {0}, 110, {{"_DefUpItemSecond", "_ArmorSkinPowderDefUp", nil}, {"_DefUpItemSecondTimer", "_ArmorSkinPowderTimer", 60}}},
	[10] = {"GourmetFish", {0}, 100, {{"_FishRegeneEnableTimer", "_WellDoneFishEnableTimer", 60}}},
	[11] = {"Immunizer", {0}, 102, {{"_VitalizerTimer", "_VitalizerTimer", 60}}},
	[9] = {"DashJuice", {0, 3}, 102, {{"_StaminaUpBuffSecondTimer", "_StaminaUpBuffSecond", 60}}},

    [12] = {"Whetstone", {1}, -1},
    [13] = {"MaxPotion", {2}, 100},
    [14] = {"Ration", {3}, -1},
}
local polishTime = {30, 60, 90}
local itemProlongerMultipliers = {1, 1.1, 1.25, 1.5}

for key,value in pairs(foodList) do
    local foodKey = key
    local itemName = value[1]
    log.debug(tostring(foodKey))
    log.debug(tostring(itemName))
    if (settings.data.userChoices[foodKey] == nil) then settings.data.userChoices[foodKey] = 1 end -- default settings to 1
end

re.on_draw_ui(function()
    if imgui.button(language.get("window.toggle")) then
        settings.data.isWindowOpen = not settings.data.isWindowOpen
        settings.handleChange(true, settings.data.isWindowOpen, "isWindowOpen")
    end
    if settings.data.isWindowOpen then
        wasOpen = true

        imgui.set_next_window_size(Vector2f.new(520, 450), 4)

        settings.data.isWindowOpen = imgui.begin_window(modName, settings.data.isWindowOpen, 0)

        imgui.spacing()
        local langChange, newVal = imgui.combo(language.get("enabled"), settings.data.language.current, langList)
        settings.data.language.current = langList[newVal]
        settings.handleChange(langChange, settings.data.language, "language")
        imgui.spacing()
        imgui.text(language.get("disclaimer"))
        imgui.spacing()
        local changedEnabled, toggleEnabled = imgui.checkbox(language.get("enabled"), settings.data.enabled)
        settings.handleChange(changedEnabled, toggleEnabled, "enabled")
        local changedOfflineOnly, toggleOfflineOnly = imgui.checkbox(language.get("offlineOnly"), settings.data.offlineOnly)
        settings.handleChange(changedOfflineOnly, toggleOfflineOnly, "offlineOnly")
        local changedMessage, toggleMessage = imgui.checkbox(language.get("message"), settings.data.message)
        settings.handleChange(changedMessage, toggleMessage, "message")
        imgui.spacing()
        local changedRequireItems, toggleRequireItems = imgui.checkbox(language.get("requireItems"), settings.data.requireItems)
        settings.handleChange(changedRequireItems, toggleRequireItems, "requireItems")
        local changedConsumeItems, toggleConsumeItems = imgui.checkbox(language.get("consumeItems"), settings.data.consumeItems)
        settings.handleChange(changedConsumeItems, toggleConsumeItems, "consumeItems")
        imgui.text(language.get("descriptions.key"))
        
        local changed = false
        for key,value in pairs(foodList) do
            local foodKey = key
            local effectName = value[1]
            changed, settings.data.userChoices[foodKey] = imgui.slider_int(language.get("foods." .. effectName), settings.data.userChoices[foodKey], 1, 5, tostring(language.get("triggerLabels")))
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

        imgui.spacing()
        imgui.text(version)
        imgui.spacing()
        imgui.end_window()
    elseif wasOpen then
        wasOpen = false
        settings.handleChange(true, settings.data.isWindowOpen, "isWindowOpen")
    end
end)

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

local function applyBuff(foodKey, buffObject, overwrite)
    -- title, type, effectId, buffName, buffAmount, buffTimerName, buffTimerDuration
    local didApply = false
    local itemId = itemList[foodKey]
    local buffTitle = buffObject[1]
    local buffTypes = buffObject[2]
    local buffEffectId = buffObject[3]
    local buffArray = buffObject[4]
    
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
        return didApply
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
    return didApply
end

local function AutoConsume()
    -- get data
    local questStatus = getQuestStatus()
    local inQuest = questStatus == 2 -- 2 means the player is in a quest
    local inBattle = modUtils.checkIfInBattle()
    local InMultiplayer = modUtils.checkIfInMultiplayer()
    local isWeaponSheathed = dracahnUtil.isWeaponSheathed()
    --dbg.questStatus = questStatus
    --dbg.inQuest = inQuest
    --dbg.inBattle = inBattle
    --dbg.InMultiplayer = InMultiplayer
    -- if I'm in a quest
    if (inQuest and not endQuest) then
        -- there are 3 triggers to activate buffs:
        -- 1. quest has started/player has respawned
        -- 2. player has started combat
        -- 3. always

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
            local applied = applyBuff(key, value, activateLevel ~= 5)
            if (applied) then
                appliedBuffs[#appliedBuffs+1] = value[1]
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

--[[
    snow.player.PlayerUserDataItemParameter

    {"Whetstone", 1}, _SharpnessHeal
    {"DemonDrug", 2}, _DemondrugAtkUp
    {"MegaDemonDrug", 3}, _GreatDemondrugAtkUp
    {"DemonPowder", 4}, _DemondrugPowderAtkUp _DemonDrugPowderTimer
    {"MightSeed", 5}, _MightSeedAtkUp _MightSeedTimer
    {"Armorskin", 7}, _ArmorSkinDefUp
    {"MegaArmorskin", 8}, _GreatArmorSkinDefUp
    {"HardshellPowder", 9}, _ArmorSkinPowderDefUp _ArmorSkinPowderTimer
    {"AdamantSeed", 10}, _AdamantSeedDefUp _AdamantSeedTimer
    {"DashJuice", 12}, _StaminaUpBuffSecond
    {"Immunizer", 13}, _VitalizerTimer
    {"GourmetFish", 14}, _WellDoneFishEnableTimer
    {"Ration", 15}
]]


-- for use with @Bolt's 'Custom In-Game Mod Menu API'


function IsModuleAvailable(name)
    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == 'function' then
                package.preload[name] = loader
                return true
            end
        end
        return false
    end
end
  
  
  local apiPackageName = "ModOptionsMenu.ModMenuApi";
  local modUI = nil;
  local DrawSlider;
  
  if IsModuleAvailable(apiPackageName) then
      modUI = require(apiPackageName);
  end
  
  
  if modUI and doOnce then
      doOnce = false
  
      local name = language.get("Title")
      local description = language.get("descriptions.short")
      modUI.OnMenu(name, description, function()
      
          if modUI.version < 1.3 then
          
            modUI.Label(language.get("modUi.modUiOutOfDate"));
          
          else		
            modUI.Header(language.get("modUi.generalSettings"))
            local changedEnabled, toggleEnabled = modUI.CheckBox(language.get("config.enabled"), settings.data.enabled)
            settings.handleChange(changedEnabled, toggleEnabled, "enabled")
            local changedEnabled, toggleMessage = modUI.CheckBox(language.get("config.message"), settings.data.message)
            settings.handleChange(changedEnabled, toggleMessage, "message")
            modUI.Header(language.get("modUi.key"))
            modUI.Label(language.get("modUi.off"));
            modUI.Label(language.get("modUi.spawn"));
            modUI.Label(language.get("modUi.combat"));
            modUI.Label(language.get("modUi.draw"));
            modUI.Label(language.get("modUi.always"));
            modUI.Header(language.get("modUi.items"));
            for key,value in pairs(foodList) do
                local foodKey = key
                local effectName = value[1]
                local changed;
                changed, settings.data.userChoices[foodKey] = modUI.Slider(language.get("foods." .. effectName), settings.data.userChoices[foodKey], 1, 5, language.get("modUi.")"1 = off, 2 = On Quest Start \r\n3 = On Combat Start, 4 = On WeaponDraw\r\n5 = Always")
                settings.handleChange(changed, settings.data.userChoices, "userChoices")
            end
            
          end
          modUI.Header(language.get("modUi.credits"))
          modUI.Label(language.get("modUi.modBy") .. language.get("modUi.author"))
      end)
  end