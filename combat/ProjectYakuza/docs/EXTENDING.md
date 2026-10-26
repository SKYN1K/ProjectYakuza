# Extending Project Yakuza

Public namespace: ProjectYakuza. Shared modules: media/lua/shared/ProjectYakuza. Client input/UI: media/lua/client/ProjectYakuza. Style item: ProjectYakuza.StyleToken. This prototype uses native melee combat; it does not provide server-authoritative multiplayer replication.

## Adding a style

Create a shared module, require ProjectYakuza/Registry, and register a unique style ID before a save starts:

~~~lua
require "ProjectYakuza/Registry"
ProjectYakuza.registerStyle({
    id = "my_style",
    name = "My style",
    comboResetMs = 750,
    lightAttacks = {
        { animation="My_Light01", nodeValue="my_light_01", duration=0.8, speed=1.0, impact=0.25 },
    },
    actions = {},
})
~~~

The menu lists registered styles automatically. Choice persists in player:getModData().ProjectYakuzaStyle; combo state is transient per player index.

For each attack provide an animation under media/anims_X/Bob and an AnimSet node under media/AnimSets/player/melee. Check ProjectYakuzaActive=true, ProjectYakuzaMove=the exact nodeValue, and AimFloorAnim=false. Use m_ConditionPriority=100, animation layer m_Priority=4, one AttackCollisionCheck event, and AttackAnim start/end events. Copy the bundled nodes as examples.

Lua animation, speed and impact values describe the move; AnimSet XML controls actual playback and hit timing. Keep the two synchronized. Changing Lua metadata alone does not generate native nodes.

## Combo lifecycle

Combo.lua controls queue size, selection and reset windows. Runtime.lua samples LMB edges and advances on accepted native OnWeaponSwing events. Buffered continuation calls player:AttemptAttack() after the previous native attack finishes. Every step is a separate native attack with normal targeting, line-of-sight, armor and damage handling.

Do not add a health-subtraction timer or a second hit loop alongside AttackCollisionCheck; that would duplicate damage.

## Finisher API

Dragon of Dojima supplies enabled variants after_1 through after_4 and double_after_1 through double_after_4. Double variants set double=true and require a completed first finisher from the matching branch. The built-in native handler requires animation, nodeValue, duration, afterLight and enabled=true for each variant, plus a matching AnimSet node. Keep speed and impact metadata synchronized with XML. ProjectYakuza.queueFinisher(player) queues MMB behavior against the current light step plus earlier buffered lights. ProjectYakuza.requestAction(player, "finisher", "after_2") starts a completed, unexpired branch directly.

Middle mouse is button index 2 (ProjectYakuza.FINISHER_MOUSE_BUTTON). It is sampled on rising edges while aiming. The second MMB tap queues the matching double variant. Subsequent lights cannot overtake a queued finisher. Full-body finisher nodes preserve leg animation and bracket playback with BlockMovement TRUE/FALSE. Runtime completion and reset also release the movement flag. Do not replace this with a second damage loop.

## Other action API

Known kinds: finisher, grab, parry, block, quickstep, quickstepAttack, runningAttack, heatAction. Grabs, parries, blocks and heat actions remain disabled. Quicksteps have a built-in native timed-action handler. Disabled slots return false, not_implemented. Enabling a slot requires an animation, a registered handler, valid target descriptors where required, enough heat and an idle combat state. Quickstep variants are forward, backward, left and right. No input keys are assigned to unfinished actions.

Successful start stores an active context and locks other actions. Signal ProjectYakuza.completeAction(player) on completion or ProjectYakuza.cancelAction(player, reason) on interruption. Unequip/death reset also cancels active actions. Handlers own their timers, target locks and cleanup. Do not complete synchronously inside start: requestAction stores the context after start returns successfully.

Context fields: player, style, kind, action, target, comboStep. Unknown variants, missing assets, failed requirements and failed starts produce no gameplay effects. Listener and handler exceptions are logged and isolated.

## Paired moves, defense and movement

Grabs and heat actions use requiresTarget=true and targetAnimation as well as the attacker animation. A handler must implement target eligibility, alignment, synchronized playback, obstruction checks, interruption and release. A targetAnimation string does not create synchronization by itself.

Parry/block handlers need timed defense and damage interception. Quicksteps need collision-aware movement and an explicit vulnerability policy. The framework grants neither protection nor teleportation while those implementations are absent.

