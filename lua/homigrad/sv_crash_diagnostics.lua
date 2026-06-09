-- Persistent server-side breadcrumbs for crashes that cannot be caught by Lua.
-- Logs are written under garrysmod/data/zcity_crash_diagnostics/.

hg.CrashDiagnostics = hg.CrashDiagnostics or {}
local diagnostics = hg.CrashDiagnostics

local LOG_DIRECTORY = "zcity_crash_diagnostics"
local CURRENT_LOG = LOG_DIRECTORY .. "/current.json"
local ACTIVE_MARKER = LOG_DIRECTORY .. "/session_active.txt"
local MAX_LOG_BYTES = 4 * 1024 * 1024
local MAX_RECENT_EVENTS = 256
local MAX_COLLISION_EVENTS_PER_SECOND = 128
local COLLISION_EVENT_DEDUPLICATION_SECONDS = 0.25
local CALLBACK_NAMES = {
    PhysicsCollide = true,
    ShouldCollide = true,
    StartTouch = true,
    Touch = true,
    EndTouch = true,
    OnCrazyPhysics = true
}

local enabled = CreateConVar(
    "hg_crash_diagnostics",
    "1",
    FCVAR_ARCHIVE,
    "Persist crash breadcrumbs, physics/collision state, grenade stages, and ULib state.",
    0,
    1
)

local heartbeatInterval = CreateConVar(
    "hg_crash_diagnostics_interval",
    "15",
    FCVAR_ARCHIVE,
    "Seconds between crash diagnostic heartbeats.",
    5,
    300
)

local collisionDiagnosticsEnabled = CreateConVar(
    "hg_crash_diagnostics_collision_rules",
    "1",
    FCVAR_ARCHIVE,
    "Record collision-rule mutations with entity state and Lua call sites.",
    0,
    1
)

local recentEvents = diagnostics.RecentEvents or {}
diagnostics.RecentEvents = recentEvents

local function shallowCount(value)
    if not istable(value) then return nil end
    return table.Count(value)
end

local function safeString(value)
    local valueType = type(value)

    if valueType == "Vector" or valueType == "Angle" then
        return tostring(value)
    end

    if isentity(value) then
        if not IsValid(value) then return "invalid entity" end
        return string.format("%s[%d]", value:GetClass(), value:EntIndex())
    end

    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        return value
    end

    if value == nil then return nil end
    return tostring(value)
end

local function sanitizeDetails(details)
    if not istable(details) then return safeString(details) end

    local sanitized = {}
    for key, value in pairs(details) do
        sanitized[tostring(key)] = safeString(value)
    end

    return sanitized
end

local function getEntityCounts()
    local counts = {
        total = 0,
        grenades = 0,
        prop_physics = 0,
        ragdolls = 0,
        constraints = 0
    }

    for _, ent in ipairs(ents.GetAll()) do
        counts.total = counts.total + 1

        if ent.ishggrenade then
            counts.grenades = counts.grenades + 1
        end

        local class = ent:GetClass()
        if class == "prop_physics" or class == "prop_physics_multiplayer" then
            counts.prop_physics = counts.prop_physics + 1
        elseif class == "prop_ragdoll" then
            counts.ragdolls = counts.ragdolls + 1
        elseif string.StartWith(class, "phys_") or string.StartWith(class, "constraint_") then
            counts.constraints = counts.constraints + 1
        end
    end

    return counts
end

function diagnostics.GetSnapshot()
    local timerCount = nil
    if timer.GetTable then
        timerCount = table.Count(timer.GetTable())
    end

    local entityCounts = getEntityCounts()
    local physicsPaused = physenv and physenv.GetPhysicsPaused and physenv.GetPhysicsPaused() or nil
    local tickInterval = engine and engine.TickInterval and engine.TickInterval() or nil
    local snapshot = {
        lua_memory_kb = math.Round(collectgarbage("count"), 2),
        entities = entityCounts.total,
        grenades = entityCounts.grenades,
        prop_physics = entityCounts.prop_physics,
        ragdolls = entityCounts.ragdolls,
        constraints = entityCounts.constraints,
        players = #player.GetAll(),
        max_players = game.MaxPlayers(),
        timers = timerCount,
        uptime_seconds = math.Round(SysTime(), 2),
        map = game.GetMap(),
        physics_paused = physicsPaused,
        tick_interval = tickInterval and math.Round(tickInterval, 6) or nil,
        frame_time = math.Round(FrameTime(), 6)
    }

    if istable(ULib) then
        snapshot.ulib = {
            groups = ULib.ucl and shallowCount(ULib.ucl.groups) or nil,
            users = ULib.ucl and shallowCount(ULib.ucl.users) or nil,
            bans = shallowCount(ULib.bans),
            version = safeString(ULib.VERSION or ULib.version)
        }
    else
        snapshot.ulib = "not loaded"
    end

    return snapshot
