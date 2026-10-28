# Lua API 3 reference

Require `ProjectYakuza/Registry` for shared definitions, `ProjectYakuza/Runtime` for client gameplay, `ProjectYakuza/Bindings` for controls, and `ProjectYakuza/NetworkExtensions` for addon observer registration. Do not require client UI from server/shared definitions.

## Style fields

`validateStyle(definition)` returns valid,errors. `registerStyle` validates, stores defaults and emits styleRegistered. Register once before play. Reusing an ID replaces that definition: use a unique namespace and treat definitions as configuration, not per-player state.

| Field | Contract/default |
| --- | --- |
| id/name | Required unique ID/readable name; none is reserved |
| description/selectorIcon | Optional text/existing texture path |
| ui | Optional heat/status/selector/selectorSlot/setup -> client provider ID or false; omitted channels retain default presentation. See [UI API](STYLE_UI.md). |
| lightAttacks | Required nonempty ordered move array |
| attackSpeed | Native ProjectYakuzaCombatSpeed; default 1 |
| runningKneeSpeed | Separate built-in knee speed; otherwise attackSpeed |
| comboResetMs/lightBufferLimit | Continuation milliseconds/default 750; pending lights/default 1 |
| groundAttacks | Optional nonempty floor-strike array |
| actions | Kind -> slot/variants map; default empty |
| heat | Shared heat opt-in; otherwise off |
| heatHud/heatAura/hitEffects | Explicit supplied profiles; see presentation |
| enemyReactions/tigerDrop | Reaction/counter opt-ins; need matching move/controller definitions |
| music/sounds | Per-style playlist/cue map; omitted/false adds no profile |
| combatVoices | CVF enabled unless false; missing recordings stay silent |
| combatVoiceVolume/quickstepVoices | Voice mix/default 1; movement-step voice enabled unless false |

## Move and action fields

| Field | Contract |
| --- | --- |
| enabled | Parent action slot must be true; variant enabled unless explicitly false |
| animation | Playable native clip/action-animation name; does not generate XML |
| nodeValue | Required for lights/ground/native strikes; matches move variable/markers |
| duration | Positive seconds after configured XML speed; Extreme Heat adds its own factor |
| speed | Positive controller/link metadata; XML still controls actual playback |
| impact/chainAt | Normalized 0..1 fractions mirroring XML; not independent hit timers |
| damageMultiplier | Nonnegative native base-damage multiplier; default 1 |
| afterLight/double | Finisher branch index / matching second-finisher flag |
| doubleLinkFrame/doubleLinkEndFrame | Source-frame handoff window matching XML |
| fullBody/groundAttack/runningAttack/quickstepAttack | Existing controller flags; not automatic node generation |
| reaction | Existing victim-reaction mapping ID |
| direction/distance | Directional variant / collision-checked travel in tiles |
| heatStocks/heatCost | Accepted-start cost: stocks take precedence over raw points |
| requiresTarget/targetAnimation | Target/paired-clip descriptors; handler validates synchronization |
| variants | Kind slot's move map; request variant defaults to default |

Parent quickstep.cooldownMs, runningAttack.runupMs, block.staminaPerHit and parry timing fields belong to their specific controller. Put costs on each spending variant; parent costs are not inherited. Custom fields are available to your handler. Validation cannot prove native asset existence or gameplay correctness.

Built-in kinds: finisher, grab, parry, block, quickstep, quickstepAttack, runningAttack, heatAction, heatActivation, taunt, styleEntry. Grab is temporarily disabled; heatAction has no cinematic handler.

## Selection and lookup

| Function | Purpose |
| --- | --- |
| getStyle(id)/listStyles() | Definition or nil / fresh menu descriptors |
| getPlayerStyle(player) | Selected registered style; default DoD |
| selectStyle(player,id) | ok,reason; selection only; busy/unknown rejected; none disables |
| equipStyle(player,id) | Client helper: select, provision token, optional entry |
| isEquipped/isBusy(player) | Recognized token/style (MP acknowledged) / combo or action ownership |
| StyleSlots.get/id/assign | Persisted left/right assignments; see selector guide |

