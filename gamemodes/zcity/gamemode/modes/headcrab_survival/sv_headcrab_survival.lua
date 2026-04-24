local MODE = MODE

MODE.name = "headcrab_survival"
MODE.PrintName = "Head Crab Survival"
MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.randomSpawns = true
MODE.Chance = 0.00

MODE.MaxHeadcrabs = 1000
MODE.SpawnTick = 0.35
MODE.MinBatchSpawn = 3
MODE.MaxBatchSpawn = 9
MODE.RoundTimeLimit = 8 * 60

local loadouts = {
	{primary = "weapon_mp5", secondary = "weapon_glock17", ammo = 5, ammo2 = 4, armor = {"vest3", "helmet1"}},
	{primary = "weapon_m4a1", secondary = "weapon_hk_usp", ammo = 4, ammo2 = 3, armor = {"vest1", "helmet1"}},
	{primary = "weapon_akm", secondary = "weapon_cz75", ammo = 4, ammo2 = 3, armor = {"vest1", "helmet1"}},
	{primary = "weapon_remington870", secondary = "weapon_deagle", ammo = 4, ammo2 = 2, armor = {"vest3", "helmet1", "mask1"}},
	{primary = "weapon_vector", secondary = "weapon_revolver2", ammo = 4, ammo2 = 3, armor = {"vest3", "helmet1"}},
	{primary = "weapon_sg552", secondary = "weapon_glock18c", ammo = 4, ammo2 = 3, armor = {"vest4", "helmet1"}}
}

local utilityItems = {
	"weapon_bandage_sh",
	"weapon_tourniquet",
	"weapon_adrenaline",
	"weapon_hg_flashbang_tpik",
	"weapon_hg_smokenade_tpik"
}

local spawnClasses = {
	"npc_headcrab",
	"npc_headcrab_fast",
	"npc_headcrab_black"
}

