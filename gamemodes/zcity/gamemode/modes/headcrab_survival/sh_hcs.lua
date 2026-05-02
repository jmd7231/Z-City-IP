local MODE = MODE

MODE.name = "headcrab_survival"
MODE.PrintName = "Head Crab Survival"
MODE.base = "dm"
MODE.randomSpawns = true
MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.Chance = 0.03

-- Keep everyone on one side to remove T vs CT split.
function MODE:Intermission()
	game.CleanUpMap()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ApplyAppearance(ply)
		ply:SetupTeam(1)
	end
end

function MODE:ShouldRoundEnd()
	return #zb:CheckAlive(true) <= 0
end
