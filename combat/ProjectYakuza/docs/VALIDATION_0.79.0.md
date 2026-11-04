# Validation: Project Yakuza 0.79.0

The selector change removes only the centre-decoration draw calls and their offset table. The Kahlua selector suite checks that the original ring crop is drawn only at slot size, catching the previous 12-pixel centre copies. Its existing animation, mouse passthrough, input, style assignment, settings persistence, cancellation and addon-icon checks remain in place.

All production Lua compiles. The native passive UI probe confirms the selector still passes RMB through. The source-comment policy and lexical-preservation checks pass. Texture provenance/pixel validation remains unchanged; every media file except StyleSelector.lua and the version string in Registry.lua matches the previous release byte for byte. The existing vanilla weapon/walking fallback remains intact.

PZ was not launched. Live appearance remains for the user's in-game check. Installation backs up changed existing files and verifies source/install byte equality; the published ZIP is verified against both.