Token: ProjectYakuza.StyleToken. Do not mint client-only tokens in MP. Use namespaced modData for your persistence; combo/action contexts are transient.

## Custom kinds and lifecycle

`registerActionKind("my_mod.charge",{blocksAttacks=true})` declares a kind; options are optional and default to native attack blocking. All custom kinds consume ordinary framework combat routing while active. False permits a specialized native attack implementation to own its native events; it does not create an attack. Built-in policies cannot be changed this way. Duplicate kind declarations must agree.

`registerStyleActionHandler(styleId,kind,handler)` overrides only that style; `registerActionHandler(kind,handler)` sets a fallback. Required start(context); optional canStart(context), update(context), cancel(context,reason). Automatic update is for custom kinds only; built-in controllers own their protocol.

`requestAction(player,kind,variant,target)` returns ok,reason after equipment/idle/slot/target/cost/branch/readiness validation. Context fields: player,style,kind,variant,action,target,comboStep,handler. You may add transient fields. Accepted starts publish ownership, spend configured heat and emit actionStarted. Failed starts invoke cancel cleanup without spending cost.

`completeAction(player,expectedContext)` clears matching ownership/emits completion, but does not call cancel cleanup. `cancelAction(player,reason,expectedContext)` clears it, calls the captured cancel handler and emits cancellation. Optional expectedContext prevents a stale timer ending a newer move. Full rules: [Actions](ACTIONS.md).

Failures include unknown_action, style_not_equipped, busy, not_implemented, unknown_variant, missing_animation, target_required, missing_target_animation, missing_handler, insufficient_heat, wrong_combo_step, combo_window_closed, handler_error and handler-specific reasons. Grab returns temporarily_disabled. A nonexistent nonempty animation string requires native playback checks to detect.

## Controls

`registerStyleInputHandler(styleId,fn)` installs one client callback fn(player,input). Input has aiming,lightDown,heavyPressed,heavyDown using current light/finisher bindings. True consumes the update. It also runs during custom ownership for release/cancellation, but not the built-in style-entry lock. It does not itself intercept vanilla key callbacks.

`Bindings.register({id="my_mod.extra",name="Extra move",mode=4,code=0})` adds a persisted control, including late registration after options exist. Mode 1=LMB, 2=RMB, 3=MMB, 4=keyboard. key may name a Keyboard constant; code=0 starts unbound. IDs cannot replace existing controls. down(id), pressed(player,id), matches(id,key), label(id), mode(id), key(id) read it. Poll pressed once per player/update in its owner. Native aim/movement stay PZ binds; avoid vanilla conflicts or explicitly intercept only your owned gesture.

## Events

`on(name,fn)` returns the listener; `off(name,fn)` removes it. Errors are isolated/logged. Events are local notifications, not authority commands. Some result events also fire on observers: check style ID/local ownership and never apply damage once per observer.

| Event | Arguments |
| --- | --- |
| styleRegistered / styleChanged / styleSlotChanged | (style)/(player,id)/(player,side,id) |
| lightAttackStarted / lightAttackFinished | (player,style,step,move)/(player,step) |
| finisherStarted / finisherFinished | (player,style,step,move)/(player,step,move) |
| groundAttackStarted / groundAttackFinished | (player,style,move)/(player,move) |
| runningAttackStarted / runningAttackFinished | (player,style,move)/(player,move) |
| quickstepAttackStarted / quickstepAttackFinished | (player,style,move)/(player,move) |
| comboCancelled / comboExpired | (player,reason)/(player) |
| combatHit | (attacker,victim,weapon,damage,step); native/results contact, not hit request |
| actionStarted / actionCompleted / actionCancelled | (context)/(context)/(context,reason) |
| heatChanged / extremeHeatStarted / extremeHeatEnded | (player,amount)/(player,fuel)/(player,reason) |
| styleEntryStarted / styleEntryStopped | (player,style)/(player,completed) |
| tauntStarted / tauntStopped | (player)/(player,completed) |
| heatActivationStarted / heatActivationFlare / heatActivationStopped | (player)/(player)/(player,completed) |
| guardHit / guardBroken / tigerDrop | (player,zombie)/(player)/(player,zombie) |
| grabHeld / throwStarted / throwHit | (player,zombie); dormant while grab disabled |