## Heat

ProjectYakuza.getHeat/player and ProjectYakuza.setHeat/player-value retain the 0–100 metadata API. Heat.lua maps this to six stocks. ProjectYakuza.Heat.config exposes conversion, decay, duration and Extreme Heat modifiers. See HEAT.md. Runtime calls Heat.onSwing and Heat.onHit on accepted native events. Heat.onHit deduplicates victims within a strike and awards damage-scaled heat; do not add a second gain loop.

An action can specify heatStocks=1 for one current stock, or heatCost for a raw 0–100 amount. Cost is debited only after a successful handler start. Extreme Heat transfers the ordinary meter into transient fuel; use Heat.display for UI and Heat.isExtreme for status. Heat.toggle/player requires an idle aiming state to start. Native ProjectYakuza attack XML uses ProjectYakuzaCombatSpeed rather than a literal speed; ensure new strikes follow the same convention. A future server mode needs authoritative replication.

## Hooks

Use ProjectYakuza.on(eventName, callback):

- styleRegistered(style), styleChanged(player, styleId)
- lightAttackStarted(player, style, step, move), lightAttackFinished(player, step)
- finisherStarted(player, style, step, move), finisherFinished(player, step, move)
- comboCancelled(player, reason), comboExpired(player)
- combatHit(attacker, victim, weapon, damage, step)
- actionStarted(context), actionCompleted(context), actionCancelled(context, reason)
- heatChanged(player, amount)

combatHit follows native OnWeaponHitCharacter. Clip/hit markers are diagnostic signals, not evidence of target contact.

## Current scope

Mouse input is local and combo states are indexed by player. The HUD targets player 0. Controller support, split-screen HUD, network replication and a GUI settings page remain future work. Other combat mods may compete for the same native states.

## Conditional recovery and reactions

Lights use ProjectYakuzaChainReady after their hit marker. First finishers instead open ProjectYakuzaDoubleReady=<nodeValue> at the pose-matched frame and clear it three source frames later. Only a queued second MMB press with a matching current hit marker can release the first animation. No follow-up input means full playback. Late presses wait for completion. Metadata doubleLinkFrame/doubleLinkEndFrame documents the branch's source frames; XML events control runtime eligibility. Linked follow-up nodes share the existing ProjectYakuzaMove but require ProjectYakuzaLinkedDouble=true; original follow-ups require false. Each route retains one native collision, remapped after any source entry trim. A movement hold spans cleanup and the linked move and is released on completion, cancellation, timeout or interruption. Keep releaseFinisherHandoff in all cleanup paths. Light buffer and combo timeout behavior are unchanged.

Styles opt into enemy reactions with enemyReactions=true. Each move supplies reaction="enemy_01" through "enemy_04". Reactions.lua scopes visual overrides to actual style hits on living standing zombies. Its tags gate native hitreaction nodes; native reaction enums, deaths, rear hits and physics states retain their routing. Additional reaction clips need matching nodes and compatible native lifecycle events.

## Quickstep handler

Each enabled quickstep variant supplies direction, animation, nodeValue, duration, speed and distance. A matching player/actions node checks PerformingAction against animation. It emits ProjectYakuzaQuickstepStarted at start, monotonic ProjectYakuzaQuickstepProgress values over the travel portion and ProjectYakuzaQuickstepDone at end. No AttackCollisionCheck belongs in a quickstep node.

ProjectYakuza.requestAction(player, "quickstep", "forward") requests facing-relative movement. Input can supply an optional target table {dx=worldX,dy=worldY}; the handler normalizes it and retains that world direction. Quicksteps.lua owns the timed action, native movement/hand-model overrides, input latch, cooldown, terrain guards and cleanup. No movement or invulnerability state is serialized.

## Update costs

Use ProjectYakuza.setVisual for cached ProjectYakuzaActive/ProjectYakuzaMove writes. Avoid reapplying them per frame. Reactions.lua uses OnTick at 20 Hz for tagged victims only; do not add a global per-zombie scan. Quickstep native hand overrides explicitly disable forced model refresh. Routine combat logging is diagnostics-only.

## Quickstep attack handover

The quickstepAttack slot supplies four directional variants with quickstepAttack=true, full-body native melee nodes and one AttackCollisionCheck each. Runtime.lua shares the native attack handler with finishers, while separate quickstepAttackStarted/player-style-move and quickstepAttackFinished/player-move hooks distinguish lifecycle events.

