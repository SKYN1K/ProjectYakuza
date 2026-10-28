# Validation — 0.37.0

No PZ client/server was launched. Current local logs were read only; they identify v0.36.0 and contain no reported charge-effect Lua exception. This does not establish successful GPU rendering. Live depth/visibility, final blended-pose alignment and input feel remain unverified.

| Kahlua fixture | Assertions |
| --- | ---: |
| Combat/aura/music | 2,647 |
| Charge/controller/UI | 181 |
| Quickstep | 71 |
| MP | 104 |
| Extension API | 42 |
| Starter | 9 |
| Heat/shove | 23 |
| Heat audio | 35 |
| Entry | 21 |
| Taunt/aura | 190 |
| CVF | 63 |
| Selector | 50 |
| Settings | 94 |
| Limb rendering/lifecycle | 401 |
| Total | **3,931** |

All 40 production Lua files compile. Limb tests now explicitly distinguish core glow from normal-alpha flame rendering instead of asserting normal alpha on every draw. They verify native world XYZ and screen projection for eight facings; world-anchor compensation preserves the lowered punch/charge centres, and the native render calls receive positive limb-height Z rather than foot depth. No global GL depth state is modified.

Controller tests verify that a held charge cannot cancel before both native hit/chain markers or before hold recognition, buffered lights keep priority, and charge queuing preserves ProjectYakuzaActive. Startup tests simulate the timed action beginning before its context is assigned to activeActions, plus absent debug tracks, visible bounded particles, throttled retries, stop/owner cleanup and renderer flag restoration. Taunt tests verify no additive brightness pass and one base-aura frame advance.

Native validation retains all source checks: nine charge paths/87 samples, source charge handoff markers, fourteen charge nodes, 188 event-free observer selectors, original clip import/pose continuity, 130 aura PNG decodes, all 229 loader filenames, original smoke/HUD pixels and alpha-bearing flame provenance. The four entry wind-ups and their eight observer copies use matching .14-second blend-in. All **455 animation/image/audio files are byte-identical to v0.36.0**.

Installation preflights against v0.36.0, backs up only changed files, verifies installed bytes and publishes a unique v0.37.0 ZIP/release. Source/install/ZIP bytes and the uploaded digest are compared after publication.
