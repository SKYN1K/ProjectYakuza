# Dragon of Dojima locomotion

Ordinary vanilla weapon idle/aim/movement uses native PZ selection. Unarmed relaxed idle and ordinary walking retain native behavior; the reference style supplies its combat idle and eligible run motion. Native movement state controls travel and fallback selection, including exhausted running.

As of 0.101.0, the permanently disabled custom weapon-pose/ordinary-walk selectors and unused converted clips are removed. Vanilla weapon poses and ordinary unarmed walking remain selected exactly as before. The sections below and their provenance describe historical conversions. Active unarmed run/sprint and the restored unarmed RMB combat idle remain. See ASSET_CLEANUP.md and VALIDATION_0.101.0.md; the source archive references are retained for reproducibility.

## Historical conversion reference

The source-motion sections below record earlier conversions and disabled experiments; they are not instructions to enable additional locomotion in the player release. Current behavior is described above.

### Walking and sprinting

Unarmed ordinary walking and slow walking use the first complete 65-frame gait cycle from P_KRU_MOV_wlk_ftl. All 66 boundary-inclusive samples are preserved and retimed to the corresponding native Bob_Walk/Bob_WalkSlow cycle. Sprint uses P_KRU_MOV_run_ftl_ex, a supplied run variant, retimed to Bob_Sprint. Native Translation_Data, distance per second, movement scalars and ordinary safety fallbacks remain. This is a supplied sprint candidate, not a claim to import the original game's locomotion controller.

Ordinary running retains the previous complete P_KRU_MOV_run_ftl cycle, 1.0 healthy cadence and compensated native travel. Its healthy walking blend uses native Bob_Walk. The run body motion and travel have not been changed in this update.

## Weapons

Bat holds use WPA. Katana/long-blade holds use WPD, matching the blade attacks; the previous WPN carry reference was a mismatched source. Bottles use suitable WPA one-handed blunt motion and the crate uses WPC bulky-object motion. The profile assignment is a suitable-motion selection and does not reproduce Dragon Engine object IK.

Ready/relaxed holds use the matching stdA/stdB loops. Katana walking/running uses its supplied wpd movement variants; crate walking uses wpc. Other weapons use Kiryu's supplied battle walk/general run arm motion. Walking and slow walking retain native PZ legs, torso, head, helper bones and deferred travel. Source shoulder/elbow/wrist directions are fitted relative to the chest using PZ's anatomical segment lengths. Wrist articulation follows the original forearm-relative rotation. This corrects the old rest-axis and torso-basis mismatch while retaining the Yakuza poses. Native grip offsets fit the held model to PZ's hand; they do not select a native hold animation. Running/sprinting combines those source arms with the existing Kiryu run or newly converted sprint body. Native hand-to-prop offsets are recomputed every frame during conversion.

Ready and relaxed idle loops retain the original two-second Yakuza timing instead of compressing the whole loop into a short native idle cycle. Native idle-body samples repeat at their existing cadence beneath those source arms.

Bat, blade, bottle and crate profiles have relaxed idle, walk, slow walk, run and sprint clips plus an aimed hold. Knife carry/ready/run remains native; its custom attack blends receive the same smoothing. Existing blade/bat/knife attack motion and item scripts remain unchanged. Earlier disabled source reference clips remain supplied for future repair; these converted pose clips are currently disabled at runtime.

The katana ready selectors disable extra native torso twisting. Earlier offline mesh-edge checks did not reproduce the reported live neck clipping. The custom weapon poses are now disabled; restoring them requires further live testing.

## Blending and fallbacks

Locomotion entry/recovery blends are 0.25 seconds, aimed holds 0.28 seconds. Custom weapon melee/guard entry is 0.14 seconds and recovery 0.20 seconds. Aimed holds/guards keep native walking legs. Source loop phases and native movement blends remain in use. Source sample interpolation during retargeting/retiming does not invent motion or artwork.

Selectors require the selected DoD style, matching profile and Aim=false for relaxed locomotion. They reject injury, trees, sneaking, overburdened state and turn-around; idle additionally excludes native 90-degree turns. Native special states retain control. Existing equipped-style/profile variables already replicate normal movement to MP observers; attacks additionally use event-free observer nodes. Matching files are required on server and clients.

## Authoring and validation

Locomotion uses ordinary AnimSets XML. Addon authors can supply their own named clips/nodes, style/profile conditions, upper-body masks, native deferred travel and safety fallbacks. Keep source motion, model attachments and grips compatible. Do not add per-frame actor displacement to normal locomotion.

See [weapon motion provenance](weapon-motion-assets.json), [walk/sprint provenance](style-travel-assets.json), [selector inventory](locomotion-nodes.json) and [Validation](VALIDATION.md). Offline checks compare source/native samples, hand-prop FK, movement tracks, mesh clearance, native import and selector isolation. Live foot planting, clothing clearance and MP latency still need assessment after restarting PZ. The game was kept closed.
