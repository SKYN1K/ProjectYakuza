# 0.26.0 validation

- 2,664 combat, animation, aura and music lifecycle checks pass with current production modules.

- 22 heat/shove, 46 style selector, 50 MP, 39 native audio settings and 55 actual CVF API checks pass.

- 64 new taunt lifecycle, input, heat, world aura, pause, failure cleanup and remote clip checks pass.

- Total: 2,940 Lua checks, executed in PZ's bundled Kahlua runtime.

- All 74 remote animation nodes parse/select in PZ's native animation classes; all have zero gameplay events.

- Native animation importer accepts ProjectYakuza_DD_Taunt01: 4.7667 seconds, 35 channels, 144 right-hand keys.

- All existing graphical/audio/animation assets match 0.25.0 byte-for-byte. Only new motion is converted from the supplied GMT recorded in TAUNT_SOURCE.json.

- No live single-player or multiplayer session was launched. Visual appearance, actual input and network latency still need a live-game check.

