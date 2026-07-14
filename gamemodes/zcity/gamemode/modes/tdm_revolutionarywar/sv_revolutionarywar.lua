local MODE = MODE

MODE.name = "revolutionarywar"
MODE.PrintName = "Revolutionary War"
MODE.Chance = 0.03
MODE.BuyTime = 0
MODE.start_time = 0
MODE.buymenu = false
MODE.ROUND_TIME = 240

local TEAM_LOADOUTS = {
    [0] = {
        name = "American",
        class = "american",
        color = Color(35, 90, 180),
        model = "models/player/american/light_a/light_a.mdl",
    },
    [1] = {
        name = "Redcoat",
        class = "redcoat",
        color = Color(190, 30, 30),
        model = "models/player/british/light_b/light_b.mdl",
    },
}

local MUSKET_AMMO = 20
local FLINTLOCK_EXTRA_AMMO = 10

local function GetEntitySpawnPositions(classes)
    local positions = {}

    for _, className in ipairs(classes) do
        for _, spawn in ipairs(ents.FindByClass(className)) do
            positions[#positions + 1] = spawn:GetPos()
        end
    end

    return positions
end

function MODE:GetTeamSpawn()
    -- Gang Wars and HL2DM both use these paired TDM point groups.
    local americanSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
    local redcoatSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))

    if #americanSpawns == 0 then
        americanSpawns = GetEntitySpawnPositions({"info_player_terrorist", "info_player_rebel"})
    end

    if #redcoatSpawns == 0 then
        redcoatSpawns = GetEntitySpawnPositions({"info_player_counterterrorist", "info_player_combine"})
    end

    return americanSpawns, redcoatSpawns
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        for _, ply in player.Iterator() do
            if not ply:Alive() then continue end

            local loadout = TEAM_LOADOUTS[ply:Team()]
            if not loadout then continue end

            ply:SetSuppressPickupNotices(true)
            ply.noSound = true
            ply:SetPlayerClass(loadout.class)
            zb.GiveRole(ply, loadout.name, loadout.color)

            local inv = ply:GetNetVar("Inventory", {})
            inv.Weapons = inv.Weapons or {}
            inv.Weapons.hg_sling = true
            ply:SetNetVar("Inventory", inv)

            local musket = ply:Give("weapon_musket")
            local flintlock = ply:Give("weapon_flintlock")

            if IsValid(musket) then
                musket:SetClip1(musket:GetMaxClip1())
                ply:GiveAmmo(MUSKET_AMMO, musket:GetPrimaryAmmoType(), true)
            end

            if IsValid(flintlock) then
                flintlock:SetClip1(flintlock:GetMaxClip1())
                ply:GiveAmmo(FLINTLOCK_EXTRA_AMMO, flintlock:GetPrimaryAmmoType(), true)
            end

            ply:Give("weapon_melee")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_tourniquet")
            ply:Give("weapon_hands_sh")
            ply.organism.allowholster = true
            ply:SelectWeapon(IsValid(musket) and musket:GetClass() or "weapon_hands_sh")

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
