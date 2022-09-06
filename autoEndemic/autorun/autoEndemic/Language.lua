local utils = require("autoEndemic/dracahn_util")
local language = {}

function language.init(inConfigHandler)
    language.configHandler = inConfigHandler
    language.configHandler.data.languages = language.read_languages()
end

-- Loads all languages from the language folder
function language.load_languages()
    local files = fs.glob([[[aA]utoEndemic\\Languages\\.*json]])
    if files == nil then return end
    for i = 1, #files do
        local file = files[i]
        local split = utils.split(file, "\\")
        local fileName = split[#split]
        local languageName = utils.split(fileName, ".")[1]
        language.configHandler.data.languages[languageName] = json.load_file(file)
    end
end

function language.read_languages()
    local languages = {}
    local files = fs.glob([[[aA]utoEndemic\\Languages\\.*json]])
    if files == nil then return end
    languages.files = files
    for i = 1, #files do
        local file = files[i]
        local split = utils.split(file, "\\")
        local fileName = split[#split]
        local languageName = utils.split(fileName, ".")[1]
        languages[languageName] = json.load_file(file)
        languages.dbg = json.load_file(file)
        --languages.files[file].split =
        --languages.files[file].fileName = fileName
        --languages.files[file].languageName = languageName
    end

    return languages
end

-- Get a single value from the language from the provided key
function language.get(key)
    if language.configHandler.data.language.current == nil then
        return "current langauge is nil for key: " .. key
    end
    if language.configHandler.data.languages[language.configHandler.data.language.current] == nil then
        return "cannot find current language '" .. language.configHandler.data.language.current .. "': " .. key
    end

    local language_data = language.configHandler.data.languages[language.configHandler.data.language.current]
    if language_data == nil then return nil end
    if string.find(key, ".") == nil then
        return language_data[key]
    else
        local keys = utils.split(key, ".")
        local value = language_data
        for i = 1, #keys do
            value = value[keys[i]]
            if value == nil then return "Invalid Language Key: " .. key end
        end
        return value
    end
end

return language
