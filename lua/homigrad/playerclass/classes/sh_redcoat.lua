local CLASS = player.RegClass("redcoat")

CLASS.Name = "Redcoat"
CLASS.Color = Color(190, 30, 30)
CLASS.Model = "models/player/british/light_b/light_b.mdl"

function CLASS.Off(self)
    if CLIENT then return end
end

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)

    local appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    appearance.AAttachments = ""
    appearance.AColthes = ""

    self:SetNWString("PlayerName", "Redcoat " .. appearance.AName)
    self:SetPlayerColor(CLASS.Color:ToVector())
    self:SetModel(CLASS.Model)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")

    local inv = self:GetNetVar("Inventory", {})
    inv.Weapons = inv.Weapons or {}
    inv.Weapons.hg_sling = true
    self:SetNetVar("Inventory", inv)

    self.CurAppearance = appearance
end
