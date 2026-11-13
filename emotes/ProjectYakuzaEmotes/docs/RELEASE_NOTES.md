# Project Yakuza Emotes 0.1.0

- Moved Majima: Bat Point, Lau Ka Long: Spear Ground Strike and Kiryu: Bad Luck into a standalone Build 42 mod with ID ProjectYakuzaEmotes.
- No dependency on Project Yakuza combat or Custom Voice Framework. Both remain compatible. Emotes have their own native wheel category and Lua namespace.
- Majima and Kiryu retain their original animation/selector bytes. Lau gains 75 original continuation frames from the matching next cut: +2.5 seconds, for 5.1 seconds total at the original speed.
- Supports all 22 native spears with individual model-specific grip/floor calibration, plus modded spear-class weapons through the crafted-spear fallback. Native bone lengths, wrist/weapon rotation, grounded soles and bounded arm clearance keep the extended sweep above the floor. Custom modded geometry is not individually calibrated.
- Native cancellation and multiplayer state parameters remain intact. No new textures, models, audio, weapons or combat behavior are added.
- Enable the addon separately. If using both mods, update combat to 0.107.0 or newer so the gestures are loaded only from the addon.
- Offline original-source/native checks, standalone dispatch, combat coexistence, both CVF menu load orders, Lua compilation and source-comment checks pass. Installed locally without launching Project Zomboid. Visual/live multiplayer testing remains outstanding.