end

local logCreationWarningPrinted = false

local function ensureCurrentLog()
    if file.Exists(CURRENT_LOG, "DATA") then return true end

    file.CreateDir(LOG_DIRECTORY)

    local bootstrap = util.TableToJSON({
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        realtime = math.Round(RealTime(), 4),
        category = "diagnostics",
        event = "log_created",
        details = {
            reason = "current_log_missing"
        }
    }, false)

    if bootstrap then
        -- Garry's Mod may not create a data file for an empty string, so write a
        -- valid JSONL record as the first payload instead of probing with "".
        file.Write(CURRENT_LOG, bootstrap .. "\n")
    end

    if file.Exists(CURRENT_LOG, "DATA") then
        logCreationWarningPrinted = false
        return true
    end

    if not logCreationWarningPrinted then
        logCreationWarningPrinted = true
        MsgC(
            Color(255, 80, 80),
            "[Z-City Diagnostics] Unable to create data/",
            CURRENT_LOG,
            ". Check the server data directory permissions.\n"
        )
    end

    return false
end

local function ensureActiveMarker()
    if file.Exists(ACTIVE_MARKER, "DATA") then return true end

    file.Write(ACTIVE_MARKER, os.date("!%Y-%m-%dT%H:%M:%SZ"))
    return file.Exists(ACTIVE_MARKER, "DATA")
end

local function rotateOversizedLog()
    local size = file.Size(CURRENT_LOG, "DATA")
    if not size or size < MAX_LOG_BYTES then return end

    local archiveName = string.format(
        "%s/oversized_%s.json",
        LOG_DIRECTORY,
        os.date("%Y%m%d_%H%M%S")
    )

    file.Rename(CURRENT_LOG, archiveName)
end

