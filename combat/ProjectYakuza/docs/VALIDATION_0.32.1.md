# Validation — 0.32.1

No game/client/server was launched. Live GPU appearance and multiplayer were not verified. Offline checks use the installed B42 Kahlua VM and native image decoder.

- 2,713 combat/aura/music lifecycle assertions pass.
- 132 charged/UI/outline/particle assertions pass, including incoming additive-state isolation, full-opacity six-orb rings/glasses, glow below artwork and blend restoration after injected HUD failure.
- 161 taunt/aura/MP assertions pass, including pre-mode activation fire/smoke, continuous handover into active mode, interrupted cleanup and remote observer activation.
- All 37 production Lua files compile.
- Native ImageData decodes all 130 aura PNGs. Original crop/hash checks verify the unchanged 66 flame/wisp exports and 64 smoke crops; original HUD atlas pixels also remain unchanged.
- `validate_effect_loader_paths.py` checks the installed IsoAnim class's native filename-concatenation recipes and resolves all 229 normal/extreme/taunt frame names using prefix_kind_frame.png. The original native bytecode was inspected offline to confirm LoadFramesNoDirPageDirect uses that convention. No game JAR was modified.

The earlier tests decoded PNG files by their exported filenames; they did not verify the paths requested by the native sprite loader. This allowed the missing-prefix-underscore bug through. Filename-contract checks are now separate from decode/pixel checks.

All 451 previously shipped media-file contents match v0.32.0 by SHA256 multiset. 133 incorrect filenames are replaced with the native convention; no pixels, motion frames or recordings are generated or changed. The installer checks the old installed bytes before overwriting/removing known obsolete paths, backs up changed files only and verifies all installed source bytes. Source/install/ZIP equality and GitHub artifact digest are checked after publication.
