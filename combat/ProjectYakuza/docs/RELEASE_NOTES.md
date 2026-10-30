# Project Yakuza 0.45.0

- Added DoD-only knife and sweeping-blade profiles for 36 additional explicit B42 items (48 total with bats/clubs). Includes hunting/kitchen/fighting knives, small blades, cleavers, machetes, katanas and swords. The selected style and actual weapon remain equipped together; other styles/items do not inherit the animations.
- Each blade profile has three supplied-source light attacks, standalone/queued heavy, ground strike and source stance with native walking legs. Longer blades also have source guard phases with walking legs; the knife source set has no guard. Both retain light quickstep cancels and the existing three-per-15-second quota. Lights x1, heavies x1.25 of the real item damage.
- Converted 16 supplied Yakuza 6 motion clips with explicit non-AI retarget authorization. Preserved native weapon models, condition/durability and sounds; no new textures/models/audio, AI or invented motion. All existing media bytes remain unchanged. Separate voice pack untouched.
- Fixed supplementary blade hits to respect the held weapon's native reach and meaningful high sword damage. Native primary-only knife jaw-kill/critical damage cannot copy onto all SP extra targets. Both SP/MP reject stale supplementary hits after changing the held weapon. Primary native hit and durability handling stay unchanged.
- Added 56 event-free MP observer selectors, for 276 total. Heavy axes/spears/firearms remain native. Unarmed special moves require the style item; grabs stay disabled and hitstop stays deferred. See [weapons](WEAPONS.md).

## Validation

4,292 offline Kahlua assertions across 16 fixtures pass; all 42 production Lua files compile. Native B42 import covers all 26 supplied-source weapon clips and 39,935 finite bone samples. All 32 weapon owner selectors are isolated to their style/profile, and 276 MP observers remain event-free. Original GMT/BEP/rig/output hashes, contact windows and all 48 B42 item IDs verified. All 561 pre-existing motion/image/audio files match 0.44.0. See [validation](VALIDATION_0.45.0.md).

Installed locally and published as a new release ZIP. PZ was not launched; live grip/blending and multiplayer timing remain unverified. Fully restart with matching server/client versions.
