# Validation — 0.33.0

No Project Zomboid client/server was launched. GPU appearance, exact input feel and a live multiplayer session remain unverified. Offline checks use the installed game's Kahlua VM, animation importer/parser/selector and native image decoder.

| Kahlua fixture | Passing assertions |
| --- | ---: |
| Combat/aura/music | 2,713 |
| Charge source timing, looping holds, particles, UI and outline | 150 |
| Quickstep ownership | 71 |
| MP authority/catalog | 98 |
| Addon API | 42 |
| Shipped starter | 9 |
| Heat/shove | 23 |
| Activation SFX | 35 |
| Locked entry | 21 |
| Taunt/activation aura, alpha material and exact .55 flame speed | 165 |
| Optional CVF | 63 |
| Selector | 50 |
| Mod settings | 94 |
| Total | **3,534** |

All 37 production Lua files compile. The charge fixture checks source pause times, native wind-up-to-looping-hold transition, long holds without forced release, release/interrupt restoration, missing hold acknowledgement, unchanged unchargeable second finishers, branch-bound native strike tickets, twelve bounded world sprites, ready pulse, pause, stale-actor cleanup and blend-state restoration after injected render failure. Aura checks verify each flame speed is exactly .55 of its previous value and both flames/smoke use alpha blending.

The four supplied BEPs independently verify Charge event type 206 at frames 6/7/6/5 (30 fps) and source hit-window starts at 18/19/15/18. The source file hashes are recorded in y6-charge-timing.json. Engine-wide/full-charge thresholds are not documented by those properties: input adaptation and B42-specific blends are not claimed as bit-exact Dragon Engine behavior.

Twelve native source-derived clips import with 35 channels each. Wind-ups last .2/.233333/.2/.166667 seconds; releases last 1.7/1.533333/1.833333/1.833333 seconds at source 1x playback. Each hold is a .033333-second loop repeating one original source sample. All 105 rotation/scale/translation channels match across wind-up endpoint, hold and release start. No new pose or animation curve is authored.

All fourteen native charge nodes parse; holds have no collisions and releases have one. 188 event-free observer nodes (94 per cycle) parse and select only for matching remote clips. The addon observer builder passes its independent deterministic/non-destructive generation, native parsing/compilation and safety checks.

All 130 aura PNGs decode through B42 ImageData. The 64 changed flame files exactly match original alpha-bearing e_j_0076_aura_gA8L8.dds cells; no pixels/alpha are repainted or synthesized. Pixel tests reject a visible black matte. Remaining source smoke/HUD/spark assets retain their original pixels. Native filename-contract checks resolve all 229 aura/burst frame paths.

Of the 451 previously shipped media files, only eight charged wind-up/release clips and 64 flame cells change. Four source-pose hold clips are added; all other 379 prior media files are byte-identical. No generated artwork, audio or upscaling is used. The separate voice pack is untouched.

Installation compares old installed files against v0.32.1, backs up only changed paths and verifies all installed source bytes. The release ZIP contains the source mod directory only; extraction folders, previews, native test libraries/classes, credentials and backups stay excluded. A full restart is required to refresh cached animation/texture assets; MP clients/server need the same version.
