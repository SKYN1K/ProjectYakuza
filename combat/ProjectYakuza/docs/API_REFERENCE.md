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
| impactFeedback | Optional `unarmed`, `blunt`, `blade` visual preset; weapon profiles inherit or override, `false` retains legacy visuals |
| enemyReactions/tigerDrop | Reaction/counter opt-ins; need matching move/controller definitions |
| music/sounds | Per-style playlist/cue map; omitted/false adds no profile |
| combatVoices | CVF enabled unless false; missing recordings stay silent |
| combatVoiceVolume/combatVoiceGains | Optional overall multiplier and line-ID-to-gain map; nonnegative, default 1 per missing cue. Both compose with the Voices slider. |
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
| heatStocks/heatCost | Stocks take precedence over raw points; paired Heat Actions pay at confirmed playback, other kinds at accepted start |
| requiresTarget/targetAnimation | Target/paired-clip descriptors; handler validates synchronization |
| variants | Kind slot's move map; request variant defaults to default |

Parent quickstep.cooldownMs, runningAttack.runupMs, block.staminaPerHit and parry timing fields belong to their specific controller. Put costs on each spending variant; parent costs are not inherited. Custom fields are available to your handler. Validation cannot prove native asset existence or gameplay correctness.

Built-in kinds: finisher, grab, grabHeat, groundHeat, parry, block, quickstep, quickstepAttack, runningAttack, heatAction, heatActivation, taunt, styleEntry. DoD supplies paired Heat Actions; grabHeat uses the shared held-target wall handler. See [Grabs](GRABS.md).

## Selection and lookup

| Function | Purpose |
| --- | --- |
| getStyle(id)/listStyles() | Definition or nil / fresh menu descriptors |
| getPlayerStyle(player) | Selected registered style; default DoD |
| selectStyle(player,id,feedback) | ok,reason; selection only; busy/unknown rejected; none disables; optional false feedback suppresses selection audio while retaining lifecycle events |
| equipStyle(player,id) | Client helper: select, provision token, optional entry |
| isEquipped/isBusy(player) | Recognized token/style (MP acknowledged) / combo or action ownership |
| StyleSlots.get/id/assign | Persisted left/right assignments; see selector guide |

Token: ProjectYakuza.StyleToken. Do not mint client-only tokens in MP. Use namespaced modData for your persistence; combo/action contexts are transient.

## Custom kinds and lifecycle

`registerActionKind("my_mod.charge",{blocksAttacks=true})` declares a kind; options are optional and default to native attack blocking. All custom kinds consume ordinary framework combat routing while active. False permits a specialized native attack implementation to own its native events; it does not create an attack. Built-in policies cannot be changed this way. Duplicate kind declarations must agree.

`registerStyleActionHandler(styleId,kind,handler)` overrides only that style; `registerActionHandler(kind,handler)` sets a fallback. Required start(context); optional canStart(context), update(context), cancel(context,reason). Automatic update is for custom kinds only; built-in controllers own their protocol.

`requestAction(player,kind,variant,target)` returns ok,reason after equipment/idle/slot/target/cost/branch/readiness validation. Context fields: player,style,kind,variant,action,target,comboStep,handler. You may add transient fields. Accepted starts publish ownership and emit actionStarted. Custom and ordinary action kinds spend configured Heat at acceptance. Built-in paired heatAction/groundHeat/grabHeat defer payment until the first confirmed native playback sample; their controller calls payActionHeat(context), which rechecks the selected resource and cannot debit twice. Failed starts invoke cancel cleanup without spending cost. A paired startup that never reaches playback also spends nothing; cancellation after payment does not refund it.

`completeAction(player,expectedContext)` clears matching ownership/emits completion, but does not call cancel cleanup. `cancelAction(player,reason,expectedContext)` clears it, calls the captured cancel handler and emits cancellation. Optional expectedContext prevents a stale timer ending a newer move. Full rules: [Actions](ACTIONS.md).

