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
local accentColor = Color(235, 175, 65)
local panelColor = Color(12, 14, 18, 215)
local panelBorderColor = Color(255, 255, 255, 24)

surface.CreateFont("ZB_BattleRoyaleTitle", {
    font = "Roboto",
    size = 18,
    weight = 700,
    extended = true,
})

surface.CreateFont("ZB_BattleRoyaleTimer", {
    font = "Roboto",
    size = 30,
    weight = 800,
    extended = true,
})

surface.CreateFont("ZB_BattleRoyaleStat", {
    font = "Roboto",
    size = 17,
    weight = 600,
    extended = true,
})

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

    local screenWidth, screenHeight = ScrW(), ScrH()
    local radius = getRadius()
    local delta = ply:GetPos() - zone.center
    delta.z = 0

    local distanceToEdge = radius - delta:Length()
    local outside = distanceToEdge < 0
    local statusColor = outside and warningColor or safeColor
    local statusLabel
    local statusTime = ""

    if CurTime() < zone.shrinkStart then
        local timeLeft = math.max(math.ceil(zone.shrinkStart - CurTime()), 0)
        statusLabel = "SAFE ZONE SHRINKS IN"
        statusTime = string.FormattedTime(timeLeft, "%02i:%02i")
    elseif CurTime() < zone.shrinkEnd then
        local timeLeft = math.max(math.ceil(zone.shrinkEnd - CurTime()), 0)
        statusLabel = "SAFE ZONE CLOSING"
        statusTime = string.FormattedTime(timeLeft, "%02i:%02i")
    elseif zone.phase < zone.phaseCount then
        statusLabel = "NEXT PHASE INCOMING"
    else
        statusLabel = "FINAL SAFE ZONE"
    end

    local mainWidth = math.Clamp(screenWidth * 0.34, 340, 520)
    local mainHeight = 72
    local statGap = 8
    local statHeight = 38
    local mainX = math.floor((screenWidth - mainWidth) * 0.5)
    local mainY = math.max(math.floor(screenHeight * 0.025), 16)
    local halfStatWidth = (mainWidth - statGap) * 0.5
    local statY = mainY + mainHeight + statGap

    draw.RoundedBox(8, mainX, mainY, mainWidth, mainHeight, panelColor)
    surface.SetDrawColor(panelBorderColor)
    surface.DrawOutlinedRect(mainX, mainY, mainWidth, mainHeight, 1)
    draw.RoundedBoxEx(8, mainX, mainY, mainWidth, 4, statusColor, true, true, false, false)

    draw.SimpleText(statusLabel, "ZB_BattleRoyaleTitle", mainX + mainWidth * 0.5, mainY + 14, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    if statusTime ~= "" then
        draw.SimpleText(statusTime, "ZB_BattleRoyaleTimer", mainX + mainWidth * 0.5, mainY + 34, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("BATTLE ROYALE", "ZB_BattleRoyaleTimer", mainX + mainWidth * 0.5, mainY + 34, accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    draw.RoundedBox(7, mainX, statY, halfStatWidth, statHeight, panelColor)
    draw.RoundedBox(7, mainX + halfStatWidth + statGap, statY, halfStatWidth, statHeight, panelColor)
    surface.SetDrawColor(panelBorderColor)
    surface.DrawOutlinedRect(mainX, statY, halfStatWidth, statHeight, 1)
    surface.DrawOutlinedRect(mainX + halfStatWidth + statGap, statY, halfStatWidth, statHeight, 1)

    draw.SimpleText("SURVIVORS  " .. aliveCount(), "ZB_BattleRoyaleStat", mainX + halfStatWidth * 0.5, statY + statHeight * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("PHASE  " .. zone.phase .. " / " .. zone.phaseCount, "ZB_BattleRoyaleStat", mainX + halfStatWidth + statGap + halfStatWidth * 0.5, statY + statHeight * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local edgeDistance = math.ceil(math.abs(distanceToEdge) / 52.49)
    local edgeText = outside and (edgeDistance .. "m OUTSIDE SAFE ZONE") or (edgeDistance .. "m TO ZONE EDGE")
    draw.SimpleText(edgeText, "ZB_BattleRoyaleStat", screenWidth * 0.5, statY + statHeight + 9, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    if outside then
        local warningWidth = math.min(460, screenWidth - 32)
        draw.RoundedBox(7, (screenWidth - warningWidth) * 0.5, screenHeight * 0.18 - 20, warningWidth, 40, Color(55, 8, 8, 220))
        draw.SimpleText("RETURN TO THE SAFE ZONE  |  " .. zone.damage .. " DAMAGE/SEC", "ZB_BattleRoyaleTitle", screenWidth * 0.5, screenHeight * 0.18, warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if (zb.ROUND_START or 0) + MODE.CombatDelay > CurTime() then
        local combatTime = math.max(math.ceil((zb.ROUND_START + MODE.CombatDelay) - CurTime()), 0)
        local graceText = "SCAVENGE NOW  |  COMBAT UNLOCKS IN " .. combatTime
        local graceWidth = math.Clamp(screenWidth * 0.42, 380, 620)
        local graceX = (screenWidth - graceWidth) * 0.5
        local graceY = screenHeight * 0.74

        draw.RoundedBox(7, graceX, graceY, graceWidth, 42, panelColor)
        draw.SimpleText(graceText, "ZB_BattleRoyaleTitle", screenWidth * 0.5, graceY + 21, accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
