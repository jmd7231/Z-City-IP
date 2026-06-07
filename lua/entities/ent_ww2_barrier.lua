if SERVER then AddCSLuaFile() end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Defensive Barrier"
ENT.Spawnable = false
ENT.Model = "models/props_c17/concrete_barrier001a.mdl"
ENT.MaxBarrierHealth = 3000
ENT.MaxHealth = 3000

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "BarrierHealth")
    self:NetworkVar("Int", 1, "BarrierMaxHealth")
end

function ENT:Initialize()
    if CLIENT then return end

    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetBarrierMaxHealth(self.MaxBarrierHealth)
    self:SetBarrierHealth(self.MaxBarrierHealth)
    self:SetMaxHealth(self.MaxBarrierHealth)
    self:SetHealth(self.MaxBarrierHealth)

    local physics = self:GetPhysicsObject()
    if IsValid(physics) then
        physics:EnableMotion(false)
    end
end

function ENT:OnTakeDamage(damageInfo)
    if CLIENT then return end

    self:TakePhysicsDamage(damageInfo)

    local remainingHealth = math.max(math.ceil(self:GetBarrierHealth() - damageInfo:GetDamage()), 0)
    self:SetBarrierHealth(remainingHealth)
    self:SetHealth(remainingHealth)

    if remainingHealth <= 0 then
        self:EmitSound("physics/concrete/concrete_break2.wav", 75, 95)
        self:Remove()
    end
end

if CLIENT then
    local barWidth = 180
    local barHeight = 18
    local barScale = 0.1

    function ENT:Draw()
        self:DrawModel()

        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) or localPlayer:GetPos():DistToSqr(self:GetPos()) > 1200 * 1200 then return end

        local maximumHealth = self:GetBarrierMaxHealth()
        if maximumHealth <= 0 then return end

        local health = math.Clamp(self:GetBarrierHealth(), 0, maximumHealth)
        local healthFraction = health / maximumHealth
        local _, boundsMax = self:GetRenderBounds()
        local barPosition = self:GetPos() + Vector(0, 0, boundsMax.z + 18)
        local barAngles = Angle(0, localPlayer:EyeAngles().y - 90, 90)
        local healthColor = HSVToColor(healthFraction * 120, 0.85, 0.95)

        cam.Start3D2D(barPosition, barAngles, barScale)
            draw.RoundedBox(5, -barWidth * 0.5 - 3, -3, barWidth + 6, barHeight + 6, Color(10, 10, 10, 220))
            draw.RoundedBox(3, -barWidth * 0.5, 0, barWidth, barHeight, Color(45, 45, 45, 235))
            draw.RoundedBox(3, -barWidth * 0.5, 0, barWidth * healthFraction, barHeight, healthColor)
            draw.SimpleText(math.ceil(health) .. " / " .. maximumHealth .. " HP", "DermaDefaultBold", 0, barHeight * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
