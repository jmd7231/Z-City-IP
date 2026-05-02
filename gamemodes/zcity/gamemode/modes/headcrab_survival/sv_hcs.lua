local MODE = MODE

local MAX_HEADCRABS = 1000
local SPAWN_PER_TICK_MIN = 8
local SPAWN_PER_TICK_MAX = 20
local SPAWN_INTERVAL = 1.25
local SPAWN_HEIGHT = 350
local SPAWN_RADIUS = 900

local headcrabClasses = {
	"npc_headcrab",
	"npc_headcrab_fast",
	"npc_headcrab_poison"
}

local function validSpawnPos(pos)
	if not pos then return false end

	local tr = util.TraceLine({
		start = pos + Vector(0, 0, 128),
		endpos = pos - Vector(0, 0, 1024),
		mask = MASK_SOLID_BRUSHONLY
	})

	if not tr.Hit then return false end

	local spawnPos = tr.HitPos + Vector(0, 0, 8)
	if util.IsInWorld(spawnPos) then
		return spawnPos
	end

	return false
end

local function randomMapSpawnPoint()
	local navAreas = navmesh.GetAllNavAreas()
	if navAreas and #navAreas > 0 then
		local area = navAreas[math.random(#navAreas)]
		local center = area:GetCenter()
		local randomOffset = Vector(math.Rand(-SPAWN_RADIUS, SPAWN_RADIUS), math.Rand(-SPAWN_RADIUS, SPAWN_RADIUS), math.Rand(48, SPAWN_HEIGHT))
		return center + randomOffset
	end

	local fallback = zb:GetRandomSpawn()
	if fallback then
		return fallback + Vector(math.Rand(-SPAWN_RADIUS, SPAWN_RADIUS), math.Rand(-SPAWN_RADIUS, SPAWN_RADIUS), math.Rand(32, SPAWN_HEIGHT))
	end
end

local function countHeadcrabs()
	local count = 0
	for _, ent in ipairs(ents.GetAll()) do
		if ent:IsNPC() and headcrabClasses[ent:GetClass()] then
			count = count + 1
		end
	end
	return count
end

local classLookup = {}
for _, class in ipairs(headcrabClasses) do
	classLookup[class] = true
end
headcrabClasses = classLookup

function MODE:RoundStart()
	if self.BaseClass and self.BaseClass.RoundStart then
		self.BaseClass.RoundStart(self)
	end

	timer.Remove("hcs_spawn_headcrabs")
	timer.Create("hcs_spawn_headcrabs", SPAWN_INTERVAL, 0, function()
		if zb.CROUND_MAIN ~= MODE.name or zb.ROUND_STATE ~= 1 then
			timer.Remove("hcs_spawn_headcrabs")
			return
		end

		local alive = #zb:CheckAlive(true)
		if alive <= 0 then return end

		local current = countHeadcrabs()
		if current >= MAX_HEADCRABS then return end

		local burst = math.random(SPAWN_PER_TICK_MIN, SPAWN_PER_TICK_MAX)
		local canSpawn = math.min(burst, MAX_HEADCRABS - current)

		for i = 1, canSpawn do
			local testPos = randomMapSpawnPoint()
			local spawnPos = validSpawnPos(testPos)
			if not spawnPos then continue end

			local class = table.Random({"npc_headcrab", "npc_headcrab_fast", "npc_headcrab_poison"})
			local headcrab = ents.Create(class)
			if not IsValid(headcrab) then continue end

			headcrab:SetPos(spawnPos)
			headcrab:Spawn()
			headcrab:Activate()
		end
	end)
end

function MODE:RoundEnd()
	timer.Remove("hcs_spawn_headcrabs")
end
