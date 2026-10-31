# Validation: 0.57.0

PZ was not launched. This update was validated offline with the installed B42 importer/node parser, Kahlua and supplied local motion sources. Live pose blending, exact source-strike alignment, native zombie ownership migration and real multiplayer latency remain in-game verification items.

## Regression coverage

All 22 Kahlua fixtures pass (6,219 assertions). The complete offline runner reports 69 passing steps. All 52 production Lua modules compile; 607 source files contain zero comments, and six lexical preservation tests pass.

New directional checks exercise all integer turn sectors, invalid vectors, actual Runtime move selection, native light routing, x0.75 damage, Extreme bonus application, chain endings, finisher exclusion, no automatic player rotation, post-contact quickstep readiness through the owned movement lock, interruption cleanup, expiry and style/weapon isolation. Existing three-target supplementary hit tests now include all three directional moves.

Taunt lifecycle checks verify attention starts only after complete playback, never after interruption or equipment changes. MP checks verify an observed source-duration lease, early completion rejection, one-time completion, server-selected target IDs, non-damaging native aggro, radius/attacking/downed/path filters, native zombie ownership, duplicate suppression, streamed target retries and a maximum of 32 path candidates per completion. Weapon MP checks reject directional moves while armed and preserve native primary plus exactly-once x0.75 supplementary damage. Existing controls, heat, charge, barrages, counter, guard, movement, aura, hit/blood effects, HUD, intro, music, volumes, CVF and reconnect/session tests remain green. Grabs remain disabled.

## Approved supplied animation conversion

The three converted clips retain all 46, 46 and 58 source frames. Exact fighter_command.cfc mappings identify AttackRevL, AttackRevR and Heavy_Rev. Source GMT/BEP, rig, native fist/prop inputs and output hashes are recorded in directional-attack-assets.json. No root-yaw normalization, synthesized motion, source trimming or invented blend poses are baked into the files.

Source comparisons cover 5,100 finite retained body samples. Native import reads all three clips; native FK verifies 300 hand-prop pairs, with maximum matrix error below 0.00001. Native owner nodes select only for the correct style/profile and each has exactly one collision. BEP contacts occur at frames 10, 10 and 11; cancel markers are exactly one frame later. Owners have full-body masks, explicit movement start/end flags and early-transition support for committed quickstep cancellation. All 316 event-free MP observer nodes import/select in two cycles. Reflection confirms the native aggro, target and zombie-ownership methods.

All 617 existing motion/image/audio files match 0.56.0 byte-for-byte. Only the three approved source-retargeted motion files are added. No image/audio assets or separate voice-pack files are created or modified; no AI/upscaling is used. XML/Lua changes implement routing and eligibility rather than creating artwork.

## Installation and publication

Verify the 1,318-file installed 0.56.0 tree against its release ZIP before updating. Back up only replaced existing files, install the new payload, verify complete source/install/ZIP equality, publish unique v0.57.0 through Publish-CombatRelease.ps1 and compare its GitHub asset digest. Confirm a clean Git worktree. Extraction/native-inspection folders, intermediate retargets, previews, backups, raw game files and credentials stay outside Git and the install ZIP. Restart matching server and client installations before live testing.
