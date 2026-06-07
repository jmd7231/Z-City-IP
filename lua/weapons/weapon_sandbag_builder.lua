if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Sandbag Builder"
SWEP.Author = "Z-City"
SWEP.Instructions = "LMB: build a sandbag barricade (5 seconds)\nRMB: rotate placement\nReload: cancel construction"
SWEP.Category = "Z-City"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.BuildTime = 5
SWEP.BuildRange = 180
SWEP.MaxBarricades = 6
SWEP.SandbagModel = "models/props_c17/concrete_barrier001a.mdl"

local placementMins = Vector(-48, -14, 2)
local placementMaxs = Vector(48, 14, 42)

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Building")
    self:NetworkVar("Float", 0, "BuildEndsAt")
    self:NetworkVar("Float", 1, "PlacementRotation")
    self:NetworkVar("Vector", 0, "BuildPosition")
    self:NetworkVar("Angle", 0, "BuildAngles")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    if SERVER then
        self:SetBuilding(false)
        self:SetPlacementRotation(0)
    end
end

function SWEP:GetPlacement(owner)
    local trace = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * self.BuildRange,
        filter = owner,
        mask = MASK_SOLID,
    })

    if not trace.Hit or trace.HitSky or trace.HitNormal.z < 0.55 then return end

    local position = trace.HitPos + trace.HitNormal * 2
    local angles = Angle(0, owner:EyeAngles().y + 90 + self:GetPlacementRotation(), 0)
    local blocked = util.TraceHull({
        start = position,
        endpos = position,
        mins = placementMins,
        maxs = placementMaxs,
        filter = owner,
        mask = MASK_SOLID,
    }).Hit

    return position, angles, not blocked
end

function SWEP:CountOwnerBarricades(owner)
    local count = 0

    for _, barricade in ipairs(ents.FindByClass("ent_ww2_sandbag")) do
        if barricade:GetCreator() == owner then
            count = count + 1
        end
    end

    return count
end

function SWEP:CancelBuild(message)
    if not self:GetBuilding() then return end

    self:SetBuilding(false)
    self:SetBuildEndsAt(0)

    local owner = self:GetOwner()
    if message and IsValid(owner) then
        owner:ChatPrint(message)
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT or self:GetBuilding() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() then return end

    if self:CountOwnerBarricades(owner) >= self.MaxBarricades then
        owner:ChatPrint("You may only have " .. self.MaxBarricades .. " sandbag barricades at once.")
        return
    end

    local position, angles, valid = self:GetPlacement(owner)
    if not position then
        owner:ChatPrint("Aim at nearby, reasonably flat ground to build sandbags.")
        return
    end

    if not valid then
        owner:ChatPrint("There is not enough room to build sandbags there.")
        return
    end

    self:SetBuildPosition(position)
    self:SetBuildAngles(angles)
    self:SetBuildEndsAt(CurTime() + self.BuildTime)
    self:SetBuilding(true)
    owner:EmitSound("ambient/materials/metal_stress1.wav", 60, 110)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.2)
    if CLIENT or self:GetBuilding() then return end

    self:SetPlacementRotation((self:GetPlacementRotation() + 15) % 180)
    self:GetOwner():EmitSound("buttons/lightswitch2.wav", 55, 110)
end

function SWEP:Reload()
    if SERVER then
        self:CancelBuild("Sandbag construction cancelled.")
    end
end

function SWEP:Think()
    if CLIENT or not self:GetBuilding() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() or owner:GetActiveWeapon() ~= self then
        self:CancelBuild()
        return
    end

    if owner:GetPos():DistToSqr(self:GetBuildPosition()) > (self.BuildRange + 80) ^ 2 then
        self:CancelBuild("You moved too far away; sandbag construction cancelled.")
        return
    end

    if CurTime() < self:GetBuildEndsAt() then return end

    local blocked = util.TraceHull({
        start = self:GetBuildPosition(),
        endpos = self:GetBuildPosition(),
        mins = placementMins,
        maxs = placementMaxs,
        filter = owner,
        mask = MASK_SOLID,
    }).Hit

    if blocked then
        self:CancelBuild("The sandbag site became blocked.")
        return
    end

    local barricade = ents.Create("ent_ww2_sandbag")
    if not IsValid(barricade) then
        self:CancelBuild("The sandbag barricade could not be created.")
        return
    end

    barricade:SetPos(self:GetBuildPosition())
    barricade:SetAngles(self:GetBuildAngles())
    barricade:SetCreator(owner)
    barricade:Spawn()
    barricade:Activate()

    owner:EmitSound("physics/concrete/concrete_impact_hard3.wav", 70, 95)
    self:SetBuilding(false)
    self:SetBuildEndsAt(0)
    self:SetNextPrimaryFire(CurTime() + 1)
end

function SWEP:Holster()
    if SERVER then self:CancelBuild() end
    return true
end

function SWEP:OnRemove()
    if SERVER then self:CancelBuild() end
end

if CLIENT then
    local ghostColor = Color(100, 210, 100, 110)
    local blockedColor = Color(220, 80, 80, 110)

    function SWEP:DrawHUD()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if self:GetBuilding() then
            local progress = math.Clamp(1 - (self:GetBuildEndsAt() - CurTime()) / self.BuildTime, 0, 1)
            local width, height = 320, 22
            local x, y = ScrW() * 0.5 - width * 0.5, ScrH() * 0.78

            draw.RoundedBox(4, x, y, width, height, Color(15, 15, 15, 220))
            draw.RoundedBox(4, x + 3, y + 3, (width - 6) * progress, height - 6, Color(190, 165, 90, 240))
            draw.SimpleText("Building sandbags... " .. math.floor(progress * 100) .. "%", "DermaDefaultBold", ScrW() * 0.5, y + height * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local position, angles, valid = self:GetPlacement(owner)
        if not position then return end

        if not IsValid(self.SandbagGhost) then
            self.SandbagGhost = ClientsideModel(self.SandbagModel, RENDERGROUP_TRANSLUCENT)
            if not IsValid(self.SandbagGhost) then return end
            self.SandbagGhost:SetNoDraw(true)
        end

        self.SandbagGhost:SetPos(position)
        self.SandbagGhost:SetAngles(angles)
        self.SandbagGhost:SetColor(valid and ghostColor or blockedColor)
        self.SandbagGhost:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self.SandbagGhost:DrawModel()

        draw.SimpleText("LMB: build | RMB: rotate", "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.72, valid and color_white or Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function SWEP:OnRemove()
        if IsValid(self.SandbagGhost) then
            self.SandbagGhost:Remove()
        end
    end
end
