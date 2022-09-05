
local util = {}

function util.on_draw_ui(settings, language, langList, modName, version, details)
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

        details()

        imgui.spacing()
        imgui.text(version)
        imgui.spacing()
        imgui.end_window()
    elseif wasOpen then
        wasOpen = false
        settings.handleChange(true, settings.data.isWindowOpen, "isWindowOpen")
    end
end

function util.modUi(settings, language, details)
    local apiPackageName = "ModOptionsMenu.ModMenuApi"
    local modUi = nil
    local DrawSlider
    
    if IsModuleAvailable(apiPackageName) then
        modUi = require(apiPackageName);
    end

    if modUi and doOnce then
        doOnce = false
    
        local name = language.get("Title")
        local description = language.get("descriptions.short")
        modUi.OnMenu(name, description, function()
        
            if modUi.version < 1.3 then
                modUi.Label(language.get("modUi.modUiOutOfDate"));
            else
            
                modUi.Header(language.get("modUi.generalSettings"))
                local changedEnabled, toggleEnabled = modUi.CheckBox(language.get("config.enabled"), settings.data.enabled)
                settings.handleChange(changedEnabled, toggleEnabled, "enabled")
                local changedEnabled, toggleMessage = modUi.CheckBox(language.get("config.message"), settings.data.message)
                settings.handleChange(changedEnabled, toggleMessage, "message")
                local changedEnabled, toggleEnabled = modUi.checkbox(language.get("enabled"), settings.data.enabled)
                settings.handleChange(changedEnabled, toggleEnabled, "enabled")
                local changedOfflineOnly, toggleOfflineOnly = modUi.checkbox(language.get("offlineOnly"), settings.data.offlineOnly)
                settings.handleChange(changedOfflineOnly, toggleOfflineOnly, "offlineOnly")
                local changedMessage, toggleMessage = modUi.checkbox(language.get("message"), settings.data.message)
                settings.handleChange(changedMessage, toggleMessage, "message")
                details()
            end
            modUi.Header(language.get("modUi.credits"))
            modUi.Label(language.get("modUi.modBy") .. language.get("modUi.author"))
        end)
    end
end

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