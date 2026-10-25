# 0.27.0 - Controls, taunt particles and audio

- Rebuild the completed-taunt flash with five short-lived upper-body wisps/sparks taken directly from Kiwami 2. Original texture dimensions and pixels; blue tint and movement supplied at render time. No generated artwork or audio. Burst duration: 260 ms.
- Support the CombatExtremeHeatActivation CVF entry on actual activation start. Retry transient provider busy/cooldown for up to 1.5 seconds while the same activation remains active; discard cancelled activation voices. Existing supplied Kiryu boost_on recordings remain usable.
- Fill the Dragon of Dojima selector circle with an original Kiwami crop at 1:1 pixel size; no upscaling.
- Limit quicksteps to three actual starts within a rolling 15-second window, persisted per character. Blocked or rejected requests do not consume a step.
- Remove Shift quicksteps. Space is the default quickstep key; all thirteen combat action inputs can be changed in Options > Mods > Dragon Combat Framework, with mouse-button or keyboard choices.
- Audio sliders are Music, Sounds and Voices. Sounds controls this mod's SFX; Voices controls only CVF combat lines requested by this mod, preserving normal voice settings and style voice mix.
- Preserve the current Kiwami 2 taunt, relaxed combat idle, damage, heat rules, music playlist and existing multiplayer synchronization.

## Default controls

Aim/movement/run use native PZ controls. While aiming: LMB light attack, MMB finisher or Tiger Drop; X block, G grab/release, MMB throw while grabbing, Q taunt, N Extreme Heat. Space quickstep; LMB during quickstep attacks. Running LMB attack, running MMB dropkick. Hold Z to select styles. Each action has its own binding in Mods settings; Shift remains native run input.

## Validation

3,046 Lua assertions passed across combat lifecycle, native attack authorization, bindings/rolling quota, taunt particles, actual CVF playback, native ModOptions persistence, style selection and MP protocol. The old broad movement fixture isolates movement from quota; the new quota fixture checks the actual three/15-second limit independently. All Lua sources compile in the bundled PZ compiler. Original particle PNGs decode pixel-identically to their source DDS files. No live game was launched; subjective appearance and two-client input/latency still need an in-game check.
