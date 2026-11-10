# Project Yakuza 0.96.0

- Added the original Yakuza 6 held-bat Heat Action from h23710_buki_d, using supplied CMN damage/audio/voice/blood timings and all 103 actor/victim motion samples at original speed.
- Available to Dragon of Dojima with the six registered bat items: hold physical RMB and press the Heat Action binding (default MMB) near an eligible standing target outside a combo. Costs one stock or equivalent Extreme Heat fuel, paid only after confirmed playback. Other blunt items do not borrow it.
- Retained the source animated right-weapon bone instead of using a rigid grip. Native owner, zombie/PvP victim and both MP observer cycles use isolated event-free selectors.
- Two automatic source damage contacts at frames 14/50 use original 1:3 weights, totaling 1.5 canonical weapon damage. Existing protection, lethal deferral, interruption and multiplayer authority/replay rules apply.
- Added five directly decoded original non-voice sound cues and six original blood-family emitter starts. Existing combat voice entries are reused; the separate voice pack is untouched. No images, textures or models are created or modified.
- All 30 Kahlua suites, 78 production Lua compilations, original motion/PCM provenance, native importer/FK/selectors, 426 MP observer selectors and source-comment checks pass offline. Prior media bytes are preserved apart from the extended scene sound declarations. Project Zomboid was not launched.

See [controls and source contract](BAT_HEAT_ACTION.md), [validation](VALIDATION_0.96.0.md) and [motion provenance](bat-heat-assets.json).
