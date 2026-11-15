# Bicycle

Version 0.114.0 uses Kiwami 2 WPH bicycle attacks and holding/walking poses, replacing WPC bulky-object motions. See bicycle-k2-assets.json for original GMT/BEP provenance, source frame counts, hand/weapon-bone orientation, contact timing and native walking composites. The existing Yakuza 6 mesh and texture are unchanged. A successfully completed Heat Action with a confirmed final contact sets the held bicycle condition to zero once and synchronizes the item; cancellation preserves it. Original physical bicycle sounds cover native hits, floor impacts, swings and breakage.

ProjectYakuza.Bicycle is the two-handed Bicycle (Yakuza 5) item introduced in 0.97.0. Obtain it through the native debug/admin item spawner or an addon. Its existing stats, original low-detail Y5 model, 128x128 reduced source texture and ordinary Y5 WPC attacks remain unchanged.

Version 0.100.0 uses Yakuza 6 h23740_buki_g, the held-heavy-weapon scene. Equip Dragon of Dojima and the bicycle, hold RMB and press the Heat Action binding near an eligible standing target outside a combo. The action costs one stock or equivalent Extreme Heat fuel after confirmed native playback. Existing clearance, protection, full recovery, lethal deferral and authoritative MP rules remain.

CMN player/victim GUIDs select h23740_000_4 and h23740_000_6. Both retain all 121 original samples at 30 fps, lasting four seconds. The bicycle follows the actor's original buki1_r_n hand-relative weapon motion through native arm adaptation. Its original right-grip model origin and native scale are retained. There is no independently positioned nearby-object track in this scene. This supersedes the v0.99 h23701 world-object action.

The original frame-50 damage marker deals 1.5 canonical held-weapon damage. Three source-bank non-voice cues occur at frames 9, 32 and 35, with the actor voice role at frame 13. Eight original victim blood-family emitter starts use existing supplied pixels. The corresponding original Y6 bank replaces the three previous bicycle WAVs. Normal attack sounds remain unchanged.

The mesh retains 397 original vertices, 250 triangles, UVs/normals and reduced original texels. It is an inventory weapon; individual wheel/pedal articulation and physics fragments are not recreated. The new scene introduces no camera or generated graphics/audio.

bicycle-heat-assets.json records CMN bindings, all source frames, original weapon-bone offsets, model references and hashes. extract_bicycle_y6_assets.py and build_bicycle_y6_heat_assets.py reproduce the current action; validate_bicycle_y6_heat_assets.py verifies source/body/grip/path/native-import contracts. The supplied bike mesh is within 0.073 native units of the skinned victim at the original hit frame. validate_y5_object_assets.py remains the validator for the unchanged ordinary attacks/model/texture. See [validation](VALIDATION_0.100.0.md).

The break cue uses the supplied Y6 arm_bicycle break recording. bicycle-fragments.json records the original low-detail front/rear wheel and handlebar submeshes. BicycleBreak.lua creates temporary non-transmitting, unpickable world objects from those parts, with bounded falling/spinning motion and save/menu cleanup. Replayed/older MP completion packets cannot repeat the effect. No persistent debris or invented mesh/texture is added.
