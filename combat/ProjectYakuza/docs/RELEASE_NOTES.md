# Project Yakuza 0.32.1

- Fixed invisible Extreme Heat and taunt burst textures: native B42 LoadFramesNoDirPageDirect expects prefix_kind_frame.png. The 130 Extreme Heat and three taunt-burst PNGs were missing the underscore after the prefix. Filenames and provenance records are corrected; every original pixel/file byte is unchanged.
- Fire and smoke now begin when the actual Extreme Heat activation animation starts, then continue into active mode without recreating/disappearing particles. Interrupted and remote activation states clean up correctly.
- Fixed the Extreme Heat orb row: all built-in HUD layers now use normal alpha blending, isolated from a world/addon renderer's incoming additive state. Purple glow is drawn behind the solid orb/frame/serpent layers. Previous renderer state is restored after both success and failure.
- New filename-contract checks cover all 229 aura/burst frames. Earlier image-decode checks did not catch the loader filename mismatch; the new check prevents that regression.
- No visual/audio asset was generated, repainted, upscaled or otherwise changed. Combat, damage, animations, heat rules and the separate voice pack are untouched.

## Validation

3,006 targeted Kahlua assertions pass, all 37 production Lua files compile, 130 aura images decode natively, and loader-path/source-pixel/provenance checks pass. All 451 shipped animation/image/audio file contents retain v0.32.0 bytes, including renamed textures. PZ was not launched; final GPU/live MP verification remains pending. See [validation](VALIDATION_0.32.1.md).
