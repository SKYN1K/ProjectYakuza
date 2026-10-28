# Project Yakuza 0.34.0

- Added a first-light-punch effect prototype: short blue glow along the striking left fist/forearm, a small animated flame, short trail and three outgoing sparks. Extreme Heat uses a stronger purple-blue tint. The effect also appears without heat so this first pass can be evaluated independently.
- Attachment positions come from the original shipped punch, sampled through B42's native importer/FK at 30 fps. Playback follows the live native track time and actor facing, including Extreme Heat speed. No image, sound or animation asset was created or modified.
- Synchronized the existing Y6 punch whoosh to source frame 3 for this move; no duplicated sound layer or new recording. Other attacks, sound volumes, body auras, damage, hit timing and inputs are unchanged.
- Remote observer playback triggers the same configured effect without additional packets. Effects clean up on hit, move/style change, end, timeout, pause/world transitions and rendering failure. Ten sprites per active punch, maximum eight actors; no idle effect tick/render subscription.
- Added numeric-track/provenance documentation and a native/Kahlua regression fixture. Lua API 3 and MP protocol 2 remain unchanged. Grabs remain disabled; the separate voice pack is untouched.

## Validation and limits

3,793 offline Kahlua assertions pass; all 39 production Lua files compile. Native import verifies all 31 source samples and eight-direction projection; original texture/sound hashes match. See [validation](VALIDATION_0.34.0.md).

This follows the original clip path, not live blended bone transforms or a limb-surface shader. Walking/torso blending and occlusion can differ. No PZ client/server was launched; GPU appearance and live MP remain unverified. Restart PZ after installing, and use the same version on server/clients.
