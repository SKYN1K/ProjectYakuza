# Source-tracked punch effects

Version 0.34.0 adds a narrow prototype for Dragon of Dojima's first light attack. Existing source textures are rendered as world sprites along the original left forearm/fist trajectory. It is visible without heat, stronger and purple-blue during Extreme Heat. Existing hit sparks and body auras are independent.

## Move configuration

`lightAttacks[1].attackEffects = {track="dd_light_01", from=2/30, to=11/30, swingFrame=3}` opts in. Omit the field to retain the existing presentation and whoosh schedule. `from`/`to` are source clip seconds, not sped-up wall time; `swingFrame` uses the current 30-fps source convention. The move's `animation` must match its track. Do not copy the DoD hand path onto a different animation.

`ProjectYakuza.AttackTracks.dd_light_01` contains an animation name, fps=30 and 31 numeric frames. Each row is model-space forearm XYZ, wrist XYZ and knuckle XYZ, extracted through B42's own animation importer and matrix helpers. These are code-side positions, not new animation/media. A separately supplied matching track can be added under a unique addon key after requiring AttackTracks; the current renderer expects that same three-point arm layout. This is not a general foot/shader attachment API. Automatic events currently cover light attacks; other move types require their own scoped presentation hook. Remote automatic selection currently covers each style's first light.

AttackEffects reads exposed scalar `dbgGetAnimTrackName/Time/Weight` methods and `getAnimAngleRadians`. It does not access unexposed model/animation-player objects or need Java injection. A bounded layer/slot search locates the clip, then caches its location. Positions interpolate the original 30 Hz path; projection mirrors native Model.vectorToWorldCoords (+pi/2 rendered angle, X mirroring, 1.5 horizontal/.61237234 vertical scale) and IsoUtils. The engine's WorldEffects attach contract centers each sprite at the projected source point. Facing is continuous.

The existing Feedback controller schedules this move's original punch whoosh against source frame 3 instead of an estimated wall-clock delay. It respects pause/cancellation and does not duplicate or change the existing sound volume. Remote visuals use the existing state/observer transition; native MP audio behavior is unchanged.

## Lifetime and budget

The effect uses existing HitGlint, ChargeSpark and ExtremeHeat_flame textures unchanged. Three glints, one small animated flame, three short trail samples and three departing sparks give ten instances per active actor, with an eight-actor cap. No zombie scan, additional network packet or idle tick/render callback is introduced. Rendering uses scoped normal alpha and restores the prior renderer flag on success/failure. World/actor/move changes dispose instances and unsubscribe idle callbacks. Pause freezes time and flame progression.

## Fidelity limits

The source path is exact at the imported source key times, then linearly interpolated in code. It does not read the final blended pose; native locomotion, torso twist, transition weights and custom character proportions may shift the rendered limb. This creates a particle glow near the limb, not an emissive material coating or true silhouette outline. It uses the existing post-render IsoSprite world projection, whose occlusion does not equal native mesh depth rendering. Live GPU and multiplayer appearance need gameplay verification before extending it to all strikes.

Provenance: [punch-effect-assets.json](punch-effect-assets.json). No visuals/audio were synthesized, resized, repainted or exported by this update. Existing unrelated effects are unchanged.
