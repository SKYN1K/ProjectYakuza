# Standalone emotes 0.2.4 validation

Lau Ka Long retains cut 007 frames 112 through 190 and now uses cut 008 frames 1 through 225. The previous version ended at cut 008 frame 75. Adding 150 original samples extends playback by exactly five seconds, giving 304 samples and 10.1 seconds at the original 30 fps. Fresh archive entries verify both actor motions, both independent spear motions, resource bindings, CMN and original skeleton.

The movement path samples the complete original pelvis hierarchy, including center and vector movement. A constant stage-origin offset joins the matching cut boundary. Native Translation_Data carries the planar path; the emote selectors enable native deferred movement with zero deferred rotation. No Lua teleporting, synthesized poses, slowed motion or repeated hold frames are used.

The source validator independently recomputes every source sample and path offset, verifies original body channels, native limb lengths, skinned sole heights, source spear rotation and per-mesh shaft/floor calibration for all 22 native spear meshes. Native importer and selector checks verify all 304 keys for each clip. Actual AnimationTrack movement follows every expected path sample, including pause, stop and post-completion behavior, without starting the game or an audio device.

All four standalone native/CVF Kahlua fixtures and the two production Lua files pass. Six unrelated emote motion/selector payloads remain byte-identical to standalone 0.2.3. The separate combat mod contains no emote loaders/assets and remains independently packaged. Local installation backs up only replaced originals and verifies installed bytes against the source and separate versioned install ZIP. Live playback and multiplayer still need an in-game check.
