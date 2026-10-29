# Project Yakuza 0.44.0

- Added a Dragon of Dojima bat/club equipment profile: three light attacks, standalone/queued heavy, ground strike, walking guard and source weapon idle. Ten supplied Yakuza 6 clips converted with explicit user authorization; no AI, invented animation, new textures/models or audio.
- Select the style and equip a supported real weapon at the same time. Selecting DoD while holding one retains it. Twelve explicit B42 blunt items supported; other styles/items keep their native behavior. Equipping the style item returns to unarmed combat.
- Preserve native held weapon models, primary hit calculation, condition/durability and weapon audio. Lights x1 weapon damage, heavy x1.25 with scoped restoration. Existing heat gain, hit sparks, controls and quota-limited light-to-quickstep cancels support these native weapon hits.
- Added public style-owned weapon profile registration, isolated owner nodes, equipment-change cleanup, validated MP inventory acknowledgements and real-weapon supplementary damage. Added 32 event-free observers, for 220 total. Grabs remain disabled; hitstop remains deferred; the separate voice pack is untouched.
- Initial armed actions are lights, heavy, ground attack, block and quickstep. Unarmed charges/doubles/counters/running/quickstep strikes/taunt/entry/Extreme activation require the unarmed style item. See [weapon guide](WEAPONS.md).

## Validation

4,211 offline Kahlua assertions across 16 fixtures; all 42 production Lua files compile. Native B42 import validates all 10 weapon clips and 13,790 finite source bone samples; 12 weapon owner selectors parse/select exclusively for the DoD weapon profile; all 220 MP observers are event-free. Source GMT/output/rig hashes, original BEP contact timings and all 12 B42 item IDs verified. Existing motion/texture/audio assets remain byte-identical to 0.43.0. See [validation](VALIDATION_0.44.0.md).

Installed locally and published as a separate release ZIP. PZ was not launched. Live weapon grip, blend appearance and MP behavior remain unverified; fully restart with matching server/client versions.
