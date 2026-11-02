# Dragon of Dojima locomotion (0.75.0)

DoD uses Kiryu's supplied Yakuza 6 motion while preserving PZ movement rules. Only the selected DoD style and its matching equipment profile use these selectors. No movement polling/controller or new network loop is added.

## Walking and sprinting

Unarmed ordinary walking and slow walking use the first complete 65-frame gait cycle from P_KRU_MOV_wlk_ftl. All 66 boundary-inclusive samples are preserved and retimed to the corresponding native Bob_Walk/Bob_WalkSlow cycle. Sprint uses P_KRU_MOV_run_ftl_ex, a supplied run variant, retimed to Bob_Sprint. Native Translation_Data, distance per second, movement scalars and ordinary safety fallbacks remain. This is a supplied sprint candidate, not a claim to import the original game's locomotion controller.

Ordinary running retains the previous complete P_KRU_MOV_run_ftl cycle, 1.0 healthy cadence and compensated native travel. Its healthy walking blend now uses the supplied walk cycle. The run body motion and travel have not been changed in this update.

## Weapons

Bat holds use WPA. Katana/long-blade holds use WPD, matching the blade attacks; the previous WPN carry reference was a mismatched source. Bottles use suitable WPA one-handed blunt motion and the crate uses WPC bulky-object motion. The profile assignment is a suitable-motion selection and does not reproduce Dragon Engine object IK.

Ready/relaxed holds use the matching stdA/stdB loops. Katana walking/running uses its supplied wpd movement variants; crate walking uses wpc. Other weapons use Kiryu's supplied battle walk/general run arm motion. Walking and slow walking retain native PZ legs, torso, head, helper bones and deferred travel. Source arm world orientations are converted back to local transforms under that native torso, avoiding the earlier local-space torso mismatch and sideways head overlay. Running/sprinting combines those source arms with the existing Kiryu run or newly converted sprint body. Native hand-to-prop offsets are recomputed every frame during conversion.

Bat, blade, bottle and crate profiles have relaxed idle, walk, slow walk, run and sprint clips plus an aimed hold. Knife carry/ready/run remains native; its custom attack blends receive the same smoothing. Native blade/bat/knife attack motion and item scripts remain unchanged. Earlier disabled source reference clips remain supplied for future repair; active selectors choose the new corrected clips.

The katana ready selectors disable extra native torso twisting. Its native mesh edges are checked against the neck/head through all hold/movement poses and sampled crossfades. These checks cover standard PZ proportions, not clothing, every live look-at layer or customized skeletons.

## Blending and fallbacks

Locomotion entry/recovery blends are 0.25 seconds, aimed holds 0.28 seconds. Custom weapon melee/guard entry is 0.14 seconds and recovery 0.20 seconds. Aimed holds/guards keep native walking legs. Source loop phases and native movement blends remain in use. Source sample interpolation during retargeting/retiming does not invent motion or artwork.

Selectors require the selected DoD style, matching profile and Aim=false for relaxed locomotion. They reject injury, trees, sneaking, overburdened state and turn-around; idle additionally excludes native 90-degree turns. Native special states retain control. Existing equipped-style/profile variables already replicate normal movement to MP observers; attacks additionally use event-free observer nodes. Matching files are required on server and clients.

## Authoring and validation

Locomotion uses ordinary AnimSets XML. Addon authors can supply their own named clips/nodes, style/profile conditions, upper-body masks, native deferred travel and safety fallbacks. Keep source motion, model attachments and grips compatible. Do not add per-frame actor displacement to normal locomotion.

See [weapon motion provenance](weapon-motion-assets.json), [walk/sprint provenance](style-travel-assets.json), [selector inventory](locomotion-nodes.json) and [validation](VALIDATION_0.75.0.md). Offline checks compare source/native samples, hand-prop FK, movement tracks, mesh clearance, native import and selector isolation. Live foot planting, clothing clearance and MP latency still need assessment after restarting PZ. The game was kept closed.
