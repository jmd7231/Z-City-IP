local MODE = MODE

MODE.name = "battleroyale"
MODE.PrintName = "Battle Royale"
MODE.Description = "gm_fork only: scavenge for equipment, stay inside the collapsing safe zone, and be the last survivor."
MODE.LootSpawn = false
MODE.LootOnTime = false
MODE.GuiltDisabled = true
MODE.randomSpawns = true
MODE.ForBigMaps = false
MODE.Chance = 0.03
MODE.ROUND_TIME = 900
MODE.start_time = 8
MODE.end_time = 8

local zonePhases = {
    {wait = 180, shrink = 45, radius = 10883, damage = 0},
    {wait = 100, shrink = 45, radius = 7676, damage = 4},
    {wait = 100, shrink = 45, radius = 3838, damage = 9},
}

local zoneRoutes = {
    {
        Vector(0, 0, 0),
        Vector(-3839, 3839, 0),
        Vector(-7676, 3839, 0),
    },
    {
        Vector(0, -7700, 0),
        Vector(0, -7700, 0),
        Vector(-3837, -7700, 0),
    },
    {
        Vector(7676, -7676, 0),
        Vector(3839, -7676, 0),
        Vector(3839, -7676, 0),
    },
    {
        Vector(7700, -7700, 0),
        Vector(7700, -7700, 0),
        Vector(11513, -7700, 0),
    },
    {
        Vector(7700, 0, 0),
        Vector(7700, 0, 0),
        Vector(11513, 0, 0),
    },
}

local gmForkLootPositions = {
    Vector(13826, 12370, -7000), Vector(4284, 3704, -7300), Vector(11396, -9762, -6150),
    Vector(-15172, 3113, -10000), Vector(-7361, 13382, -10300), Vector(-5089, -6334, -9000),
    Vector(-9061, 7659, -9600), Vector(-6502, 4995, -10400), Vector(6895, 6235, -9840),
    Vector(10970, 5150, -7340), Vector(3424, -9789, -8542), Vector(-5729, 13381, -10145),
    Vector(-8091, -265, -10400), Vector(-10163, 7202, -10049), Vector(-10049, 9856, -9906),
    Vector(-12716, 12400, -9858), Vector(-46, 6230, -9847), Vector(11394, -4829, -7841),
    Vector(-2690, -14591, -7800), Vector(-13978, 11429, -10327), Vector(6144, 1601, -7200),
    Vector(5422, 10138, -10400), Vector(10534, -1729, -7840), Vector(-504, -4781, -8900),
    Vector(-1381, -13455, -7500), Vector(-14213, -1970, -9900), Vector(-13150, -1626, -10200),
    Vector(-10414, 7888, -9962), Vector(-13024, 4610, -9901), Vector(9216, -3789, -7591),
    Vector(-7360, -12617, -8907), Vector(3921, -10168, -8650), Vector(-1193, -8116, -9000),
    Vector(-9661, -12610, -9345), Vector(-10445, -1208, -10141), Vector(-8499, 6945, -10049),
    Vector(7050, 5966, -9869), Vector(-623, -10169, -7800), Vector(-13454, -11152, -10300),
    Vector(-9925, 76, -10200), Vector(-7350, 6681, -9549), Vector(-2642, 3199, -10000),
    Vector(-6573, -2714, -10360), Vector(-6735, 7989, -9904), Vector(-8541, -12670, -9100),
    Vector(-11876, -7013, -10023), Vector(-9709, 11591, -10039), Vector(-10286, 4115, -9935),
}

local gmForkLootClasses = {
    "weapon_glock17", "weapon_hk_usp", "weapon_deagle", "weapon_mac11", "weapon_mp5",
    "weapon_remington870", "weapon_m4a1", "weapon_akm", "weapon_pkm", "weapon_bandage_sh",
    "weapon_tourniquet", "ent_armor_vest3", "ent_armor_vest1", "ent_armor_helmet1",
}

