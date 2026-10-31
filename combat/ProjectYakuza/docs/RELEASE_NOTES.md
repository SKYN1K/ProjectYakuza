# Project Yakuza 0.54.0

- Enlarged short encounter titles and automatically shrunk longer titles to fit the viewport, including the landing pulse. Source font/image files are unchanged and the stock font is never drawn above native raster scale.
- Expanded style-exclusive intro configuration with minimum zombie counts, optional no-count intros, trigger selection, player range/field-of-view, rejection backoff and stock title-size controls.
- Added opt-in visible-player, seen-by-player and player-hit triggers. Detection is local, range/facing/LOS based and bounded to 16 online candidates per poll plus local split-screen slots, with target caching. DoD retains its zombie-only defaults.
- Added namespaced custom encounter detectors with failure quarantine and target context. Existing per-style renderer lifecycles support custom effects, assets, timing, title tiers and supplied sounds; other styles receive no DoD fallback.
- Documented addon examples and new context/events in ENCOUNTER_INTROS.md. No graphical/audio asset was created or modified, and no combat, music or network protocol behavior changed.

Offline regression, native API, source-asset and Lua compilation checks pass. PZ was not launched. See VALIDATION_0.54.0.md. Restart matching server/client installations after updating. Grabs remain disabled; the separate voice pack is untouched.
