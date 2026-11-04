# Add a new move type

Reuse a kind when its controller protocol fits; register a namespaced kind for a different mechanic. Declare it in shared code before style registration:

```lua
require "ProjectYakuza/Registry"
ProjectYakuza.registerActionKind("my_mod.charge")

```

Client code registers a style-specific handler. Required start(context) queues native playback and returns true only when accepted; optional canStart is side-effect free, update handles watchdog/release polling, and cancel restores all owned effects idempotently. The complete [starter flourish](../templates/StyleSubmod/42/media/lua/client/ExampleStyle_Flourish.lua.example) shows this with an existing clip, custom binding and no damage/heat/protection.

## Lifecycle contract

1. requestAction validates equipment, idle state, slot/variant, target descriptors, combo branch and heat; canStart may return false,reason.
2. start queues the action. Only after true returns does the registry publish ownership, spend cost and emit actionStarted. Do not complete or recursively request another move synchronously inside start.
3. Native playback owns the actual animation. Set context.timedAction.started=true when it really starts; MP actions capture needs it and matching PerformingAction variables.
4. Custom update(context) runs through existing local-player Runtime updates. Normal combo/finisher/running/defense routing is consumed; style input callbacks still handle release/cancel. The completion update is also consumed to avoid leaking a held light.
5. On success, restore overrides then completeAction(player,context). On interruption use cancelAction(player,reason,context). The registry clears ownership before invoking the captured cancel handler. Completion does not invoke cancel cleanup.

New kinds block native attacks by default; the framework attemptAttack helper respects this. blocksAttacks=false is an advanced path for native attack controllers: ordinary combo classification remains suppressed. You must integrate swing/end events, damage modifiers, heat, multihit and voices deliberately. A visual timed action is not damaging merely because its clip looks like a punch.

## Cleanup

Runtime cancels custom ownership on unequip/death, hit reaction and save/menu exit. Update exceptions cancel with update_failed; failed starts call cleanup without spending configured cost. The handler must stop its native queue entry and restore only movement, AI, hand-model or animator flags it owns. Capture original values and use a cleaned guard. Pass the original context to async complete/cancel so old callbacks cannot terminate a newer move.

Native isValid/update should check floor, knockdown, vehicle, climb, target and action state as appropriate. Paused custom updates are skipped; wall-clock timers in native actions must exclude paused time. Require actual Start/End markers for success, with duration only a watchdog. Missing clips must fail without rewards/hits. Never grant protection merely because a move has an animation.

Use a namespaced Bindings.register control and poll it once in the style input handler. Start requests only when eligible; target arguments remain untrusted descriptors until validated. Existing built-in handler overrides must retain their context/marker protocol and do not get the custom update dispatcher automatically.

## Damage and MP

Native strikes use exactly one AttackCollisionCheck=MeleeSwing at contact. Do not add another health-subtraction timer. Observer registration replicates presentation, not damage, force or paired target ownership. New grabs/throws/heat actions need server checks for eligibility, range, facing, obstructions, costs/cooldowns, serial deduplication, ownership leases and disconnect cleanup. Unarmed grabs and wall Heat Actions use the validated ownership protocol in [Grabs](GRABS.md). Cinematic cameras/direct ragdoll force are outside this Lua API.

## Built-in charged heavy (API 3)

Use `heavyCharge` for a stationary native hold and `chargedHeavy` for its one-use native strike handover when that protocol fits. These built-in kinds have dedicated input/cleanup/swing handling; use a namespaced custom kind for a different mechanic. See [Charged heavy](CHARGED_HEAVY.md).

## Attack endurance (0.60.0)

Styles can opt in with exertion={}, weapon profiles can override that table, and individual moves can provide enduranceCost. Actual attacks publish attackCommitted once; the local owner applies native fitness/trait scaling and reports attackEnduranceSpent. Hits, remote playback, charge holds and queue requests do not charge again. See [Exertion](EXERTION.md) for defaults, validation, custom actions and lifecycle.


## Heat Action protection (0.70.0)

Shared `HeatActions.begin(player,ownerKey,definition)` and `HeatActions.finish(player,ownerKey)` manage action-only invulnerability and a default 500 ms targeting grace. Call them from actual native start and every cleanup path, including the authoritative server handler. See [Heat Actions](HEAT_ACTIONS.md) for ownership, watchdog/pause behavior, stock/fuel costs and paired contact contracts.
