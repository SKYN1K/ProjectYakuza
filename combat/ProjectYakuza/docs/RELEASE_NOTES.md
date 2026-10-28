# Project Yakuza 0.35.0

- Extreme Heat outline now begins immediately with the activation animation, including remote observer playback, before fuel mode starts. Interruption/end restores the previous outline.
- Added a one-second expanding smoke cloud around the feet/lower legs at activation: four original animated smoke particles, normal transparency, pause-aware lifetime, no repeated triggering during the animation. Existing sustained auras retain their timing/size.
- Rebuilt taunt completion VFX: a 320 ms torso flare with four animated source flame patches and four small outgoing sparks. Removed the old static wisps and extra additive aura-brightening pass. Taunt animation/reward/voice behavior is unchanged.
- Fixed a demonstrated native positioning bug in first-light punch particles: AttachExistingAnim overwrites offsets on a shared sprite. Punch/taunt/activation-burst particles now use detached native instances and per-instance centring. Glow centres are placed along the forearm and inset fist path.
- Made the first-light effect visibly layered: six arm glow centres, two animated flames, four short trails and six sparks; extended the source window through frame 14 and spark lifetime to .18 source seconds. Maximum eighteen instances per active punch/eight actors; no idle effect callbacks or new MP packets.
- No visual/audio/animation files were added or modified. Only supplied assets are used. Combat damage, collisions, controls, music, body-aura scale/flame speed and the separate voice pack are unchanged. Grabs remain disabled.

## Validation

3,834 offline Kahlua assertions pass; all 39 production Lua files compile. A native probe reproduces the shared-offset overwrite and verifies detached scale/alpha/pool behavior. Tests check early local/remote outline, the one-second cloud, taunt replacement/alpha, per-scale punch centring, simultaneous particles, pause, interruption and cleanup. See [validation](VALIDATION_0.35.0.md).

PZ was not launched; live GPU appearance and MP gameplay remain unverified. Source-path tracking still approximates final blended limb positions. Fully restart PZ after updating; server and clients need the same version.