## Network catalog

After requiring NetworkExtensions and registering the style, `registerNetworkAnimations(styleId,entries)` returns added count. Each entry requires id,animation,group,priority,loop,conditions={{name,value}} describing the owner node. Groups: melee/stomp/actions. IDs are globally unique; batches validate before publication, copy caller data and priority-sort the merged catalog. Requiring the registration module once is sufficient. This registers presentation only: see [Multiplayer](MULTIPLAYER.md).

Built-in quickstep strikes use a single-use handover ticket. Native attack input is gated while the strike owns the player; the first asynchronous native swing is still classified normally. Replaying a consumed ticket or mismatching its direction is rejected. Follow the built-in controller protocol rather than creating/reusing tickets from an addon.

## API 3 additions

Client `ProjectYakuza/StyleUI`: `registerStyleUI(id,provider)`, `unregisterStyleUI(id)`. Style `ui` validates heat/status/selector/selectorSlot/setup keys and provider strings or false. A provider has required render and optional create/update/destroy callbacks. See [complete UI contract](STYLE_UI.md). API 1/2 definitions remain valid.

Built-in action kinds `heavyCharge` and `chargedHeavy` use the native timed-action hold and single-use native-strike handover. Events: `heavyChargeStarted(player,style,move)`, `heavyChargeStopped(player,completed)`, `chargedHeavyStarted(player,style,move)`, `chargedHeavyFinished(player,move)`. Callbacks are local presentation/lifecycle hooks, not permission to apply damage again. See [charged heavy](CHARGED_HEAVY.md).

Charged first-finisher variants opt into `chargeBranch=<light index>` on both hold/release and `chargedFinisher=true` on release. Slot variants use default/after_1â€¦after_n. Native release tickets bind the variant/branch; second-finisher windows bypass charging. `heavyChargeStarted` receives the selected move; custom HUD code can inspect `context.action.chargeBranch` or `combo.finisherMove.chargedFinisher`. See [charged heavy](CHARGED_HEAVY.md).

Charge controller additions: optional holdAnimation, windupMs and maxHoldMs; maxHoldMs=0 disables timed auto-release. A looping hold acknowledges ProjectYakuzaChargeClip=holding. heavyChargeReady(player,style,move) fires once at the minimum wind-up endpoint for cosmetic feedback. Missing native holds cancel safely. See [charged heavy](CHARGED_HEAVY.md).

## Charge power (0.36.0)

Charged moves may set `minChargedDamageMultiplier` (0..damageMultiplier). DoD heavyCharge variants set `maxHoldMs=1200`; `minChargeMs` defines the low-power pose threshold. The controller normalizes elapsed unpaused action time between those thresholds, automatically releases at the maximum, and copies the runtime move before scaling it. `ProjectYakuza.ChargeRules.power(ageMs,minMs,maxMs)` and `.damage(move,fraction)` implement the shared rule. `heavyChargeReady` now marks full power. Optional MP state `chargePower` is validated 0..1 and locked per multihit swing. See [Charged heavy](CHARGED_HEAVY.md).

## Charge recovery and world anchors (0.37.0)

`ChargedHeavy.wantsRecovery(player,combo,style)` reports a ready held first-finisher charge intent; Runtime still requires the existing hit/chain markers before ending recovery. `heavyChargeStarted` adds an optional fourth context argument for presentation before action registry publication. Existing listener arguments are unchanged. `WorldEffects.renderCentered` accepts optional relative world anchor XYZ after color, compensating their projection to retain the requested screen centre; limb effects use them for native depth. Omitted anchors preserve existing callers. `attackEffects.verticalOffset` is an optional per-move downwards offset in sprite-pixel units.

### 0.38.0 presentation refinement

AttackEffects.facing(player) combines getAnimAngleRadians with math.rad(getShoulderTwist()) for the punch prototype. Its project helper remains the unchanged native body-space projection used by charge effects. No Java bridge is required. HeatAura completion echoes now last 750ms, reuse the normal aura animation and replace the ordinary body pass to avoid stacking brightness.
