# 0.30.2 - Original Lost Judgment Extreme Heat particles

- Removed the previous bright/smudged Extreme Heat profile and its continuous additive bloom. Normal heat remains suppressed during Extreme Heat and resumes only when eligible.
- Replaced it with original Lost Judgment flame-atlas cells and thin wisp textures, decoded/cropped losslessly at native resolution. No procedural image frames, resizing, upscaling or generated media.
- Four upper-body particles use muted blue tint and 12-22% opacity rather than an opaque luminous cloud. Native flame frames and bounded wisp drift provide movement without increasing body coverage or adding leg emitters.
- Regular heat, combat behavior, activation SFX and the separate voice pack remain unchanged.

## Validation

2,750 targeted Kahlua checks pass (121 taunt/aura and 2,629 combat/aura/music), including exclusive profile ownership, source selection, bounded size/opacity/tint, no continuous additive rendering, motion/pause and cached cleanup. All 33 production Lua files compile. All 66 new PNGs match source DDS RGBA pixels/crops and hashes; native B42 ImageData decodes all 66 at original dimensions. All 310 pre-existing media files retain their bytes. PZ was not launched. Installation backs up only changed files and verifies installed bytes.
