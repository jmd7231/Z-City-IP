local MODE = MODE

MODE.name = "battleroyale"

MODE.CombatDelay = 15
MODE.DeploymentHeight = 4000
MODE.DeploymentPositions = {
    -14000, -12000, -10000, -8000, -6000, -4000, -2000,
    0, 1500, 3000, 4500, 5000, 7500, 8000,
    14000, 12000, 10000, 8000, 6000, 4000, 2000,
    -1500, -3000, -4500, -5000, -7500, -8000,
}
MODE.LogoMaterial = "zcity/battleroyale/logo.png"
MODE.IconMaterial = "zcity/battleroyale/icon.png"
MODE.AllowedMap = "gm_fork"
MODE.MapWorldMin = -15400
MODE.MapWorldMax = 15400
-- Asset names from the original gm_fork Battle Royale content. The content addon
-- must be mounted for these textures to render; the map UI has a grid fallback.
MODE.MapMaterial = "entities/br_worldmap.png"
MODE.CompassMaterial = "entities/bussola.png"

function MODE:HG_MovementCalc_2(mul, ply, cmd, mv)
    local parachuting = IsValid(ply) and ply:GetNWBool("BattleRoyaleParachuting", false)
    if not parachuting and (zb.ROUND_START or 0) + self.CombatDelay <= CurTime() or not cmd then return end

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

function MODE:PlayerCanLegAttack(ply)
    if IsValid(ply) and ply:GetNWBool("BattleRoyaleParachuting", false) then
        return false
    end

    if (zb.ROUND_START or 0) + self.CombatDelay > CurTime() then
        return false
    end
end
