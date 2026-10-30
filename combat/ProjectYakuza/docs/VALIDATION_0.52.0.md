# Validation: 0.52.0

PZ was not launched. Live visual quality, foot planting, physical input and multiplayer playback remain untested.

## Approved source motion

The user explicitly approved retargeting the supplied running and weapon-hold clips. All 33 frames of the source run and 61 frames of each alternate weapon hold are retained in their direct converted body clips. The three walking profiles use native lower-body motion plus the supplied hold upper body; its complete loop is resampled to the native walk cycle. Native hand/finger conventions and prop offsets are reused. No AI, new artwork/audio, upscaling or invented body motion.

Provenance is recorded in locomotion-assets.json: original GMT/rig hashes, native animation/finger/offset hashes, intermediates and output hashes. The existing converter retains source rotations, removes horizontal source world travel and fits the supplied skeleton to B42. Running then retains native Translation_Data and helper channels to preserve real native movement rather than just showing in-place feet.

All 607 previous motion/image/audio files and 449 previous native XML files are byte-identical to 0.51.0. Only the 13 approved derived motion files and 10 new selectors are added to media. The separate voice pack is untouched.

## Native import, movement and source checks

LocomotionAssetProbe imports all 13 clips through B42's Jassimp/ProcessedAiScene path, checks exact names, durations, frame counts and 18,015 finite bone samples. Source carry clips retain the existing 35-bone retarget rig; run/native-walk composites retain the native 45-bone hierarchy with clothing/helper bones. Run and walking imports must retain nonzero Translation_Data travel; this check caught and prevented a zero-travel intermediate during development.

The source validator compares 17,574 local bone samples to the source retarget/native walk functions, with maximum matrix error 5.140901E-7. Native FK checks 816 hand-prop pairs across 12 armed clips, maximum error 7.092953E-6. Run/hold loop endpoints match within 1E-4, excluding continuous deferred travel. Walk composites do not worsen the original native lower-body seam (native slow-walk maximum matrix component difference 0.0152764). No endpoint pose is invented to hide it.

Native selection evaluates all 10 nodes together by group, passing 100 matching/rejection cases for style, activation, profile, aim, injury, trees, sneaking, turning and overburdened flags. Bone tracks and 2D blend references resolve, events are footsteps only, and blend durations are bounded at 0.25 seconds. Original native walking leg samples and native travel scalars remain; healthy run cadence/travel is matched using the ratio of source/native loop durations. PZ's source movement path and deferred track contract were inspected locally.

## Regression checks

All 5,489 Kahlua assertions across 21 actual-module fixtures pass. All 48 production Lua modules compile. Six lexical preservation tests pass; the comment audit reports zero comments across 594 source files. Existing stance-entry prop repair, Tiger Drop window/music separation, combat/weapon/MP, charge/heat, source contacts, blood/HUD/aura pixels, 316 event-free observers, addon API and lifecycle checks pass. No production Lua behavior changes beyond the version string are needed for these selectors.

The native new-motion checks were rerun after the final deferred-travel repair. No new polling, scans, input interception or custom network messages were introduced. Existing replicated style/profile flags scope remote playback; normal movement remains PZ's responsibility.

## Install and limits

The existing 1,300-file installation must match the 0.51.0 release ZIP before installation. Back up only replaced files and compare every source/install/ZIP byte plus the uploaded release digest. Build scratch files, extraction directories, backups and previews remain excluded from Git.

This pass covers normal non-aimed running and relaxed armed standing/walking. It does not replace sprint/start/stop/turn clips or native special movement. Source-only retargeting and 0.25-second crossfades do not reproduce Dragon Engine IK; assess appearance and exact foot contact after restarting matching clients/server. No live MP or GPU result is implied by the offline checks.
