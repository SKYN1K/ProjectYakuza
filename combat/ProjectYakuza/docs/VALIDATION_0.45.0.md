# Validation: 0.45.0

PZ was not launched. No live gameplay, GPU or multiplayer appearance claim is made.

## Actual-module gameplay checks

The expanded weapon fixture contains 125 checks across bat/knife/blade mapping and style isolation, native swing callback routing, all three lights, standalone/queued heavy, x1/x1.25 damage/restoration, heat gain/deduplication, guard availability, source-marker quickstep cancellation, swap/breakage cleanup and actual style-menu weapon retention. It verifies all 48 item mappings, range bounds and critical-safe extra damage. It drives the real MultiHit queue/flush with a primary knife close-kill value of 100, proving the secondary uses native weapon maximum instead; it also rejects a weapon change before the next player update.

The expanded MP fixture contains 34 checks covering real inventory ID/hand retention, blade profile/move isolation, source guard selection, native primary non-replay, short-knife range rejection/acceptance, x1.25 of an 8-damage sword for extra targets, deduplication, stale item/acknowledgement rejection, disable preserving the weapon and remote profile resolution before native hand replication. The existing MP fixture also loads the real Weapons module. Existing other suites remain passing. Total: 4,292 assertions across 16 fixtures; all 42 production Lua files compile.

## Native animation/assets

WeaponAssetProbe imports 26 original-source weapon clips via B42 Jassimp/ProcessedAiScene. All 39,935 source bone samples have finite position/rotation/scale/time, expected 30fps counts and native 35-channel skeleton/clip names. It parses/selects 32 weapon owner nodes and rejects another style or an unarmed profile. validate_weapon_assets.py checks source GMT/BEP/rig/grip/output SHA256 values, frame counts, unit rotations/scales, original BEP kind-68 attack contacts, one collision per strike, upper-body masks and all 48 item IDs against installed B42 item scripts.

Six WPB short-blade clips and ten WPD sweeping-blade/guard clips were added with explicit user authorization. blade-assets.json records provenance and the conversion/grip choices. Every original frame is retained, horizontal root is in-place, and no Yakuza prop IK is imported. No images/models/audio or previous motion clips changed. All 561 prior motion/image/audio files remain byte-identical to 0.44.0.

All 276 observer selectors are event-free and retain their owner clip/speed/blend/mask settings; native probes exercise 138 per restart cycle. Existing source charge/FK, native colour/instance, effect loader, aura/HUD pixel/provenance and addon importer/builder checks pass.

## Install/release and manual limits

Back up only existing installed files that change, install source updates and verify every source/install byte. Publish a unique 0.45.0 tag/install ZIP with Publish-CombatRelease.ps1, then check ZIP/source/install equality and GitHub asset digest. Ignored local reports remain under tools, and backups/previews/extractions/credentials/voice-pack content remain out of Git and releases.

After a full restart on matching versions, test real knives and longer blades from DoD: three lights, heavy, ground targeting, long-blade guard, light quickstep cancels, native condition, grip and transitions in each facing. Observe from a second client for animation/effect/heat timing. Knife primary close kills should remain native, while extras should respect real reach and ordinary weapon damage. Heavy axes/spears and unrelated styles must remain native/their own. Source importer checks cannot establish those live appearance/timing results.