Quicksteps.lua captures a fresh LMB edge during the step and completes the timed action after its opening travel progress reaches 0.25. Only perform() creates a 500 ms Q.pending ticket, so stopped actions cannot dispatch a strike. A strike waits for native hand readiness and no timed action, then consumes that ticket. Public requests without the exact pending ticket fail with quickstep_required. Reset, invalid player state and expiry discard it. Never submit a melee attack from inside the still-running timed action.

HeatUI.lua creates one non-interactive ISPanel on OnGameStart. It uses Heat.display and a 100 ms read interval. The panel draws only the bar, with no orb asset. Future heat handlers can spend heat through the existing successful-action cost path.

Extreme Heat hooks: extremeHeatStarted(player,fuel), extremeHeatEnded(player,reason). Weapon-instance original damage and player original ignore-stagger-back state must be restored on all exits; keep this cleanup when extending the mode.

## Ground attack clips

A style can provide groundAttacks={...} entries with animation, nodeValue, duration, speed, impact, groundAttack=true and fullBody=true. The current style uses two alternating clips. Native AnimSets in both player/melee and player/stomp check ProjectYakuzaActive, DFCGroundEnabled, ProjectYakuzaStompVariant and AimFloorAnim=true. Standing nodes continue to require AimFloorAnim=false.

Use exactly one AttackCollisionCheck: MeleeToFloor for player/melee, Stomp for player/stomp. Native stomp nodes use StompAnim, normal melee nodes use AttackAnim; preserve start/end pairs and movement-lock cleanup. The XML chooses the ground clip from native floor targeting even when the current ProjectYakuzaMove still identifies the provisional standing swing. Runtime.syncGroundAttack adopts the ground lifecycle after SwipeStatePlayer publishes its floor state. Do not read AttackVars.aimAtFloor as a Lua property or add a world scan.

Ground clips use s.groundMove and finish by clearing their chain, releasing movement and advancing the per-player variant. Events groundAttackStarted(player,style,move) and groundAttackFinished(player,move) identify them. Native bare-handed foot-hit callbacks can credit heat only while a ProjectYakuza ground move is active. Completed ground attacks do not open a finisher window. Keep ground disabled for styles that do not supply matching clips/nodes.

## Running attacks

Styles supply actions.runningAttack variants left/right/knee/dropkick with native animation, duration, speed, impact and bounded travel distance. The exact short-lived input ticket is required by the native action handler. LMB chooses ZombRand(3) once per eligible click; MMB always selects dropkick. Native displacement supplies facing in all directions. There is no movement-key-based variant selection.

The existing player update drives the handler. Startup temporarily holds movement and clears running/sprinting/moving until the native action state becomes idle or movement, then submits AttemptAttack once. OnWeaponSwing begins clip-driven travel. Do not rely on standalone mod actiongroup XML being auto-discovered; startup now uses the installed native transitions.

Running nodes have one native collision, ProjectYakuzaRunProgress and paired movement-lock events. The knee uses ProjectYakuzaRunningKneeSpeed (1.2 normal, 1.44 Extreme), while the other moves retain ProjectYakuzaCombatSpeed (1.6/1.92). For LMB variants, a late SetVariable ProjectYakuzaRunRecover=<nodeValue> event permits movement recovery only when ProjectYakuzaHitMarker matches and a rebound movement key is held. Side kicks use 0.78, knee 0.80. Dropkick has no recovery marker and is explicitly excluded from early release. Restore movement overrides, report ActiveAnimFinishing with AttackAnim false, then let native cleanup finish. Never add a second collision for recovery.

The moving stance mask uses Spine1 descendants and Prop1/Prop2 only. Do not include Spine, even nonrecursively: it parents both thighs, so its rotation changes native leg placement. Standing uses the same animated upper loop over baked native lower-body keys. Hooks remain runningAttackStarted and runningAttackFinished.

## Per-move damage

Moves may set damageMultiplier (default 1.0). The native swing hook applies it after heat fuel handling and restores prior move values before applying another factor. Keep Heat.endSwing in completion/reset/cancellation and Heat.applyMoveDamage when adopting a different native ground move. Do not alter scripted weapon baselines to emulate per-move damage or add extra damage in the hit callback.
