if SERVER then AddCSLuaFile() end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Sandbag Barricade"
ENT.Spawnable = false
ENT.Model = "models/props_fortifications/sandbags_line2.mdl"
ENT.MaxHealth = 600

function ENT:Initialize()
    if CLIENT then return end

    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetHealth(self.MaxHealth)

    local physics = self:GetPhysicsObject()
    if IsValid(physics) then
        physics:EnableMotion(false)
    end
end

function ENT:OnTakeDamage(damageInfo)
    if CLIENT then return end

    self:TakePhysicsDamage(damageInfo)
    self:SetHealth(self:Health() - damageInfo:GetDamage())

    if self:Health() <= 0 then
        self:EmitSound("physics/concrete/concrete_break2.wav", 75, 95)
        self:Remove()
    end
end

function ENT:Draw()
    self:DrawModel()
end
