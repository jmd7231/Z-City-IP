local MODE = MODE

MODE.name = "battleroyale"

MODE.CombatDelay = 12
MODE.AllowedMap = "gm_fork"
MODE.MapWorldMin = -15400
MODE.MapWorldMax = 15400
-- Asset names from the original gm_fork Battle Royale content. The content addon
-- must be mounted for these textures to render; the map UI has a grid fallback.
MODE.MapMaterial = "entities/br_worldmap.png"
MODE.CompassMaterial = "entities/bussola.png"

function MODE:HG_MovementCalc_2(mul, ply, cmd, mv)
    if (zb.ROUND_START or 0) + self.CombatDelay <= CurTime() or not cmd then return end

    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)

    if mv then
        mv:RemoveKey(IN_ATTACK)
        mv:RemoveKey(IN_ATTACK2)
    end

    local hands = IsValid(ply) and ply:GetWeapon("weapon_hands_sh")
    if IsValid(hands) then
        cmd:SelectWeapon(hands)
        if SERVER then ply:SelectWeapon("weapon_hands_sh") end
    end
end

function MODE:PlayerCanLegAttack()
    if (zb.ROUND_START or 0) + self.CombatDelay > CurTime() then
        return false
    end
end
