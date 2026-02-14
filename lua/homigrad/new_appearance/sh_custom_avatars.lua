hg.Appearance = hg.Appearance or {}

--[[
    Custom avatar overrides (SteamID bound).

    Format:
    ["STEAM_0:X:YYYYYY"] = {
        model = "models/your_folder/your_model.mdl", -- required
        allowDonatorMenu = true,                     -- can open/use appearance (donator skins) menu
        lockModelSelection = true,                   -- player can only use their own custom model in model selector
        disableAppearance = true,                    -- appearance options (clothes/facemaps/accessories) are ignored
        menuName = "My Custom Model"               -- optional display name in model selector
    }
]]
hg.Appearance.CustomAvatars = hg.Appearance.CustomAvatars or {
    -- ["STEAM_0:1:12345678"] = {
    --     model = "models/player/custom/example.mdl",
    --     allowDonatorMenu = true,
    --     lockModelSelection = true,
    --     disableAppearance = true,
    --     menuName = "Example Custom"
    -- }
}

local function normalizeSteamID(target)
    if IsValid(target) and target:IsPlayer() then
        return target:SteamID()
    end

    if not isstring(target) then return nil end

    local upper = string.upper(string.Trim(target))
    if string.StartWith(upper, "STEAM_") then
        return upper
    end

    return nil
end

function hg.Appearance.GetCustomAvatarData(target)
    local steamID = normalizeSteamID(target)
    if not steamID then return nil end

    local data = hg.Appearance.CustomAvatars[steamID]
    if not istable(data) then return nil end

    if not isstring(data.model) or data.model == "" then return nil end
    return data
end

function hg.Appearance.GetLockedModelForPlayer(target)
    local data = hg.Appearance.GetCustomAvatarData(target)
    if not data then return nil end

    return data.model
end

function hg.Appearance.CanOpenDonatorMenu(target)
    local data = hg.Appearance.GetCustomAvatarData(target)
    if not data then return false end

    return data.allowDonatorMenu ~= false
end

function hg.Appearance.IsModelSelectionLocked(target)
    local data = hg.Appearance.GetCustomAvatarData(target)
    if not data then return false end

    return data.lockModelSelection ~= false
end

function hg.Appearance.ShouldDisableAppearance(target)
    local data = hg.Appearance.GetCustomAvatarData(target)
    if not data then return false end

    return data.disableAppearance ~= false
end

function hg.Appearance.GetCustomMenuName(target)
    local data = hg.Appearance.GetCustomAvatarData(target)
    if not data then return nil end

    return data.menuName or "Custom Model"
end


if SERVER then
    local dataPath = "zcity/custom_avatars_overrides.json"

    local function saveOverrides()
        file.CreateDir("zcity")
        file.Write(dataPath, util.TableToJSON(hg.Appearance.CustomAvatars, true) or "{}")
    end

    local function loadOverrides()
        if not file.Exists(dataPath, "DATA") then return end

        local raw = file.Read(dataPath, "DATA")
        local tbl = util.JSONToTable(raw or "")
        if not istable(tbl) then return end

        for steamID, data in pairs(tbl) do
            if isstring(steamID) and istable(data) and isstring(data.model) and data.model != "" then
                hg.Appearance.CustomAvatars[string.upper(steamID)] = data
            end
        end
    end

    hook.Add("Initialize", "hg.Appearance.LoadCustomAvatarOverrides", loadOverrides)
    timer.Simple(0, loadOverrides)

    function hg.Appearance.SetCustomAvatarOverride(steamID, data)
        steamID = normalizeSteamID(steamID)
        if not steamID then return false, "Invalid SteamID" end
        if not istable(data) then return false, "Invalid data" end
        if not isstring(data.model) or data.model == "" then return false, "Invalid model" end
        if not util.IsValidModel(data.model) then return false, "Model path is not valid on server" end

        hg.Appearance.CustomAvatars[steamID] = {
            model = data.model,
            allowDonatorMenu = data.allowDonatorMenu ~= false,
            lockModelSelection = data.lockModelSelection ~= false,
            disableAppearance = data.disableAppearance ~= false,
            menuName = data.menuName
        }

        saveOverrides()
        return true
    end

    function hg.Appearance.RemoveCustomAvatarOverride(steamID)
        steamID = normalizeSteamID(steamID)
        if not steamID then return false, "Invalid SteamID" end
        if not hg.Appearance.CustomAvatars[steamID] then return false, "No override found" end

        hg.Appearance.CustomAvatars[steamID] = nil
        saveOverrides()

        return true
    end
end
