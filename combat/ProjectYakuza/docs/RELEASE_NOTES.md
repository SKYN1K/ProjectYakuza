# Project Yakuza 0.100.0

- Replaced the sunken combat-entry conversion with the installed Lost Judgment dod mod's blue Crane/Dragon Engine entry. All 151 original samples play at 60 fps over 2.5 seconds. Native skinned sole checks ground the root throughout the entry, which keeps its full playback and 0.3-second blend.
- Restored the previous unarmed RMB combat idle in both aim and aim-strafe. Relaxed idle stays vanilla and real weapons retain their native aim selection.
- Replaced the bicycle Heat Action with Y6 h23740_buki_g for heavy weapons already in hand. Original player/victim motions, frame-50 hit, weapon-bone motion, source sounds, voice role and blood starts replace the nearby-object scene. The supplied low-detail Y5 bicycle, texture, ordinary attacks and one-stock cost remain.
- Hit glints/sparks now vary direction, spread, scale, curved travel and fade within the existing particle/lifetime budgets. Existing source pixels, physical contact anchors and gameplay RNG are preserved.
- All 30 Kahlua suites, 83 production Lua compilations, native source/sole/grip/selector checks, 450 MP observer selectors, original sound decodes and zero-comment checks pass offline. Project Zomboid was not launched.

See [validation](VALIDATION_0.100.0.md), [combat entry](COMBAT_ENTRY.md), [bicycle](BICYCLE.md) and [effects](ATTACK_EFFECTS.md).
