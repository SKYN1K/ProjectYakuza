# Native animation contracts

Lua describes moves; native B42 AnimSet XML selects clips, playback and hit events. Scope addon nodes to your style ID or unique PerformingAction. Use unique clip/node/marker names. Raw GMT must be retargeted/imported; referencing a filename does not create a playable animation.

## Files and timing

Player clips: 42/media/anims_X/Bob/. XML: 42/media/AnimSets/player/melee, stomp or actions. Existing native PZ clips can be referenced without copying. XML m_SpeedScale controls real speed. ProjectYakuzaCombatSpeed uses style.attackSpeed plus Extreme Heat's additional x1.2. The knee may use ProjectYakuzaRunningKneeSpeed. Lua duration is seconds after normal configured speed: a 1.6-second source at x1.6 has duration=1. XML event fractions stay source fractions; do not apply speed twice.

## Native melee

The starter light checks ProjectYakuzaActive=true, ProjectYakuzaStyle=your ID, ProjectYakuzaMove=nodeValue and AimFloorAnim=false. It uses:

| Marker/event | Meaning |
| --- | --- |
| Start AttackAnim=TRUE | Native attack playback |
| Start ProjectYakuzaClipStarted=nodeValue | Requested clip observed |
| Contact ProjectYakuzaHitMarker=nodeValue | Contact-phase diagnostic |
| Contact one AttackCollisionCheck=MeleeSwing | Native collision/damage |
| Recovery ProjectYakuzaChainReady=nodeValue | Buffered light may shorten recovery; no input plays fully |
| End AttackAnim=FALSE and SetMeleeDelay=0 | Native completion |

Hit markers are not confirmed contact. combatHit follows native victim contact/results. Do not duplicate the native strike with a timer or observers; multihit already supplements eligible victims with a shared three-target cap.

## Finishers, ground and running

Finisher variants after_N and double_after_N match afterLight; doubles set double=true. First finishers open ProjectYakuzaDoubleReady=nodeValue in a pose-matched source-frame window and clear it afterward. Queued matching input/current hit marker permit handoff; otherwise the full first animation remains. Linked follow-ups check ProjectYakuzaLinkedDouble=true. Keep source speed, doubleLinkFrame/end and XML in agreement.

Ground strikes require floor-target melee/stomp nodes, appropriate masks and the existing ground controller variables. Running defaults use left/right/knee/dropkick. After impact, side kicks/knee can expose ProjectYakuzaRunRecover=nodeValue to release ending recovery when movement is requested; dropkick retains full recovery. Full-body strike nodes bracket movement locks and restore them on interruption.

## Timed actions

Use actions-group nodes conditioned on PerformingAction=the handler's animation name. BaseAction setActionAnim supplies this variable.

| Kind | Protocol/policy |
| --- | --- |
| styleEntry | ProjectYakuzaStyleEntry=started/done; full-body, in place, no attacks, vulnerable |
| taunt | ProjectYakuzaTaunt=started/done; movement locked, reward/flash at successful end, vulnerable |
| heatActivation | ProjectYakuzaHeatActivation=started/flare/done; locked, bounded protection, fuel starts on success |
| quickstep | ProjectYakuzaQuickstepStarted/Done=nodeValue; directional descriptor and collision-checked travel |
| custom | Unique Start/End markers and handler/watchdog; no implicit damage/heat/protection |

Guard uses ProjectYakuzaDefensePhase enter/hold/hit/exit and the built-in Guard node conventions; inspect Defense.lua and its XML before reusing the handler. A single arbitrary animation is insufficient. Grab paired protocols include enter, moving hold, strike1..strike4 and throw; see [Grabs](GRABS.md).

## Legs, reactions and observers

Upper-body stance/guard masks use Bip01_Spine1 descendants/props while native walking legs continue. Full-body motion uses Bip01 when source leg movement matters. Retarget parent-space alignment and preserve native root/pelvis tracks where mixing sources; a mask alone cannot fix sliding. DoD idle/turn nodes are style-specific; other styles need their own scoped stance nodes.

enemyReactions=true opts into existing move reaction mappings. New reaction IDs also need victim clips/conditions, repeat-hit states and MP validation. A new string alone creates no victim animation.

Remote nodes preserve clip/speed/blends/masks but contain zero events. Both ProjectYakuzaRemoteCycle variants permit repeated same-clip actions. Use the [observer builder](MULTIPLAYER.md) and native parser checks. Conversion/cropping must preserve supplied provenance; do not generate/upscale missing assets.

## Optional Heat attack speed (0.61.0)

Addon styles can opt in with heatAttackSpeed={max=1.25,power=1,useExtremeFuel=false}, with per-weapon overrides. The curve is sampled per committed attack, applies to the existing native speed variables and is bounded/replicated in MP snapshots. Fixed-speed timed clips are not automatically retimed. Dragon of Dojima does not enable this feature. See [Heat-based attack speed](HEAT_ATTACK_SPEED.md) for validation, timing and authoring contracts.

Style entry prepares its active style/weapon variables before playback so idle can remain eligible beneath the full-body action. Its owner and observer nodes use m_EarlyTransitionOut=true and m_BlendOutTime=0.24. The original source duration still controls the movement/attack lock; native completion or an observed clip reaching that duration releases it. Missing clips and interruptions retain their existing cleanup policy. Source motion is unchanged.
