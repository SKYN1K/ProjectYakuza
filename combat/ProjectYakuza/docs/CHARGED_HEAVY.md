# Charged heavy attacks — 0.33.0

After 1–4 lights, hold the heavy binding (default MMB while aiming) to charge that finisher. Tap-release retains ordinary finisher input. Valid Tiger Drop keeps initial-press priority. A second-finisher press queues its ordinary follow-up immediately and cannot be charged.

## Source timing and persistent pose

Kiryu's supplied original BEPs contain Charge events (type 206) at frames **6, 7, 6 and 5** at 30 fps: .2/.233333/.2/.166667 seconds. These now define each first-finisher's wind-up split and branch-specific hold-recognition timing, replacing the guessed later split points. First source hit-window starts are frames 18/19/15/18; native charged-release collisions are rebased accordingly. Charged releases play at original 1x animation rate. The neutral generic release uses its source first hit window at frame 12. Damage and second-finisher link rules remain unchanged.

At the wind-up endpoint, the native timed action explicitly switches PerformingAction to a **looping hold clip**. That clip repeats the same original source pose at two native key times; no new pose is authored. This prevents B42 from dropping an ended non-looping wind-up back to idle. The hold node acknowledges playback; a missing hold clip cancels safely instead of leaving an invisible charge/input lock. The four holds are available to MP observers too.

DoD now holds until release or interruption, rather than auto-releasing at an arbitrary 3.5 seconds. Aimed standing charge retains its generic looping source animation. Losing aim, getting hit, death, unequip, invalid movement state, save/menu exit and failed playback still restore captured flags. Charging remains vulnerable. Pause freezes the timers/particles. One short-lived variant-bound ticket authorizes one native release, with existing armor, collision, multihit and MP authority.

The BEP markers verify motion pause/contact timing. They do **not** document Dragon Engine's engine-wide/full-charge threshold or every skill/command rule. Branch input recognition is mapped to the verified source pause duration; neutral recognition retains the prior 350 ms gesture. This is a B42 adaptation using source animation timing, not a claim that all engine charge rules are reproduced exactly. See [timing/source hashes](y6-charge-timing.json).

## Charging effects

Ten original Y6 sparks, one small animated original alpha-bearing flame and one original glint/core surround the approximate lead-hand area in world space. A brief ready pulse occurs when the wind-up reaches its hold pose. No UI overlay or generated texture is used. Twelve instances per charging actor are cached/bounded, pause correctly, and are released when charging ends, a remote hold disappears or an actor becomes stale. Blend state is scoped/restored on errors. Placement follows actor facing rather than an unavailable Lua per-hand bone renderer.

## Authoring

`heavyCharge.variants` can define default/after_n moves. A branch move supplies animation (wind-up), holdAnimation (looped source-pose hold), chargeBranch, holdMs (recognition), windupMs/minChargeMs (minimum source playback), and maxHoldMs. Set maxHoldMs=0 for manual holding; omitted values retain duration-based compatibility for existing addons. Matching chargedHeavy variants set chargedHeavy=true, chargedFinisher=true and chargeBranch. Neutral variants omit chargedFinisher/chargeBranch.

Wind-up nodes emit ProjectYakuzaChargeClip=started/done. Hold nodes loop and emit ProjectYakuzaChargeClip=holding at Start. Both are full-body and contain no collision events. Strike nodes contain exactly one native collision, source-rebased contact/link markers and the appropriate speed. Register all owner nodes as event-free observers. Source/crop/hash checks verify all twelve native clips and identical wind-up/hold/release poses.

Events: heavyChargeStarted(player,style,move), heavyChargeReady(player,style,move), heavyChargeStopped(player,completed), chargedHeavyStarted(player,style,move), chargedHeavyFinished(player,move). These presentation hooks must not apply extra damage. Supply existing assets and controllers; raw GMTs cannot be played directly by B42.
