# Multiplayer and addon authority

Normal launcher, Lua-only protocol 2. Server and clients need matching shared styles, custom kind declarations, catalogs and assets. Native input/UI/timed actions belong under client; new authoritative mechanics belong under server.

| System | Current behavior |
| --- | --- |
| Equipment | Server-recognized inventory ID; waits for native delivery plus acknowledgement |
| Explicit entry | Starts after equip acknowledgement; repairs/reconnects do not replay it |
| Playback | Owner-node catalog, event-free remote clip/blend/speed/mask observers |
| Heat/aura | Owner-driven state relayed for presentation; HUD local |
| Primary hits | Native PZ; impact reporting does not hit again |
| Supplemental hits | Server checks/deduplication and shared three-target cap; observer result is not another Hit |
| Dash travel | Bounded collision-checked samples/interpolation |
| Counter | Local 0.3-second window plus server target/state/range/60-second cooldown; no rewind guarantee |
| Guard | Valid block clip/nearby attacker and scoped cancellation |
| Heat activation | Bounded protection lease restores previous flags; other kinds do not inherit it |
| Grabs/throws | Implementation/leases retained but temporarily disabled client/server |
| Music, volumes, assignments | Local preferences, not synchronized soundtrack |
| CVF | Provider owns transmission/policy; do not send voices twice |

This is not a full server heat simulation/anti-cheat. Direct ragdoll impulses, cinematic cameras, PvP parity and rollback are not provided. Live two-client testing remains necessary.

## Addon catalogs

```lua
require "ProjectYakuza/NetworkExtensions"
require "MyStyle_Style"
ProjectYakuza.registerNetworkAnimations("my_mod.my_style",{
    {id="MyStyle_Action",animation="MyStyle_Action",group="actions",
     priority=150,loop=false,
     conditions={{name="PerformingAction",value="MyStyle_Action"}}},
})
```

Conditions describe the owner node, not observer conditions. Groups: melee/stomp/actions. Style must be registered first. Catalog registration is one-time; IDs must be globally unique. Invalid batches publish nothing, caller metadata is copied and merged priority order is applied. Timed playback capture needs owned context.timedAction.started=true and matching native variables.

## Observer builder

The shipped tools/build_style_observers.py requires only Python 3's standard library. Activate your owner's .xml files first. Point --mod-root at your addon, not the framework:

```text
python ProjectYakuza/tools/build_style_observers.py --mod-root MyStyleAddon --style-id my_mod.my_style --prefix MyStyle_ --dry-run
python ProjectYakuza/tools/build_style_observers.py --mod-root MyStyleAddon --style-id my_mod.my_style --prefix MyStyle_
```

Use an exclusive prefix ending in underscore for owner XML names and shared MyStyle_Style.lua. The tool writes MyStyle_Network.lua and observers. It preserves clip/speed/blends/masks, strips every event and replaces conditions with ProjectYakuzaRemoteObserver=true, ProjectYakuzaRemoteClip=owner ID and ProjectYakuzaRemoteCycle=0/1. Melee/stomp owners get both native-group and actions copies; timed owners get actions copies.

Only simple BOOL/STRING conjunctions are supported; blend trees/complex conditions require manual support. The builder skips its stamped outputs, refuses to overwrite author-maintained files and deletes nothing. Remove only known obsolete generated nodes after renaming/removing owners. Inspect dry-run and diff. Output is Lua/XML code, not synthesized media.

## New gameplay

Catalog registration does not authorize damage, force, target grabs or teleporting. Implement scoped commands with eligibility/range/facing/obstruction validation, server costs/cooldowns where needed, serial checks, target ownership, bounded leases and disconnect cleanup. Existing commands only implement their own mechanics; never trust arbitrary client damage/force values.

Test late joins, delayed inventory/acks, repeated clips, walls/stairs, moving/streamed zombies, target ownership, interrupted actions and latency. Every victim must take damage once regardless of observer count. New paired mechanics need their own server tests; observer XML alone is insufficient.

## Move-specific responses (0.40.0)

