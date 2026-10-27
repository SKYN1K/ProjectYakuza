# Validation — 0.31.1

No PZ client/server was launched. Offline checks used the installed game's Kahlua VM and native ImageData decoder.

| Fixture | Passing assertions |
| --- | ---: |
| Combat, aura, music lifecycle | 2,629 |
| Taunt, aura modes, fast flame material/timing, MP | 126 |
| Charged heavy, UI, outline, world sprites | 70 |
| MP authority and visual catalog | 98 |
| Total | **2,923** |

All 37 production Lua files compile. The aura fixture checks four original animated flames, .55-.85-second playback bounds, preserved upper-body dimensions, saturated blue tint, bounded opacity, additive rendering and restoration after both success and injected failure. It also covers exclusive profile switching, paused animation, stable sprite allocations, native world rendering for every facing, normal-aura restoration, fade, taunt flashes and disable/cleanup behavior.

`validate_extreme_assets.py --source-dir <supplied-y6-raw_event-folder>` verifies original DDS hashes, exact crop dimensions, decoded RGBA bytes and PNG hashes for all 66 aura textures. `NativeAuraTextureProbe` decodes all 66 files through the installed B42 ImageData class. All 64 flame exports use existing 32x32 source cells; the two unused wisps retain their previous bytes. Only those 64 flame PNGs change among the 379 previously shipped animation/image/audio files. No media is generated or upscaled.

The standard previous-release-checked installer backs up only changed files and verifies every installed source byte. The release ZIP is built from the source mod folder, with extraction folders, probes' compiled classes, previews, backups and voice-pack files excluded. GPU appearance, exact perceived flame speed and live MP still need an authorized in-game test.