local gmForkVehicles = {
    {"prop_vehicle_jeep", "models/vehicle.mdl", "scripts/vehicles/jalopy.txt", Vector(6895, 6235, -9872)},
    {"prop_vehicle_jeep", "models/vehicle.mdl", "scripts/vehicles/jalopy.txt", Vector(11570, 5380, -7487)},
    {"prop_vehicle_jeep", "models/vehicle.mdl", "scripts/vehicles/jalopy.txt", Vector(10037, -2323, -7871)},
    {"prop_vehicle_jeep", "models/vehicle.mdl", "scripts/vehicles/jalopy.txt", Vector(-841, -7620, -9037)},
    {"prop_vehicle_airboat", "models/airboat.mdl", "scripts/vehicles/airboat.txt", Vector(8698, 8815, -9893)},
    {"prop_vehicle_airboat", "models/airboat.mdl", "scripts/vehicles/airboat.txt", Vector(-660, 8153, -10200)},
    {"prop_vehicle_airboat", "models/airboat.mdl", "scripts/vehicles/airboat.txt", Vector(-5250, 13492, -10100)},
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
util.AddNetworkString("zb_battleroyale_thirdperson")

resource.AddFile("materials/zcity/battleroyale/icon.png")
resource.AddFile("materials/zcity/battleroyale/logo.png")

local function interpolateVector(startPos, endPos, fraction)
    return startPos + (endPos - startPos) * math.Clamp(fraction, 0, 1)
end

local function spawnAtPosition(className, pos)
    local ent = ents.Create(className)
    if not IsValid(ent) then return end

    ent:SetPos(pos + Vector(0, 0, 12))
    ent:Spawn()
    ent.IsSpawned = true
    return ent
end


function MODE:IsAllowedMap()
    return string.lower(game.GetMap()) == self.AllowedMap
end

function MODE:CanLaunch()
    return self:IsAllowedMap()
end

function MODE:GetZoneFraction(atTime)
    local state = self.ZoneState
    if not state or state.shrinkEnd <= state.shrinkStart then return 1 end
    return math.Clamp(math.TimeFraction(state.shrinkStart, state.shrinkEnd, atTime or CurTime()), 0, 1)
end

function MODE:GetZoneRadius(atTime)
    local state = self.ZoneState
    if not state then return 0 end
    return Lerp(self:GetZoneFraction(atTime), state.startRadius, state.targetRadius)
end

function MODE:GetZoneCenter(atTime)
    local state = self.ZoneState
    if not state then return vector_origin end
    return interpolateVector(state.startCenter, state.targetCenter, self:GetZoneFraction(atTime))
end

function MODE:SendZoneState(recipient)
    local state = self.ZoneState
    if not state then return end

    net.Start("zb_battleroyale_zone")
        net.WriteVector(state.startCenter)
        net.WriteVector(state.targetCenter)
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

    local route = zoneRoutes[self.ZoneRoute]
    state.phase = phaseIndex
    state.startCenter = self:GetZoneCenter()
    state.targetCenter = route[phaseIndex]
    state.startRadius = self:GetZoneRadius()
    state.targetRadius = phase.radius
    state.shrinkStart = CurTime() + phase.wait
    state.shrinkEnd = state.shrinkStart + phase.shrink
    state.damage = phase.damage

    self:SendZoneState()

    PrintMessage(HUD_PRINTTALK, "[Battle Royale] Safe zone phase " .. phaseIndex .. " begins shrinking in " .. phase.wait .. " seconds.")
end

function MODE:SpawnGmForkContent()
    local positions = table.Copy(gmForkLootPositions)
    for index = 1, math.min(#positions, 42) do
        local positionIndex = math.random(#positions)
        local pos = table.remove(positions, positionIndex)
        local className = gmForkLootClasses[math.random(#gmForkLootClasses)]
        spawnAtPosition(className, pos)
    end

    for _, data in ipairs(gmForkVehicles) do
        local vehicle = ents.Create(data[1])
        if IsValid(vehicle) then
            vehicle:SetModel(data[2])
            vehicle:SetKeyValue("vehiclescript", data[3])
            vehicle:SetPos(data[4])
            vehicle:Spawn()
            vehicle:Activate()
        end
    end
end

function MODE:Intermission()
    self.InvalidMap = not self:IsAllowedMap()
    if self.InvalidMap then
        PrintMessage(HUD_PRINTTALK, "[Battle Royale] This mode can only be played on gm_fork.")
        return
    end

    game.CleanUpMap()

    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            ApplyAppearance(ply)
            ply:SetupTeam(0)
        end
    end

    self.ZoneRoute = math.random(#zoneRoutes)
    self.InitialZoneRadius = 22000
    self.ZoneState = {
        phase = 0,
        startCenter = vector_origin,
        targetCenter = vector_origin,
        startRadius = self.InitialZoneRadius,
        targetRadius = self.InitialZoneRadius,
        shrinkStart = CurTime(),
        shrinkEnd = CurTime(),
        damage = 0,
    }
    self.NextZoneDamage = 0
    self.NextDrowningDamage = 0

    self:SpawnGmForkContent()

    self:SendZoneState()
end

function MODE:FinishParachute(ply, landed)
    if not IsValid(ply) then return end

    ply:SetNWBool("BattleRoyaleParachuting", false)
    ply.Parachuting = false
    ply.BattleRoyaleParachuteStarted = nil
    ply:SetGravity(1)

    if ply.BattleRoyaleCollisionGroup then
        ply:SetCollisionGroup(ply.BattleRoyaleCollisionGroup)
        ply.BattleRoyaleCollisionGroup = nil
    end

    if IsValid(ply.BattleRoyaleParachute) then
        ply.BattleRoyaleParachute:Remove()
    end
    ply.BattleRoyaleParachute = nil

    if landed and ply:Alive() then
        ply:SetLocalVelocity(vector_origin)
        ply:ViewPunch(Angle(5, 0, 0))
        ply:EmitSound("npc/combine_soldier/zipline_clip2.wav", 70, 100)
    end
end

function MODE:StartParachute(ply)
    if not IsValid(ply) or not ply:Alive() then return end

    self:FinishParachute(ply, false)

    local positions = self.DeploymentPositions or {0}
    local x = positions[math.random(#positions)]
    local y = positions[math.random(#positions)]
    local height = self.DeploymentHeight or 4000

    ply.BattleRoyaleCollisionGroup = ply:GetCollisionGroup()
    ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    ply:SetPos(Vector(x, y, height))
    ply:SetLocalVelocity(vector_origin)
    ply:SetGravity(0.75)
    ply:SetNWBool("BattleRoyaleOutsideZone", false)
    ply:SetNWBool("BattleRoyaleParachuting", true)
    ply.Parachuting = true
    ply.BattleRoyaleParachuteStarted = CurTime()
    ply:ViewPunch(Angle(20, 0, 0))
    ply:EmitSound("ambient/fire/mtov_flame2.wav", 70, 90)

    local parachute = ents.Create("ent_zcity_br_parachute")
    if IsValid(parachute) then
        parachute:SetOwner(ply)
        parachute:SetPos(ply:GetPos())
        parachute:Spawn()
        ply.BattleRoyaleParachute = parachute
    end
end

function MODE:UpdateParachute(ply)
    if not IsValid(ply) or not ply:GetNWBool("BattleRoyaleParachuting", false) then return end

    if not ply:Alive() then
        self:FinishParachute(ply, false)
        return
    end

    if (ply:OnGround() or ply:WaterLevel() > 1) and CurTime() > (ply.BattleRoyaleParachuteStarted or 0) + 1 then
        self:FinishParachute(ply, true)
        return
    end

    local flare = ply:KeyDown(IN_USE)
    local forwardSpeed = ply:KeyDown(IN_FORWARD) and 420 or (ply:KeyDown(IN_BACK) and 170 or 285)
    local descentSpeed = flare and -135 or -225
    local direction = Angle(0, ply:EyeAngles().y, 0):Forward()

    ply:SetLocalVelocity(direction * forwardSpeed + Vector(0, 0, descentSpeed))
end

function MODE:GetFallDamage(ply)
    if IsValid(ply) and ply:GetNWBool("BattleRoyaleParachuting", false) then
        return 0
    end
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
            self:StartParachute(ply)
        end
    end

    self:BeginZonePhase(1)
end

function MODE:Think()
    if zb.ROUND_STATE ~= 1 then return end

    for _, ply in player.Iterator() do
        self:UpdateParachute(ply)
    end
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
    local center = self:GetZoneCenter()
    for _, ply in player.Iterator() do
        if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR and not ply:GetNWBool("BattleRoyaleParachuting", false) then
            local delta = ply:GetPos() - center
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

            if ply:WaterLevel() >= 2 and CurTime() >= (ply.BattleRoyaleNextDrown or 0) then
                ply.BattleRoyaleNextDrown = CurTime() + 1
                ply:TakeDamage(1, game.GetWorld(), game.GetWorld())
                ply:EmitSound("player/pl_drown" .. math.random(1, 3) .. ".wav", 65, 100)
            elseif ply:WaterLevel() < 2 then
                ply.BattleRoyaleNextDrown = CurTime() + 10
            end
        end
    end
end

local function setThirdPersonState(ply, enabled)
    if not IsValid(ply) or zb.CROUND ~= "battleroyale" then return end

    ply:SetNWBool("BattleRoyaleThirdPerson", enabled)
    if not enabled then
        ply:SetNWBool("BattleRoyaleThirdPersonShoulder", false)
    end
end

net.Receive("zb_battleroyale_thirdperson", function(_, ply)
    if zb.CROUND ~= MODE.name then return end

    local action = net.ReadUInt(1)
    if action == 0 then
        setThirdPersonState(ply, not ply:GetNWBool("BattleRoyaleThirdPerson", false))
    elseif ply:GetNWBool("BattleRoyaleThirdPerson", false) then
        ply:SetNWBool("BattleRoyaleThirdPersonShoulder", not ply:GetNWBool("BattleRoyaleThirdPersonShoulder", false))
    end
end)

function MODE:PlayerCanHearPlayersVoice(listener, talker)
    if not IsValid(listener) or not IsValid(talker) then return false end
    return listener:GetPos():DistToSqr(talker:GetPos()) <= 500 * 500, true
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
    self:FinishParachute(ply, false)
    ply:SetNWBool("BattleRoyaleOutsideZone", false)
    ply:SetNWBool("BattleRoyaleThirdPerson", false)
    ply:SetNWBool("BattleRoyaleThirdPersonShoulder", false)
    ply.BattleRoyaleNextDrown = nil
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
        self:FinishParachute(ply, false)
        ply:SetNWBool("BattleRoyaleOutsideZone", false)
        ply:SetNWBool("BattleRoyaleThirdPerson", false)
        ply:SetNWBool("BattleRoyaleThirdPersonShoulder", false)
        ply.BattleRoyaleNextDrown = nil
    end

    timer.Simple(1, function()
        net.Start("zb_battleroyale_end")
            net.WriteEntity(IsValid(winner) and winner or NULL)
        net.Broadcast()
    end)
end
