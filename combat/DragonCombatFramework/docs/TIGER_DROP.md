# Tiger Drop — 0.17.0

While holding RMB with Dragon of Dojima equipped, tap MMB while a standing zombie in front of you is in the last 0.2 seconds before its bite collision. Tiger Drop takes priority over the MMB finisher only when its target and timing checks succeed. Outside that window, existing finishers retain their input. There is no queued or held-button parry.

The player must be free to act: no other combat/timed action, vehicle, climbing, knockdown or hit reaction. Only the attacking zombie targeting this player is countered, within 1.5 tiles and the forward cone. A successful counter cancels that attack's target, calls the native Kill(player) path immediately, and plays Kiryu's original P_KRU_BTL_SUD_ath_cntr_tora.gmt animation (1.1 seconds). There is no area kill or player invulnerability. No effects apply to failed/early/late inputs or rejected action queues.

Cooldown: 60 real seconds after a successful counter. The ready timestamp is kept in player mod data, so save/reload does not reset it. Misses and out-of-window presses do not consume it. Existing heat, damage multipliers, HUD and character aura are unchanged.

## Normal-launcher knockback choice

The user chose to keep the normal game launcher instead of installing a Java bridge for direct Bullet ragdoll impulses. This implementation is Lua only: an outward native hit direction, hit force of 12, the native physical-hit-reaction flag and a short collision-checked outward movement burst. The burst uses moveUnmodded, is bounded to 0.16 tiles per tick / 2.5 tiles total / 300 ms, stops against obstacles, and relinquishes movement immediately if native ragdoll simulation becomes active. There are no coordinate teleports, global physics settings or repeated force loops after that burst. This approximates a launch; it does not claim direct airborne ragdoll-force control. Native physics options, the body/death state and collision geometry affect visible results. Multiplayer ragdoll behavior is not provided by this client feature.

## Timing source and scope

The installed B42.21 start bite clip is 1600/4800 = 1/3 seconds. The success clip is 4800/4800 = 1 second. Both native nodes use speed 1.04; collision remains at success fraction 0.2. The final 200 ms therefore begin at start fraction 0.976 and continue through success fraction 0.2. Counter-enabled clones retain all original native conditions/events, adding scoped SetVariable markers. They do not replace base-game files. Failed, interrupted, completed or already damaging attacks cannot be countered with stale markers.

Marker nodes are enabled only on nearby standing zombies before attack entry while the local player can counter. Beginning to aim after a zombie has already entered its attack does not retroactively restart that attack. Tracking scans at most 25 nearby squares every 50 ms while ready; no global OnZombieUpdate loop is registered. Counter movement hooks unregister when empty. Pause blocks input and freezes the movement burst.

## Validation

- Original GMT retargeted onto the existing PZ skeleton. The installed game's Jassimp/ProcessedAiScene imports DCF_DD_TigerDrop with a 1.1-second duration, 35 animation channels and 34 right-hand rotation keys.
- Native AnimState selection verifies exclusive Tiger Drop timed-action playback, unrelated action exclusion, and original-versus-tracked bite-node selection for both phases.
- Native Kahlua tests cover early/out-of-range/behind/other-target/already-hit/interrupted/completed/paused rejection, MMB priority and held-button rejection, immediate native kill and attacker credit, queue rejection, force direction, exact 59.999/60-second cooldown boundaries, movement cleanup, native-ragdoll ownership handoff and hook disposal.
- All existing combat, heat, aura and music regressions remain covered. Live gameplay and the visible knockback have not been tested.
