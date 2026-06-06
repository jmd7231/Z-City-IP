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
`garrysmod/data/zcity_crash_diagnostics/current.jsonl`. It records periodic Lua
memory/entity/timer samples, shallow ULib state, player connections, and the
last completed stage of each grenade explosion. If the server exits without a
clean `ShutDown` hook, the next startup preserves the log as
`unclean_YYYYMMDD_HHMMSS.jsonl`.

Useful server console commands:

- `hg_crash_diagnostics_status` prints the current memory and object snapshot.
- `hg_crash_diagnostics_mark <message>` adds a timestamped marker before a test.
- `hg_crash_diagnostics_dump` copies the current log to a timestamped manual log.
- `hg_crash_diagnostics 0` disables recording; it defaults to enabled.
- `hg_crash_diagnostics_interval 15` controls heartbeat frequency (effective on
  the next server start).

After a crash, inspect the final records in the newest `unclean_*.jsonl`. A
`grenade` record without its matching `*_complete` stage narrows the failure to
sound networking, blast damage, the physics pass, or shrapnel processing. A
steady increase in `snapshot.lua_memory_kb`, `snapshot.entities`, or
`snapshot.timers` across heartbeats points toward a leak. ULib access changes
are recorded as `ulib` events with a fresh snapshot.
