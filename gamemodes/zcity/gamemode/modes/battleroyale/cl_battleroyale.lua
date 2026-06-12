local MODE = MODE

MODE.name = "battleroyale"

local zone = {
    startCenter = Vector(0, 0, 0),
    targetCenter = Vector(0, 0, 0),
    startRadius = 0,
    targetRadius = 0,
    shrinkStart = 0,
    shrinkEnd = 0,
    phase = 0,
    phaseCount = 0,
    damage = 0,
}

local circleMaterial = Material("cable/redlaser")
local whiteMaterial = Material("vgui/white")
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

local function getZoneFraction()
    if zone.shrinkEnd <= zone.shrinkStart then return 1 end
    return math.Clamp(math.TimeFraction(zone.shrinkStart, zone.shrinkEnd, CurTime()), 0, 1)
end

local function getRadius()
    return Lerp(getZoneFraction(), zone.startRadius, zone.targetRadius)
end

local function getCenter()
    return zone.startCenter + (zone.targetCenter - zone.startCenter) * getZoneFraction()
end

local mapPanel
local mapWorldMin = MODE.MapWorldMin or -15400
local mapWorldMax = MODE.MapWorldMax or 15400
local mapTexture = Material(MODE.MapMaterial or "entities/br_worldmap.png", "smooth")
local compassTexture = Material(MODE.CompassMaterial or "entities/bussola.png", "smooth")
local logoTexture = Material(MODE.LogoMaterial or "zcity/battleroyale/logo.png", "smooth")
local iconTexture = Material(MODE.IconMaterial or "zcity/battleroyale/icon.png", "smooth")

local function worldToMap(pos, width, height)
    local worldMin = mapWorldMin
    local worldSize = mapWorldMax - worldMin
    local x = math.Clamp((pos.x - worldMin) / worldSize, 0, 1) * width
    local y = (1 - math.Clamp((pos.y - worldMin) / worldSize, 0, 1)) * height

    return x, y
end

local function getGridPosition(pos)
    local worldMin = mapWorldMin
    local worldSize = mapWorldMax - worldMin
    local column = math.Clamp(math.floor((pos.x - worldMin) / worldSize * 8), 0, 7)
    local row = math.Clamp(math.floor((mapWorldMax - pos.y) / worldSize * 8), 0, 7)

    return string.char(string.byte("A") + column) .. tostring(row + 1)
end

