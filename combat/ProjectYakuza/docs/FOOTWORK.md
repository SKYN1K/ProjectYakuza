# Animated Kiryu stance with native legs, 0.12.1

Both aim and aim-strafe use ProjectYakuza_DD_CombatIdleLoop, derived from the provided P_KRU_BTL_SUD_stdB_lp.gmt conversion (updated in 0.26.3). The previous fixed moving pose is no longer selected. Both states use 1.0x speed, disabled locomotion sync tracking and matching 0.28s blend-in/out. The upper loop remains consistent across movement directions.

The new clip combines Kiryu upper-body rotations with the installed native Bob_IdleAim1Hand root, hips, Spine and lower-body tracks. Kiryu torso orientation is transferred into Spine1 relative to the native Spine, preserving the source relaxed combat stance without rotating the thigh parent. The moving mask includes only Spine1 descendants and Prop1/Prop2; it excludes Spine entirely. Both thighs descend from Spine in Zomboid's skeleton, so even a nonrecursive Spine rotation changes leg placement.

While moving, native normal/slow strafe nodes continue selecting the original nine-point Bob blend layout with DeltaX/DeltaY, StrafeSpeed and the original 0.8 per-clip rate. Native movement and collisions control displacement. The upper animation is independent of the walking cycle, avoiding phase jumps forced by short footstep loops. The final twelve source frames close the idle loop smoothly. No Lua polling, state variable or event callback was added.

Validation independently compares all 12,274 lower-body rotation/translation keys to resampled native idle data, checks the loop seam and non-frozen upper motion, and verifies both node masks and shared clip selection. The installed native importer processes 35 channels over 12 seconds. Rendered walking previews show native leg changes beneath the Kiryu guard. The 533 existing combat checks remain unchanged apart from the version string. In-game visual confirmation remains pending.

Builder: tools/build_combat_idle.py. Validator: tools/validate_combat_idle.py. Detailed bone provenance is in combat-idle-report.json. Legacy stance/footwork clips remain packaged but are not referenced by active stance nodes.

