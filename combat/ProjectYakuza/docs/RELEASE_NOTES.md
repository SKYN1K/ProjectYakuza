# Project Yakuza 0.95.0

- Read all six supplied Heat Action cmn.bin scenes, including the crate's big-endian Yakuza 5 format. Separate victim damage from prop damage, sound starts and particle starts.
- Correct bottle contacts to frames 32/42/59/84 and wall contacts to 12/48. Restore both punches in each repeated crate section, and correct Rush punches, final kick and failure-ending timing against the retained source frame maps.
- Preserve total damage, stock/fuel prices, eligibility, QTE controls and earned final-damage rules. Ground trample has no CMN damage markers and retains its verified frame-30 contact.
- Play 23 original non-voice bank streams at their CMN starts, alongside five existing katana cues. Actor voice roles use existing Combat entries; the separate voice pack is untouched.
- Schedule 106 source blood-family starts at native bone attachments across six main clips and two failure endings, using existing supplied blood pixels. Source cameras and non-blood engine effects are not recreated. Suppress generic contact layers for these scenes.
- Preserve the katana's airborne grip reversal and every prior animation, texture and model byte. All 30 rebuilt Kahlua suites pass; source/PCM provenance, native sound parsing, deterministic scene/FK catalogs, Lua compilation and source-comment checks pass offline. Project Zomboid was not launched.

See [validation](VALIDATION_0.95.0.md), [scene contracts](HEAT_SCENES.md) and [source manifest](heat-scenes.json).
