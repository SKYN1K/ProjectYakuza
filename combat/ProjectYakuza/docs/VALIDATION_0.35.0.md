# Validation — 0.35.0

No PZ client/server was launched. Live appearance, final blended limb alignment and multiplayer gameplay remain unverified.

| Kahlua suite | Assertions |
| --- | ---: |
| Combat/aura/music | 2,647 |
| Charged/UI | 150 |
| Quicksteps | 71 |
| Multiplayer | 98 |
| Extension API | 42 |
| Starter addon | 9 |
| Heat/shove | 23 |
| Heat audio | 35 |
| Style entry | 21 |
| Taunt/activation/aura | 189 |
| CVF adapter | 63 |
| Selector | 50 |
| Sound settings | 94 |
| Punch source tracking/positioning/audio | 342 |
| Total | **3,834** |

All 39 production Lua files compile. Runtime-dependent assertion totals differ when a redundant additive pass is removed; the taunt suite explicitly asserts its absence.

The native DetachedEffectProbe reproduces AttachExistingAnim writing shared IsoSprite.soff offsets, then verifies pooled detached instances retain zero sprite offsets and independent scale/alpha. It performs no game launch, texture/GPU initialization or JAR edits. The punch suite embeds the actual WorldEffects helpers and checks every differently sized glow centre against its projected source point, plus eighteen-instance/eight-actor limits and several simultaneously visible particles.

The taunt suite embeds HeatOutline and HeatAura. It checks outline flags before the first render and before Extreme Heat fuel, four translucent lower-leg cloud centres, exact 1,000 ms unpaused lifetime, no repeated cloud while activating, pause, interruption, remote activation cleanup, four animated flame/four spark taunt completion particles, no old wisps/additive wash and renderer flag restoration including foreign additive mode.

Existing native/source checks pass: original 31 punch FK samples and eight-facing projection; 130 native aura PNG decodes; fourteen charge nodes; 188 observer nodes; addon builder safety; original BEP charge timing and pose continuity; exact .55 Extreme Heat flame speed; no black matte; all 229 native loader filenames; original smoke/HUD pixels. Source manifests retain all original media hashes.

All **455 animation/image/audio files are byte-identical to v0.34.0**. No new visual/audio asset or upscale was generated. Only Lua/code/docs and test sources changed. The original movement/upper-body blend can still diverge from a code-sampled limb path; the corrected sprite centring does not provide a live mesh/bone shader.

Installation preflights against the prior release, backs up only changed files, and verifies source/install/ZIP bytes. Publishing uses the unique v0.35.0 tag and verifies the uploaded ZIP digest.
