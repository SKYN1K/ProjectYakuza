# Validation — 0.41.0

No PZ game/client/server was launched. Live GPU rendering and MP appearance remain unverified.

Fourteen Kahlua fixtures pass 4,076 assertions: framework 2,647; charge/UI 181; quickstep 71; MP/reactions/juggling 192; extension 42; starter 9; heat/shove 23; heat audio 35; entry 21; taunt 198; CVF 63; selector 50; settings 94; limb effects 450. All 41 production Lua files compile.

The taunt fixture now uses a read-only colour proxy whose field assignments throw, matching the reported attempted-index-of-non-table failure. Production uses the exposed :set(r,g,b,a) method. DetachedEffectProbe invokes that real float setter on both native Color and ColorInfo and verifies the stored value, without starting PZ. This tests native method availability and the regression contract; it does not claim a live GPU test.

Juggling checks cover opt-in/disabled configuration, schema limits, launcher/followup/ender behavior, ownership, same-swing duplicates, hard/soft deadlines, hit/relaunch budgets, cooldown, native landing/death, style change, observed pause, target cap, no health/position/Hit side effects, actual post-native-hit SP queue, server primary result without another Hit, client relay, invalid counters, duplicate/late packet ordering and teardown. Existing DoD responses still pass all 149 prior MP/reaction checks. No production style enables juggling.

Limb checks exercise eight facings with six supplied live world coordinates, exact hand anchoring without sampled rotation/height inset, one provider call per draw, unregister and failing-provider throttle/fallback. The default path is still source-sampled: no exposed final native bone-transform object or bridge is supplied. These adapter tests are not evidence of an installed live bone provider.

All prior native/source checks pass: model FK/projection, pool contracts, 188 observers, charge source paths/pose/timing, 226 aura PNG decodes, 325 frame paths, approved colour-only pixel mapping and original flame/smoke/HUD provenance. All 551 motion/image/audio files match v0.40.0 bytes. No media were added.

Installation backs up only changed installed files after v0.40.0 baseline preflight, verifies all installed bytes, and publishes a unique v0.41.0 release/install ZIP. Source/install/ZIP bytes and remote asset digest are compared after publication.
