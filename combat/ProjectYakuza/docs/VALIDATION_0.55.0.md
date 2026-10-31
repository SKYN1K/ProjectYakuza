# Validation: 0.55.0

PZ was not launched. Validation uses the installed B42 native importer, animation node parser/selectors, original local Yakuza source files and Kahlua. GPU appearance, exact live foot planting and real multiplayer latency have not been tested.

## Runtime and protocol

All 21 offline Kahlua fixtures pass: 5,758 assertions. The boost/barrage fixture covers actual native light routing, mode transitions, a last fuel-depleted boost swing, retained clip selection, removed reversing variants, weapon isolation, direct action gates, fifth-click/heavy routing, short buffers, native phase timing, pause, skipped late contacts, duplicate prevention, movement restoration and actual SP Hit damage/target caching. Multiplayer checks cover mode-start authorization, action leases, contact timing/order, replay and ID deduplication, cap rejection, walls, server-calculated damage, depletion and expiry. Owner/observer hit effects and per-contact sound are deduplicated, without earning heat from barrage results.

All 50 production Lua modules compile. The source comment scan reports 585 source files and zero comments; all six lexical preservation tests pass. The complete offline reference runner reports 66 passing steps, including unchanged combat, controls, heat, music, UI, aura, blood, effects, encounters, voice integration and weapon regressions.

## Supplied motion and native import

Six approved Yakuza 6 `bct_ath` motions retain all original source frames. GMT/BEP/rig/native finger and grip hashes, output hashes and contacts are recorded in boost-attack-assets.json. Source comparisons verify 9,452 finite retained bone samples. Native B42 imports all six clips; native FK validates 556 hand-prop pairs. Six owner selectors parse/select with no style/weapon leakage. Four boost-light nodes each have one native collision; barrage nodes have no native collision events and use the source 13/five contact frames. All 304 event-free observers parse/select in two repeat cycles.

Four running clips change only their existing Translation_Data animation block. Every body, finger and prop block remains text-identical to the 0.54.0 payload. Healthy playback is 1.0 instead of 1.28, and deferred travel is scaled 1.28, preserving the distance/time product. Source/native comparison checks 13,284 local samples with maximum error below 0.000001; native import checks 13 locomotion clips, 13,605 finite bone samples and 100 selector/fallback contracts. Native FK checks 576 locomotion hand-prop pairs. Existing carry holds and native walking legs remain unchanged.

The nine obsolete reversing animation files and 45 corresponding owner/observer nodes are removed. Their historical source manifest and versioned validation notes remain as provenance. No original graphical/audio media changed: all 420 existing images and 64 audio files match 0.54.0 byte-for-byte. No new images/audio were created and no AI asset generation was used. The separate CVF voice-pack project is untouched.

## Installation and publication

Before installation, verify the complete 0.54.0 installed tree against its ZIP. Back up only replaced/removed existing files, remove only the 54 explicitly obsolete files within the fixed mod installation, and verify the full installed tree against current source. Publish a unique v0.55.0 release using Publish-CombatRelease.ps1, verify its ZIP tree/bytes and GitHub asset digest, and confirm a clean Git worktree. Extraction folders, raw intermediates, previews, backups and credentials are not part of Git or the install ZIP. A full restart of matching client/server installs is required to load new animation resources.
