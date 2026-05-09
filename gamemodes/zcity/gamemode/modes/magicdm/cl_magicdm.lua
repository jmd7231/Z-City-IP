MODE.name = "magicdm"

local MODE = MODE

local deathmatch_nozone = ConVarExists("deathmatch_nozone") and GetConVar("deathmatch_nozone") or CreateConVar("deathmatch_nozone", 0, FCVAR_REPLICATED, "Allows to disable deathmatch mode zone.", 0, 1)
local mat = Material("hmcd_dmzone")

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

hook.Add("Think", "MagicDMZoneSoundThink", function()
	if CurrentRound() and CurrentRound().name ~= "magicdm" then return end
	local station = zb.SoundStation
	if not IsValid(station) then return end
	if deathmatch_nozone:GetBool() then return end
	if not ZonePos then return end

	local radius = MODE.GetZoneRadius()
	local volume = math.Clamp((LocalPlayer():GetPos():Distance(ZonePos) - radius) + 200, 0, 200) / 200
	station:SetVolume(volume)
end)

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if (not bSkybox and not isDraw3DSkybox) and not deathmatch_nozone:GetBool() and ZonePos then
		local radius = MODE.GetZoneRadius()
		render.SetMaterial(mat)
		render.DrawSphere(ZonePos, -radius, 60, 60, color_white)
	end
end
