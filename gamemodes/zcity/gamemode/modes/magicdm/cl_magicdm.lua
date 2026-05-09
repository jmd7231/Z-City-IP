MODE.name = "magicdm"

local MODE = MODE

local fighter = {
	objective = "Kill everyone with magic.",
	name = "Fighter",
	color1 = Color(0, 120, 190)
}

function MODE:HUDPaint()
	if not lply:Alive() then return end
	if zb.ROUND_START + 8.5 < CurTime() then return end

	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

	draw.SimpleText("Homicide | Magic DM", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local colorRole = fighter.color1
	colorRole.a = 255 * fade
	draw.SimpleText("You are a " .. fighter.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(fighter.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
