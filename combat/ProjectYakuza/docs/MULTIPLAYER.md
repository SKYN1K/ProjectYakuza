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
| Counter | Local 0.2-second window plus server target/state/range/60-second cooldown; no rewind guarantee |
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