Failures include unknown_action, style_not_equipped, busy, not_implemented, unknown_variant, missing_animation, target_required, missing_target_animation, missing_handler, insufficient_heat, wrong_combo_step, combo_window_closed, handler_error and handler-specific reasons. Disabled per-style grab definitions are rejected. A nonexistent nonempty animation string requires native playback checks to detect.

## Controls

`registerStyleInputHandler(styleId,fn)` installs one client callback fn(player,input). Input has aiming,lightDown,heavyPressed,heavyDown using current light/finisher bindings. True consumes the update. It also runs during custom ownership for release/cancellation, but not the built-in style-entry lock. It does not itself intercept vanilla key callbacks.

`Bindings.register({id="my_mod.extra",name="Extra move",mode=4,code=0})` adds a persisted control, including late registration after options exist. Mode 1=LMB, 2=RMB, 3=MMB, 4=keyboard. key may name a Keyboard constant; code=0 starts unbound. IDs cannot replace existing controls. down(id), pressed(player,id), matches(id,key), label(id), mode(id), key(id) read it. Poll pressed once per player/update in its owner. Native aim/movement stay PZ binds; avoid vanilla conflicts or explicitly intercept only your owned gesture.

## Events

`on(name,fn)` returns the listener; `off(name,fn)` removes it. Errors are isolated/logged. Events are local notifications, not authority commands. Some result events also fire on observers: check style ID/local ownership and never apply damage once per observer.

| Event | Arguments |
| --- | --- |
| styleRegistered / styleChanged / styleSlotChanged | (style)/(player,id,feedback)/(player,side,id) |
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
| grabHeld / throwStarted / throwHit | (player,zombie); emitted by the paired grab/throw controller |

## Network catalog

After requiring NetworkExtensions and registering the style, `registerNetworkAnimations(styleId,entries)` returns added count. Each entry requires id,animation,group,priority,loop,conditions={{name,value}} describing the owner node. Groups: melee/stomp/actions. IDs are globally unique; batches validate before publication, copy caller data and priority-sort the merged catalog. Requiring the registration module once is sufficient. This registers presentation only: see [Multiplayer](MULTIPLAYER.md).

Built-in quickstep strikes use a single-use handover ticket. Native attack input is gated while the strike owns the player; the first asynchronous native swing is still classified normally. Replaying a consumed ticket or mismatching its direction is rejected. Follow the built-in controller protocol rather than creating/reusing tickets from an addon.

## API 3 additions

Client `ProjectYakuza/StyleUI`: `registerStyleUI(id,provider)`, `unregisterStyleUI(id)`. Style `ui` validates heat/status/selector/selectorSlot/setup keys and provider strings or false. A provider has required render and optional create/update/destroy callbacks. See [complete UI contract](STYLE_UI.md). API 1/2 definitions remain valid.

Built-in action kinds `heavyCharge` and `chargedHeavy` use the native timed-action hold and single-use native-strike handover. Events: `heavyChargeStarted(player,style,move)`, `heavyChargeStopped(player,completed)`, `chargedHeavyStarted(player,style,move)`, `chargedHeavyFinished(player,move)`. Callbacks are local presentation/lifecycle hooks, not permission to apply damage again. See [charged heavy](CHARGED_HEAVY.md).

Charged first-finisher variants opt into `chargeBranch=<light index>` on both hold/release and `chargedFinisher=true` on release. Slot variants use default/after_1ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦after_n. Native release tickets bind the variant/branch; second-finisher windows bypass charging. `heavyChargeStarted` receives the selected move; custom HUD code can inspect `context.action.chargeBranch` or `combo.finisherMove.chargedFinisher`. See [charged heavy](CHARGED_HEAVY.md).

Charge controller additions: optional holdAnimation, windupMs and maxHoldMs; maxHoldMs=0 disables timed auto-release. A looping hold acknowledges ProjectYakuzaChargeClip=holding. heavyChargeReady(player,style,move) fires once at the minimum wind-up endpoint for cosmetic feedback. Missing native holds cancel safely. See [charged heavy](CHARGED_HEAVY.md).

## Charge power (0.36.0)

