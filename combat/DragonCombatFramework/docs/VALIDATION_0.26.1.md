# 0.26.1 validation

- Identified native attack failure in installed PZ IsoPlayer bytecode: setAuthorizeMeleeAction delegates to setAuthorizedHandToHandAction, and DoAttack returns before pressedAttack when this flag is false. The 0.24 shove gate had left it false while the style was equipped.
- 2,956 Lua assertions pass in independent PZ Kahlua runtimes: 2,664 combat/aura/music; 23 heat/shove; 56 actual CVF API; 54 MP; 68 taunt/effects; 6 native attack authorization regressions; 46 selector; 39 native audio settings.
- Native animation importer accepts converted Kiwami taunt: 1.6 s, 35 channels, 49 right-hand keys.
- Six source-motion samples inspected on the existing PZ mannequin. No generated artwork or audio.
- All pre-existing textures/audio and other animation clips remain byte-identical to 0.26.0; only the requested taunt clip changes.
- No game launched. Actual game input, appearance and multiplayer latency remain to be checked in a live session.
