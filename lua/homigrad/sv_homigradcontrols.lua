local hg_allow_homigrad = ConVarExists("hg_allow_homigrad") and GetConVar("hg_allow_homigrad") or CreateConVar("hg_allow_homigrad",0,FCVAR_SERVER_CAN_EXECUTE,"Allow homigrad-like entity drag for administrators in spectator mode",0,1)

local function WakeEntityPhysics(ent, bone)
	if not IsValid(ent) then return end

	if bone then
		local phys = ent:GetPhysicsObjectNum(bone)
		if IsValid(phys) then
			phys:EnableMotion(true)
			phys:Wake()
		end

		return
	end

	local count = ent:GetPhysicsObjectCount()
	for i = 0, count - 1 do
		local phys = ent:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			phys:EnableMotion(true)
			phys:Wake()
		end
	end
end

local function CanFreezeCarriedEntity(ent)
	if not IsValid(ent) then return false end

	local class = ent:GetClass()
	return not string.StartWith(class, "ent_hg_grenade") and string.find(class, "grenade", 1, true) == nil
end

hook.Add("Player Think","ShadowControlAdmin",function(ply, time)
	if !hg_allow_homigrad:GetBool() then return end
	if !ply:IsSuperAdmin() or ply:Alive() then return end

	if ply:KeyDown(IN_ATTACK) and ply:GetMoveType() == MOVETYPE_NOCLIP then
		local enta = ply:GetEyeTrace().Entity
		if enta:IsPlayer() and !enta.FakeRagdoll and !IsValid(ply.ShadowCarryEnt) then
			hg.Fake(enta)
		end
		if !IsValid(enta:GetPhysicsObject()) then return end
		ply.ShadowCarryEntPhysbone = ply.ShadowCarryEntPhysbone or ply:GetEyeTrace().PhysicsBone
		local physbone = ply.ShadowCarryEntPhysbone
		ply.ShadowCarryEnt = IsValid(ply.ShadowCarryEnt) and ply.ShadowCarryEnt or enta

		if IsValid(ply.ShadowCarryEnt) then
			ply.ShadowCarryEnt:SetPhysicsAttacker(ply,5)

			ply.ShadowCarryEntLen = math.max(ply.ShadowCarryEntLen or ply.ShadowCarryEnt:GetPos():Distance(ply:EyePos()), 50)
			local ent = ply.ShadowCarryEnt
			local len = ply.ShadowCarryEntLen
			ply.ShadowCarryEnt:GetPhysicsObjectNum(ply.ShadowCarryEntPhysbone):EnableMotion(true)
			ply.ShadowCarryEnt.isheld = true
			local ang = ply:EyeAngles()
			ang[1] = 0
			if ent and len then
				local shadowparams = {}
				shadowparams.pos = ply:EyePos() + ply:EyeAngles():Forward() * len
				shadowparams.angle = ang
				shadowparams.maxangular = 50
				shadowparams.maxangulardamp = 25
				shadowparams.maxspeed = 10000
				shadowparams.maxspeeddamp = 1000
				shadowparams.dampfactor = 0.8
				shadowparams.teleportdistance = 0
				shadowparams.deltatime = CurTime()
				ent:GetPhysicsObjectNum(physbone):Wake()
				ent:GetPhysicsObjectNum(physbone):ComputeShadowControl(shadowparams)
			end
		end
	else
		if IsValid(ply.ShadowCarryEnt) then
			WakeEntityPhysics(ply.ShadowCarryEnt, ply.ShadowCarryEntPhysbone)
			ply.ShadowCarryEnt.isheld = false
			ply.ShadowCarryEnt = nil
			ply.ShadowCarryEntLen = nil
			ply.ShadowCarryEntPhysbone = nil
		end
	end
	if ply:KeyDown(IN_ATTACK2) and ply.allowGrab then
		if IsValid(ply.ShadowCarryEnt) and CanFreezeCarriedEntity(ply.ShadowCarryEnt) then
			ply.ShadowCarryEnt:GetPhysicsObjectNum(ply.ShadowCarryEntPhysbone):EnableMotion(false)
			ply.ShadowCarryEnt.isheld = true
		end
	end
end)

hook.Add("StartCommand","ShadowControlAdmin",function(ply, cmd)
	if !hg_allow_homigrad:GetBool() then return end
	if !ply:IsSuperAdmin() or ply:Alive() then return end

	local num = ply:GetInfo("physgun_wheelspeed")
	if !IsValid(ply.ShadowCarryEnt) then return end
	if cmd:GetMouseWheel() > 0 then ply.ShadowCarryEntLen = ply.ShadowCarryEntLen + num end
	if cmd:GetMouseWheel() < 0 then ply.ShadowCarryEntLen = ply.ShadowCarryEntLen - num end
end)