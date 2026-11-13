# Project Yakuza Emotes

Version **0.2.0**, for Project Zomboid Build 42. Mod ID: `ProjectYakuzaEmotes`.

This standalone mod contains four original Kiwami 1 cutscene gestures. It works without Project Yakuza combat or Custom Voice Framework, and coexists with either. Enable Project Yakuza Emotes separately in your game or server mod list. Both peers need the same files for multiplayer playback.

Stand still without aiming and open the native emote wheel, then choose **Project Yakuza Emotes**:

- **Majima: Bat Point**: hold a usable supported native baseball bat. The original batting-center raise/point/lower gesture lasts about 5.03 seconds.
- **Lau Ka Long: Spear Ground Strike**: hold any usable spear-class weapon. All 22 native spear items have model-specific grip/floor calibration, and modded spear-class weapons have a fallback. The floor strike and continued flourish lasts 5.1 seconds.
- **Kiryu: Bad Luck**: empty both hands. The original puppy-rescue neck/head gesture and closing lean lasts 11.8 seconds.
- **Kiryu: Step Up**: empty both hands. The original final-chapter crowd challenge with Haruka lasts 7.3 seconds.

The original source timing, native skeleton, grounded feet and cancellable native emote playback are retained. Lau now includes 75 original frames from the matching next cut, adding exactly 2.5 seconds. Native spear-specific shaft calibration and a bounded arm clearance keep the longer flourish above the floor. Native and CVF menu entries remain available. The addon adds no combat styles, damage, Heat, protection, weapons, textures, voice or sounds. When Project Yakuza combat is present, its active combat actions also prevent starting an emote. No combat files are required by the addon.

Extract the ZIP's `ProjectYakuzaEmotes` folder into your Zomboid `mods` folder, then enable it. Upgrade Project Yakuza combat to 0.107.0 or newer when using both mods; earlier combat versions bundled these gestures. The separate CVF voice pack is unchanged.

See the individual gesture guides in docs for compatible weapons and source provenance. The 0.104.0–0.106.0 validation documents record their historical combat-mod integration; VALIDATION_0.1.0.md records the standalone split. VALIDATION_0.2.0.md covers the added final-chapter gesture. Offline tests pass. Custom modded spear geometry uses the crafted-spear fallback and is not individually calibrated. Visual blending and live multiplayer still need in-game testing.