local function drawMapGrid(x, y, width, height)
    surface.SetDrawColor(255, 255, 255, 28)
    for index = 1, 7 do
        local offsetX = x + width * index / 8
        local offsetY = y + height * index / 8
        surface.DrawLine(offsetX, y, offsetX, y + height)
        surface.DrawLine(x, offsetY, x + width, offsetY)
    end

    for index = 0, 7 do
        draw.SimpleText(string.char(string.byte("A") + index), "ZB_BattleRoyaleStat", x + width * (index + 0.5) / 8, y + 5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(index + 1, "ZB_BattleRoyaleStat", x + 7, y + height * (index + 0.5) / 8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local function drawWorldMap(panel, width, height)
    local padding = 36
    local headerHeight = 86
    local mapSize = math.max(math.min(width - padding * 2, height - headerHeight - padding), 64)
    local mapX = (width - mapSize) * 0.5
    local mapY = headerHeight
    local mapWidth, mapHeight = mapSize, mapSize

    surface.SetDrawColor(12, 14, 18, 255)
    surface.DrawRect(0, 0, width, height)

    if not logoTexture:IsError() then
        local logoWidth = math.min(180, width * 0.34)
        local logoHeight = logoWidth / 2.25
        surface.SetMaterial(logoTexture)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect((width - logoWidth) * 0.5, 4, logoWidth, logoHeight)
    end

    if not mapTexture:IsError() then
        surface.SetMaterial(mapTexture)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(mapX, mapY, mapWidth, mapHeight)
    else
        surface.SetDrawColor(32, 38, 42)
        surface.DrawRect(mapX, mapY, mapWidth, mapHeight)
        draw.SimpleText("br_worldmap.png is not mounted", "ZB_BattleRoyaleTitle", width * 0.5, height * 0.5, warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    drawMapGrid(mapX, mapY, mapWidth, mapHeight)

    if not compassTexture:IsError() then
        surface.SetMaterial(compassTexture)
        surface.SetDrawColor(255, 255, 255, 210)
        surface.DrawTexturedRect(mapX, mapY, mapWidth, mapHeight)
    end

    if zone.startRadius > 0 then
        local zoneX, zoneY = worldToMap(getCenter(), mapWidth, mapHeight)
        local worldSize = mapWorldMax - mapWorldMin
        local zoneRadius = getRadius() / worldSize * mapWidth

        surface.SetDrawColor(warningColor)
        surface.DrawCircle(mapX + zoneX, mapY + zoneY, zoneRadius, warningColor.r, warningColor.g, warningColor.b, 220)
    end

    local ply = LocalPlayer()
    if IsValid(ply) then
        local playerX, playerY = worldToMap(ply:GetPos(), mapWidth, mapHeight)
        local markerX, markerY = mapX + playerX, mapY + playerY
        local yaw = math.rad(ply:EyeAngles().y)
        local direction = Vector(math.cos(yaw), -math.sin(yaw), 0)
        local right = Vector(-direction.y, direction.x, 0)
        local tipX, tipY = markerX + direction.x * 13, markerY + direction.y * 13
        local leftX, leftY = markerX - direction.x * 8 + right.x * 7, markerY - direction.y * 8 + right.y * 7
        local rightX, rightY = markerX - direction.x * 8 - right.x * 7, markerY - direction.y * 8 - right.y * 7

        surface.SetMaterial(whiteMaterial)
        surface.SetDrawColor(accentColor)
        surface.DrawPoly({
            {x = tipX, y = tipY},
            {x = leftX, y = leftY},
            {x = rightX, y = rightY},
        })
    end
end

local function closeMap()
    if IsValid(mapPanel) then mapPanel:Remove() end
    mapPanel = nil
end

local function toggleMap()
    if IsValid(mapPanel) then
        closeMap()
        return
    end

    mapPanel = vgui.Create("DFrame")
    mapPanel:SetSize(math.min(ScrW() * 0.78, ScrH() * 0.82), math.min(ScrW() * 0.78, ScrH() * 0.82))
    mapPanel:Center()
    mapPanel:SetTitle("gm_fork World Map  |  Press M to close")
    mapPanel:SetDraggable(false)
    mapPanel:ShowCloseButton(true)
    mapPanel:MakePopup()
    mapPanel.OnRemove = function() mapPanel = nil end

    local canvas = vgui.Create("DPanel", mapPanel)
    canvas:Dock(FILL)
    canvas.Paint = drawWorldMap
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
    zone.startCenter = net.ReadVector()
    zone.targetCenter = net.ReadVector()
    zone.startRadius = net.ReadFloat()
    zone.targetRadius = net.ReadFloat()
    zone.shrinkStart = net.ReadFloat()
    zone.shrinkEnd = net.ReadFloat()
    zone.phase = net.ReadUInt(4)
    zone.phaseCount = net.ReadUInt(4)
    zone.damage = net.ReadUInt(8)
end)

net.Receive("zb_battleroyale_end", function()
    closeMap()

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
        local point = getCenter() + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 12)

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

function MODE:PlayerButtonDown(ply, key)
    if ply ~= LocalPlayer() or key ~= KEY_M or string.lower(game.GetMap()) ~= (self.AllowedMap or "gm_fork") then return end
    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    toggleMap()
end

function MODE:CreateMove(cmd)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:GetNWBool("BattleRoyaleParachuting", false) and not ply.Parachuting then return end

    local shake = math.sin(RealTime() * 35) * 0.01
    cmd:SetViewAngles(cmd:GetViewAngles() + Angle(shake, shake, 0))
end

function MODE:ShutDown()
    closeMap()
end

function MODE:CalcView(ply, origin, angles, fov)
    if not IsValid(ply) or not ply:GetNWBool("BattleRoyaleThirdPerson", false) then return end

    local distance = ply:InVehicle() and 210 or 90
    local trace = util.TraceHull({
        start = origin,
        endpos = origin - angles:Forward() * distance,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        filter = ply,
        mask = MASK_SOLID,
    })

    return {
        origin = trace.HitPos + trace.HitNormal * 4,
        angles = angles,
        fov = fov,
        drawviewer = true,
    }
end

function MODE:ShouldDrawLocalPlayer(ply)
    if IsValid(ply) and ply:GetNWBool("BattleRoyaleThirdPerson", false) then
        return true
    end
end

function MODE:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) or zone.startRadius <= 0 then return end

    local screenWidth, screenHeight = ScrW(), ScrH()
    local heading = math.NormalizeAngle(ply:EyeAngles().y)
    local directions = {"E", "NE", "N", "NW", "W", "SW", "S", "SE"}
    local directionIndex = math.floor(((heading + 22.5) % 360) / 45) + 1
    local gridPosition = getGridPosition(ply:GetPos())

    if not iconTexture:IsError() then
        surface.SetMaterial(iconTexture)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(screenWidth - 56, 18, 32, 32)
    end

    draw.SimpleText(directions[directionIndex] .. "  |  " .. gridPosition .. "  |  M: MAP  |  T: CAMERA", "ZB_BattleRoyaleStat", screenWidth - 64, 24, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    if ply:GetNWBool("BattleRoyaleParachuting", false) then
        draw.SimpleText("PARACHUTING  |  W/S: SPEED  |  HOLD E: FLARE", "ZB_BattleRoyaleTitle", screenWidth * 0.5, screenHeight * 0.68, accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local radius = getRadius()
    local delta = ply:GetPos() - getCenter()
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