local function AddMapPointPositions(into, pointName)
	local points = zb.GetMapPoints(pointName) or {}
	for _, point in ipairs(points) do
		if point and point.pos then
			into[#into + 1] = point.pos
		end
	end
end

local function GetRandomPlayerLoadout()
	return loadouts[math.random(#loadouts)]
end

local function GiveRandomLoadout(ply)
	local loadout = GetRandomPlayerLoadout()
	ply:Give("weapon_hands_sh")

	local primary = ply:Give(loadout.primary)
	if IsValid(primary) then
		ply:GiveAmmo(primary:GetMaxClip1() * loadout.ammo, primary:GetPrimaryAmmoType(), true)
	end

	local secondary = ply:Give(loadout.secondary)
	if IsValid(secondary) then
		ply:GiveAmmo(secondary:GetMaxClip1() * loadout.ammo2, secondary:GetPrimaryAmmoType(), true)
	end

	hg.AddArmor(ply, loadout.armor or {})
	ply:Give("weapon_melee")
	ply:Give("weapon_walkie_talkie")
	ply:Give(table.Random(utilityItems))
	ply:Give(table.Random(utilityItems))
	ply:SelectWeapon("weapon_hands_sh")
end

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	game.CleanUpMap()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then
			continue
		end

		ApplyAppearance(ply)
		ply:SetupTeam(0) -- no T/CT split in this mode
	end
end

function MODE:CheckAlivePlayers()
	local alive = {}
	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end
		alive[#alive + 1] = ply
	end

	return alive
end

function MODE:BuildSpawnPool()
	local points = {}

	AddMapPointPositions(points, "RandomSpawns")
	AddMapPointPositions(points, "Spawnpoint")

	local fallbackSpawnClasses = {
		"info_player_start",
		"info_player_deathmatch",
		"info_player_counterterrorist",
		"info_player_terrorist"
	}

	for _, className in ipairs(fallbackSpawnClasses) do
		for _, ent in ipairs(ents.FindByClass(className)) do
			points[#points + 1] = ent:GetPos()
		end
	end

	if navmesh.IsLoaded() then
		local areas = navmesh.GetAllNavAreas() or {}
		for i = 1, math.min(#areas, 300), 3 do
			local area = areas[i]
			if area then
				points[#points + 1] = area:GetCenter()
			end
		end
	end

	self.SpawnPool = points
end

function MODE:FindSpawnPosFromBase(basePos)
	local jitter = Vector(math.random(-900, 900), math.random(-900, 900), 0)
	local traceStart = basePos + jitter + Vector(0, 0, math.random(400, 1200))
	local tr = util.TraceLine({
		start = traceStart,
		endpos = traceStart - Vector(0, 0, 3500),
		mask = MASK_SOLID_BRUSHONLY
	})

	if tr.Hit then
		return tr.HitPos + Vector(0, 0, 10)
	end
end

function MODE:SpawnHeadcrabAt(pos)
	if self.TotalHeadcrabsSpawned >= self.MaxHeadcrabs then return false end

	local npcClass = spawnClasses[math.random(#spawnClasses)]
	local crab = ents.Create(npcClass)
	if not IsValid(crab) then return false end

	crab:SetPos(pos)
	crab:Spawn()
	crab:Activate()

	self.TotalHeadcrabsSpawned = self.TotalHeadcrabsSpawned + 1
	self.ActiveHeadcrabs = self.ActiveHeadcrabs + 1
	self.NextDifficultySpike = (self.NextDifficultySpike or 0) + 1

	crab:CallOnRemove("HeadcrabSurvivalTrack_" .. crab:EntIndex(), function()
		if not MODE then return end
		MODE.ActiveHeadcrabs = math.max((MODE.ActiveHeadcrabs or 1) - 1, 0)
	end)

	return true
end

function MODE:SpawnHeadcrabBatch()
	if not self.SpawnPool or #self.SpawnPool <= 0 then return end
	if self.TotalHeadcrabsSpawned >= self.MaxHeadcrabs then return end

	local alivePlayers = self:CheckAlivePlayers()
	if #alivePlayers <= 0 then return end

	local batchCount = math.random(self.MinBatchSpawn, self.MaxBatchSpawn)
	if self.TotalHeadcrabsSpawned >= 450 then
		batchCount = batchCount + 2
	end

	for _ = 1, batchCount do
		if self.TotalHeadcrabsSpawned >= self.MaxHeadcrabs then break end

		local basePos = self.SpawnPool[math.random(#self.SpawnPool)]
		local spawnPos = self:FindSpawnPosFromBase(basePos)
		if spawnPos then
			self:SpawnHeadcrabAt(spawnPos)
		end
	end
end

function MODE:RoundStart()
	self:BuildSpawnPool()
	self.TotalHeadcrabsSpawned = 0
	self.ActiveHeadcrabs = 0
	self.RoundEndsAt = CurTime() + self.RoundTimeLimit

	timer.Remove("ZB_HeadcrabSurvivalSpawner")
	timer.Create("ZB_HeadcrabSurvivalSpawner", self.SpawnTick, 0, function()
		local round = CurrentRound()
		if not round or round.name ~= self.name then
			timer.Remove("ZB_HeadcrabSurvivalSpawner")
			return
		end

		self:SpawnHeadcrabBatch()
	end)

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		GiveRandomLoadout(ply)
		zb.GiveRole(ply, "Survivor", Color(100, 210, 100))

		timer.Simple(0.1, function()
			if IsValid(ply) then
				ply.noSound = false
				ply:SetSuppressPickupNotices(false)
			end
		end)
	end
end

function MODE:ShouldRoundEnd()
	if #self:CheckAlivePlayers() <= 0 then
		self.RoundResult = "headcrabs"
		return true
	end

	if self.TotalHeadcrabsSpawned >= self.MaxHeadcrabs and self.ActiveHeadcrabs <= 0 then
		self.RoundResult = "survivors"
		return true
	end

	if self.RoundEndsAt and CurTime() >= self.RoundEndsAt then
		self.RoundResult = "survivors"
		return true
	end

	return false
end

function MODE:EndRound()
	timer.Remove("ZB_HeadcrabSurvivalSpawner")

	if self.RoundResult == "survivors" then
		for _, ply in ipairs(self:CheckAlivePlayers()) do
			if IsValid(ply) then
				ply:GiveExp(math.random(120, 180))
				ply:GiveSkill(math.Rand(0.1, 0.2))
			end
		end
	end
end

function MODE:CanSpawn()
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end
