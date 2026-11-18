# Project Yakuza Phone (Dev) 0.1.2

Optional add-on for Project Yakuza 0.129.0 or newer. Enable both mods and choose Settings in the style wheel. The shared combat dependency supplies the white, fuller smoke and varied impacts in both setups.

- Matched the saved reference preview's hierarchy: tilted Xperia at left, coloured app symbols on pale icon plates, orange selection frames, original Heat orbs, and a taller dark right panel with a pale title bar, style header, green section text, fine dividers, aligned values and a footer.
- Phone text is now projected glyph by glyph onto the display. Labels, the clock, style name, Heat count and prompts follow its rotation, scale and opening pose. The old upright hovering captions are removed. Original PZ font metrics and its unchanged atlas supply the glyphs; native Texture.split and ordinary four-corner UI drawing need no Java bridge or generated text images.
- Cached glyph textures and label layouts avoid recreating text while animating. The render-cadence fix, bounded drawing, saved preferences, scrolling, input cleanup and existing gameplay actions remain.
- Offline checks pass 41,215 native-projection/input/text-placement/page/lifecycle assertions. All six Lua modules compile. Native importer checks retain all original geometry and pixels, test normal Lua font-atlas bindings and verify original glyph regions. Package privacy and installed-byte checks are required before release.

PZ was not launched. The preview is adapted to native orthographic UI rendering with world dimming; original Yakuza 6 perspective, blur and shaders are not reproduced. Live appearance and performance still need an in-game check.
