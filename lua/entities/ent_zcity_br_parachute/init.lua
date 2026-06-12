AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate025x025.mdl")
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
end

function ENT:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() or not owner:GetNWBool("BattleRoyaleParachuting", false) then
        self:Remove()
        return
    end

    self:SetPos(owner:GetPos())
    self:SetAngles(Angle(0, owner:EyeAngles().y, 0))
    self:NextThink(CurTime())
    return true
end