function diagnostics.Event(category, eventName, details, includeSnapshot)
    if not enabled:GetBool() then return end
    if not ensureCurrentLog() then return end

    rotateOversizedLog()
    if not ensureCurrentLog() then return end
    ensureActiveMarker()

    local record = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        realtime = math.Round(RealTime(), 4),
        category = tostring(category or "unknown"),
        event = tostring(eventName or "unknown"),
        details = sanitizeDetails(details)
    }

    if includeSnapshot then
        record.snapshot = diagnostics.GetSnapshot()
    end

    recentEvents[#recentEvents + 1] = record
    if #recentEvents > MAX_RECENT_EVENTS then
        table.remove(recentEvents, 1)
    end

    local encoded = util.TableToJSON(record, false)
    if not encoded then
        encoded = util.TableToJSON({
            timestamp = record.timestamp,
            category = "diagnostics",
            event = "json_encode_failed"
        }, false)
    end

    file.Append(CURRENT_LOG, encoded .. "\n")
end

local function getEntityDiagnosticDetails(ent, prefix)
    prefix = prefix or "entity_"
    local details = {}

    if not IsValid(ent) then
        details[prefix .. "valid"] = false
        return details
    end

    details[prefix .. "valid"] = true
    details[prefix .. "class"] = ent:GetClass()
    details[prefix .. "index"] = ent:EntIndex()
    details[prefix .. "model"] = ent:GetModel()
    details[prefix .. "position"] = ent:GetPos()
    details[prefix .. "angles"] = ent:GetAngles()
    details[prefix .. "velocity"] = ent:GetVelocity()
    details[prefix .. "collision_group"] = ent:GetCollisionGroup()
    details[prefix .. "solid"] = ent:GetSolid()
    details[prefix .. "move_type"] = ent:GetMoveType()
    details[prefix .. "owner"] = ent:GetOwner()
    details[prefix .. "parent"] = ent:GetParent()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        details[prefix .. "physics_valid"] = true
        details[prefix .. "physics_mass"] = phys:GetMass()
        details[prefix .. "physics_motion_enabled"] = phys:IsMotionEnabled()
        details[prefix .. "physics_asleep"] = phys:IsAsleep()
        details[prefix .. "physics_velocity"] = phys:GetVelocity()
        details[prefix .. "physics_angular_velocity"] = phys:GetAngleVelocity()
    else
        details[prefix .. "physics_valid"] = false
    end

    return details
end

local function mergeDetails(destination, source)
    for key, value in pairs(source) do
        destination[key] = value
    end
end

local registeredCollisionCallbacks = diagnostics.RegisteredCollisionCallbacks or setmetatable({}, {__mode = "k"})
diagnostics.RegisteredCollisionCallbacks = registeredCollisionCallbacks

local function getLuaCallContext(ent)
    local frames = {}
    local entityCallbacks = {}

    if IsValid(ent) then
        for callbackName in pairs(CALLBACK_NAMES) do
            local callback = ent[callbackName]
            if isfunction(callback) then
                entityCallbacks[callback] = callbackName
            end
        end
    end

    local shouldCollideHooks = hook.GetTable().ShouldCollide or {}
    local callbackName = nil
    local firstCallSite = nil

    for level = 3, 14 do
        local info = debug.getinfo(level, "fnSl")
        if not info then break end

        local source = info.short_src or info.source or "unknown"
        local name = info.name or "anonymous"
        local frame = string.format("%s:%s (%s)", source, tostring(info.currentline or 0), name)
        frames[#frames + 1] = frame

        if not firstCallSite and not string.find(source, "sv_crash_diagnostics.lua", 1, true) then
            firstCallSite = frame
        end

        if CALLBACK_NAMES[name] then
            callbackName = name
        elseif info.func and registeredCollisionCallbacks[info.func] then
            callbackName = registeredCollisionCallbacks[info.func]
        elseif info.func and entityCallbacks[info.func] then
            callbackName = entityCallbacks[info.func]
        elseif info.func then
            for _, callback in pairs(shouldCollideHooks) do
                if callback == info.func then
                    callbackName = "ShouldCollide"
                    break
                end
            end
        end
    end

    return {
        callback = callbackName,
        call_site = firstCallSite or frames[1],
        call_stack = table.concat(frames, " <- ")
    }
end

local collisionEventWindow = {
    started = 0,
    count = 0,
    dropped = 0
}
local recentCollisionMutations = {}

local function allowCollisionEvent(deduplicationKey, suspicious)
    local now = RealTime()

    if now - collisionEventWindow.started >= 1 then
        if collisionEventWindow.dropped > 0 then
            diagnostics.Event("collision_rules", "events_throttled", {
                dropped = collisionEventWindow.dropped,
                previous_window_started = collisionEventWindow.started
            }, false)
        end

        collisionEventWindow.started = now
        collisionEventWindow.count = 0
        collisionEventWindow.dropped = 0

        if table.Count(recentCollisionMutations) > 8192 then
            recentCollisionMutations = {}
        end
    end

    local lastRecorded = recentCollisionMutations[deduplicationKey]
    if not suspicious and lastRecorded and now - lastRecorded < COLLISION_EVENT_DEDUPLICATION_SECONDS then
        collisionEventWindow.dropped = collisionEventWindow.dropped + 1
        return false
    end

    if collisionEventWindow.count >= MAX_COLLISION_EVENTS_PER_SECOND then
        collisionEventWindow.dropped = collisionEventWindow.dropped + 1
        return false
    end

    collisionEventWindow.count = collisionEventWindow.count + 1
    recentCollisionMutations[deduplicationKey] = now
    return true
end

function diagnostics.CollisionRuleMutation(ent, methodName, arguments)
    if not enabled:GetBool() or not collisionDiagnosticsEnabled:GetBool() then return end

    local context = getLuaCallContext(ent)
    local class = IsValid(ent) and ent:GetClass() or "invalid"
    local entityIndex = IsValid(ent) and ent:EntIndex() or -1
    local suspicious = context.callback ~= nil
        or methodName == "CollisionRulesChanged"
        or class == "prop_physics"
        or class == "prop_physics_multiplayer"
    local deduplicationKey = table.concat({
        class,
        entityIndex,
        methodName,
        context.call_site or "unknown"
    }, ":")

    if not allowCollisionEvent(deduplicationKey, suspicious) then return end

    local details = {
        method = methodName,
        arguments = arguments,
        callback = context.callback or "not detected",
        suspicious_callback = suspicious,
        call_site = context.call_site,
        call_stack = context.call_stack
    }
    mergeDetails(details, getEntityDiagnosticDetails(ent))

    diagnostics.Event(
        "collision_rules",
        context.callback and "mutation_inside_callback" or "mutation",
        details,
        context.callback ~= nil
    )
end

local function stringifyArguments(...)
    local arguments = {}

    for index = 1, select("#", ...) do
        arguments[index] = tostring(select(index, ...))
    end

    return table.concat(arguments, ", ")
end

local function installCollisionRuleInstrumentation()
    diagnostics.OriginalCollisionMethods = diagnostics.OriginalCollisionMethods or {}
    local originals = diagnostics.OriginalCollisionMethods
    local entityMeta = FindMetaTable("Entity")
    if not entityMeta then return end

    if not originals.AddCallback and isfunction(entityMeta.AddCallback) then
        originals.AddCallback = entityMeta.AddCallback
    end

    if originals.AddCallback then
        entityMeta.AddCallback = function(ent, callbackName, callback)
            if CALLBACK_NAMES[callbackName] and isfunction(callback) then
                registeredCollisionCallbacks[callback] = callbackName
            end

            return originals.AddCallback(ent, callbackName, callback)
        end
    end

    local methods = {
        "CollisionRulesChanged",
        "SetCollisionGroup",
        "SetCustomCollisionCheck",
        "SetNotSolid",
        "SetSolid",
        "SetMoveType"
    }

    for _, methodName in ipairs(methods) do
        if not originals[methodName] and isfunction(entityMeta[methodName]) then
            originals[methodName] = entityMeta[methodName]
        end

        local wrappedMethodName = methodName
        local original = originals[wrappedMethodName]
        if original then
            entityMeta[wrappedMethodName] = function(ent, ...)
                diagnostics.CollisionRuleMutation(ent, wrappedMethodName, stringifyArguments(...))
                return original(ent, ...)
            end
        end
    end
end

installCollisionRuleInstrumentation()

local physicsWasPaused = physenv and physenv.GetPhysicsPaused and physenv.GetPhysicsPaused() or false
hook.Add("Tick", "ZCityCrashDiagnosticsPhysicsState", function()
    if not physenv or not physenv.GetPhysicsPaused then return end

    local physicsPaused = physenv.GetPhysicsPaused()
    if physicsPaused == physicsWasPaused then return end

    physicsWasPaused = physicsPaused
    diagnostics.Event("physics", physicsPaused and "simulation_paused" or "simulation_resumed", nil, true)
end)

hook.Add("OnCrazyPhysics", "ZCityCrashDiagnosticsCrazyPhysics", function(ent, phys)
    local details = getEntityDiagnosticDetails(ent)

    if IsValid(phys) then
        details.reported_physics_mass = phys:GetMass()
        details.reported_physics_velocity = phys:GetVelocity()
        details.reported_physics_angular_velocity = phys:GetAngleVelocity()
    end

    local context = getLuaCallContext(ent)
    details.call_site = context.call_site
    details.call_stack = context.call_stack
    diagnostics.Event("physics", "crazy_physics", details, true)
end)

function diagnostics.GrenadeStage(grenade, stage, details, includeSnapshot)
    if not IsValid(grenade) then return end

    details = details or {}
    details.class = grenade:GetClass()
    details.entity_index = grenade:EntIndex()
    details.position = grenade:GetPos()
    details.fragmentation = grenade.Fragmentation
    details.owner = grenade.owner

    diagnostics.Event("grenade", stage, details, includeSnapshot)
end

local function initializeSession()
    file.CreateDir(LOG_DIRECTORY)

    if file.Exists(ACTIVE_MARKER, "DATA") and file.Exists(CURRENT_LOG, "DATA") then
        local archiveName = string.format(
            "%s/unclean_%s.json",
            LOG_DIRECTORY,
            os.date("%Y%m%d_%H%M%S")
        )

        file.Rename(CURRENT_LOG, archiveName)
        MsgC(Color(255, 180, 50), "[Z-City Diagnostics] Previous session ended uncleanly. Saved ", archiveName, "\n")
    else
        file.Delete(CURRENT_LOG)
    end

    if not enabled:GetBool() then
        file.Delete(ACTIVE_MARKER)
        MsgC(
            Color(255, 180, 50),
            "[Z-City Diagnostics] Disabled by hg_crash_diagnostics 0; no JSON log will be written.\n"
        )
        return
    end

    if not ensureCurrentLog() then
        file.Delete(ACTIVE_MARKER)
        return
    end

    file.Write(ACTIVE_MARKER, os.date("!%Y-%m-%dT%H:%M:%SZ"))
    diagnostics.Event("lifecycle", "session_start", nil, true)
    MsgC(Color(120, 220, 120), "[Z-City Diagnostics] Recording to data/", CURRENT_LOG, "\n")
end

initializeSession()

timer.Create("ZCityCrashDiagnosticsHeartbeat", heartbeatInterval:GetFloat(), 0, function()
    diagnostics.Event("heartbeat", "server_alive", nil, true)
end)

hook.Add("ShutDown", "ZCityCrashDiagnosticsCleanShutdown", function()
    diagnostics.Event("lifecycle", "clean_shutdown", nil, true)
    file.Delete(ACTIVE_MARKER)
end)

hook.Add("PlayerInitialSpawn", "ZCityCrashDiagnosticsPlayerJoin", function(ply)
    diagnostics.Event("player", "initial_spawn", {
        name = ply:Nick(),
        steam_id = ply:SteamID(),
        entity_index = ply:EntIndex()
    }, true)
end)

hook.Add("PlayerDisconnected", "ZCityCrashDiagnosticsPlayerLeave", function(ply)
    diagnostics.Event("player", "disconnected", {
        name = ply:Nick(),
        steam_id = ply:SteamID(),
        entity_index = ply:EntIndex()
    }, true)
end)

local ulibHooks = {
    "ULibUserAccessChanged",
    "ULibGroupAccessChanged",
    "ULibUserRemoved",
    "ULibGroupCreated",
    "ULibGroupRemoved",
    "ULibGroupRenamed"
}

for _, hookName in ipairs(ulibHooks) do
    hook.Add(hookName, "ZCityCrashDiagnostics" .. hookName, function(...)
        diagnostics.Event("ulib", hookName, {argument_count = select("#", ...)}, true)
    end)
end

local function canUseCommand(ply)
    return not IsValid(ply) or ply:IsSuperAdmin()
end

local function printCommandMessage(ply, message)
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, message .. "\n")
    else
        print(message)
    end
end

concommand.Add("hg_crash_diagnostics_status", function(ply)
    if not canUseCommand(ply) then return end

    local recordingEnabled = enabled:GetBool()
    local repairedLog = false
    if recordingEnabled and not file.Exists(CURRENT_LOG, "DATA") then
        repairedLog = ensureCurrentLog()
    end
    if recordingEnabled and file.Exists(CURRENT_LOG, "DATA") then
        ensureActiveMarker()
    end

    local status = {
        enabled = recordingEnabled,
        collision_diagnostics_enabled = collisionDiagnosticsEnabled:GetBool(),
        data_path = "data/" .. CURRENT_LOG,
        log_format = "json_lines",
        log_exists = file.Exists(CURRENT_LOG, "DATA"),
        log_size_bytes = file.Size(CURRENT_LOG, "DATA"),
        active_marker_exists = file.Exists(ACTIVE_MARKER, "DATA"),
        repaired_missing_log = repairedLog,
        snapshot = diagnostics.GetSnapshot()
    }
    local json = util.TableToJSON(status, true) or "Unable to encode diagnostics status"
    printCommandMessage(ply, json)
end)

concommand.Add("hg_crash_diagnostics_mark", function(ply, _, args)
    if not canUseCommand(ply) then return end

    diagnostics.Event("manual", "admin_marker", {
        message = table.concat(args, " "),
        actor = IsValid(ply) and ply or "server console"
    }, true)
end)

concommand.Add("hg_crash_diagnostics_dump", function(ply)
    if not canUseCommand(ply) then return end

    diagnostics.Event("manual", "diagnostic_dump", nil, true)
    local destination = string.format("%s/manual_%s.json", LOG_DIRECTORY, os.date("%Y%m%d_%H%M%S"))
    file.Write(destination, file.Read(CURRENT_LOG, "DATA") or "")

    local message = "[Z-City Diagnostics] Wrote data/" .. destination
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, message .. "\n")
    else
        print(message)
    end
end)
