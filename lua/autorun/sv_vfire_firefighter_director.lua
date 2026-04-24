if not SERVER then return end

local FIRE_THRESHOLD = 50
local CHECK_INTERVAL = 1
local BOT_CLASS = "nextbot_firefighter"

local function countActiveFires()
    return #ents.FindByClass("vfire") + #ents.FindByClass("vfire_ball")
end

local function getBot()
    local bots = ents.FindByClass(BOT_CLASS)

    for _, bot in ipairs(bots) do
        if IsValid(bot) then
            return bot
        end
    end
end

local function findSpawnPosition()
    local fires = ents.FindByClass("vfire")
    if #fires == 0 then
        fires = ents.FindByClass("vfire_ball")
    end

    local center = Vector(0, 0, 0)

    if #fires > 0 then
        for _, fire in ipairs(fires) do
            center:Add(fire:GetPos())
        end

        center:Mul(1 / #fires)
    else
        local players = player.GetHumans()
        if #players > 0 then
            center = players[1]:GetPos()
        end
    end

    local trace = util.TraceHull({
        start = center + Vector(0, 0, 400),
        endpos = center - Vector(0, 0, 600),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID_BRUSHONLY
    })

    return trace.HitPos + Vector(0, 0, 10)
end

local function ensureFirefighter()
    local activeFires = countActiveFires()
    local bot = getBot()

    if activeFires > FIRE_THRESHOLD then
        if not IsValid(bot) then
            bot = ents.Create(BOT_CLASS)
            if not IsValid(bot) then return end

            bot:SetPos(findSpawnPosition())
            bot:Spawn()

            if bot.AddEntityRelationship then
                for _, ply in ipairs(player.GetAll()) do
                    bot:AddEntityRelationship(ply, D_LI, 99)
                end
            end
        end

        return
    end

    if activeFires <= 0 and IsValid(bot) then
        bot:Remove()
    end
end

timer.Create("vfire_firefighter_director", CHECK_INTERVAL, 0, ensureFirefighter)

hook.Add("PlayerInitialSpawn", "vfire_firefighter_friendly", function(ply)
    local bot = getBot()
    if IsValid(bot) and bot.AddEntityRelationship then
        bot:AddEntityRelationship(ply, D_LI, 99)
    end
end)