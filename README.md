# Z-City
Z-City is a GMod addon which modifies character damage and controls. Z-City also comes with its own weapon base and a gamemode

https://github.com/uzelezz123/8bit_zcity - 8bit module (compiled version is in lua/bin)

Optional Discord RPC module for clients:
1. https://github.com/YuRaNnNzZZ/gmcl_steamrichpresencer/releases/tag/2023.07.20
2. https://github.com/fluffy-servers/gmod-discord-rpc/releases/tag/1.2.1

The current version in the repository is 1.4.0

## The numbers in the version number indicate:
A.Bcc -> 1.000
- A -> Global updates
- B -> New mechanics, gameplay changes
- c -> Fixes and other small things

## Support us
**Donation links:**
- [Yoomoney](https://yoomoney.ru/fundraise/17GFEQH326Q.250101) 
- [Boosty](https://boosty.to/sadsalat/donate)

**Crypto**
- USDT(TRC20): TYgpaZgHQr6qEgemhHzVvV7AQESiyhHpZD
- BTC(BTC): bc1qa8pk9ag6xa5yav2mvlxkra8xk25lg3htgfqh5w
- ETH(ERC20)* 0x72AdCCcCEB4E323C64bCF0955A779DD9298E9483

## Crash diagnostics

The server keeps a lightweight JSON-lines flight recorder in
`garrysmod/data/zcity_crash_diagnostics/current.json`. The `.json` extension is
required because Garry's Mod rejects writes to unsupported extensions such as
`.jsonl`; the contents still use one complete JSON object per line. It records
periodic Lua memory/entity/timer/physics samples, shallow ULib state, player
connections, collision-rule mutations, crazy-physics events, and the last completed stage of
each grenade explosion. If the server exits without a
clean `ShutDown` hook, the next startup preserves the log as
`unclean_YYYYMMDD_HHMMSS.json`.

Useful server console commands:

- `hg_crash_diagnostics_status` prints whether recording is enabled, the exact
  data path, file/marker existence and size, and the current server snapshot. It
  also attempts to recreate a missing active log when diagnostics are enabled.
- `hg_crash_diagnostics_mark <message>` adds a timestamped marker before a test.
- `hg_crash_diagnostics_dump` copies the current log to a timestamped manual log.
- `hg_crash_diagnostics 0` disables recording; it defaults to enabled.
- `hg_crash_diagnostics_interval 15` controls heartbeat frequency (effective on
  the next server start).
- `hg_crash_diagnostics_collision_rules 0` disables the more detailed
  collision-rule call-site recorder while leaving the rest of the flight
  recorder enabled.

At startup, the server console prints either the active `data/.../current.json`
path or a warning explaining why recording is disabled or the file could not be
created. If the directory contains only `session_active.txt`, check that
`hg_crash_diagnostics` is `1`, restart the server, and check the console for a
data-directory permissions error. The marker is created only after
`current.json` has been created successfully. The JSON log starts with a
`log_created` record because Garry's Mod may not create data files when asked to
write an empty string.

After a crash, inspect the final records in the newest `unclean_*.json`. A
`grenade` record without its matching `*_complete` stage narrows the failure to
sound networking, blast damage, the physics pass, or shrapnel processing. A
steady increase in `snapshot.lua_memory_kb`, `snapshot.entities`, or
`snapshot.timers` across heartbeats points toward a leak. Snapshots also split
out physics props, ragdolls, constraints, frame/tick timing, and whether physics
is paused. ULib access changes are recorded as `ulib` events with a fresh
snapshot.

For warnings such as `prop_physics[305]: Changing collision rules within a
callback is likely to cause crashes!`, look for a nearby `collision_rules`
record. It includes the mutation method, Lua call site and stack, callback name
when detectable, model, position, owner, parent, collision state, and physics
velocity/mass. Repeated bursts are capped to protect the diagnostic log; an
`events_throttled` record reports how many duplicate/excess events were omitted.
`physics` records additionally report physics pause/resume transitions and
`OnCrazyPhysics` entity state.
