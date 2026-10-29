# Juggling hooks for future styles — 0.41.0

This is an opt-in gameplay-window and animation-integration API. Dragon of Dojima has no juggling configuration and gains no launcher moves. The framework does not fabricate airborne motion, lift a zombie by changing floor Z, apply ragdoll force, freeze AI, or add damage. A future style must supply matching victim animations/presentation (and its own compatible physics bridge if real airborne physics is wanted). Native target selection/collision remains unchanged.

## Style configuration

```lua
juggling = {
    enabled = true,                 -- false disables while preserving move declarations
    windowMs = 650,                  -- 50..2000, refreshed by permitted hits
    maxDurationMs = 1800,            -- 50..6000, absolute cap from launch
    maxHits = 4,                     -- 1..12 followups, including the terminating hit
    maxRelaunches = 1,               -- 0..3, also consumes followup budget
    landingCooldownMs = 500,         -- 0..5000 before this victim can be launched again
    presentation = "yourmod.airborne", -- optional addon identifier, <=100 characters
},
```

Add `juggle={kind="launch"}` to a launcher move, `juggle={kind="followup"}` to an eligible air hit, and `juggle={kind="ender"}` to a landing finisher. Each may override windowMs within 50..2000 and the configured hard duration. `juggle=false` or an unmarked move does not continue a juggle. Ground attacks cannot declare juggling. Style registration validates all limits, finite numbers, kinds and opt-ins. A style without this configuration keeps its old behavior.

The launch itself starts with zero followups. Followups refresh only the soft deadline; they never extend the original hard deadline. The final permitted hit ends the state after normal native damage has already occurred. Relaunch, hit count and landing cooldown limits prevent infinite refresh loops. A followup cannot create a new window by itself. Ownership is per attacker/style: another attacker, an unmarked hit, native landing/knockdown/death, style/weapon changes, expiry or world exit closes it.

## Presentation contract

Victim variables are strings/booleans suitable for an addon's native animation-node conditions:

- ProjectYakuzaJuggleActive (boolean)
- ProjectYakuzaJugglePhase (launch/hit while active, empty on exit)
- ProjectYakuzaJuggleStyle
- ProjectYakuzaJugglePresentation
- ProjectYakuzaJuggleHits (numeric string)

Events `juggleStarted(attacker,victim,result)`, `juggleHit(...)` and `juggleEnded(...)` let an addon select its supplied victim/landing animation, sounds/effects and release its own presentation resources. result contains seq, style, phase, reason, hits, relaunches, remaining, hardRemaining and presentation. Do not alter result inside a listener. End reasons include timeout, landed, owner_changed, hit_limit, relaunch_limit, ender, unmarked_hit, interrupted and world_exit.

An addon should use native animation condition flags or its own presentation controller to play its supplied assets. Merely declaring a launcher will track a window; it will not visibly throw a zombie into the air. While a window is active, generic Project Yakuza force/stagger/knockdown responses are suppressed so they do not replace the addon's aerial presentation. The terminating hit may use its normal hitResponse profile for landing. Native damage/death remains authoritative; the API never makes a dead/downed zombie stand up.

## Runtime and multiplayer

Require `ProjectYakuza/Juggling` before using `ProjectYakuza.Juggling`. `get(victim)` returns a detached state snapshot or nil. `plan(style,move)` captures scalar configuration for a confirmed hit. The built-in native-hit pipeline automatically commits it after SP health loss or validated server hits; addons should not call `hit` speculatively on button presses. `finish(victim,reason,false)` cancels an owned presentation window, and clearAll releases flags/hooks. None of these functions deals damage.

SP native hit events are staged until damage calculation returns. MP uses the existing validated per-swing target/path/range/duplicate checks, sends resolved launch/hit/end metadata in impact/damage packets, and mirrors it on clients. Timeout/landing cancellation uses a small standalone juggle result. Stale/duplicate sequences cannot revive an ended window. Client counters/durations are bounded and validated; a pure client cannot commit its own authoritative hit. Native MP architecture remains client-owned for primary hits; this does not claim proof of source animation/charge time.

The state map has a 64-target cap, weak victim keys, and an active-only tick hook. OnTickEvenPaused is used when available, otherwise OnTick; elapsed time observed while paused is compensated. No global zombie search or idle juggle tick is added. No positions, velocities, health, invulnerability or AI movement flags are written. All peers must use matching versions and install the future style's assets.
