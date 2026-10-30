# Validation: 0.49.0

PZ was not launched. GPU appearance, live gameplay and live MP latency were not tested.

## Approved source motions

Nine supplied Kiryu GMT clips are retargeted: Heavy_Rev, four AttackRevFin first finishers and four AttackRevFinW doubles. The original fighter_command.cfc contains each exact command-to-GMT string pair. Source GMT/BEP, original source/PZ rigs, native finger grip, bind data and final output hashes are recorded in extreme-attack-assets.json and verified.

All 19,460 bone samples have finite numeric channels, normalized quaternions, expected frame counts/times and unit scales. Where local full-retarget intermediates are present, every retained non-prop position/rotation/scale sample equals the full source retarget after the documented prefix trim. All first finishers/neutral heavy retain their entire frame ranges. Only double branch 2 omits one leading source frame. No new poses, baked bridge frames, graphical/audio generation, AI or upscaling.

Every new native owner has one collision exactly at its original BEP type-68 contact, adjusted for that one prefix frame. Source-pose markers choose first frames 27/23/26/29 for the pairs. Local bone rotation RMS gaps are 0.061/4.399/1.031/0.780 degrees and maximum root-position gap is below 0.001 model units. No synthesized pose transition is included; doubles use the native 0.10-second blend.

Native B42 Jassimp/ProcessedAiScene/FK imports all nine clips and checks 1,112 hand-relative prop pairs against the native authored bat grip; maximum matrix error is 0.000007092953, below 0.0001 tolerance. ExtremeAttackProbe parses/selects all nine native owners, verifies one collision each, and rejects other styles/weapon profiles. Thirty-six new event-free observers bring the existing native selector checks to 316 nodes, 158 per cycle. Existing 27 weapon/heavy imports, 41,720 samples and 31-clip/2,568-pair prop checks retain their passes.

All 594 existing motion/image/audio files and all 402 existing native XML files are byte-identical to 0.48.0. Only nine authorized source-motion clips and 45 owner/observer XML files are added to media. Existing effects, blood pixels, HUD/aura frames, sounds and the separate voice pack are untouched.

## Actual-module runtime and MP checks

4,689 Kahlua assertions across 19 fixtures pass. All 45 production Lua files compile. The dedicated Extreme attack fixture has 93 checks and embeds actual Heat, Runtime, weapon/style definitions and existing combat modules. It verifies inactive mode rejection, original neutral/branch fallbacks, nine mode variations, unchanged heavy and Heat damage factors, all four paired doubles, source-marker-gated recovery, movement handoff cleanup, no third finisher, full first playback without additional input, depletion during/between attacks, last-swing fuel cost depletion, matching follow-up after depletion, window expiry, weapon isolation, unchanged LMB motion and another style's fallback.

The expanded 56-check weapon MP fixture verifies mode gating, active first registration, ongoing swings after depletion, branch matching/consumption/expiry for depleted follow-ups, cached protocol lookup, the new native selector and one bounded final cost-depleted swing. In its selector scenario the reference scan performs 34 actor-variable reads while the compiled cache reads 5. Existing authority, duplicate/range/weapon ownership and extra-hit checks remain. The refreshed 2,717-check framework fixture exercises all 32 existing attack definitions through multihit alongside lifecycle/heat/effects/music checks.

Blood, taunt, aura, charge/source-hold timing, native texture pixels/paths, audio, CVF, configurable UI/controls, item protection and addon extension tests retain their passes. Six lexical tests pass; the comment audit reports zero comments across 566 tracked/whitelisted source files. The release publisher passes native PowerShell parsing.

## Installation and remaining visual checks

The installed 1,230-file 0.48.0 tree matches its prior release ZIP before updating. Back up only existing replaced files, install the new payload, verify complete source/install/ZIP equality, publish a unique 0.49.0 release and compare its GitHub asset digest. Local extraction/intermediate/preview/backup files and credentials remain ignored.

The new source poses, contact fractions, mode gates and multiplayer presentation are verified offline. Actual model proportions, overlay/blend appearance, facing contacts and live MP timing require user assessment after a full restart on matching server/client versions. Grabs remain disabled. Existing charged/light/weapon motions and damage balance are unchanged.
