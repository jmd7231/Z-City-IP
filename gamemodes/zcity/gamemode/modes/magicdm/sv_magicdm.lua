local MODE = MODE

MODE.base = "dm"
MODE.name = "magicdm"
MODE.PrintName = "Magic DM"
MODE.Chance = 0.04

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
