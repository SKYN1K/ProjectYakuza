# Project Yakuza Phone (Dev) 0.1.3

Requires Project Yakuza 0.130.0 or newer. Enable both mods, then choose Settings in the style wheel.

- Selecting or hovering over Items previews the character's real Project Zomboid skills, levels and progress toward the next level. Pressing Items opens a categorized inventory page for weapons, food, medical supplies, clothing and other items. Skills also has a dedicated app. Items are rechecked before native equip or context actions run.
- The Items page adapts the original Yakuza 6 pause_item scene's ten-frame root fade to a 60 Hz UI clock. Its categories, inventory actions and skills use PZ data. This does not reproduce the full original scene hierarchy, camera or shaders.
- Original Yakuza 6 English gothic menu glyphs replace the PZ Latin font. The original BC4 coverage strip is retained without resizing; non-Latin text uses native PZ fallback glyphs. Text remains attached to the phone display. Font regions and layouts are cached.
- Added the original dragon wallpaper, icon plate shadows and edge shading. Filled Heat stocks now use the luminous filled core; empty stocks retain the empty ring. Battery fill, percentage and red-to-green colour follow overall character health.
- Phone textures warm up at game start. Unready hardware, UI textures and glyphs wait for loading instead of drawing temporary placeholders. Combat 0.130.0 supplies the same texture warm-up and softer zombie contact effects in both builds; white limb smoke is unchanged.
- Offline validation: 121,936 Kahlua projection/input/menu/lifecycle assertions; 3,510 native UI3DScene projection cases; 4,316 source triangles with native imported geometry and UV checks; 2,031,282 native decoded pixels across 17 textures; original font coverage, wallpaper crop and scene source hashes; and all seven production Lua modules compile. PZ was not launched. Live GPU appearance and performance remain unverified.

The Flaticon research and proposed category mapping are saved in ICON_CANDIDATES.md. No third-party icons are included. Install ZIPs contain runtime files only; documentation, source extractions, tools and private paths are excluded.
