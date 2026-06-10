local MODE = MODE

MODE.name = "battleroyale"

MODE.CombatDelay = 12

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
