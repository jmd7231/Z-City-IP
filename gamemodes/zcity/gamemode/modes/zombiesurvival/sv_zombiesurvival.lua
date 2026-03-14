local MODE = MODE

util.AddNetworkString("ZS_RoundStart")
util.AddNetworkString("ZS_RoundEnd")

MODE.ZombieClass = "headcrabzombie"
MODE.HeadcrabAmount = 12 -- initial wave
MODE.HeadcrabSpawnPerTick = 12
MODE.HeadcrabSpawnInterval = 10
MODE.HeadcrabMaxAlive = 500
MODE.HeadcrabSpawnClasses = {
	"info_player_start",
	"info_player_human",
	"info_player_zombie",
	"info_player_counterterrorist",
	"info_player_terrorist",
}

function MODE:Intermission()
	game.CleanUpMap()
	self.RoundStartGraceEnd = nil
	timer.Remove("ZS_HeadcrabSpawner")

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:KillSilent()
		ply:SetupTeam(0)
		ply.isTraitor = false
		ply.MainTraitor = false
		ply.ZSIsZombie = false
		ply.ZSIsAlpha = false
		ply.ZSTurning = nil
		ply.ZSHeadcrabThreatUntil = nil
	end

	local candidates = {}
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		candidates[#candidates + 1] = ply
	end

	if #candidates > 0 then
		local alpha = table.Random(candidates)
		alpha.isTraitor = true
		alpha.MainTraitor = true
		alpha.ZSIsZombie = true
		alpha.ZSIsAlpha = true
	end
end

function MODE:CanLaunch()
	local active = 0
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then
			active = active + 1
		end
	end

	return active >= 3
end


function MODE:GetTeamSpawn()
	local team0 = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
	local team1 = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))

	if not team0 or #team0 == 0 then
		team0 = {zb:GetRandomSpawn()}
	end

	if not team1 or #team1 == 0 then
		team1 = {zb:GetRandomSpawn()}
	end

	return team0, team1
end

