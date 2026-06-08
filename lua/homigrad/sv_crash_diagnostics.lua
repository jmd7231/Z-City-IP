-- Persistent server-side breadcrumbs for crashes that cannot be caught by Lua.
-- Logs are written under garrysmod/data/zcity_crash_diagnostics/.

hg.CrashDiagnostics = hg.CrashDiagnostics or {}
local diagnostics = hg.CrashDiagnostics

local LOG_DIRECTORY = "zcity_crash_diagnostics"
local CURRENT_LOG = LOG_DIRECTORY .. "/current.jsonl"
local ACTIVE_MARKER = LOG_DIRECTORY .. "/session_active.txt"
local MAX_LOG_BYTES = 4 * 1024 * 1024
local MAX_RECENT_EVENTS = 128

local enabled = CreateConVar(
    "hg_crash_diagnostics",
    "1",
    FCVAR_ARCHIVE,
    "Persist crash breadcrumbs, memory samples, grenade stages, and ULib state.",
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

local function countGrenades()
    local count = 0

    for _, ent in ipairs(ents.GetAll()) do
        if ent.ishggrenade then
            count = count + 1
        end
    end

    return count
end

function diagnostics.GetSnapshot()
    local timerCount = nil
    if timer.GetTable then
        timerCount = table.Count(timer.GetTable())
    end

    local snapshot = {
        lua_memory_kb = math.Round(collectgarbage("count"), 2),
        entities = #ents.GetAll(),
        grenades = countGrenades(),
        players = #player.GetAll(),
        timers = timerCount,
        uptime_seconds = math.Round(SysTime(), 2),
        map = game.GetMap()
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

local function rotateOversizedLog()
    local size = file.Size(CURRENT_LOG, "DATA")
    if not size or size < MAX_LOG_BYTES then return end

    local archiveName = string.format(
        "%s/oversized_%s.jsonl",
        LOG_DIRECTORY,
        os.date("%Y%m%d_%H%M%S")
    )

    file.Rename(CURRENT_LOG, archiveName)
end

function diagnostics.Event(category, eventName, details, includeSnapshot)
    if not enabled:GetBool() then return end

    rotateOversizedLog()

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
            "%s/unclean_%s.jsonl",
            LOG_DIRECTORY,
            os.date("%Y%m%d_%H%M%S")
        )

        file.Rename(CURRENT_LOG, archiveName)
        MsgC(Color(255, 180, 50), "[Z-City Diagnostics] Previous session ended uncleanly. Saved ", archiveName, "\n")
    else
        file.Delete(CURRENT_LOG)
    end

    file.Write(ACTIVE_MARKER, os.date("!%Y-%m-%dT%H:%M:%SZ"))
    diagnostics.Event("lifecycle", "session_start", nil, true)
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

concommand.Add("hg_crash_diagnostics_status", function(ply)
    if not canUseCommand(ply) then return end

    local json = util.TableToJSON(diagnostics.GetSnapshot(), true) or "Unable to encode snapshot"
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, json .. "\n")
    else
        print(json)
    end
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
    local destination = string.format("%s/manual_%s.jsonl", LOG_DIRECTORY, os.date("%Y%m%d_%H%M%S"))
    file.Write(destination, file.Read(CURRENT_LOG, "DATA") or "")

    local message = "[Z-City Diagnostics] Wrote data/" .. destination
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, message .. "\n")
    else
        print(message)
    end
end)
