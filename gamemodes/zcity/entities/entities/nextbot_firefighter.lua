AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = false
ENT.PrintName = "Firefighter NextBot"

ENT.Model = "models/player/riot.mdl"
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

    self.loco:SetDesiredSpeed(self.MoveSpeed)
    self.loco:SetAcceleration(4000)
    self.loco:SetDeceleration(4000)
    self.loco:SetStepHeight(32)
    self.loco:SetJumpHeight(150)

    self.NextTargetSearch = 0
    self.NextSpray = 0
    self.LastFireSeen = CurTime()

    self:EquipExtinguisherProp()
end

function ENT:EquipExtinguisherProp()
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
        self:StartActivity(ACT_RUN)

        if self.NextTargetSearch <= CurTime() then
            self.NextTargetSearch = CurTime() + self.TargetRefreshDelay
            self.TargetFire = self:FindBestFire()
        end

        if IsValid(self.TargetFire) then
            self.LastFireSeen = CurTime()
            self:MoveAndExtinguish(self.TargetFire)
        elseif self.LastFireSeen + self.DespawnDelay <= CurTime() then
            self:Remove()
            return
        else
            self:StartActivity(ACT_IDLE)
            coroutine.wait(0.1)
        end

        coroutine.yield()
    end
end

function ENT:MoveAndExtinguish(fire)
    local firePos = fire:GetPos()
    local myPos = self:GetPos()
    local toFire = firePos - myPos
    local dist = toFire:Length()

    if dist > 1 then
        local moveDir = toFire / dist

        self:SetAngles(moveDir:Angle())
        self.loco:SetVelocity(moveDir * self.MoveSpeed)

        local tr = util.TraceLine({
            start = myPos + Vector(0, 0, 36),
            endpos = firePos + Vector(0, 0, 36),
            filter = self,
            mask = MASK_SOLID_BRUSHONLY
        })

        if tr.Hit and self:IsOnGround() then
            self.loco:Jump()
        end
    end

    if dist <= self.ExtinguishRange and self.NextSpray <= CurTime() then
        self.NextSpray = CurTime() + 0.1

        if IsValid(fire) then
            fire:Extinguish()
        end
    end
end

function ENT:OnContact(ent)
    if not IsValid(ent) then return end

    if hgIsDoor and hgIsDoor(ent) and ent:GetInternalVariable("m_eDoorState") == 0 then
        ent:Fire("Open")
    end
end

function ENT:HandleStuck()
    self:SetPos(self:GetPos() + VectorRand() * 30 + Vector(0, 0, 20))
    self.loco:ClearStuck()
end
