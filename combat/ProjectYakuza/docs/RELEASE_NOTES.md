# Project Yakuza 0.87.0

- Attack effects now resolve the animation actually playing within the committed move, including linked double finishers and paired failure endings. They use that clip's native frame and PZ limb samples, with blend-weight selection and cached lookups.
- Rebuilt the numeric effect catalogue from the current supplied motions: 83 clips and 104 contact windows, including grab strikes and the current Heat Rush sequence. Finishers select their own striking limb instead of inheriting a charge-up pose; kicks use hip/knee/foot tracks.
- Added a fading world-space wake lasting up to 0.2 seconds. It can remain briefly after an attack ends or the next attack starts. Turning does not rotate old trail positions. Teleports, interruption, style changes and world exit clean up safely.
- Kept fixed multiplayer budgets: eight active actors, eight retired wakes, 30 sprites per active actor and 12 retained sprites per wake. Observers reconstruct effects locally without new network packets, and repeated snapshots no longer reset them.

No visual/audio/motion assets were created or changed. Existing supplied Y6 flame, glint and spark textures are reused. Damage, attack timing, charge effects and body auras are unchanged. Offline validation only; PZ was not launched. See [validation](VALIDATION_0.87.0.md). Restart game/server and use matching versions on all MP clients.