function MODE:GetHeadcrabSpawnPoints()
	local spawnPoints = {}
	for _, className in ipairs(self.HeadcrabSpawnClasses) do
		for _, ent in ipairs(ents.FindByClass(className)) do
			spawnPoints[#spawnPoints + 1] = ent
		end
	end

	return spawnPoints
end

function MODE:GetAliveHeadcrabCount()
	self.SpawnedZombieHeadcrabs = self.SpawnedZombieHeadcrabs or {}
	local alive = {}

	for _, ent in ipairs(self.SpawnedZombieHeadcrabs) do
		if IsValid(ent) and ent:GetClass() == "npc_headcrab" and ent:Health() > 0 then
			alive[#alive + 1] = ent
		end
	end

	self.SpawnedZombieHeadcrabs = alive
	return #alive
end

function MODE:GetAlphaPlayer()
	for _, ply in player.Iterator() do
		if ply.ZSIsAlpha and ply:Team() ~= TEAM_SPECTATOR then
			return ply
		end
	end
end

function MODE:ApplyHeadcrabAlphaRelationship(headcrab)
	if not IsValid(headcrab) or not headcrab:IsNPC() then return end

	local alpha = self:GetAlphaPlayer()
	if not IsValid(alpha) then return end

	headcrab:AddEntityRelationship(alpha, D_LI, 99)
	alpha:AddEntityRelationship(headcrab, D_LI, 99)

	if headcrab.SetEnemy then
		headcrab:SetEnemy(NULL)
	end
end

function MODE:GiveZombieAttackSWEP(ply)
	if not IsValid(ply) then return end

	local zombieWep = ply:GetWeapon("weapon_zombclaws")
	if not IsValid(zombieWep) then
		zombieWep = ply:Give("weapon_zombclaws")
	end

	if not IsValid(zombieWep) then
		zombieWep = ply:GetWeapon("weapon_hands_sh")
		if not IsValid(zombieWep) then
			zombieWep = ply:Give("weapon_hands_sh")
		end
	end

	if IsValid(zombieWep) then
		ply:SelectWeapon(zombieWep:GetClass())
	end
end

function MODE:EnsureZombieLoadout(ply)
	if not IsValid(ply) then return end
	if not ply.ZSIsZombie then return end

	self:GiveZombieAttackSWEP(ply)

	if ply.ZSIsAlpha then
		self:RefreshHeadcrabRelationships()
	end
end

function MODE:RefreshHeadcrabRelationships()
	self.SpawnedZombieHeadcrabs = self.SpawnedZombieHeadcrabs or {}

	for _, headcrab in ipairs(self.SpawnedZombieHeadcrabs) do
		self:ApplyHeadcrabAlphaRelationship(headcrab)
	end
end

function MODE:SpawnAmbientHeadcrabs(spawnCount)
	local spawnPoints = self:GetHeadcrabSpawnPoints()
	if #spawnPoints == 0 then return 0 end

	local aliveCount = self:GetAliveHeadcrabCount()
	local freeSlots = math.max((self.HeadcrabMaxAlive or 500) - aliveCount, 0)
	if freeSlots <= 0 then return 0 end

	local toSpawn = math.min(spawnCount or self.HeadcrabAmount, freeSlots)
	local spawned = 0

	for _ = 1, toSpawn do
		local spawnEnt = spawnPoints[math.random(#spawnPoints)]
		if not IsValid(spawnEnt) then continue end

		local headcrab = ents.Create("npc_headcrab")
		if not IsValid(headcrab) then continue end

		headcrab:SetPos(spawnEnt:GetPos() + Vector(0, 0, 6))
		headcrab:SetAngles(Angle(0, math.random(0, 359), 0))
		headcrab:Spawn()
		headcrab:Activate()
		self:ApplyHeadcrabAlphaRelationship(headcrab)
		self.SpawnedZombieHeadcrabs[#self.SpawnedZombieHeadcrabs + 1] = headcrab
		spawned = spawned + 1
	end

	return spawned
end

function MODE:StartHeadcrabSpawner()
	timer.Remove("ZS_HeadcrabSpawner")
	timer.Create("ZS_HeadcrabSpawner", self.HeadcrabSpawnInterval, 0, function()
		if CurrentRound().name ~= "zombiesurvival" then
			timer.Remove("ZS_HeadcrabSpawner")
			return
		end

		MODE:SpawnAmbientHeadcrabs(MODE.HeadcrabSpawnPerTick)
	end)
end

function MODE:RoundStart()
	self.RoundStartGraceEnd = CurTime() + 5
	self.SpawnedZombieHeadcrabs = {}
	self:SpawnAmbientHeadcrabs(self.HeadcrabAmount)
	self:StartHeadcrabSpawner()

	net.Start("ZS_RoundStart")
	net.Broadcast()
end

function MODE:MakeZombie(ply, isAlpha)
	if not IsValid(ply) then return end

	ply:SetPlayerClass(self.ZombieClass)
	ply:StripWeapons()
	self:GiveZombieAttackSWEP(ply)
	timer.Simple(0, function()
		if IsValid(ply) and ply.ZSIsZombie then
			MODE:EnsureZombieLoadout(ply)
		end
	end)
	ply.isTraitor = true
	ply.MainTraitor = isAlpha and true or false
	ply.ZSIsZombie = true
	ply.ZSIsAlpha = isAlpha and true or false
	ply:SetNetVar("flashlight", false)

	if isAlpha then
		zb.GiveRole(ply, "Zombie Alpha", Color(130, 220, 90))
		self:EnsureZombieLoadout(ply)
	else
		zb.GiveRole(ply, "Zombie", Color(100, 170, 70))
	end
end

function MODE:MakeSurvivor(ply)
	if not IsValid(ply) then return end

	ply:StripWeapons()
	if ApplyAppearance then
		ApplyAppearance(ply, nil, nil, nil, true)
	end
	local hands = ply:Give("weapon_hands_sh")
	if IsValid(hands) then
		ply:SelectWeapon("weapon_hands_sh")
	end
	ply:Give("weapon_pocketknife")
	ply:Give("weapon_bandage_sh")
	ply:Give("weapon_smallconsumable")

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_flashlight"] = true
	ply:SetNetVar("Inventory", inv)

	ply.isTraitor = false
	ply.MainTraitor = false
	ply.ZSIsZombie = false
	ply.ZSIsAlpha = false
	zb.GiveRole(ply, "Survivor", Color(70, 130, 200))
end

function MODE:GiveEquipment()
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		if ApplyAppearance then
			ApplyAppearance(ply, nil, nil, nil, true)
		end

		ply:Spawn()
		ply:GetRandomSpawn()
		if not ply:Alive() then continue end

		if ply.ZSIsAlpha then
			self:MakeZombie(ply, true)
		else
			self:MakeSurvivor(ply)
		end
	end
end

function MODE:GetAlphaAlive()
	for _, ply in player.Iterator() do
		if ply.ZSIsAlpha and ply:Alive() and (not ply.organism or not ply.organism.incapacitated) then
			return ply
		end
	end
end

function MODE:GetAliveSurvivorCount()
	local count = 0
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if ply.ZSIsZombie then continue end
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end
		count = count + 1
	end
	return count
end

function MODE:ShouldRoundEnd()
	if self.RoundStartGraceEnd and CurTime() < self.RoundStartGraceEnd then
		return false
	end

	local alpha = self:GetAlphaAlive()
	if not IsValid(alpha) then
		self.ZSWinner = "survivors"
		return true
	end

	if self:GetAliveSurvivorCount() == 0 then
		self.ZSWinner = "zombies"
		return true
	end

	return false
end

function MODE:EndRound()
	timer.Remove("ZS_HeadcrabSpawner")

	if self.SpawnedZombieHeadcrabs then
		for _, ent in ipairs(self.SpawnedZombieHeadcrabs) do
			if IsValid(ent) then
				ent:Remove()
			end
		end
		self.SpawnedZombieHeadcrabs = {}
	end

	net.Start("ZS_RoundEnd")
		net.WriteString(self.ZSWinner or "draw")
	net.Broadcast()

	self.ZSWinner = nil
	self.RoundStartGraceEnd = nil

	for _, ply in player.Iterator() do
		ply.ZSHeadcrabThreatUntil = nil
	end
end

function MODE:StartZombieTurn(victim)
	if not IsValid(victim) then return end
	if victim:Team() == TEAM_SPECTATOR then return end
	if victim.ZSTurning then return end

	victim.ZSTurning = true
	victim:StripWeapons()

	timer.Simple(0.2, function()
		if not IsValid(victim) then return end
		if victim:Team() == TEAM_SPECTATOR then return end

		victim:Spawn()
		victim:GetRandomSpawn()
		self:MakeZombie(victim, false)
		victim.ZSTurning = nil
	end)
end

hook.Add("Player_Death", "ZS_InfectOnZombieKill", function(victim)
	if CurrentRound().name ~= "zombiesurvival" then return end
	if not IsValid(victim) then return end
	if victim:Team() == TEAM_SPECTATOR then return end
	if victim.ZSIsZombie then return end

	local topAttacker, topDamage = nil, 0
	for attacker, damage in pairs(zb.HarmDone[victim] or {}) do
		if not IsValid(attacker) then continue end
		if damage <= topDamage then continue end
		topDamage = damage
		topAttacker = attacker
	end

	if not IsValid(topAttacker) then return end
	if not topAttacker.ZSIsZombie then return end

	MODE:StartZombieTurn(victim)
end)

hook.Add("PlayerCanSuicide", "ZS_BlockKillbindDuringTurn", function(ply)
	if CurrentRound().name ~= "zombiesurvival" then return end
	if not IsValid(ply) then return end

	if ply.ZSTurning then
		return false
	end

	if not ply.ZSIsZombie and (ply.ZSHeadcrabThreatUntil or 0) > CurTime() then
		return false
	end

	if not ply.ZSIsZombie and ply:Alive() and (zb.ROUND_STATE == 1) then
		return false
	end

	return false
end)

hook.Add("EntityTakeDamage", "ZS_MarkHeadcrabThreatOnSurvivor", function(target, dmginfo)
	if CurrentRound().name ~= "zombiesurvival" then return end
	if not IsValid(target) or not target:IsPlayer() then return end
	if target.ZSIsZombie then return end

	local attacker = dmginfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsNPC() then return end
	if not string.StartWith(attacker:GetClass(), "npc_headcrab") then return end

	target.ZSHeadcrabThreatUntil = CurTime() + 8
end)

hook.Add("EntityTakeDamage", "ZS_BlockHeadcrabDamageToAlpha", function(target, dmginfo)
	if CurrentRound().name ~= "zombiesurvival" then return end
	if not IsValid(target) or not target:IsPlayer() then return end
	if not target.ZSIsAlpha then return end

	local attacker = dmginfo:GetAttacker()
	local inflictor = dmginfo:GetInflictor()
	local attackerClass = IsValid(attacker) and attacker:GetClass() or ""
	local inflictorClass = IsValid(inflictor) and inflictor:GetClass() or ""

	if (not string.StartWith(attackerClass, "npc_headcrab")) and (not string.StartWith(inflictorClass, "npc_headcrab")) then
		return
	end

	dmginfo:SetDamage(0)
	dmginfo:ScaleDamage(0)
	return true
end)

hook.Add("PlayerSpawn", "ZS_EnsureZombieSWEPOnSpawn", function(ply)
	if CurrentRound().name ~= "zombiesurvival" then return end
	if not IsValid(ply) or not ply.ZSIsZombie then return end

	timer.Simple(0, function()
		if IsValid(ply) and CurrentRound().name == "zombiesurvival" then
			MODE:EnsureZombieLoadout(ply)
		end
	end)
end)
