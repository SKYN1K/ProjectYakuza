# 0.30.1 - Exclusive Extreme Heat aura

- Extreme Heat now replaces the regular heat glow instead of layering over it. The normal instances are released for the duration and return only when normal heat is eligible.
- The replacement uses different existing animated wisps, a slightly brighter cyan tint and a restrained 16% glow. It has the same four body anchors/scales as normal heat, with no size increase or leg aura.
- Base and glow passes reuse one animation frame. Sprite profiles are cached; mode changes preserve fade opacity and do not introduce per-update allocations. Taunt completion flashes the selected profile.
- Existing supplied textures, audio, motion, combat timing, damage and the separate voice pack are unchanged.

## Validation

2,750 targeted Kahlua checks pass (121 taunt/aura checks and 2,629 combat/aura/music checks). All 33 production Lua files compile. Exclusive profile selection, disposal/restoration, identical bounds, restrained brightness, animation advancement, blend restoration and allocation stability are covered. All 310 media files are byte-identical to v0.30.0; no visual/audio asset was generated. PZ was not launched. Local installation backs up only changed files and verifies installed bytes.
