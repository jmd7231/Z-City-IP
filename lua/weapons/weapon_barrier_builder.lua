if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Barrier Builder"
SWEP.Author = "Z-City"
SWEP.Instructions = "LMB: build a defensive barrier (5 seconds, 30-second cooldown)\nRMB: rotate placement\nReload: cancel construction"
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
SWEP.BuildCooldown = 30
SWEP.BuildRange = 180
SWEP.MaxBarriers = 6
SWEP.BarrierModel = "models/props_c17/concrete_barrier001a.mdl"

local placementMins = Vector(-48, -14, 2)
local placementMaxs = Vector(48, 14, 42)
local cooldownNetworkKey = "WW2BarrierBuildReadyAt"

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

function SWEP:GetBuildCooldownRemaining(owner)
    if not IsValid(owner) then return 0 end

    return math.max(owner:GetNWFloat(cooldownNetworkKey, 0) - CurTime(), 0)
end

function SWEP:CountOwnerBarriers(owner)
    local count = 0

    for _, barrier in ipairs(ents.FindByClass("ent_ww2_barrier")) do
        if barrier:GetCreator() == owner then
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

    local cooldownRemaining = self:GetBuildCooldownRemaining(owner)
    if cooldownRemaining > 0 then
        owner:ChatPrint("You must wait " .. math.ceil(cooldownRemaining) .. " seconds before building another barrier.")
        self:SetNextPrimaryFire(CurTime() + math.min(cooldownRemaining, 1))
        return
    end

    if self:CountOwnerBarriers(owner) >= self.MaxBarriers then
        owner:ChatPrint("You may only have " .. self.MaxBarriers .. " defensive barriers at once.")
        return
    end

    local position, angles, valid = self:GetPlacement(owner)
    if not position then
        owner:ChatPrint("Aim at nearby, reasonably flat ground to build a barrier.")
        return
    end

    if not valid then
        owner:ChatPrint("There is not enough room to build a barrier there.")
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
        self:CancelBuild("Barrier construction cancelled.")
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
        self:CancelBuild("You moved too far away; barrier construction cancelled.")
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
        self:CancelBuild("The barrier site became blocked.")
        return
    end

    local barrier = ents.Create("ent_ww2_barrier")
    if not IsValid(barrier) then
        self:CancelBuild("The defensive barrier could not be created.")
        return
    end

    barrier:SetPos(self:GetBuildPosition())
    barrier:SetAngles(self:GetBuildAngles())
    barrier:SetCreator(owner)
    barrier:Spawn()
    barrier:Activate()

    local cooldownEndsAt = CurTime() + self.BuildCooldown
    owner:SetNWFloat(cooldownNetworkKey, cooldownEndsAt)
    owner:EmitSound("physics/concrete/concrete_impact_hard3.wav", 70, 95)
    owner:ChatPrint("Barrier built. You can build another in " .. self.BuildCooldown .. " seconds.")
    self:SetBuilding(false)
    self:SetBuildEndsAt(0)
    self:SetNextPrimaryFire(cooldownEndsAt)
end

function SWEP:Holster()
    if SERVER then self:CancelBuild() end
    return true
end

function SWEP:OnRemove()
    if SERVER then self:CancelBuild() end
end

if CLIENT then
    local validGhostColor = Color(80, 220, 120, 135)
    local blockedGhostColor = Color(235, 70, 70, 135)
    local buildingGhostColor = Color(80, 170, 255, 190)

    function SWEP:GetBarrierGhost()
        if IsValid(self.BarrierGhost) then return self.BarrierGhost end

        self.BarrierGhost = ClientsideModel(self.BarrierModel, RENDERGROUP_TRANSLUCENT)
        if not IsValid(self.BarrierGhost) then return end

        self.BarrierGhost:SetNoDraw(true)
        self.BarrierGhost:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self.BarrierGhost:SetMaterial("models/wireframe")

        return self.BarrierGhost
    end

    function SWEP:DrawHUD()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if self:GetBuilding() then
            local progress = math.Clamp(1 - (self:GetBuildEndsAt() - CurTime()) / self.BuildTime, 0, 1)
            local width, height = 320, 22
            local x, y = ScrW() * 0.5 - width * 0.5, ScrH() * 0.78

            draw.RoundedBox(4, x, y, width, height, Color(15, 15, 15, 220))
            draw.RoundedBox(4, x + 3, y + 3, (width - 6) * progress, height - 6, Color(190, 165, 90, 240))
            draw.SimpleText("Building barrier... " .. math.floor(progress * 100) .. "%", "DermaDefaultBold", ScrW() * 0.5, y + height * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local cooldownRemaining = self:GetBuildCooldownRemaining(owner)
        if cooldownRemaining > 0 then
            draw.SimpleText("Next barrier available in " .. math.ceil(cooldownRemaining) .. "s", "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.72, Color(255, 190, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local _, _, valid = self:GetPlacement(owner)
        draw.SimpleText("LMB: build | RMB: rotate", "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.72, valid and color_white or Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function SWEP:OnRemove()
        if IsValid(self.BarrierGhost) then
            self.BarrierGhost:Remove()
        end
    end

    hook.Add("PostDrawTranslucentRenderables", "WW2BarrierBuilderHologram", function(_, drawingSkybox)
        if drawingSkybox then return end

        local owner = LocalPlayer()
        if not IsValid(owner) or not owner:Alive() then return end

        local weapon = owner:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= "weapon_barrier_builder" then return end

        local building = weapon:GetBuilding()
        local position, angles, valid
        local progress = 1

        if building then
            position = weapon:GetBuildPosition()
            angles = weapon:GetBuildAngles()
            valid = true
            progress = math.Clamp(1 - (weapon:GetBuildEndsAt() - CurTime()) / weapon.BuildTime, 0, 1)
        else
            position, angles, valid = weapon:GetPlacement(owner)
            valid = valid and weapon:GetBuildCooldownRemaining(owner) <= 0
        end

        if not position then return end

        local ghost = weapon:GetBarrierGhost()
        if not IsValid(ghost) then return end

        local color = building and buildingGhostColor or (valid and validGhostColor or blockedGhostColor)
        local renderMatrix = Matrix()
        renderMatrix:SetScale(Vector(1, 1, building and math.max(progress, 0.03) or 1))

        ghost:SetPos(position)
        ghost:SetAngles(angles)
        ghost:SetColor(color)
        ghost:EnableMatrix("RenderMultiply", renderMatrix)
        ghost:SetupBones()

        render.SuppressEngineLighting(true)
        render.SetBlend((color.a / 255) * (building and Lerp(progress, 0.35, 1) or 1))
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        ghost:DrawModel()
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        render.SuppressEngineLighting(false)
    end)
end
