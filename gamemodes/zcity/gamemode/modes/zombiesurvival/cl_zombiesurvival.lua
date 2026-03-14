local MODE = MODE

local modeTitleColor = Color(0, 162, 255)
local roleZombieColor = Color(130, 220, 90)
local roleSurvivorColor = Color(70, 130, 200)
local objectiveZombieColor = Color(180, 220, 120)
local objectiveSurvivorColor = Color(160, 210, 255)

net.Receive("ZS_RoundStart", function()
	surface.PlaySound("ambient/alarms/warningbell1.wav")
	zb.RemoveFade()
	chat.AddText(Color(130, 220, 90), "[Zombie Survival] ", color_white, "A Zombie Alpha is hunting the survivors.")
end)

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
	if zb.ROUND_START + 8.5 < CurTime() then return end
	if not lply:Alive() then return end

	zb.RemoveFade()

	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local roleName = (lply.role and lply.role.name) or "Survivor"
	local isZombieRole = roleName == "Zombie" or roleName == "Zombie Alpha"
	local roleColor = isZombieRole and roleZombieColor or roleSurvivorColor
	local objectiveColor = isZombieRole and objectiveZombieColor or objectiveSurvivorColor
	local objective = isZombieRole and "Infect all survivors before Alpha is killed." or "Survive and kill the Zombie Alpha."

	draw.SimpleText("Zombie Survival", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(modeTitleColor.r, modeTitleColor.g, modeTitleColor.b, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("You are " .. roleName, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, Color(roleColor.r, roleColor.g, roleColor.b, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(objectiveColor.r, objectiveColor.g, objectiveColor.b, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

net.Receive("ZS_RoundEnd", function()
	local winner = net.ReadString()
	if winner == "zombies" then
		chat.AddText(Color(130, 220, 90), "[Zombie Survival] ", color_white, "The infection consumed everyone.")
	elseif winner == "survivors" then
		chat.AddText(Color(70, 130, 200), "[Zombie Survival] ", color_white, "The Zombie Alpha was killed.")
	else
		chat.AddText(Color(180, 180, 180), "[Zombie Survival] ", color_white, "Round ended.")
	end
end)
