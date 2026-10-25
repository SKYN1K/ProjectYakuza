# 0.26.4 validation

- 68 taunt/action lifecycle, heat reward, interruption, pause, aura and remote effect checks pass.
- 54 MP protocol/authority/observer checks pass.
- Updated effect assertions verify four ordinary sprites, no Extreme Heat boost during taunt flash, 12% maximum additive opacity, same animation frame across normal/flash passes, 180 ms expiry, and additive state restoration even on rendering failure.
- Native importer accepts DCF_DD_Taunt01: 55/30 seconds, 35 channels, 56 hand keys. Style action duration matches that source duration; end-marker completion remains the release condition.
- Only the requested taunt animation changes among all motion, texture and audio files. The relaxed idle fix is retained byte-for-byte.
- No new texture/audio assets generated. No game launched; subjective flash appearance and live MP latency still need an in-game check.
