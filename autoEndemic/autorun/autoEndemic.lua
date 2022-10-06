local modName = "autoEndemic"
local version = "1.0.0"
local author = "dracahn"
local dbg = {}

local wasOpen = false
local spawnVar = true
local modUtils = require(modName .. "/mod_utils")
local dracahnUtil = require(modName .. "/dracahn_util")
local language = require(modName .. "/Language")
modUtils.info(modName .. " loaded!")


local settings = modUtils.getConfigHandler({
    enabled = true,
    ecItemPouch = {
        nil,
        nil,
        nil,
        nil,
        nil,
    },
    language = {
        current = "en-us",
        languages = {},
        sorted = {},
    }
}, modName)
-- Load the languages
language.init(settings)

local function getEndemicList()
    local list = {}
    local names = language.get("endemicLife")
    for key, value in pairs(language.get("endemicLifeIds")) do
        list[key] = { id = value, name = names[tostring(value)] }
    end
    return list
end

local function endemicNamesForDropDown(endemicList)
    if endemicList == nil then return nil end

    local ddList = {}
    for key, value in pairs(endemicList) do
        ddList[#ddList + 1] = value.name
    end

    return ddList
end

local function autoEndemic()
    local questStatus = modUtils.getQuestStatus()
    local inQuest = questStatus == 2 -- 2 means the player is in a quest
    if not inQuest then
        spawnVar = true
        return
    end
    if (not settings.data.enabled or not spawnVar) then return end

    spawnVar = false

    local endemicList = getEndemicList()
    local DataManager = sdk.get_managed_singleton("snow.data.DataManager");
    local ecPouchItems = DataManager:get_field("<Ec_ItemPouch>k__BackingField"):get_field("<InventoryDataList>k__BackingField")
        :get_elements(); -- snow.data.ItemInventoryData[]
    for i = 1, 5, 1 do
        local currentSetting = settings.data.ecItemPouch[i]
        if (currentSetting > 1) then
            local itemId = tonumber(endemicList[currentSetting].id)
            ecPouchItems[i]:call("set", itemId, 1, true)

            if itemId == 69206037 then -- Needs to be reset otherwise it will be stuck in the "consumed" state
                local creature_manager = sdk.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager")
                local inputManager = sdk.get_managed_singleton("snow.StmInputManager")
                local inGameInputDevice = inputManager:get_field("_InGameInputDevice")
                local playerInput = inGameInputDevice:get_field("_pl_input")
                local playerBase = playerInput:get_field("RefPlayer")
                local playerIndex = playerBase:get_field("_PlayerIndex")
                creature_manager:call("addEc057GetCount", playerIndex)
            end
        end
    end
end

re.on_draw_ui(function()
    if imgui.button(language.get("window.toggle")) then
        settings.data.isWindowOpen = not settings.data.isWindowOpen
        settings.handleChange(true, settings.data.isWindowOpen, "isWindowOpen")
    end
    if settings.data.isWindowOpen then
        local endemicList = getEndemicList()
        local endemicNamesForDropDown = endemicNamesForDropDown(endemicList)
        wasOpen = true

        imgui.set_next_window_size(Vector2f.new(520, 450), 4)

        settings.data.isWindowOpen = imgui.begin_window(modName, settings.data.isWindowOpen, 0)
        settings.imgui("enabled", imgui.checkbox, language.get("config.enable"))
        imgui.spacing()
        local langChange, newVal = imgui.combo(language.get("enabled"), settings.data.language.current, langList)
        settings.data.language.current = langList[newVal]
        settings.handleChange(langChange, settings.data.language, "language")
        imgui.spacing()
        imgui.spacing()


        local changed = false
        for i = 1, 5, 1 do
            local loopChange
            loopChange, settings.data.ecItemPouch[i] = imgui.combo(tostring(i), settings.data.ecItemPouch[i],
                endemicNamesForDropDown)
            changed = loopChange or changed
        end
        settings.handleChange(changed, settings.data.ecItemPouch, "ecItemPouch")

        if imgui.tree_node("Debug Info (send a screenshot of this info along with the bug report)") then
            imgui.text("spawnVar: " .. tostring(spawnVar))
            if imgui.button("Toggle spawnVar") then
                spawnVar = not spawnVar
            end

            local DataManager = sdk.get_managed_singleton("snow.data.DataManager");
            local ecPouchItems = DataManager:get_field("<Ec_ItemPouch>k__BackingField"):get_field("<InventoryDataList>k__BackingField")
                :get_elements(); -- snow.data.ItemInventoryData[]
            imgui.text("current ecPouch:")
            for i = 1, 5, 1 do
                local ecPouchItem = ecPouchItems[i]
                local ecPouchItemId = ecPouchItem:call("getItemId") -- snow.data.ContentsIdSystem.ItemId (Extends System.Enum)
                imgui.text("  " .. i .. ": " .. ecPouchItemId)
            end

            if (imgui.button("set ec1")) then
                --ecPouchItems[1]:call("setId", 69206016)
                ecPouchItems[1]:call("set", 69206016, 1, true)
            end

            if (imgui.button("set cage")) then
                autoEndemic()
            end

            imgui.text("settings.data: " .. json.dump_string(settings.data))
            --imgui.text("endemicList: " .. json.dump_string(endemicList))
            imgui.text("settings.data.dbg: " .. json.dump_string(settings.data.dbg))
            imgui.text("dataDump:")
            imgui.text(json.dump_string(dbg))
            -- modUtils.printDebugInfo()
            imgui.tree_pop()
        end

        if not settings.isSavingAvailable then
            imgui.text("WARNING: JSON utils not available (your REFramework version may be outdated). Configuration will not be saved between restarts.")
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

re.on_pre_application_entry("UpdateBehavior", function()
    autoEndemic()
end)
