local MODE = MODE

MODE.base = "dm"
MODE.name = "magicdm"
MODE.PrintName = "Magic DM"
MODE.Chance = 0.04

local deathmatch_nozone = ConVarExists("deathmatch_nozone") and GetConVar("deathmatch_nozone") or CreateConVar("deathmatch_nozone", 0, FCVAR_REPLICATED, "Allows to disable deathmatch mode zone.", 0, 1)

function MODE:RoundStart()
	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true

		ply:StripWeapons()
		ply:Give("magic")
		ply:SelectWeapon("magic")

		if ply.organism then
			ply.organism.recoilmul = 0.5
		end

		timer.Simple(0.1, function()
			if not IsValid(ply) then return end
			ply.noSound = false
			ply:SetSuppressPickupNotices(false)
		end)

		zb.GiveRole(ply, "Fighter", Color(190, 15, 15))
		ply:SetNetVar("CurPluv", "pluvboss")
	end
end

local cooldown = CurTime()
hook.Add("Think", "magicdm_zone_shrink", function()
	local rnd = CurrentRound()
	if not rnd or rnd.name ~= "magicdm" then return end
	if (zb.ROUND_START or CurTime()) + 20 > CurTime() then return end
	if cooldown > CurTime() then return end
	if deathmatch_nozone:GetBool() then return end

	cooldown = CurTime() + 0.5

	local pos = zonepoint
	if not pos then return end

	local radius = MODE.GetZoneRadius()
	local radiusSqr = radius * radius

	for _, ent in ents.Iterator() do
		if pos:DistToSqr(ent:GetPos()) > radiusSqr and ent:IsPlayer() then
			hg.LightStunPlayer(ent)
		end
	end
end)
