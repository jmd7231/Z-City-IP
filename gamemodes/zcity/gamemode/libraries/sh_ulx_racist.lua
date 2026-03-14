if not ulx then return end

local CATEGORY_NAME = "ZCity"
local RACIST_NETVAR = "zb_ulx_racist"

local function IsValidTarget(target_ply)
    return IsValid(target_ply) and target_ply:IsPlayer()
end

if SERVER then
    local STORAGE_FILE = "zcity_ulx_racist_list.json"
    local RacistSteamIDs = {}

    local function MakeStorageKey(steamID64)
        if not steamID64 or steamID64 == "" then return nil end
        return "sid64:" .. tostring(steamID64)
    end

    local function MakeStorageKeySteamID(steamID)
        if not steamID or steamID == "" or steamID == "BOT" then return nil end
        return "sid:" .. tostring(steamID)
    end

    local function BuildStorageList()
        local out = {}

        for key in pairs(RacistSteamIDs) do
            out[#out + 1] = key
        end

        table.sort(out)
        return out
    end

    local function LoadRacistStorage()
        RacistSteamIDs = {}

        if not file.Exists(STORAGE_FILE, "DATA") then
            return
        end

        local raw = file.Read(STORAGE_FILE, "DATA")
        local decoded = util.JSONToTable(raw or "")
        if not istable(decoded) then
            return
        end

        if #decoded > 0 then
            for _, key in ipairs(decoded) do
                if isstring(key) and key ~= "" then
                    RacistSteamIDs[key] = true
                end
            end
            return
        end

        for key, enabled in pairs(decoded) do
            if enabled then
                local keyString = tostring(key or "")

                if keyString ~= "" then
                    if string.StartWith(keyString, "sid64:") then
                        RacistSteamIDs[keyString] = true
                    else
                        RacistSteamIDs["sid64:" .. keyString] = true
                    end
                end
            end
        end
    end

    local function SaveRacistStorage()
        file.Write(STORAGE_FILE, util.TableToJSON(BuildStorageList(), true))
    end

    local function GetTargetStorageKeys(target_ply)
        if not IsValidTarget(target_ply) then return {} end

        local keys = {}
        local steamID = MakeStorageKeySteamID(target_ply:SteamID())
        local steamID64 = MakeStorageKey(target_ply:SteamID64())

        if steamID then
            keys[#keys + 1] = steamID
        end

        if steamID64 and steamID64 ~= steamID then
            keys[#keys + 1] = steamID64
        end

        return keys
    end

    local function IsRacist(target_ply)
        if not IsValidTarget(target_ply) then return false end

        if target_ply:GetNWBool(RACIST_NETVAR, false) then
            return true
        end

        local storageKeys = GetTargetStorageKeys(target_ply)
        for _, storageKey in ipairs(storageKeys) do
            if RacistSteamIDs[storageKey] then
                return true
            end
        end

        return false
    end

    local function RefreshRacistStateFromStorage(target_ply)
        if not IsValidTarget(target_ply) then return false end

        local state = false
        local storageKeys = GetTargetStorageKeys(target_ply)

        for _, storageKey in ipairs(storageKeys) do
            if RacistSteamIDs[storageKey] then
                state = true
                break
            end
        end

        target_ply:SetNWBool(RACIST_NETVAR, state)
        return state
    end

    local function ApplyRacistRestrictions(target_ply)
        if not IsRacist(target_ply) then return end

        target_ply:StripWeapons()
        target_ply:StripAmmo()
    end

    local function SetRacistState(target_ply, state)
        if not IsValidTarget(target_ply) then return false end

        target_ply:SetNWBool(RACIST_NETVAR, state)

        local storageKeys = GetTargetStorageKeys(target_ply)
        if #storageKeys > 0 then
            for _, storageKey in ipairs(storageKeys) do
                RacistSteamIDs[storageKey] = state and true or nil
            end
            SaveRacistStorage()
        end

        if state then
            ApplyRacistRestrictions(target_ply)
        end

        return true
    end

    LoadRacistStorage()

    function ulx.racist(calling_ply, target_ply)
        if not IsValidTarget(target_ply) then
            ULib.tsayError(calling_ply, "You must specify a valid player.", true)
            return
        end

        SetRacistState(target_ply, true)

        ulx.fancyLogAdmin(calling_ply, "#A marked #T with ulx racist", target_ply)
    end

    function ulx.unracist(calling_ply, target_ply)
        if not IsValidTarget(target_ply) then
            ULib.tsayError(calling_ply, "You must specify a valid player.", true)
            return
        end

        SetRacistState(target_ply, false)

        ulx.fancyLogAdmin(calling_ply, "#A removed ulx racist from #T", target_ply)
    end

    local racist = ulx.command(CATEGORY_NAME, "ulx racist", ulx.racist, "!racist")
    racist:addParam {type = ULib.cmds.PlayerArg}
    racist:defaultAccess(ULib.ACCESS_ADMIN)
    racist:help("Marks a player to be muted, gagged, and weapon stripped until unracist.")

    local unracist = ulx.command(CATEGORY_NAME, "ulx unracist", ulx.unracist, "!unracist")
    unracist:addParam {type = ULib.cmds.PlayerArg}
    unracist:defaultAccess(ULib.ACCESS_ADMIN)
    unracist:help("Removes ulx racist restrictions from a player.")

    hook.Add("PlayerInitialSpawn", "ZB_ULXRacist_ApplyPersistentState", function(ply)
        RefreshRacistStateFromStorage(ply)
    end)

    hook.Add("PlayerAuthed", "ZB_ULXRacist_ApplyPersistentStateAuthed", function(ply)
        RefreshRacistStateFromStorage(ply)
    end)

    hook.Add("PlayerSay", "ZB_ULXRacist_GagChat", function(ply, text)
        if IsRacist(ply) then
            return ""
        end
    end)

    hook.Add("PlayerCanHearPlayersVoice", "ZB_ULXRacist_MuteVoice", function(listener, talker)
        if IsRacist(talker) then
            return false, false
        end
    end)

    hook.Add("CanPlayerHearPlayerVoice", "ZB_ULXRacist_MuteVoiceLegacy", function(listener, talker)
        if IsRacist(talker) then
            return false, false
        end
    end)

    hook.Add("PlayerCanSeePlayersChat", "ZB_ULXRacist_BlockDeadChatVisibility", function(text, teamOnly, listener, speaker)
        if IsRacist(speaker) then
            return false
        end
    end)

    hook.Add("CanListenOthers", "ZB_ULXRacist_BlockDeadChatSend", function(output, input, isChat)
        if isChat and IsRacist(input) then
            return false, false
        end
    end)

    hook.Add("PlayerSpawn", "ZB_ULXRacist_StripOnSpawn", function(ply)
        if IsRacist(ply) then
            ply:SetNWBool(RACIST_NETVAR, true)
        end

        ApplyRacistRestrictions(ply)
    end)

    hook.Add("ZB_StartRound", "ZB_ULXRacist_StripEveryRound", function()
        for _, ply in ipairs(player.GetAll()) do
            ApplyRacistRestrictions(ply)
        end
    end)

    hook.Add("PlayerCanPickupWeapon", "ZB_ULXRacist_BlockWeaponPickup", function(ply)
        if IsRacist(ply) then
            return false
        end
    end)
end

if CLIENT then
    local drawColor = Color(255, 64, 64)

    hook.Add("PostPlayerDraw", "ZB_ULXRacist_Indicator", function(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if not ply:GetNWBool(RACIST_NETVAR, false) then return end

        local lply = LocalPlayer()
        if not IsValid(lply) then return end
        if ply == lply then return end

        local pos = ply:EyePos() + Vector(0, 0, 14)
        local ang = EyeAngles()

        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)

        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
            draw.SimpleTextOutlined("RACIST: 0 karma lost for kill", "Trebuchet24", 0, 0, drawColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
        cam.End3D2D()
    end)
end