Charged moves may set `minChargedDamageMultiplier` (0..damageMultiplier). DoD heavyCharge variants set `maxHoldMs=1200`; `minChargeMs` defines the low-power pose threshold. The controller normalizes elapsed unpaused action time between those thresholds, automatically releases at the maximum, and copies the runtime move before scaling it. `ProjectYakuza.ChargeRules.power(ageMs,minMs,maxMs)` and `.damage(move,fraction)` implement the shared rule. `heavyChargeReady` now marks full power. Optional MP state `chargePower` is validated 0..1 and locked per multihit swing. See [Charged heavy](CHARGED_HEAVY.md).

## Charge recovery and world anchors (0.37.0)

`ChargedHeavy.wantsRecovery(player,combo,style)` reports a ready held first-finisher charge intent; Runtime still requires the existing hit/chain markers before ending recovery. `heavyChargeStarted` adds an optional fourth context argument for presentation before action registry publication. Existing listener arguments are unchanged. `WorldEffects.renderCentered` accepts optional relative world anchor XYZ after color, compensating their projection to retain the requested screen centre; limb effects use them for native depth. Omitted anchors preserve existing callers. Punch coating uses absolute world coordinates without a fixed screen inset.

### 0.38.0 presentation refinement

AttackEffects.facing(player) reads the continuous rendered getAnimAngleRadians value without an additional shoulder-twist rotation. Its project helper remains the unchanged native body-space projection used by charge effects. No Java bridge is required. HeatAura completion bursts last 450 ms and use existing animated Y6 flame/smoke clouds with a restrained world-space fade. Style entry uses a separate 380 ms cloud layout and activation uses a one-second layout. Each burst has three fire and three smoke instances, with normal-heat blue or Extreme Heat purple-blue tint. Regular heat-aura assets are preserved.

### 0.39.0 approved taunt colour copies

The TauntAura_a/b/c sequences are colour-only copies of the existing HeatWisp sequences. RGB is rounded 75% source plus 25% white; alpha, dimensions and frame order are identical. drawTaunt fades the colour toward the original blue at either end using a multiplicative tint, independently of the existing size/opacity envelope. Normal and Extreme Heat source assets are unchanged. See taunt-aura-assets.json for hashes and the explicit authorization.

## Move-specific hit responses (0.40.0)

Optional style.hitResponses defines named flinch/stagger/knockdown profiles with finite force 0..1.5 and optional full-charge threshold/response. Moves may select a profile with hitResponse="name" or opt out with false. Defaults distinguish lights, first/double finishers and charged heavies. Ground attacks are excluded. Styles without profiles keep their existing behavior. See [Hit responses](HIT_RESPONSES.md) for fields, native timing, MP ownership and limits.

## Future-style juggling (0.41.0)

Optional style.juggling and move.juggle={kind="launch"/"followup"/"ender"} enable bounded launcher/followup windows, hit/relaunch caps, landing cooldown, victim animation variables and start/hit/end events. No airborne assets or physical lift are supplied by the core. SP/server confirmed hits drive the state; optional result metadata and ordered end packets mirror it in MP. DoD remains unconfigured. See [Juggling](JUGGLING.md) for limits, presentation ownership, cancellation and examples.

AttackEffects.registerLimbProvider(id,fn) optionally consumes forearm/hand and optional shoulder world positions from a compatible external adapter; removeLimbProvider(id,fn) unregisters it. No adapter is bundled. See [punch effects](ATTACK_EFFECTS.md). HeatAura now uses the native ColorInfo:set method rather than Lua field writes.

## Light quickstep cancels (0.44.0)

While aiming, the bound quickstep input can cancel DoD lights after their native post-hit cancel marker. It has a 150ms input buffer and a 400ms native handoff timeout; quota/cooldown/wall checks are preserved. Other move types are unchanged. Future styles opt in with quickstepCancelLights=true and eligible light.quickstepCancelAt plus the matching native marker. See [Light quickstep cancels](LIGHT_QUICKSTEP_CANCELS.md).

## Weapon equipment views

