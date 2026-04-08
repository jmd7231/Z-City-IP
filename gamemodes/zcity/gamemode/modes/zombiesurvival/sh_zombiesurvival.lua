local MODE = MODE

MODE.name = "zombiesurvival"
MODE.PrintName = "Zombie Survival"

MODE.Chance = 0.08
MODE.ForBigMaps = false
MODE.LootSpawn = false
MODE.ROUND_TIME = 480
MODE.OverrideSpawn = true

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end