Existing impact/damage packets now optionally carry server-resolved responseKind/responseForce. The move and release power are locked per swing; extra victims use the same captured values. Primary response flags are deferred until the next server tick and mirrored to the attacker and observers. No primary Hit/damage is replayed. Supplemental knockdowns use these fields, not the legacy throw knock flag, so regular combat feedback and heat are preserved. See [Hit responses](HIT_RESPONSES.md). MP protocol remains 2 with additive optional result fields; use matching mod versions on all peers.

## Future-style juggling (0.41.0)

Optional style.juggling and move.juggle={kind="launch"/"followup"/"ender"} enable bounded launcher/followup windows, hit/relaunch caps, landing cooldown, victim animation variables and start/hit/end events. No airborne assets or physical lift are supplied by the core. SP/server confirmed hits drive the state; optional result metadata and ordered end packets mirror it in MP. DoD remains unconfigured. See [Juggling](JUGGLING.md) for limits, presentation ownership, cancellation and examples.

## Observer lifecycle and sessions (0.56.0)

Server states, equipment acknowledgements and relayed combat results carry an additive session serial. A new native player object receives a new monotonic server session, even when its online ID is recycled. Clients accept fresh session counters without retaining the old high sequence number, discard older-session messages, and clear only that peer's result/deferred caches. Replaced actors also release old protection/retained leases. Session state is reset on world exit; restart matching server/client versions after updating.

Melee/stomp playback restarts on a new swing serial, and timed-action playback restarts on a new action serial. Updating the other counter no longer restarts an already-playing clip. Clip/style changes still transition normally. Repeated same-clip paired actions and native finishers therefore use their own serial type. Same-sequence server protection-expiry corrections remain accepted.

Combat commands force an immediate state check but reuse an unchanged snapshot. Changed state is sent before the dependent command; periodic heartbeats and explicit forced snapshots are retained. This avoids sending the same full state alongside every hit/dash sample.

Stale/replaced remote actors release observer action flags, weapon-profile/charge/link flags, Heat state, aura/outline and attack/charge limb effects. Unknown addon styles clear their presentation rather than invoking a missing style's aura/UI. Install all required style addons on every peer for full presentation.

Server primary response planning and supplemental damage now resolve the equipped weapon's style view for hit responses and future juggling configuration, matching SP behavior. Native primary damage remains native and is never replayed. Music/UI preferences remain local; CVF retains its own network policy. Grabs remain disabled.

The audit validates offline client/server command paths and native resource selection. It does not replace a real two-client test for network latency, native zombie ownership migration, corpse/death timing or GPU appearance. PZ was not started.

## Directional lights and taunt attention (0.57.0)

Directional lights use the normal native swing serial, isolated catalogued clips and supplemental hit limits; real weapon profiles cannot select DoD's unarmed directional map. Taunt attention is authorized from an observed timed-action lease and a fresh completion counter, then server-selected zombie IDs are relayed to their native AI owners. Per-completion/per-target deduplication, player sessions, path/range/eligibility limits and a 750 ms streaming retry bound apply. See DIRECTIONAL_AND_TAUNTS.md. Observer count is now 316 across both repeat cycles.

## Scripted sound variety (0.58.0)

Styles can opt in with `soundVariety=true` and register existing multi-clip sound pools with `ProjectYakuza.SoundVariety.registerPool(name, count)` in shared code. Scripted Feedback uses shuffled native clips with original parent volumes and validated MP relays. See [Sound variety](SOUND_VARIETY.md) for configuration, heavy/counter sound slots, limits and lifecycle.

## Paired Heat Rush and QTEs (0.59.0)

DoD uses source-order connected-light proof, a single actor/target lease, validated source-time input windows and canonical server-calculated QTE damage. Completed/expired/disconnected sequences restore victim flags. Wrong serials, replayed hits and stale/late pose messages cannot restart or repeat them. Observers are event-free. See [rush details](EXTREME_ATTACKS.md) and [QTE authoring](QTE.md).

## Optional Heat attack speed (0.61.0)

Addon styles can opt in with heatAttackSpeed={max=1.25,power=1,useExtremeFuel=false}, with per-weapon overrides. The curve is sampled per committed attack, applies to the existing native speed variables and is bounded/replicated in MP snapshots. Fixed-speed timed clips are not automatically retimed. Dragon of Dojima does not enable this feature. See [Heat-based attack speed](HEAT_ATTACK_SPEED.md) for validation, timing and authoring contracts.
