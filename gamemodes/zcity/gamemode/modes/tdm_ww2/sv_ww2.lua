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
        model = "models/player/dod_german.mdl",
        primaryWeapon = "weapon_mp40",
        machineGun = "weapon_mg34",
    },
    [1] = {
        name = "American",
        riflemanRole = "American Rifleman",
        gunnerRole = "American Machine Gunner",
        color = Color(75, 105, 145),
        model = "models/player/dod_american.mdl",
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
    if ply:HasWeapon(className) then
        return ply:GetWeapon(className)
    end

    -- These WW2 SWEPs are supplied by a mounted addon. Calling Give directly is
    -- more reliable than prechecking the local registry, which may not expose an
    -- externally registered weapon even though Player:Give can create it.
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

local function ApplyTeamModel(ply, model)
    -- Appearance bodygroups, accessories, submaterials, and bone transforms are
    -- model-specific. Clear them before applying a DOD model so data from the
    -- player's normal appearance cannot deform or clip through the WW2 model.
    ply:SetNetVar("Accessories", "")
    ply.CurAppearance = {}
    ply:SetSubMaterial()
    ply:SetModel(model)
    ply:SetModelScale(1, 0)
    ply:SetSkin(0)
    ply:SetBodyGroups("00000000000000000000")

    local zeroVector = Vector(0, 0, 0)
    local zeroAngle = Angle(0, 0, 0)
    local fullScale = Vector(1, 1, 1)

    for bone = 0, math.max(ply:GetBoneCount() - 1, 0) do
        ply:ManipulateBonePosition(bone, zeroVector, true)
        ply:ManipulateBoneAngles(bone, zeroAngle, true)
        ply:ManipulateBoneScale(bone, fullScale, true)
    end

    ply:SetupBones()
end

local function VerifyTeamLoadout(ply, teamIndex, isMachineGunner)
    if not IsValid(ply) or not ply:Alive() or ply:Team() ~= teamIndex then return end

    local loadout = TEAM_LOADOUTS[teamIndex]
    if not loadout then return end

    local weaponClass = isMachineGunner and loadout.machineGun or loadout.primaryWeapon
    local magazineCount = isMachineGunner and 6 or 12

    -- Reapply even when the model path already matches: a later appearance hook
    -- can change bodygroups, submaterials, accessories, or bone transforms without
    -- changing GetModel().
    ApplyTeamModel(ply, loadout.model)

    local primary = GiveLoadoutWeapon(ply, weaponClass)
    FillWeaponAndGiveAmmo(ply, primary, magazineCount)

    if IsValid(primary) then
        ply:SelectWeapon(weaponClass)
    else
        ply:ChatPrint("Missing WW2 weapon class: " .. weaponClass)
    end
end

local function ScheduleLoadoutVerification(ply, teamIndex, isMachineGunner)
    for _, delay in ipairs({0.25, 1, 3}) do
        timer.Simple(delay, function()
            VerifyTeamLoadout(ply, teamIndex, isMachineGunner)
        end)
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

            local teamIndex = ply:Team()
            local isMachineGunner = machineGunners[teamIndex][ply] == true
            ply.WW2TeamIndex = teamIndex
            ply.WW2IsMachineGunner = isMachineGunner

            ply:SetSuppressPickupNotices(true)
            ply.noSound = true
            ply:SetPlayerClass()

            ApplyTeamModel(ply, loadout.model)
            zb.GiveRole(ply, isMachineGunner and loadout.gunnerRole or loadout.riflemanRole, loadout.color)

            local inventory = ply:GetNetVar("Inventory", {})
            inventory.Weapons = inventory.Weapons or {}
            inventory.Weapons.hg_sling = true
            ply:SetNetVar("Inventory", inventory)

            local weaponClass = isMachineGunner and loadout.machineGun or loadout.primaryWeapon
            local magazineCount = isMachineGunner and 6 or 12
            local primary = GiveLoadoutWeapon(ply, weaponClass)
            FillWeaponAndGiveAmmo(ply, primary, magazineCount)

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
            end

            ScheduleLoadoutVerification(ply, teamIndex, isMachineGunner)

            timer.Simple(0.1, function()
                if IsValid(ply) then
                    ply.noSound = false
                end
            end)

            ply:SetSuppressPickupNotices(false)
        end
    end)
end

function MODE:RoundStart()
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            ply:Freeze(false)
        end

        local teamIndex = ply:Team()
        local isMachineGunner = ply.WW2TeamIndex == teamIndex and ply.WW2IsMachineGunner or false

        ScheduleLoadoutVerification(ply, teamIndex, isMachineGunner)
    end
end

function MODE:ShowSpare1()
end
