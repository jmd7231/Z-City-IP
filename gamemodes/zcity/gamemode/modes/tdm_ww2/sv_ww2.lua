local MODE = MODE

MODE.name = "ww2tdm"
MODE.PrintName = "WW2 Team Deathmatch"
MODE.Chance = 0.03
MODE.BuyTime = 0
MODE.start_time = 0
MODE.buymenu = false
MODE.ROUND_TIME = 300

local TEAM_LOADOUTS = {
    [0] = {
        name = "German",
        riflemanRole = "German Rifleman",
        gunnerRole = "German Machine Gunner",
        color = Color(75, 90, 65),
        model = "models/player/dod_german_exp_pm.mdl",
        primaryWeapon = "weapon_mp40",
        machineGun = "weapon_mg34",
    },
    [1] = {
        name = "American",
        riflemanRole = "American Rifleman",
        gunnerRole = "American Machine Gunner",
        color = Color(75, 105, 145),
        model = "models/player/dod_american_exp_pm.mdl",
        primaryWeapon = "weapon_thompson",
        machineGun = "weapon_m249",
    },
}

local function GetEntitySpawnPositions(classes)
    local positions = {}

    for _, className in ipairs(classes) do
        for _, spawn in ipairs(ents.FindByClass(className)) do
            positions[#positions + 1] = spawn:GetPos()
        end
    end

    return positions
end

local function GetLivingTeamPlayers(teamIndex)
    local players = {}

    for _, ply in ipairs(team.GetPlayers(teamIndex)) do
        if ply:Alive() then
            players[#players + 1] = ply
        end
    end

    return players
end

local function GiveLoadoutWeapon(ply, className)
    if not weapons.GetStored(className) then return end

    local weapon = ply:Give(className)
    if IsValid(weapon) then return weapon end
end

local function SelectMachineGunners(candidates)
    local selected = {}
    if #candidates == 0 then return selected end

    local pool = table.Copy(candidates)
    local maximumGunners = math.max(1, math.ceil(#pool / 2))
    local gunnerCount = 1

    -- Every additional teammate has a 25% chance to add another machine gunner.
    -- At most half of a team can receive the role, keeping standard weapons common.
    for _ = 2, #pool do
        if gunnerCount >= maximumGunners then break end
        if math.Rand(0, 1) <= 0.25 then
            gunnerCount = gunnerCount + 1
        end
    end

    for _ = 1, gunnerCount do
        local index = math.random(#pool)
        selected[pool[index]] = true
        table.remove(pool, index)
    end

    return selected
end

local function FillWeaponAndGiveAmmo(ply, weapon, magazineCount)
    if not IsValid(weapon) then return end

    local maxClip = weapon:GetMaxClip1()
    if maxClip and maxClip > 0 then
        weapon:SetClip1(maxClip)
    end

    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then
        ply:GiveAmmo(math.max(maxClip, 30) * magazineCount, ammoType, true)
    end
end

function MODE:GetTeamSpawn()
    local germanSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
    local americanSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))

    if #germanSpawns == 0 then
        germanSpawns = GetEntitySpawnPositions({"info_player_terrorist", "info_player_axis", "info_player_rebel"})
    end

    if #americanSpawns == 0 then
        americanSpawns = GetEntitySpawnPositions({"info_player_counterterrorist", "info_player_allies", "info_player_combine"})
    end

    return germanSpawns, americanSpawns
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        local machineGunners = {}

        for teamIndex in pairs(TEAM_LOADOUTS) do
            machineGunners[teamIndex] = SelectMachineGunners(GetLivingTeamPlayers(teamIndex))
        end

        for _, ply in player.Iterator() do
            if not ply:Alive() then continue end

            local loadout = TEAM_LOADOUTS[ply:Team()]
            if not loadout then continue end

            local isMachineGunner = machineGunners[ply:Team()][ply] == true

            ply:SetSuppressPickupNotices(true)
            ply.noSound = true
            ply:SetPlayerClass()

            -- WW2 uniforms provide the complete appearance; do not layer saved cosmetics
            -- (such as backpacks or hats) or unrelated fallback models over them.
            ply:SetModel(loadout.model)
            ply:SetNetVar("Accessories", "none")
            zb.GiveRole(ply, isMachineGunner and loadout.gunnerRole or loadout.riflemanRole, loadout.color)

            local inventory = ply:GetNetVar("Inventory", {})
            inventory.Weapons = inventory.Weapons or {}
            inventory.Weapons.hg_sling = true
            ply:SetNetVar("Inventory", inventory)

            local weaponClass = isMachineGunner and loadout.machineGun or loadout.primaryWeapon
            local primary = GiveLoadoutWeapon(ply, weaponClass)
            FillWeaponAndGiveAmmo(ply, primary, isMachineGunner and 6 or 12)

            ply:Give("weapon_barrier_builder")
            ply:Give("weapon_melee")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_tourniquet")
            ply:Give("weapon_hands_sh")
            ply.organism.allowholster = true

            if IsValid(primary) then
                ply:SelectWeapon(primary:GetClass())
            else
                ply:SelectWeapon("weapon_hands_sh")
                ply:ChatPrint("Missing WW2 weapon class: " .. weaponClass)
            end

            timer.Simple(0.1, function()
                if IsValid(ply) then
                    ply.noSound = false
                end
            end)

            ply:SetSuppressPickupNotices(false)
        end
    end)
end

function MODE:ShowSpare1()
end
