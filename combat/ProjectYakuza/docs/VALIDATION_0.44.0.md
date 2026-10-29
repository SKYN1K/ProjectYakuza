# Validation: 0.44.0

PZ was not launched. No live GPU, weapon-grip or multiplayer claims are made.

## Gameplay checks

The existing 4,133 Kahlua assertions remain passing. A 56-check actual-module weapon fixture covers explicit selection, all 12 item mappings, style isolation, three native attack callbacks, standalone and queued heavies, x1/x1.25 damage/restoration, native ground-index reset, same-profile item swap, breakage, unsupported equipment, transaction/namespace validation and armed light quickstep cancellation. A 22-check armed MP fixture covers inventory-ID acknowledgement, two-handed retention, profile/move/action rejection, native primary hit non-replay, real-weapon extra-target damage, deduplication, stale swing/item/acknowledgement rejection and disable preserving the held weapon. Total: 4,211 across 16 fixtures. All 42 production Lua files compile.

Run build_weapon_tests.py/build_weapon_mp_tests.py and their Kahlua LuaRunner outputs in tools/combat-tests. Rebuild the existing fixtures from current production sources before the full suite. The optional voice-pack files are not read or modified by this update.

## Native files

WeaponAssetProbe imports all ten new clips through B42 Jassimp/ProcessedAiScene and checks 35 native bone channels per clip, all 13,790 frame samples for finite position/rotation/scale/time, expected source sample counts and clip names. It parses/selects all 12 weapon owner nodes, rejects another style and the unarmed profile, and checks the held weapon API methods. No game or GL context is started.

validate_weapon_assets.py verifies source GMT/output/rig/grip SHA256 values, all original frame ranges at 30fps, unit quaternion/scale values, the original BEP attack interval starts (kind 68), exactly one native collision per strike, upper-body masks and the 12 supported item IDs against installed B42 item scripts. weapon-assets.json records explicit source-retarget authorization and the source/rig/output hashes. Ten existing-source animation files were added; no graphics, models or audio were created/changed.

The existing native importer, aura/HUD pixel/provenance, charge timing/FK, colour API, loader path, starter builder and source clip validations pass. All 220 observer nodes are event-free and keep their owner animation/blend/speed/mask settings; native selector probes cover 110 per restart cycle. Existing 551 motion/image/audio files match the prior release exactly.

## Installation and release

Install only changed source files, backing up only existing changed installed files. Check the full source/install byte set, then publish a fresh 0.44.0 ZIP/tag using Publish-CombatRelease.ps1. Verify the ZIP/source/install payloads and GitHub asset digest. Detailed local reports remain ignored under tools; backups/extractions/previews/credentials/voice-pack files are excluded from Git and the release.

## Manual verification still required

After a full restart on matching versions: select DoD, equip a listed bat/club, test all three lights and weapon heavy/ground/guard, then swap/break/disable/return to the style item. Check native grip across facings, recovery blends/contacts and durability once per native swing; view a second client for weapon animations, sparks/heat and supplementary victims. Another style or an unsupported item must stay on its own/native weapon behavior. No Yakuza prop IK or physics bridge is supplied.
