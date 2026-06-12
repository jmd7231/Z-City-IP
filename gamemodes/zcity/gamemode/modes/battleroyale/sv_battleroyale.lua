local MODE = MODE

MODE.name = "battleroyale"
MODE.PrintName = "Battle Royale"
MODE.Description = "gm_fork only: scavenge for equipment, stay inside the collapsing safe zone, and be the last survivor."
MODE.LootSpawn = true
MODE.LootOnTime = false
MODE.GuiltDisabled = true
MODE.randomSpawns = true
MODE.ForBigMaps = false
MODE.Chance = 0.03
MODE.ROUND_TIME = 900
MODE.start_time = 8
MODE.end_time = 8

local zonePhases = {
    {wait = 55, shrink = 50, scale = 0.72, damage = 3},
    {wait = 40, shrink = 45, scale = 0.52, damage = 5},
    {wait = 30, shrink = 40, scale = 0.34, damage = 8},
    {wait = 20, shrink = 35, scale = 0.20, damage = 12},
    {wait = 12, shrink = 30, scale = 0.09, damage = 18},
    {wait = 8, shrink = 25, scale = 0.025, damage = 25},
}

MODE.LootTable = {
    {58, {
        {12, "*ammo*"},
        {10, "weapon_bandage_sh"},
        {8, "weapon_tourniquet"},
        {7, "weapon_hg_crowbar"},
        {6, "weapon_pocketknife"},
        {5, "weapon_hatchet"},
        {4, "weapon_bigconsumable"},
        {4, "weapon_smallconsumable"},
        {3, "ent_armor_helmet1"},
        {3, "ent_armor_vest3"},
    }},
    {34, {
        {12, "*ammo*"},
        {10, "weapon_glock17"},
        {9, "weapon_hk_usp"},
        {8, "weapon_cz75"},
        {8, "weapon_doublebarrel_short"},
        {7, "weapon_mac11"},
        {7, "weapon_uzi"},
        {6, "weapon_mp5"},
        {6, "weapon_remington870"},
        {5, "weapon_m4a1"},
        {5, "weapon_akm"},
        {4, "weapon_sks"},
        {4, "weapon_hg_grenade_tpik"},
        {4, "weapon_hg_smokenade_tpik"},
        {4, "*attachments*"},
        {3, "ent_armor_helmet1"},
        {3, "ent_armor_vest1"},
        {2, "ent_armor_vest4"},
    }},
    {8, {
        {10, "*ammo*"},
        {7, "weapon_hk416"},
        {7, "weapon_ar15"},
        {6, "weapon_saiga12"},
        {5, "weapon_svd"},
        {4, "weapon_sr25"},
        {3, "weapon_m98b"},
        {3, "weapon_hg_f1_tpik"},
        {3, "ent_armor_vest1"},
        {2, "ent_armor_vest4"},
        {2, "ent_armor_helmet1"},
        {2, "*sight*"},
    }},
}

util.AddNetworkString("zb_battleroyale_zone")
util.AddNetworkString("zb_battleroyale_end")

