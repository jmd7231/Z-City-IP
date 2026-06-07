local MODE = MODE

MODE.name = "ww2tdm"
MODE.base = "tdm"
MODE.PrintName = "WW2 Team Deathmatch"

local function RegisterWW2Class(name)
    local class = player.RegClass(name)

    function class.On(ply)
        if CLIENT then return end

        -- WW2 models are applied by the mode. Do not run the normal homicide
        -- appearance system here, because it replaces the fixed DOD models.
        ply:SetNetVar("Accessories", "")
        ply.CurAppearance = {}
    end

    function class.Off()
    end

    function class.Guilt(ply, victim)
        if victim:GetPlayerClass() == ply:GetPlayerClass() then
            return 1
        end
    end

    class.CanUseDefaultPhrase = true
    class.CanEmitRNDSound = true
    class.CanUseGestures = true
end

RegisterWW2Class("ww2_german")
RegisterWW2Class("ww2_american")

-- This mode has fixed loadouts and no TDM buy phase.
function MODE:HG_MovementCalc_2()
end
