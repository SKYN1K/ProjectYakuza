# Charged heavy attacks — 0.36.0

Hold MMB while aiming after 1–4 lights to charge that first finisher. Tap-release retains normal finisher input; Tiger Drop keeps initial-press priority. Second finishers cannot charge.

## Input, timing and damage

DoD now has a **1,200 ms charge-action limit**, measured after the native charge action starts, excluding pause. The initial hold-recognition gesture is separate (350 ms neutral, source-pause duration after lights). Holding to the limit automatically submits one full-power native attack. Releasing earlier submits once the minimum pose/handoff is reached, with lower damage. A held key does not automatically begin another charge.

The native source pause frames remain 6/7/6/5 at 30 fps. Minimum wind-up durations are .2/.233333/.2/.166667 seconds; neutral minimum is 350 ms. Charge fraction is clamp((elapsed-minimum)/(1200-minimum),0,1). Charged first finishers scale linearly from x1.25 to x2 damage; neutral charged heavy scales from x1 to x2, before existing heat modifiers. Full power retains the previous maximum. Ordinary second-finisher damage is unchanged.

A variant-bound, expiring, one-use ticket carries the fraction. Runtime copies the resolved move before applying damage; it never changes the shared style definition. Invalid native submissions may retry within the existing 600 ms handover. Getting hit, losing aim, death, unequip, invalid state or missing playback cancels without a strike and restores movement flags. Charging stays vulnerable.

## Animation handoff and work reduction

Wind-ups emit started, a handoff marker one source frame before the end, then done. The controller switches to the matching original-pose looping hold only after a native handoff/done marker, rather than cutting it based on wall time. Wind-up/hold blends are .08/.06 seconds. The original hold/release poses and all .x files are unchanged. Missing hold acknowledgement cancels; pause now suspends that timeout too.

Stationary charging no longer repeatedly rewrites tile/current-square state. Position correction runs only if the actor actually drifts from the anchor. Movement/attack locks remain intact. These changes address transition timing and redundant position updates; live smoothness is not established by offline tests.

## Limb effects

The former fixed facing offset/wide spark orbit is removed. ChargeTracks contains numeric positions imported from the already-retargeted native B42 clips: neutral hands and branch-specific forearm/wrist or calf/ankle paths. Four source wind-ups, four fixed holds and the neutral loop supply 87 original sample times. Each charged limb has three glints, two animated source flame patches and a small spark travelling inside the limb span. A neutral two-arm charge uses twelve instances, branch charges six, with an eight-actor cap. Native playback time/facing, pause, cached lookups, detached per-instance centring and cleanup are preserved. Glow strength rises with charge fraction.

These are code-sampled particle positions, not final blended bone transforms or an emissive mesh shader. Full-body charge poses reduce locomotion mismatch, but visual alignment still needs live testing. [Provenance](charge-limb-tracks.json) records native clip hashes, selected bones and exact output-code hash. No image/audio/motion asset was created, altered or upscaled.

## Multiplayer

Existing state snapshots carry an optional bounded chargePower fraction. Charging updates are quantized to tenths for the existing snapshot throttle. Observers use it for limb glow; the server validates 0..1 and locks a private scaled move per multihit swing, so additional victims use the same damage. Native primary damage is not applied twice. This remains the existing client-owned combat model: a bounded reported fraction does not prove that a client genuinely held the key. Same version is required on server and clients; MP protocol remains 2.

## Framework fields

`heavyCharge` variants use animation, holdAnimation, chargeBranch, holdMs (input recognition), windupMs/minChargeMs (minimum pose) and maxHoldMs (automatic release). DoD sets maxHoldMs=1200. Other styles may explicitly use zero for manual-only release. Matching `chargedHeavy` variants use damageMultiplier (maximum) and optional minChargedDamageMultiplier (minimum, validated 0..maximum). Omit the minimum to retain that addon's fixed damage. `ProjectYakuza.ChargeRules.power` and `.damage` centralize clamping/interpolation.

`heavyChargeReady` now means full power, rather than the start of the held pose. Existing started/stopped and chargedHeavyStarted/Finished hooks remain. Presentation hooks must not apply extra damage. Original BEPs prove pause/contact markers, not a Dragon Engine global full-charge threshold; the 1.2-second limit is this mod's selected policy.
