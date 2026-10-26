# Unreleased PR — Mad Dog of Shimano

- Separate original-motion style addon 0.1.1 and optional per-style held-weapon appearance, based on framework 0.30.1. PR remains unmerged and unpublished.
- Correct Yakuza-to-PZ forward-axis handedness against the actual Human inverse-skin bind; rebuild all 26 original clips without generated poses or time reversal.
- 28,824 independent source-direction checks pass across 2,402 native poses on both survivor rigs; the previous installed clips fail all 52 body/clip pairs. 463 Kahlua assertions, 37 Lua compiles and native selectors pass. See the addon validation report for scope and live-test limits.

# 0.30.1 - Exclusive Extreme Heat aura

- Extreme Heat now replaces the regular heat glow instead of layering over it. The normal instances are released for the duration and return only when normal heat is eligible.
- The replacement uses different existing animated wisps, a slightly brighter cyan tint and a restrained 16% glow. It has the same four body anchors/scales as normal heat, with no size increase or leg aura.
- Base and glow passes reuse one animation frame. Sprite profiles are cached; mode changes preserve fade opacity and do not introduce per-update allocations. Taunt completion flashes the selected profile.
- Existing supplied textures, audio, motion, combat timing, damage and the separate voice pack are unchanged.

## Validation

2,750 targeted Kahlua checks pass (121 taunt/aura checks and 2,629 combat/aura/music checks). All 33 production Lua files compile. Exclusive profile selection, disposal/restoration, identical bounds, restrained brightness, animation advancement, blend restoration and allocation stability are covered. All 310 media files are byte-identical to v0.30.0; no visual/audio asset was generated. PZ was not launched. Local installation backs up only changed files and verifies installed bytes.
