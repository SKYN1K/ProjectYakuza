# Validation — 0.32.0

No Project Zomboid game/server was launched. Live multiplayer, final GPU appearance and actual input feel are untested. Offline checks use the installed B42 Kahlua VM, native importer/parser/selector and ImageData decoder.

| Kahlua fixture | Passing assertions |
| --- | ---: |
| Combat/aura/music lifecycle | 2,633 |
| Charged branches, unchargeable doubles, UI, particles, outline | 127 |
| One-strike quickstep | 71 |
| MP authority/catalog/observers | 98 |
| Extension API | 42 |
| Shipped starter | 9 |
| Heat/shove | 23 |
| Activation SFX | 35 |
| Locked style entry | 21 |
| Taunt/aura/low-smoke cleanup/MP | 152 |
| Optional CVF adapter | 63 |
| Selector/persistence | 50 |
| Native Mods settings | 94 |
| Total | **3,418** |

All 37 production Lua files compile. Charged checks cover all four branch-specific wind-ups/releases, variant-bound tickets, immediate ordinary second-finisher queuing, holding without a later charge, public-API follow-up rejection, native retry/asynchronous completion, expiry, interruption, pause and movement restoration. Additional checks retain a valid charge press past light-combo expiry and follow an already-buffered light that actually executes. HUD checks select original dark body/head/orb/connector/tail regions, preserve all six dark orbs, use purple-blue glow, pause animation and restore normal white artwork on mode exit. Aura checks distinguish additive upper flames from alpha-blended low smoke, release extra smoke instances on mode exit and restore blend state after injected failure.

Eight new source-derived skeletal clips import through native Assimp/JAssImp as one clip each with 35 channels. Wind-up durations are .333333/.533333/.4/.533333 seconds; source release durations before playback scaling are 1.566667/1.233333/1.633333/1.466667 seconds. Hash/range checks confirm the supplied GMT sources, original sample counts and identical wind-up/release endpoint poses across all 105 rotation/scale/translation channels per branch. Non-looping wind-ups hold their final source pose; no additional animated poses were invented.

All ten charge action/melee nodes parse natively. Holds have no collision events; each release has exactly one native collision. Both event-free MP cycles parse/select only for their clip, with 180 observer nodes in total. The independent addon observer builder passes its deterministic/non-destructive dry-run, native parser/compiler and safety checks.

All 130 aura PNGs decode through native ImageData. All 64 new 64x64 smoke crops exactly match the supplied DDS pixels and SHA256 records. Existing 66 flame/wisp exports still match their original source crops. The complete original HUD atlas matches the supplied btl_hact.dds pixels; six Extreme Heat rectangles remain within its native bounds. All 379 pre-existing animation/image/audio files retain v0.31.1 bytes. Only eight original-motion splits/retargets and 64 original texture cells are added; no generated/upscaled media or voice-pack files are included.

The previous-release-checked installer backs up only replaced/removed installed files, preserves unexpected local edits by refusing to overwrite them, and verifies every installed source byte. The ZIP contains the source mod folder only; extraction folders, previews, backups, credentials, compiled probes and the separate voice pack remain outside Git/release artifacts.
