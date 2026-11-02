# Project Yakuza 0.71.0

- Added separately spawnable Intact Beer Bottle, Intact Wine Bottle and Intact Whiskey Bottle weapons, using the existing PZ bottle models/icons. They are one-handed Short Blunt weapons with native damage, durability and normal combat outside styles. Ordinary drink bottles are unchanged.
- Added the original Yakuza 6 small blunt-object Heat Action to those three weapons in Dragon of Dojima. The full five-second attacker/victim motion is preserved. DoD bottle attacks use its existing Short Blunt profile.
- The bottle Heat Action uses the separate rebindable input (default MMB), still requires physical RMB and no active/recent combo, and costs one stock. Shared protection lasts only for the action; zombie targeting grace lasts another 0.5 seconds. Existing katana/unarmed Heat Actions remain available under their own eligibility rules.
- Fixed the katana victim being embedded in the ground by applying its source vector height, normalized paired scene headings, and removed camera-stage teleports from katana/unarmed paired paths.
- Added a fast-fading Heat Action eligibility icon with the currently rebound input above it. It reuses original Y6 flame atlas pixels, caches candidate checks at 5 Hz, and supports per-style ui.heatAction overrides.
- Added source provenance, native importer/grip/animator/item-parser checks and client/MP regressions for the new weapons and paired motion. No AI, new artwork/audio or upscaling is used.

Project Zomboid was not launched. See [validation](VALIDATION_0.71.0.md) and [spawn IDs/controls](BOTTLE_WEAPONS.md). Restart after updating and install the same release on server and clients.
