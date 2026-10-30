# Validation: 0.48.0

PZ was not launched. GPU appearance, live gameplay and live MP timing were not tested.

## Supplied blood assets

Sixteen native-size 128x128 RGBA PNG frames are exact 4x4 row-major crops of the supplied Yakuza 6 e_j_0035_bfBloodSplash03.dds. validate_blood_assets.py verifies original DDS/output hashes, source crop byte equality, unchanged alpha, visible red samples, nonempty frames and exact native filenames. BloodAssetProbe decodes every output through B42 ImageData and checks dimensions/pixel data without a GPU. Conversion was explicitly approved; no AI, resizing, alpha conversion, new colours or invented artwork.

All 578 existing motion/image/audio assets are byte-identical to 0.47.0. No existing native XML changes. Only the 16 approved blood crops are added to media. No audio, model or voice-pack changes.

## Runtime checks

4,522 Kahlua assertions across 18 fixtures pass. All 45 production Lua files compile. The new actual-module blood fixture embeds WorldEffects, BloodEffects and HitEffects and passes 183 checks: real confirmed-hit/damage/weapon guards, per-victim deduplication, sparks and blood together, all sixteen source frames, unchanged time without new allocations, pause/resume, complete expiry, ordinary/charged/downed scales, stable world anchors across eight simulated facings, existing remote impact spawn, explicit style opt-in and hit-effect toggle.

The same fixture checks four-per-attacker and sixteen-global burst budgets, cached sprites, native instance disposal, style/death cleanup, no idle tick/render hooks, normal transparency, restoration of the incoming blend state and failure cleanup. Every allocated mock native instance is released. Native detached-instance/colour contracts also pass. The frame clock uses milliseconds, not repeated render calls; it does not scan zombies or add network packets.

Existing weapon/MP equipment, neutral heavy, combo/charge/double routes, quickstep limits/cancels, heat/taunt/aura/HUD, source limb tracks, music/settings, CVF adapters, addon APIs and native observer/source-contact tests retain their passes. Native checks import 27 weapon/heavy clips, 41,720 finite bone samples, 33 owner selectors and 280 event-free observers. The 31-clip prop repair remains validated across 2,568 hand/prop pairs. Native HUD/aura/source frame and colour-copy checks remain unchanged.

Six lexical preservation tests pass. The comment audit reports zero comments across 517 tracked/whitelisted source files. The publisher is parsed with native PowerShell before release.

## Installation and limits

The installed 1,210-file 0.47.0 tree exactly matches its prior release ZIP before installation. Back up only existing replaced files, install the new payload and compare every source/install/ZIP byte. Publish a unique 0.48.0 release and verify its GitHub digest against the local ZIP. Extraction sources, previews, backups and credentials remain excluded from Git.

The blood burst is client world presentation tied to existing confirmed impact handling; native damage, wounds and permanent decals are unchanged. Actual live effect size/occlusion and MP delivery still require user assessment after a full restart on matching versions.
