# Validation — 0.36.0

No PZ client/server was launched. GPU appearance, final blended limb alignment, input feel and live MP remain unverified.

| Kahlua fixture | Assertions |
| --- | ---: |
| Combat/aura/music | 2,647 |
| Charge rules/lifecycle/UI | 176 |
| Quicksteps | 71 |
| Multiplayer | 104 |
| Extension API | 42 |
| Starter | 9 |
| Heat/shove | 23 |
| Heat audio | 35 |
| Style entry | 21 |
| Taunt/aura | 190 |
| Optional CVF | 63 |
| Selector | 50 |
| Sound settings | 94 |
| Punch and charge limb presentation | 528 |
| Total | **4,053** |

All 40 production Lua files compile in B42. Native Jassimp/HelperFunctions validate nine untouched charge clips and all 87 exported sample times against the numeric limb code. Four owner wind-ups carry the expected one-source-frame-before-end marker; all fourteen charge nodes parse, releases each retain one collision, and 188 event-free observers match their owner clip/blend/mask settings. Original BEP pause/contact timings and wind-up/hold/release endpoint poses remain unchanged.

Charge tests cover fractional damage, no mutation of registered moves, native retry/one-use tickets, all four full-power deadlines, early releases, pause-safe missing-hold timeout, no wall-time-only handoff, interruption and unchargeable second finishers. MP tests reject invalid/nonfinite fractions and verify actual additional-victim damage plus per-swing power locking. The reported fraction remains client-owned rather than a server proof of charging time.

Limb presentation tests embed actual WorldEffects/AttackEffects/ChargeEffects and native numeric paths. They check white-blue inset punch centres, short trails, per-branch limb centres, remote power, bounded six/twelve charging instances and eight actors, pause, cleanup, no per-frame particle reallocation and graphics-state restoration. Taunt tests check the bounded completion aura pulse and exact shared smoke/flame tint.

Existing native checks pass: detached sprite-offset/pool contract, original 31 punch samples/eight-facing projection, 130 decoded aura PNGs, 229 loader filenames, .55 flame speed, true-alpha/no-black-matte pixels, original smoke/HUD pixels and addon observer-builder safety. All **455 motion/image/audio files are byte-identical to v0.35.0**. XML/code changes do not synthesize media or poses.

Installation compares the prior-release baseline before writes, backs up only changed files and verifies installed bytes. The release uses a unique v0.36.0 tag, install ZIP and verified remote digest.
