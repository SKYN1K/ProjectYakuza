# Validation: 0.56.0

PZ was not launched. This is an offline multiplayer audit and relaxed-weapon selector repair, not a live server/client certification. Native zombie ownership migration, real latency/streaming and final GPU appearance still need an in-game test with matching files on every peer.

## Runtime and network

All 21 Kahlua fixtures pass (5,781 assertions); all 50 production Lua modules compile. The source policy check reports 585 source files with zero comments, and all six lexical preservation tests pass. The complete offline reference runner has 66 passing steps.

New MP regressions reproduce the two-counter finisher restart and verify melee/stomp versus timed-action restart ownership, repeated barrages, fresh reconnect sessions and restarted sequence counters, old-session state/damage rejection, scoped duplicate/deferred-cache reset, native actor replacement, effect/Heat/profile/charge/link cleanup, absent addon styles, replaced-actor temporary protection release and authoritative session tagging. Added command-order tests verify unchanged snapshots are reused and changed state is delivered before a dependent command. Weapon regressions verify server response/juggling lookup uses the actual weapon style view for primary and supplemental hits.

Existing tests retain authoritative inventory-ID delivery/acknowledgement, delayed equipment, explicit stance entry, normal and Extreme attacks, charge release power, native primary-hit non-replay, three-target supplemental damage, source-timed barrages/depletion, Tiger Drop timing/cooldown, guard, quickstep movement/limits, source clip observers, heat/aura, taunt completion, blood/hit effects, local music/volumes/UI and CVF integration. Grabs remain temporarily disabled; their retained implementation is not enabled by this update.

Native observer checks import/select all 304 event-free observer nodes in both repeat cycles. Existing resource/native-API probes pass. Inspection of the supplied installed B42 bytecode confirms native Kill/onKilled and corpse/death broadcast paths; no game classes/JARs are modified or bundled.

## RMB-released weapon holds

Nine existing idle/walk/run-blend selector files now reference native relaxed weapon holds. Bats/blades select Bob_IdleBat, Bob_WalkBat and Bob_WalkSlow_Bat; knives select Bob_Idle, Bob_Walk and Bob_WalkSlow. These are existing game animations, imported directly by native B42 checks; their source paths/hashes are in locomotion-nodes.json. The selectors reject frozen combat-arm carry clips, remain scoped to DoD and the correct weapon profile, and exclude Aim=true. Native lower-body motion/grips remain together. All 100 existing locomotion selector/fallback contracts pass.

No animation file was created or edited. The previous reference carry composites remain unselected. Aimed combat stances, custom attacks and the 0.55.0 running cadence/travel tracks are byte-identical. All 617 existing motion/image/audio assets match the 0.55.0 ZIP byte-for-byte. There are no new media files and no AI-generated/upscaled assets. The separate voice-pack project is untouched.

## Installation and release

Verify the existing 1,317-file local installation against the 0.55.0 ZIP, back up only replaced existing files, and install the new payload. Verify complete source/install/ZIP equality, publish unique v0.56.0 using Publish-CombatRelease.ps1, compare its GitHub ZIP digest and verify a clean worktree. Extraction/native-inspection folders, previews, backups, raw game files and credentials stay out of Git and the install ZIP. Fully restart matching client/server installations; a live two-client test remains outstanding.