See [Weapons](WEAPONS.md) for Weapons.register, explicit per-style item mappings, equipment views, standalone heavies, native weapon preservation, events and MP authoring contracts. getPlayerStyle returns the current view while getStyle/listStyles retain the base style identity. Register profiles after the base style; every distinct move needs a unique nodeValue and supplied animation nodes.

Since 0.45.0, Weapons.hitRange(item) bounds registered weapon supplementary reach to its native maximum (framework .25Ã¢â‚¬â€œ1.65 bounds); Weapons.extraDamage(item,damage) bounds SP supplementary damage to the current native maximum and 20, avoiding propagation of primary-only close kills. Native primary hit calculation is unchanged. See [weapon rules](WEAPONS.md#sharp-weapons-0450).

Registration-aware internal indexes now accelerate clip and move resolution. Register configuration through the documented APIs and treat published nested tables as immutable. Re-registering a style refreshes its move index; registerNetworkAnimations publishes a fresh catalogue/selector index. See [maintenance notes](PERFORMANCE.md).

## Temporary style equipment (0.47.0)

`ProjectYakuza.equipStyle(player,id,playEntry)` retains a supported real weapon or equips the temporary style item. Optional `playEntry=false` suppresses the entry on automatic return from a real weapon. `ProjectYakuza.unequipStyle(player)` returns `(ok,reason)`, refuses a busy switch, disables the style, removes its temporary items and retains real equipment. Manual token unequip triggers the same disable/removal once native timed equipment changes settle. Multiplayer inventory deletion is server-owned.

`ProjectYakuza.StyleItem` implements token-only cleanliness, protected normal inventory actions and lifecycle tracking. Other item types are unaffected. A finisher variant with `neutralHeavy=true` is eligible as `variants.default` when no combo/follow-up exists; it does not open a double-finisher branch. Styles without that opt-in keep their existing routing.

## Blood presentation (0.48.0)

A style opts into supplied Y6 blood via `bloodEffects="yakuza6"`; the built-in confirmed-hit pipeline also requires `hitEffects="yakuza6"`. `ProjectYakuza.BloodEffects.spawn(player,victim,strong,charged)` creates a bounded client world burst; `clear(player)` releases that playerÃ¢â‚¬â„¢s bursts, or all bursts when omitted. Existing hit-effect preferences apply. Other styles have no default blood opt-in. See [Blood effects](BLOOD_EFFECTS.md) for source provenance, lifecycle and limits.

## Extreme finisher variants (0.49.0)

Unarmed finisher routing recognizes enabled `extreme_default`, `extreme_after_N` and `extreme_double_after_N` variants while Heat is active. Define `extremeHeat=true` on those moves, retain ordinary move contracts and register their isolated native nodes/observers. First finishers latch mode for their paired double; the existing afterLight/window checks remain. Ordinary variants are the fallback. Standalone weapon heavies remain owned by their weapon profile. See [Extreme attacks](EXTREME_ATTACKS.md).

## Style-owned encounter intros (0.50.0)

`style.encounterIntro` configures enabled/radius/durationMs/quietMs/pollMs/titles and optional soundKey/soundVolume. `style.ui.encounter` names a `registerStyleUI` provider; no provider or style is inherited automatically. The client `ProjectYakuza.EncounterIntro` API exposes request, clear, title, layoutText and drawText; lifecycle events are encounterIntroStarted, encounterIntroEnded and encounterEnded. Counts are local, batched and capped by the configured highest tier. [Complete contract and examples](ENCOUNTER_INTROS.md).

## Encounter detector extensions (0.54.0)

registerEncounterDetector(id,fn) and unregisterEncounterDetector(id,fn) manage namespaced, per-style opt-in detection callbacks. See ENCOUNTER_INTROS.md for trigger fields, minimum counts, no-count/player intros, target context, text fitting, custom effects and failure/rejection events. Defaults retain existing zombie-only behavior.

## Extreme Heat rush and reusable QTEs (0.59.0)

extremeLightAttacks supports 1..16 independently sized moves, with finisherBranches mapping extended chains to authored branches. The removed automatic-contact modules/action kind are no longer registered. DoD now uses a paired heatAction with source paths, validated QTE inputs and a style-scoped handler. ProjectYakuza.QTE exposes valid, create, window, update and cancel, plus qtePrompt, qteInput, qteResult, qteFinished and qteCancelled events. See [QTE API](QTE.md), [rush contracts](EXTREME_ATTACKS.md) and [directional finishers](DIRECTIONAL_AND_TAUNTS.md).

## Directional light routing and taunt attention (0.57.0)

Styles can opt into `directionalAttacks` and `tauntReactions`. Runtime latches a manual-turn light replacement and ends the chain; native primary/supplemental hit paths and quickstep budgets remain in force. Taunt attention uses completion-only native AI with server authorization and zombie-owning client replay. See [configuration, limits, supplied motion and MP contracts](DIRECTIONAL_AND_TAUNTS.md).

## Scripted sound variety (0.58.0)

Styles can opt in with `soundVariety=true` and register existing multi-clip sound pools with `ProjectYakuza.SoundVariety.registerPool(name, count)` in shared code. Scripted Feedback uses shuffled native clips with original parent volumes and validated MP relays. See [Sound variety](SOUND_VARIETY.md) for configuration, heavy/counter sound slots, limits and lifecycle.

## Attack endurance (0.60.0)

Styles can opt in with exertion={}, weapon profiles can override that table, and individual moves can provide enduranceCost. Actual attacks publish attackCommitted once; the local owner applies native fitness/trait scaling and reports attackEnduranceSpent. Hits, remote playback, charge holds and queue requests do not charge again. See [Exertion](EXERTION.md) for defaults, validation, custom actions and lifecycle.

## Optional Heat attack speed (0.61.0)

Addon styles can opt in with heatAttackSpeed={max=1.25,power=1,useExtremeFuel=false}, with per-weapon overrides. The curve is sampled per committed attack, applies to the existing native speed variables and is bounded/replicated in MP snapshots. Fixed-speed timed clips are not automatically retimed. Dragon of Dojima does not enable this feature. See [Heat-based attack speed](HEAT_ATTACK_SPEED.md) for validation, timing and authoring contracts.

## Weapon-specific feedback (0.62.0)

See [Weapons](WEAPONS.md) for `impactFeedback`, profile cue maps, native weapon audio, heavy/ground accent deduplication and style isolation. `HitEffects.spawn(player,victim,strong,charged,guard,feedback)` accepts an optional final preset for authoritative observer playback; omitted values use the current style view. `BloodEffects.spawn(player,victim,strong,charged,feedback)` accepts the same optional family, captures size/timing on creation and preserves the existing burst budgets. Callers supplying `false` select legacy visuals. These are client presentation APIs and never apply damage.

## Network definition lookups (0.63.0)

`NetworkProtocol.supports(styleView,clipEntry)` checks whether the registered equipment view supports a native animation or enabled action contract. `NetworkProtocol.kind(styleId,clipId)` retains its kind/move metadata result, including disabled definitions. The per-definition index is invalidated by official style registration or replacement of its move/action collections. Keep registered nested tables immutable during play and re-register changes. This cache does not bypass per-hit range/path/ownership/replay validation. See [Performance](PERFORMANCE.md).

## Per-style Heat rules (0.64.0)

Optional `heatConfig` sets per-style gain, normal/Extreme drain and 1..32 stock capacity. Weapon profiles inherit and merge field overrides. Taunt rewards, stock-priced actions, the built-in orb row, custom UI context and server activation protection use the effective capacity. Omitted configuration leaves DoD unchanged. See [Heat configuration](HEAT_CONFIGURATION.md) for bounds, defaults, APIs, stock retention and network requirements.


Version 0.66.0 expands the style-owned attack coating to all active DoD attack clips, including weapon profiles and finisher contacts. Existing source motion and game textures are reused. Contact-specific arm/leg tracks, bounded irregular movement and observer reconstruction use the existing animation phase and protocol; no additional particle packets are sent. Explicit move configuration takes priority and other styles remain opt-in. See [Attack effects](ATTACK_EFFECTS.md).


## In-place hit stun and native knockback control (0.68.0)

A hit-response profile can use `kind="stun",force=0`. It freezes zombie AI/root movement for 250 ms without a stagger-back force; repeated hits refresh the same lease. Original useless/ignore/deferred-movement flags are restored at expiry or world exit. `HitResponses.releaseStun(victim)` releases a lease before another paired controller takes ownership. Nonzero stun force is rejected.

A move can opt into boolean `noKnockback=true`. The Heat controller temporarily zeros the weapon's push/knockdown modifiers and disables native knockback/always-knockdown for that swing. Original values, including false booleans, restore on completion, interruption or saved-item preparation. `HitResponses.nativeHit(attacker,victim,item,amount,move)` applies the same scoped override around an authoritative supplemental native Hit and restores it even if Hit fails. It returns success,result; callers still own target/range/permission validation.


## Heat Action protection (0.70.0)

Shared `HeatActions.begin(player,ownerKey,definition)` and `HeatActions.finish(player,ownerKey)` manage action-only invulnerability and a default 500 ms targeting grace. Call them from actual native start and every cleanup path, including the authoritative server handler. See [Heat Actions](HEAT_ACTIONS.md) for ownership, watchdog/pause behavior, stock/fuel costs and paired contact contracts.

## QTE failure policy (0.73.0)

QTE definitions support per-prompt timing/bindings plus `failureLimit`, `failureMode` and `feedback`. Sessions expose total/consecutive misses, failure identity and accepted input times. `qteFailed` and callback `failure` select author-supplied failure endings. Client `QTEFeedback` plays original local Y6 prompt/press/failure cues; optional `prompt`, `success`, `miss` and `failure` keys override individual cues with style sounds. DoD's paired backend supports `qteFailure` and deferred final health settlement while preserving native victim playback. See [QTE API](QTE.md) for bounds, sound setup, author examples and MP responsibilities.

Attack effects (0.87.0) resolve the actually playing native clip within its committed `actionAnimation` family. Catalogue windows select independent arm/leg tracks per contact, including linked finishers and paired endings. `AttackEffects.finish(player)` retires the live coat into a short world-space wake; `clear(player)` and `clearAll()` also remove retired wakes. MP visual deduplication uses action, swing and clip identity. See ATTACK_EFFECTS.md for the numeric-track/provider contract and bounded budgets.

Styles may opt into `lowHealthFeedback` for configurable native-health warning thresholds, recovery hysteresis, HUD visibility and private heartbeat audio. `LowHealthRules` validates and caches configuration; `LowHealthFeedback.sample(player)` exposes the current local pulse, critical flag and health. Style UI context adds `lowHealth`. Existing style sound groups control the optional cue without adding MP packets or remote-player audio. See LOW_HEALTH_FEEDBACK.md for defaults, constraints and lifecycle events.

Heat Action sound/visual presentation follows the native playing clip independently of authoritative contacts. See [Heat Action presentation](HEAT_ACTION_PRESENTATION.md) for sound preroll, shared victim contact anchors, custom cue/layer fallback, observer playback and cleanup. QTE and damage timing are unchanged.

The shared [paired damage policy](HEAT_ACTION_DAMAGE.md) applies nonlethal damage on contact and holds lethal damage through full recovery. Presentation and three-contact katana trails remain tied to the playing source clip.

Native sandbox settings are read dynamically from SandboxVars.ProjectYakuza. DragonTigerDrop defaults to true; DragonTigerDropWindowMs defaults to 160 and clamps to 10..1000; DragonTigerDropCooldownSeconds defaults to 20 and clamps to 0..600. HeatActions, Grabs and ExtremeHeat default to true. The shared Sandbox policy controls framework action kinds on both clients and servers without rewriting style definitions. Disabling Heat Actions includes weapon, ground, grab and Extreme Heat QTE scenes. Disabling Extreme Heat retains ordinary Heat gain and other Heat Actions. Weapon Heat Actions remain available while Extreme Heat is active. requestAction returns sandbox_disabled before resource or action ownership changes when a switch rejects it.
