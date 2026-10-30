# Validation: 0.50.0

PZ was not launched. GPU appearance, live mouse/gameplay behavior and live MP threat detection were not tested.

## Supplied font and original Yakuza effect

The user explicitly approved extraction/decoding of original intro assets and non-AI rasterization of the installed Edo SZ HQ font. The atlas contains 95 printable ASCII glyphs directly drawn from that font at 128 pixels. The validator reconstructs the complete atlas from the supplied font and verifies exact RGBA bytes, offsets, bounds, advances, kerning, source hash and generated metrics hash. All requested title characters exist. The renderer scales glyphs below the atlas raster resolution and does not replace any PZ font. Font data loads through the existing global-namespace module pattern; it does not depend on a return value from PZ require.

The original Yakuza 6 btl_flush DDS is decoded unchanged at 512x512. Source/copy RGBA pixels, alpha range, dimensions and hashes match. Only runtime animation, transparency and tint are applied. Native ImageData decodes the 2048x512 font atlas and 512x512 flare successfully. Native reflection verifies Stats.getNumChasingZombies/getNumVisibleZombies/getNumVeryCloseZombies and IsoCell.getZombieList. Native ISUIElement Lua signatures for drawSubTexture/drawTextureScaled/setWantMouseEvents were inspected; existing draw APIs are used unchanged.

All 603 existing motion/image/audio files and 447 existing native XML files remain byte-identical to 0.49.0. Only the approved font atlas and original flare PNGs are added to graphical media. No character animation, audio, blood/heat texture or voice-pack asset is modified.

## Actual-module UI and framework checks

5,093 Kahlua assertions across 20 fixtures pass. All 48 production Lua files compile. The 404-check encounter fixture embeds current Registry, DoD definition, StyleUI, actual detector, glyph metrics and renderer. It checks exact inclusive title boundaries at 0/10/11/39/40/100, a 12-tile circular boundary, dead/out-of-radius/other-floor exclusions, early stop at 40, at most 64 loaded zombie entry reads per tick, no zombie scan in player update, native threat-counter throttling and no idle tick hook.

The same fixture checks source glyph crop bounds, valid destination/alpha ranges, normal blend restoration, detached mouse-transparent panels, per-player viewport placement, pause-aware counting/animation, one intro per continuous encounter, confirmed-hit fallback, quiet-time rearming, cleanup on style disable/change, registered custom renderers/sounds, provider lifecycle/removal and no DoD fallback on another style. Every mock panel is removed. Invalid radius and title configurations are rejected. Generic StyleUI failure quarantine/blend/lifecycle checks retain their existing charge/UI fixture coverage.

Existing style-entry tests retain 21 checks and that module/motion is unchanged. Weapon/MP, Extreme variations/depletion, multihit, charging, quicksteps, item policies, source contacts, observer nodes, sound/settings, CVF and addon APIs retain their passes. Native tests still validate 316 observers, source-only paired finisher poses, prop tracks, original HUD/aura/blood pixels and source frame paths. Six lexical preservation tests pass; the comment audit reports zero comments across 573 tracked/whitelisted source files.

The encounter detector reads native threat counters at most once per 400 ms for DoD. Counting runs only on a new encounter; the temporary tick hook is removed after count/display completion. Other styles without explicit config/provider perform no threat-counter read or crowd scan. The system adds no damage/protection/camera/input lock or network messages. Its full-viewport panel requests no mouse events; real in-game input remains a live verification item.

## Install and remaining limits

The 1,287-file installed 0.49.0 tree matches its prior ZIP before installation. Back up only replaced existing files, verify all new source/install/ZIP bytes and compare the unique 0.50.0 GitHub asset digest. Source extraction files, previews, backups and credentials remain ignored.

The intro uses source assets and supplied typography with Lua recreation of its timing, not an imported original UI scene. Crowd counts are a local loaded-world snapshot across several ticks; dynamic list changes can affect exact membership. Counts are capped once the highest configured tier is established. Native threat counters provide an encounter heuristic, with 12-second quiet rearming. Each MP player sees only their own local style's intro. Live visual polish, detection feel and input behavior require testing after a full restart on matching versions.
