# Project Yakuza 0.49.0

- Added nine supplied Kiryu Extreme Heat variations: neutral heavy, four first finishers and four matching doubles. Existing MMB inputs select them automatically while Extreme Heat is active.
- Source-matched double handoffs preserve full first animations without further input; only one second-finisher leading frame is trimmed. No invented motion or baked transition poses.
- Playing attacks finish naturally on Heat depletion, including an attack that consumes the remaining fuel. Paired doubles retain the matching animation within the existing follow-up window. Later attacks return to normal.
- Existing heavy/Heat damage and speed bonuses remain. Lights, charges, weapon profiles, sounds, visuals and normal-mode motions are unchanged.
- Added native owner/remote observer nodes, mode/continuation validation and offline source/pose/MP regression checks. No game launch; see VALIDATION_0.49.0.md.

Approved source animation retargets only. No new artwork, textures, audio, AI or upscaling. Install matching server/client versions and fully restart. Grabs remain disabled and the separate voice pack is untouched.
