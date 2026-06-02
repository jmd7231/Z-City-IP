AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = false
ENT.PrintName = "Firefighter NextBot"

ENT.Model = "models/player/Group03/male_07.mdl"
ENT.SearchRadius = 25000
ENT.MoveSpeed = 700
ENT.ExtinguishRange = 175
ENT.TargetRefreshDelay = 0.1
ENT.DespawnDelay = 1

local function getActiveFires()
    local fires = ents.FindByClass("vfire")

    for _, fireBall in ipairs(ents.FindByClass("vfire_ball")) do
        fires[#fires + 1] = fireBall
    end

    return fires
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetHealth(500)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetNoDraw(false)
    
    if CLIENT then return end

    if self.loco then
        self.loco:SetDesiredSpeed(self.MoveSpeed)
        self.loco:SetAcceleration(4000)
        self.loco:SetDeceleration(4000)
        self.loco:SetStepHeight(32)
        self.loco:SetJumpHeight(150)
    end

    self.NextTargetSearch = 0
    self.NextSpray = 0
    self.LastFireSeen = CurTime()
    self.LastMoveThink = CurTime()

    self:EquipExtinguisherProp()
end

function ENT:EquipExtinguisherProp()
    if CLIENT then return end

    local extinguisher = ents.Create("prop_dynamic")
    if not IsValid(extinguisher) then return end

    extinguisher:SetModel("models/weapons/tfa_nmrih/w_tool_extinguisher.mdl")
    extinguisher:SetPos(self:GetPos())
    extinguisher:SetAngles(self:GetAngles())
    extinguisher:SetParent(self)
    extinguisher:SetLocalPos(Vector(2, 4, 40))
    extinguisher:SetLocalAngles(Angle(0, 90, 180))
    extinguisher:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    extinguisher:Spawn()

    self.ExtinguisherProp = extinguisher
end

function ENT:OnRemove()
    if IsValid(self.ExtinguisherProp) then
        self.ExtinguisherProp:Remove()
    end
end

function ENT:FindBestFire()
    local myPos = self:GetPos()
    local bestFire
    local bestScore = -math.huge

    for _, fire in ipairs(getActiveFires()) do
        if not IsValid(fire) then continue end

        local firePos = fire:GetPos()
        local distSqr = myPos:DistToSqr(firePos)
        if distSqr > (self.SearchRadius * self.SearchRadius) then continue end

        local lifeScore = tonumber(fire.life) or 0
        local score = lifeScore * 3000 - distSqr

        if score > bestScore then
            bestScore = score
            bestFire = fire
        end
    end

    return bestFire
end

function ENT:RunBehaviour()
    while true do
        coroutine.wait(0.1)
        coroutine.yield()
    end
end

function ENT:MoveTowards(pos, delta)
    local myPos = self:GetPos()
    local toGoal = pos - myPos
    local dist = toGoal:Length()
    if dist <= 1 then return dist end

    local moveDir = toGoal / dist
    local moveAng = moveDir:Angle()
    self:SetAngles(Angle(0, moveAng.y, 0))

    local step = math.min(dist, self.MoveSpeed * delta)
    local nextPos = myPos + moveDir * step

    local tr = util.TraceHull({
        start = myPos + Vector(0, 0, 20),
        endpos = nextPos + Vector(0, 0, 20),
        mins = Vector(-12, -12, 0),
        maxs = Vector(12, 12, 64),
        filter = self,
        mask = MASK_PLAYERSOLID
    })

    if tr.Hit then
        if IsValid(tr.Entity) and hgIsDoor and hgIsDoor(tr.Entity) and tr.Entity:GetInternalVariable("m_eDoorState") == 0 then
            tr.Entity:Fire("Open")
        else
            nextPos = myPos + Vector(0, 0, 24)
        end
    end

    self:SetPos(nextPos)
    return dist
end

function ENT:SprayAtFire(fire)
    if self.NextSpray > CurTime() then return end
    self.NextSpray = CurTime() + 0.1

    self:EmitSound("fire_extinguisher/fire_extinguisger_startloop.wav", 65, 100, 0.6, CHAN_AUTO)

    local firePos = fire:GetPos()
    for _, ent in ipairs(ents.FindInSphere(firePos, self.ExtinguishRange * 0.75)) do
        local class = ent:GetClass()
        if class == "vfire" or class == "vfire_ball" then
            ent:Extinguish()
        end
    end
end

function ENT:Think()
    if CLIENT then return end

    local curTime = CurTime()
    local delta = math.Clamp(curTime - self.LastMoveThink, 0, 0.1)
    self.LastMoveThink = curTime

    if self.NextTargetSearch <= curTime then
        self.NextTargetSearch = curTime + self.TargetRefreshDelay
        self.TargetFire = self:FindBestFire()
    end

    if IsValid(self.TargetFire) then
        self.LastFireSeen = curTime
        self:StartActivity(ACT_RUN)

        local dist = self:MoveTowards(self.TargetFire:GetPos(), delta)
        if dist <= self.ExtinguishRange then
            self:SprayAtFire(self.TargetFire)
        end
    else
        self:StartActivity(ACT_IDLE)
        if self.LastFireSeen + self.DespawnDelay <= curTime then
            self:Remove()
            return
        end
    end

    self:NextThink(curTime)
    return true
end

function ENT:BodyUpdate()
    self:BodyMoveXY()
end

function ENT:OnContact(ent)
    if not IsValid(ent) then return end

    if hgIsDoor and hgIsDoor(ent) and ent:GetInternalVariable("m_eDoorState") == 0 then
        ent:Fire("Open")
    end
end

function ENT:HandleStuck()
    self:SetPos(self:GetPos() + VectorRand() * 30 + Vector(0, 0, 20))
    if self.loco then
        self.loco:ClearStuck()
    end
end
