# Full-arm punch coating and trails (0.65.0)

The Lua-only replacement uses the already supplied Y6 flame, glint and spark textures as overlapping world sprites from the PZ shoulder to the fist. The visual target is an arm-sized blue-white coating with a short trailing wake, using the supplied game references and [SEGA's Y6 Extreme Heat presentation](https://asia.sega.com/ryu-ga-gotoku/six/battle/battle03/). No artwork, animation, audio, model or texture was generated, resized or edited.

The built-in trigger remains DoD's configured first normal light. Other moves/styles are not opted in automatically. Charge particles, impact splashes on victims, the body aura, damage and attack timing retain their existing behavior. Addons can opt a light move into the renderer with their own permitted numeric source track and `attackEffects` window.

## Position and coverage

`AttackTracks.dd_light_01.frames` retains its original 31 model-space forearm, wrist and knuckle samples. New `upperFrames` contains the matching PZ upper-arm/shoulder XYZ samples at the same 30 Hz. All four positions are independently verified against B42's native importer and HelperFunctions forward kinematics from the unchanged converted source clip. The hand centre remains 35% from wrist toward knuckle. See [Provenance](punch-effect-assets.json).

The current native animation phase interpolates those positions. The continuous rendered body angle projects the current pose into world space using the independently checked B42 model projection. Eleven overlapping animated flame centres span shoulder to elbow to fist, with three soft inner cores. Centres use actual absolute world coordinates and native sprite half-height centring; there is no outward inset, blanket shoulder-yaw adjustment or fixed screen-height correction. Per-particle alpha uses normal blending, not an additive brightness layer.

This is deliberately an approximation of the supplied PZ animation, not live attachment to the final blended bones. Walking, blending, IK, clothing/model proportions and self-occlusion can still differ. The user chose to keep the normal Lua-only launcher after inspection showed the live bone-transform classes are not exposed to ordinary Lua. No Java integration or launcher change was installed.

## History and animation

A fixed twelve-pose ring stores shoulder, elbow and fist world coordinates, with at least eight milliseconds between records. Four trail particles interpolate recent poses 18..72 ms behind the arm. They never reproject past positions through the current facing, so turning does not swing old particles outwards. A root jump over one tile or a significant floor change clears the history. Four short-lived hand sparks reuse those recorded positions and existing source artwork.

The current coating follows the source track immediately. Native animated sprites advance only when the effect clock changes; repeated draws at the same clock do not advance them twice. Pause freezes the source clock, history and animation. Clip restart/change, attack completion, hit interruption, cancellation, style change, death and world exit release the scoped state and sprites. A failed draw restores the incoming blend mode and cleans up.

## Addon contract

```lua
attackEffects={
    track="myaddon.leftPunch",
    from=2/30,
    to=14/30,
    swingFrame=3,
},
```

Register the matching numeric track in `ProjectYakuza.AttackTracks` before use. `animation` must match the move, `fps` defines the sample rate, and each `frames` row contains forearm XYZ, wrist XYZ and knuckle XYZ. Optional `upperFrames` supplies shoulder XYZ at every corresponding frame; omitting it keeps coating coverage at forearm-to-hand rather than inventing a shoulder position. Source windows and optional whoosh `swingFrame` retain their previous semantics. Author new paths from permitted supplied motion; registering metadata does not create animation assets.

`AttackEffects.registerLimbProvider(id,fn)` remains an optional adapter hook. A move chooses its `limbProvider` ID, defaulting to `live`. The callback receives player, animation name and source time, returning forearm XYZ and desired hand-centre XYZ in absolute world coordinates. It may additionally return shoulder XYZ as values seven through nine. A six-value provider keeps its exact hand/forearm endpoints and uses the sampled shoulder offset. Invalid, partial or failing results fall back with a one-second retry throttle. `removeLimbProvider(id,fn)` unregisters it. No provider is bundled in the Lua-only setup.

## Limits and multiplayer

Each active actor allocates at most 22 detached native sprites, with the existing eight-actor cap: 176 simultaneous instances at maximum. Native sprites and history rows are allocated at activation, not per particle draw. Root position/angle is captured once per actor draw, and native clip-slot lookup is reused. Actual particles render directly at their world coordinates, avoiding redundant actor-coordinate reads per sprite. Hooks are installed only while an effect is active.

MP observers use the same configured clip/window, local animation clock and actor-facing projection. History is reconstructed locally; no particle positions or extra packets are sent. Observer clip changes and remote cleanup release the same state. Matching mod/track files are required on all clients. Offline tests cover source samples, 32 facings, coverage throughout the source window, retained world positions while turning, teleports, pause, provider contracts, bounded histories/instances and cleanup. No live GPU or multiplayer latency test was run.
