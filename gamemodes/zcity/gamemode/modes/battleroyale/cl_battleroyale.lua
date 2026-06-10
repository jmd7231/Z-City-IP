local MODE = MODE

MODE.name = "battleroyale"

local zone = {
    center = Vector(0, 0, 0),
    startRadius = 0,
    targetRadius = 0,
    shrinkStart = 0,
    shrinkEnd = 0,
    phase = 0,
    phaseCount = 0,
    damage = 0,
}

local circleMaterial = Material("cable/redlaser")
local warningColor = Color(235, 65, 45)
local safeColor = Color(80, 190, 110)
local panelColor = Color(12, 14, 18, 205)

local function getRadius()
    local fraction = zone.shrinkEnd > zone.shrinkStart and math.TimeFraction(zone.shrinkStart, zone.shrinkEnd, CurTime()) or 1
    return Lerp(math.Clamp(fraction, 0, 1), zone.startRadius, zone.targetRadius)
end

local function aliveCount()
    local count = 0
    for _, ply in player.Iterator() do
        if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR and not (ply.organism and ply.organism.incapacitated) then
            count = count + 1
        end
    end
    return count
end

net.Receive("zb_battleroyale_zone", function()
    zone.center = net.ReadVector()
    zone.startRadius = net.ReadFloat()
    zone.targetRadius = net.ReadFloat()
    zone.shrinkStart = net.ReadFloat()
    zone.shrinkEnd = net.ReadFloat()
    zone.phase = net.ReadUInt(4)
    zone.phaseCount = net.ReadUInt(4)
    zone.damage = net.ReadUInt(8)
end)

net.Receive("zb_battleroyale_end", function()
    local winner = net.ReadEntity()
    local name = IsValid(winner) and winner:Nick() or "Nobody"

    chat.AddText(Color(235, 175, 65), "[Battle Royale] ", color_white, name .. " is the last survivor!")
    surface.PlaySound("ambient/alarms/warningbell1.wav")
end)

function MODE:PostDrawTranslucentRenderables(depth, skybox, draw3DSkybox)
    if skybox or draw3DSkybox or zone.startRadius <= 0 then return end

    local radius = getRadius()
    local segments = 96
    local previous

    render.SetMaterial(circleMaterial)
    for index = 0, segments do
        local angle = math.rad(index / segments * 360)
        local point = zone.center + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 12)

        if previous then
            render.DrawBeam(previous, point, 12, 0, 1, Color(235, 65, 45, 180))
        end

        previous = point
    end
end

function MODE:RenderScreenspaceEffects()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNWBool("BattleRoyaleOutsideZone", false) then return end

    DrawColorModify({
        ["$pp_colour_addr"] = 0.06,
        ["$pp_colour_addg"] = -0.03,
        ["$pp_colour_addb"] = -0.03,
        ["$pp_colour_brightness"] = -0.04,
        ["$pp_colour_contrast"] = 1.08,
        ["$pp_colour_colour"] = 0.72,
        ["$pp_colour_mulr"] = 0.2,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0,
    })
end

function MODE:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) or zone.startRadius <= 0 then return end

    local radius = getRadius()
    local delta = ply:GetPos() - zone.center
    delta.z = 0
    local distanceToEdge = radius - delta:Length()
    local outside = distanceToEdge < 0
    local statusColor = outside and warningColor or safeColor
    local statusText
    local timeLeft

    if CurTime() < zone.shrinkStart then
        timeLeft = math.max(math.ceil(zone.shrinkStart - CurTime()), 0)
        statusText = "ZONE SHRINKS IN " .. string.FormattedTime(timeLeft, "%02i:%02i")
    elseif CurTime() < zone.shrinkEnd then
        timeLeft = math.max(math.ceil(zone.shrinkEnd - CurTime()), 0)
        statusText = "ZONE CLOSING  " .. string.FormattedTime(timeLeft, "%02i:%02i")
    else
        statusText = zone.phase < zone.phaseCount and "NEXT PHASE INCOMING" or "FINAL ZONE"
    end

    local width, height = 310, 112
    local x, y = ScrW() - width - 24, 24

    draw.RoundedBox(8, x, y, width, height, panelColor)
    draw.SimpleText("BATTLE ROYALE", "ZB_HomicideMedium", x + 14, y + 10, Color(235, 175, 65), TEXT_ALIGN_LEFT)
    draw.SimpleText("Survivors: " .. aliveCount(), "ZB_InterfaceMedium", x + 14, y + 43, color_white, TEXT_ALIGN_LEFT)
    draw.SimpleText("Phase: " .. zone.phase .. "/" .. zone.phaseCount, "ZB_InterfaceMedium", x + width - 14, y + 43, color_white, TEXT_ALIGN_RIGHT)
    draw.SimpleText(statusText, "ZB_InterfaceMedium", x + 14, y + 72, statusColor, TEXT_ALIGN_LEFT)

    local edgeDistance = math.ceil(math.abs(distanceToEdge) / 52.49)
    local edgeText = outside and ("OUTSIDE: " .. edgeDistance .. "m") or ("Edge: " .. edgeDistance .. "m")
    draw.SimpleText(edgeText, "ZB_InterfaceMedium", x + width - 14, y + 72, statusColor, TEXT_ALIGN_RIGHT)

    if outside then
        draw.SimpleText("RETURN TO THE SAFE ZONE - " .. zone.damage .. " DAMAGE/SEC", "ZB_HomicideMedium", ScrW() * 0.5, ScrH() * 0.18, warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if (zb.ROUND_START or 0) + MODE.CombatDelay > CurTime() then
        local combatTime = math.max(math.ceil((zb.ROUND_START + MODE.CombatDelay) - CurTime()), 0)
        draw.SimpleText("SCAVENGE - COMBAT UNLOCKS IN " .. combatTime, "ZB_HomicideMedium", ScrW() * 0.5, ScrH() * 0.75, Color(235, 175, 65), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
