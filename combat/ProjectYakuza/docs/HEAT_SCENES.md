# Original Heat Action scene contracts

Version 0.97.0 adds the [bicycle action](BICYCLE.md) after the bat action from 0.96.0 and six scene contracts from 0.95.0. All nine built-in Dragon of Dojima Heat Actions read their supplied original cmn.bin. HeatSceneData and HeatScenes apply source events before style and equipment registration, so playback, authoritative contacts and multiplayer presentation share the same definitions. Prices and eligibility are unchanged. Startup pays once only after native playback is confirmed.

| Action | Original victim damage frames at 30 fps | Current main-clip contact frames |
| --- | --- | --- |
| Unarmed Rush | 56, 68, 78, 90, 102, 114, 144 | 56, 68, 80, 92, 114, 126, 146, 158, 170, 182, 204, 216, 246 |
| Bottle | 32, 42, 59, 84 | Same |
| Wall | 12, 48 | Same |
| Ground trample | No damage markers | Verified sole/head contact at 30 |
| Beer crate | 14, 44, 54, 82 | 14, 44, 54, 74, 84, 104, 114, 142 |
| Katana | 24, 44, 64 | Same |
| Bat | 14, 50 | Same |
| Bicycle | 131, 158 | 6, 33 |
| Knife | 40, 90 | Same |

Rush retains its bounded two-pass sections. Source events belong to the logical section, preventing overlapping copied pose frames from replaying the preceding section's hit. Its closing kick maps to failure-ending frame 26. Crate retains three repeats of source frames 34–63; both punches map into each repeat. Its failure contact maps to frame 19. The crate's frame-13 damage belongs to the prop and is excluded from victim damage.

Bottle's original 300/300/300/1100 victim weights distribute its unchanged 1.5 total into 0.225/0.225/0.225/0.825. Wall's 500/1000 weights distribute its unchanged total 5. Katana retains 0.375/0.375/0.75. Rush and crate retain QTE-earned final damage aggregation: earlier contacts remain presentation only. Moving damage to punches before their input windows close would alter the established controls. Lethal contacts still reserve damage until full paired completion.

Sound starts are independent of damage. CMN18 sound indices are one-based; CRI CueId is index minus one. CMN10 uses zero-based IDs. The bank's CueTable/CueNameTable identify real stream names before decoding. Twenty-eight non-voice streams from supplied installed banks become direct PCM16 WAV decodes, retaining rate, channels and samples. Five existing katana cues are reused. No sounds are synthesized, combined or recorded. Named Kiryu voice cues in the crate bank use existing combat voice entries instead of imported voice recordings. Enemy voices are not imported; the separate voice pack is untouched.

The source manifest records blood-family emitter starts, bone-local offsets and node offsets. These become 112 native victim-bone anchors across nine main/ending clips. Existing supplied blood pixels approximate the source blood family; they do not reproduce the original engine's individual gore emitters. Non-blood particles, cameras and cinematic staging are not recreated. Ground has no emitter nodes and receives no invented generic burst. Prior animation, prop, model and texture files remain byte-identical to v0.95.0, including the katana release, reversal and sharp-end thrust. Only the new bat actor/victim clips are added.

The controller reads the playing native clip and switches failure endings to their own clock. Event identities reset only on clip changes. Repeated renders and MP echoes cannot repeat events. Pause freezes emission; events over 100 ms late are dropped. Ending audio/voice lists use the same bounds and registry validation as main lists. Custom styles retain contact/layer fallback.

Reproduce source contracts and bank decodes with tools/combat-tests/build_heat_scenes.py --write; default mode verifies deterministic outputs. build_heat_scene_anchors.py reproduces numeric attachments from retained native victim clips. build_heat_presentation.py and build_attack_trails.py rebuild dependent numeric catalogs. validate_heat_scenes.py checks expected contacts, totals, victim filtering, source attachments, fresh PCM decodes and unchanged prior media. heat-scenes.json records source/bank hashes; heat-scene-effects.json records clip hashes and anchors. Earlier per-action conversion manifests describe retained motion builds; this contract supersedes their historical contact-timing claims.

The bicycle retains source frames 125..308. Its CMN10 source prop-damage event at 174 is excluded from victim damage. Both 100-point victim markers become 0.75 canonical weapon damage. Source audio uses its independent fractional-frame starts without rounding.

Version 0.98.0 adds the original Y6 knife h23680_buki_b source contract, 500/1500 victim weights and six independent non-voice cues. See KNIFE_HEAT_ACTION.md.
