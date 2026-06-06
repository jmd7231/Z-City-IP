local MODE = MODE

MODE.name = "revolutionarywar"

local teams = {
    [0] = {
        objective = "Defeat the Redcoats.",
        name = "an American",
        color = Color(35, 90, 180),
    },
    [1] = {
        objective = "Defeat the Americans.",
        name = "a Redcoat",
        color = Color(190, 30, 30),
    },
}

function MODE:HUDPaint()
    local startTime = zb.ROUND_START or CurTime()
    local timeLeft = math.max(startTime + (zb.ROUND_TIME or self.ROUND_TIME) - CurTime(), 0)
    draw.SimpleText(string.FormattedTime(timeLeft, "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if startTime + 8 < CurTime() or not lply:Alive() then return end

    zb.RemoveFade()

    local teamData = teams[lply:Team()]
    if not teamData then return end

    local fade = math.Clamp(startTime + 8 - CurTime(), 0, 1)
    local roleColor = ColorAlpha(teamData.color, 255 * fade)

    draw.SimpleText("ZBattle | Revolutionary War", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("You are " .. teamData.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(teamData.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