local function getSpawnPoints()
    local points = zb.GetMapPoints("RandomSpawns") or {}
    local positions = {}

    for _, point in ipairs(points) do
        local pos = isvector(point) and point or point.pos
        if isvector(pos) then
            positions[#positions + 1] = pos
        end
    end

    return positions
end

local function calculateInitialZone(positions)
    local center = Vector(0, 0, 0)

    for _, pos in ipairs(positions) do
        center:Add(pos)
    end

    if #positions > 0 then
        center:Div(#positions)
    end

    local radius = 0
    for _, pos in ipairs(positions) do
        local delta = pos - center
        delta.z = 0
        radius = math.max(radius, delta:Length())
    end

    return center, math.max(radius + 512, 1400)
end

function MODE:IsAllowedMap()
    return string.lower(game.GetMap()) == self.AllowedMap
end

function MODE:CanLaunch()
    return self:IsAllowedMap() and #getSpawnPoints() >= 2
end

function MODE:GetZoneRadius(atTime)
    local state = self.ZoneState
    if not state then return 0 end

    local fraction = state.shrinkEnd > state.shrinkStart and math.TimeFraction(state.shrinkStart, state.shrinkEnd, atTime or CurTime()) or 1
    return Lerp(math.Clamp(fraction, 0, 1), state.startRadius, state.targetRadius)
end

function MODE:SendZoneState(recipient)
    local state = self.ZoneState
    if not state then return end

    net.Start("zb_battleroyale_zone")
        net.WriteVector(state.center)
        net.WriteFloat(state.startRadius)
        net.WriteFloat(state.targetRadius)
        net.WriteFloat(state.shrinkStart)
        net.WriteFloat(state.shrinkEnd)
        net.WriteUInt(state.phase, 4)
        net.WriteUInt(#zonePhases, 4)
        net.WriteUInt(state.damage, 8)
    if IsValid(recipient) then
        net.Send(recipient)
    else
        net.Broadcast()
    end
end

function MODE:BeginZonePhase(phaseIndex)
    local phase = zonePhases[phaseIndex]
    local state = self.ZoneState
    if not phase or not state then return end

    state.phase = phaseIndex
    state.startRadius = self:GetZoneRadius()
    state.targetRadius = math.max(self.InitialZoneRadius * phase.scale, 96)
    state.shrinkStart = CurTime() + phase.wait
    state.shrinkEnd = state.shrinkStart + phase.shrink
    state.damage = phase.damage

    self:SendZoneState()

    PrintMessage(HUD_PRINTTALK, "[Battle Royale] Safe zone phase " .. phaseIndex .. " begins shrinking in " .. phase.wait .. " seconds.")
end

function MODE:Intermission()
    self.InvalidMap = not self:IsAllowedMap()
    if self.InvalidMap then
        PrintMessage(HUD_PRINTTALK, "[Battle Royale] This mode can only be played on gm_fork.")
        return
    end

    game.CleanUpMap()

    local activePositions = {}
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            ApplyAppearance(ply)
            ply:SetupTeam(0)
            activePositions[#activePositions + 1] = ply:GetPos()
        end
    end

    local positions = getSpawnPoints()
    if #positions == 0 then positions = activePositions end

    local center, radius = calculateInitialZone(positions)
    self.InitialZoneRadius = radius
    self.ZoneState = {
        center = center,
        phase = 0,
        startRadius = radius,
        targetRadius = radius,
        shrinkStart = CurTime(),
        shrinkEnd = CurTime(),
        damage = 0,
    }
    self.NextZoneDamage = 0

    self:SendZoneState()
end

function MODE:ShouldRoundEnd()
    return self.InvalidMap or #zb:CheckAlive(true) <= 1
end

function MODE:RoundStart()
    if self.InvalidMap then return end

    for _, ply in player.Iterator() do
        if ply:Alive() then
            ply:SetSuppressPickupNotices(true)
            ply.noSound = true
            ply:Give("weapon_hands_sh")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_tourniquet")
            ply:Give("weapon_walkie_talkie")
            ply:SelectWeapon("weapon_hands_sh")

            local inventory = ply:GetNetVar("Inventory")
            if inventory and inventory.Weapons then
                inventory.Weapons.hg_sling = true
                ply:SetNetVar("Inventory", inventory)
            end

            if ply.organism then ply.organism.recoilmul = 0.5 end

            timer.Simple(0.1, function()
                if IsValid(ply) then ply.noSound = false end
            end)

            ply:SetSuppressPickupNotices(false)
            zb.GiveRole(ply, "Survivor", Color(215, 145, 45))
        end
    end

    self:BeginZonePhase(1)
end

function MODE:RoundThink()
    local state = self.ZoneState
    if not state then return end

    if CurTime() >= state.shrinkEnd and state.phase < #zonePhases then
        self:BeginZonePhase(state.phase + 1)
        state = self.ZoneState
    end

    if CurTime() < (self.NextZoneDamage or 0) then return end
    self.NextZoneDamage = CurTime() + 1

    local radiusSqr = self:GetZoneRadius() ^ 2
    for _, ply in player.Iterator() do
        if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
            local delta = ply:GetPos() - state.center
            delta.z = 0
            local outside = delta:LengthSqr() > radiusSqr
            ply:SetNWBool("BattleRoyaleOutsideZone", outside)

            if outside and state.damage > 0 then
                local damage = DamageInfo()
                damage:SetDamage(state.damage)
                damage:SetDamageType(DMG_RADIATION)
                damage:SetAttacker(game.GetWorld())
                damage:SetInflictor(game.GetWorld())
                ply:TakeDamageInfo(damage)
            end
        end
    end
end

function MODE:PlayerInitialSpawn(ply)
    if zb.CROUND ~= self.name or not self.ZoneState then return end

    timer.Simple(1, function()
        if IsValid(ply) and zb.CROUND == self.name then
            self:SendZoneState(ply)
        end
    end)
end

function MODE:PlayerDeath(ply)
    ply:SetNWBool("BattleRoyaleOutsideZone", false)
    if zb.ROUND_STATE == 1 then ply:GiveSkill(-0.05) end
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

function MODE:CanSpawn()
end

function MODE:EndRound()
    if self.InvalidMap then
        self.InvalidMap = nil
        return
    end

    local winner = zb:CheckAlive(true)[1]

    if IsValid(winner) then
        winner:GiveExp(math.random(175, 250))
        winner:GiveSkill(math.Rand(0.2, 0.35))
    end

    for _, ply in player.Iterator() do
        ply:SetNWBool("BattleRoyaleOutsideZone", false)
    end

    timer.Simple(1, function()
        net.Start("zb_battleroyale_end")
            net.WriteEntity(IsValid(winner) and winner or NULL)
        net.Broadcast()
    end)
end
