# Project Yakuza 0.75.0

- Added separate DoD bottle and beer-crate profiles with original Yakuza 6 light combos, heavies, ground strikes and moving guards. Bottles use one-handed blunt gestures; the crate uses the bulky-object set. Existing weapon damage, durability, range and multihit rules remain.
- Restored original-source bat and katana relaxed idle, walking and running poses, plus sprint variants. Katana holds now use WPD, matching its attack set, replacing the mismatched WPN reference. Native hand-relative grips and disabled extra torso twisting keep the held blade away from the neck in offline pose/blend checks.
- Weapon walking keeps native PZ legs, torso, head and travel, with source arm orientations composed in world space. Moving poses use original walk/run arm motion rather than a frozen stance. All custom weapon attacks/guards use 140 ms entry and 200 ms recovery blends; locomotion uses 250 ms and aimed holds 280 ms.
- Added DoD-only Kiryu ordinary walk/slow walk and sprint, retimed to native gait cadence and travel. Existing healthy run cadence, native injury/tree/sneak/turn fallbacks and other styles remain unchanged.
- Updated multiplayer action authorization, event-free observer nodes and the numeric limb-effect catalogue for the new profiles. Bottle Heat Actions retain their original paired motion and now belong to the bottle profile.

Only approved supplied motion conversions and code are used. No AI, new artwork/audio, models, textures, Java bridge or voice-pack changes. Project Zomboid was not launched. See [validation](VALIDATION_0.75.0.md). Restart PZ and install the same release on the server and clients.
