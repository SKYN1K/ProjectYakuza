# Validation: 0.53.0

PZ was not launched. Live visuals, mesh/weapon intersections, actual input and MP latency remain untested.

## Regression and native checks

5,761 Kahlua assertions across 21 fixtures pass. All 48 production Lua files compile. Six lexical preservation tests pass; the comment audit reports zero comments across 596 source files.

The 454-check punch fixture compares the imported native arm/palm path in 16 facings, removes the previous fixed height/inset, verifies render-time phase refresh, normal transparency, live-provider fallback, pooling, pause, cancellation and source-clock sound timing. Heavy whooshes are checked beyond the old 350ms cutoff, at the live clip phase and once only. This is a source-path correction, not a claim of final blended-bone access; PZ suppresses torso twist while attacking and a blanket shoulder-yaw correction is not applied.

The 229-check blood/impact fixture covers confirmed hits, guard sparks without blood, subtle shock-ring opacity, detached sprite ownership, expiry, bounded pooling and renderer restoration on an injected draw failure. Existing charge/UI tests include the single new ring. Native B42 sound parsing accepts all 18 definitions and 51 source-clip references, resolving every existing file. Guard/double cues reference supplied audio without editing waveforms.

The 1,008-check encounter fixture checks all title boundaries, exact radius/floor/death exclusions, early stop at 40, nearby-grid budgets, at most three ordinary 12-tile count ticks, pause/rearm, style isolation, mouse transparency and provider cleanup. A fixture containing 5,000 distant zombies reads none of those zombies. The landing draws exactly one enlarged source-atlas frame at a time and no explosion after completion. Native reflection confirms IsoCell.getGridSquare and IsoGridSquare.getMovingObjects; the four original intro textures still decode natively and retain source pixels.

## Weapon carry repair

Nine relaxed carry clips are repaired; the four Kiryu run clips, aimed stances and weapon attacks are unchanged. Native idle grips replace the previous attack grip. Source arms use the existing frame-zero pose consistently across idle/slow/walk, while native torso, neck, head, legs, travel and helper hierarchy remain. This avoids a separately resampled upper-body loop and retains native head direction. The source/native provenance, original/output hashes and operation are in locomotion-assets.json and carry-repair-053.json. No new body pose is invented.

Native import checks pass for 13 clips / 13,605 finite bone samples and 100 selection/fallback contracts. Source/native comparison validates 13,284 local samples (max matrix error 4.172326E-7). Native FK validates 576 hand-prop pairs (max error 6.973744E-6). Native carry hierarchy is required to match its supplied base; B42's native 35/45-bone helper variants are both retained correctly. Run/hold endpoints and native walk seams retain the existing tolerances. These checks establish transforms and data integrity, not live katana mesh clearance.

Exactly nine previous media files differ from the 0.52.0 ZIP, all approved carry motion composites. Every existing image/audio file is byte-identical. Source reuse hashes are in feedback-polish-assets.json; no image/audio asset was generated, upscaled or repainted. No separate voice-pack file is touched. Existing attack contacts, charge timing, source poses, 316 event-free observers, weapon/MP authority, heat, UI, addon and sound-settings fixtures pass.

## Runtime scope and installation

The spatial count runs once at encounter start, over the captured local radius; no loaded-world zombie list is traversed. Native threat polling remains once per 400ms and quiet rearming remains 12 seconds. Mutable moving-object lists can affect membership while counting; the deduplication set prevents repeats. Extremely dense non-zombie moving-object lists or larger addon radii can take longer than the ordinary three-tick fixture. No FPS benchmark or live performance measurement is claimed.

Impact/guard presentation retains existing per-player/global caps and hooks only while bursts exist. Guard visuals reuse the existing MP fanout; no protocol change or new network message is added. Existing movement, damage, heat gain, voice and music rules are retained.

The prior 1,327-file installation must match its published ZIP before replacement. Back up only replaced files, then verify all source/install/ZIP bytes and the published asset digest. Restart matching installations to load repaired clips. The remaining live checks are palm alignment during rendered blends/turns, relaxed weapon clearance and appearance, burst size and crowd-detection feel.
