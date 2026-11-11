# Bicycle weapon and Yakuza 6 Heat Action

ProjectYakuza.Bicycle is the two-handed Bicycle (Yakuza 5) item introduced in 0.97.0. Obtain it through the native debug/admin item spawner or an addon supplying the item. Its existing 7-weight stats, original low-detail Y5 model, 128x128 reduced original texture and ordinary Y5 WPC attacks remain unchanged.

Version 0.99.0 replaces its old Y5 Heat Action with the original Yakuza 6 h23701_buki_f big/heavy-object scene. Equip Dragon of Dojima and the bicycle, hold physical RMB and press the Heat Action binding (MMB by default) near an eligible standing target outside a combo. It costs one stock or equivalent Extreme Heat fuel, committed after confirmed native playback. Shared clearance, protection, full recovery, lethal deferral and authoritative MP rules apply.

The player/victim GUIDs select h23701_000_4 and h23701_000_6. Both clips retain all 145 source samples at 30 fps, lasting 4.8 seconds. Independent object GMT h23701_000_7/null3 supplies the original big-object motion. The original scene uses the bs_c000_type_c_kanban model reference. The supplied bicycle is adapted to that world-object origin by undoing its hand-anchor rebase and seating its initial lowest vertex at floor level. It follows the complete original object rotation/translation track. No invented body poses, camera or physics fragments are added.

The original victim damage marker at 58 deals 1.5 canonical held-weapon damage. Three original non-voice cues at 8/55/95 and one actor voice role at 22 retain their independent timing. Four original victim blood-family emitters use existing supplied pixels. The old four Y5 bicycle WAVs and events are removed. Normal attack sounds remain unchanged.

The existing bicycle mesh still has 397 original vertices, 250 triangles, original UVs/normals and nearest-neighbour source texels at 128x128. Its model source remains Yakuza 5; the current Heat Action and matching scene audio come from Yakuza 6. This is an inventory weapon, not a rideable vehicle. Individual wheel/pedal articulation and physics fragments are not recreated.

bicycle-heat-assets.json records the current Y6 source roles, all original frames, object matrices, model calibration and hashes. The prior Y5 Heat Action builder is historical; current builds use extract_bicycle_y6_assets.py and build_bicycle_y6_heat_assets.py. validate_y5_object_assets.py now checks the unchanged original ordinary attacks/model/texture, while validate_bicycle_y6_heat_assets.py verifies the current action. See [validation](VALIDATION_0.99.0.md).
