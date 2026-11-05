# Validation: 0.85.0

PZ was not launched. Validation is offline; native visual playback and actual MP latency still require an in-game check after restart.

- All 28 Kahlua gameplay suites pass, including 1,295 grab and 1,808 MP checks. All 71 production Lua files compile with the game's compiler.
- Grab input tests use a remapped keyboard binding, verify a fresh press throws instead of releasing, holding it cannot restart the throw, and Heavy no longer throws when a wall action is unavailable. The separate Throw binding is absent.
- Crowd tests cover a bounded 25-square scan, repeated object deduplication, nearest-first target cap, native outward knockdown, unchanged health, walls, dead/downed/held/paired targets, different floors, targets behind the body and out of range. Unconfigured styles opt out; invalid radius/force/cap/offset authoring is rejected.
- MP tests reject premature throw impacts and stale grab IDs before damage, verify server-chosen secondary targets get no extra damage, deduplicate replicated knockdowns, reject invalid force and preserve the primary victim's prone landing and AI cleanup.
- Native passive-UI routing, stun/PvP reaction APIs and the supplied settings-background import checks remain green. The complete regression suite includes Rush/QTE, weapons, heat, sound, style entry and input prompt checks.
- All visual/audio asset bytes match v0.84.0. No new asset conversion or generated media was needed. The source-comment scanner reports zero comments before release.

Installation backs up only changed existing files and verifies complete source/install/ZIP equality. No separate voice-pack files are touched.
