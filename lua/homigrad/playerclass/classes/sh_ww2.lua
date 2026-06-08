local WW2_CLASSES = {
    ww2_german = "models/player/dod_german_exp_pm.mdl",
    ww2_american = "models/player/dod_american_exp_pm.mdl",
}

local function ResetModelAppearance(ply, model)
    ply:SetModel(model)
    ply:SetSkin(0)
    ply:SetSubMaterial()
    ply:SetColor(color_white)
    ply:SetPlayerColor(Vector(1, 1, 1))
    ply:SetNWVector("PlayerColor", Vector(1, 1, 1))

    for _, bodygroup in ipairs(ply:GetBodyGroups()) do
        ply:SetBodygroup(bodygroup.id, 0)
    end

    ply:SetNetVar("Accessories", "none")
end

local function RegisterWW2Class(name, model)
    local CLASS = player.RegClass(name)

    function CLASS.Off(self)
        if CLIENT then return end
    end

    function CLASS.On(self)
        if CLIENT then return end

        local appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
        appearance.AModel = model
        appearance.AAttachments = "none"
        appearance.AClothes = {}
        appearance.ABodygroups = {}
        appearance.AColor = color_white
        self.CurAppearance = appearance

        ResetModelAppearance(self, model)

        -- Some model/bodygroup state is rebuilt at the end of the spawn tick.
        -- Reapply the clean WW2 appearance after that work has completed.
        timer.Simple(0, function()
            if not IsValid(self) or self.PlayerClassName ~= name then return end
            ResetModelAppearance(self, model)
        end)
    end

    function CLASS.Guilt(self, victim)
        if CLIENT then return end

        if victim:GetPlayerClass() == self:GetPlayerClass() then
            return 1
        end
    end

    CLASS.CanUseDefaultPhrase = true
    CLASS.CanEmitRNDSound = true
    CLASS.CanUseGestures = true
end

for name, model in pairs(WW2_CLASSES) do
    RegisterWW2Class(name, model)
end
