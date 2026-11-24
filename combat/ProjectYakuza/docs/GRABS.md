# Grabs, grab strikes and Heat Actions

Dragon of Dojima now enables unarmed grabs. Hold RMB and press the configured Grab binding (G by default) to grab a standing zombie in front of you. Press it again to throw. There is no manual let-go input; releasing RMB keeps the grab active. During the hold you can walk using native Zomboid leg movement; the victim follows the paired pose. Losing the style, taking a hit/knockdown or running out of endurance still interrupts the hold safely. Other zombies can still hurt you during ordinary grabs.

LMB, or the configured Light binding, cycles four original Kiryu grab strikes. Each fresh press starts the next strike when the previous motion has returned to hold. Movement locks during the source strike, and damage occurs once at its original BEP collision frame. Own grab strikes suppress knockdown/stagger so a surviving victim stays held. Strikes and the continuous hold use endurance.

The same configured Grab binding throws the held zombie on a fresh press after hold begins. Holding the button does not repeat the throw, and presses during enter/strike/throw phases cannot restart it. The obsolete separate Throw binding has been removed; rebinding Grab controls both grabbing and throwing. With RMB held, MMB or the configured Heat Action binding selects the held-target Heat Action. A valid wall takes priority; otherwise the original Yakuza 6 shoulder throw and follow-up is available when both paths fit in open space. The Yakuza prompt shows that binding. Doors and windows do not qualify. Both grab Heat Actions cost one full stock and may use Extreme Heat fuel.

The wall action uses the original h2000_knock_wall_l attacker/victim pair. It aligns the source scene to a nearby wall, checks space for both paths, locks movement, and uses the existing paired Heat Action controller. Source scene frames 1, 28 and 73 drive sound/voice/impact feedback. Damage is deferred until completion so native death cannot cut off the victim motion. Invulnerability lasts through the action; targeting protection continues for the existing 0.5-second grace afterward. Contact tint and bounded shake use the shared local Heat Action presentation.

## State ownership and multiplayer

The hold suppresses AI movement/attacks. When the controller observes the victim transition from its captured state into the grab reaction, it acquires a native state-machine lock. B42 does not expose the lock getter to Lua, so only locks acquired by this controller are tracked and released; no reflection or debug mode is required. Matching victim nodes also cover the idle state, so an animation-state transition cannot replace the paired pose with ordinary idle. Every release/cancel path restores the victim's previous movement, deferred-motion and useless flags, and releases any native lock acquired by this controller. The old 3.5-second local expiry is removed. Server leases renew only while recent valid grab state is maintained and release on timeout, invalid position, equipment change, death or disconnect.

MP damage remains server authoritative. Each grab has a unique lease ID. Strike sequence, selected original clip, contact timing, range and per-contact replay checks are enforced by the server. Ended grab IDs reject stale poses, starts and releases. A grab Heat Action requires ownership of the held target, enough Heat and clear source paths. The server independently chooses the wall/open variant, retains wall priority and rejects unknown or mismatched variants. Its handoff request token prevents the server grab-end message from cancelling the matching local grab before the Heat Action grant arrives. Both sides revalidate placement before starting, and native playback confirmation pays the cost once. Server cancellation also ends the owner's local action. Owned AI-lock release is included in observer cleanup.

## Adding grabs to a style

The existing grab handler uses actions.grab and its enter/hold/throw animation-node conventions. Supply compatible player and zombie phase nodes, including native-leg walking variants, rather than setting only one arbitrary clip. The default pair spacing is 0.7 tiles. The optional strikes array contains up to four paired moves with animation, targetAnimation, duration (seconds), contactMs, and damageMultiplier. Durations must be positive and at most 10 seconds, contacts must be inside the clip duration, and supplied damage multipliers must be finite in the range 0..3. Provide matching strike1..strike4 nodes using ProjectYakuzaDefensePhase for the actor and ProjectYakuzaGrabPhase for the victim. The actor's PerformingAction remains the grab slot's animation during these phases. Native AttackCollisionCheck events must be absent; the controller owns each contact.

The grabHeat built-in action kind uses the shared paired Heat Action handler. A style opts in through actions.grabHeat with enabled=true, grabHeat=true, requiresTarget=true, animation, targetAnimation, nodeValue, motionId, duration, heatStocks and contacts. Register the source actor/victim paths in ProjectYakuza.PairedMotions under motionId. This wall handler aligns the normalized source forward axis with the outward wall normal, independent of the player's aim. wallDepth is the maximum forward travel of either participant plus 0.15 tiles, keeping the source paths on the interior side of the wall. Other staging conventions can use a separate action handler. Styles without these slots do not inherit DoD's grabs or Heat Action.

Use the standard heatAction style-UI provider channel to replace the eligibility prompt. Existing bindings, contact feedback, optional Combat voice entries and heat configuration are reused. Armed DoD profiles retain their existing moves and do not enable grabs.

See grab-strike-assets.json and wall-heat-assets.json for original sources, hashes, paired-role verification and contact frames. No invented motion, AI, new artwork or audio is used. Live game appearance and actual multiplayer sessions still require testing after restart; validation is offline.


## Native skeleton positioning (0.83.0)

DoD uses a 0.48-tile hold distance and a 0.019354-tile lateral correction. The source hand/neck reference requires 0.291238 tiles before clearance; 0.188762 additional tiles address live body-overlap feedback. The holding/walking masks own only Spine1 and its descendants plus the props. Root, pelvis, lower spine and leg transforms remain native, avoiding a whole-body sideways rotation from a partial source-root blend. Raw source-space hand measurements do not establish exact live grip alignment. Each original strike supplies its own `pairOffset={forward=...,right=...}`; the grab slot supplies `throwOffset` for the throw and `lateral` for the hold. Offsets move the victim root relative to the actor root; positive right follows `(fy,-fx)`. A 120 ms smooth transition preserves the previous root position at phase changes. Strikes and throws retain the established pair heading while player movement is locked; hold still uses native walking and animated facing. The victim follows through the throw until impact instead of only receiving one initial snap. Server-owned grabs use the same offsets, blends and facing rules.

The framework retains a 0.7-tile default hold distance for styles without authored spacing. Forward pair offsets must be 0.05–1.5 tiles and lateral values within ±0.75 tiles; grab distance remains 0.25–1.0. These are code-only staging corrections. Existing attacker/victim animation files are unchanged. Contact positioning is verified against converted skeleton transforms offline; live appearance still needs an in-game check.


## Throw landing (0.84.0)

A completed grab throw enters the native zombie ground state directly after releasing the owned grab lock. It clears the standing hit reaction, stagger-back and push force, sets a face-up floor pose, then allows native recovery. Release/interruption before throw impact still restores normal standing behavior. MP damage and grab-end packets carry the same landing result, so either packet order settles the zombie without replaying a standing fall reaction. Replay checks still prevent duplicate throw damage. This is a landing correction, not permanent immobilization.


## Crowd impacts (0.85.0)

DoD enables `actions.grab.throwCrowd={radius=1.1,forward=.45,maxTargets=4,force=.65}`. At the original throw impact, the controller scans nearby squares once around a point 0.45 tiles ahead of the thrown victim. Up to four nearest standing zombies inside 1.1 tiles are knocked away from the player using native knockdown flags. Walls block the effect. The thrown victim, players, dead/downed zombies, different floors, targets behind the thrown body and zombies already grabbed, paired or in a hit reaction are excluded. Secondary targets receive no extra damage, heat or per-target audio burst. The thrown victim keeps its existing damage and prone landing.

The scan visits at most 25 squares with the allowed radius and deduplicates moving objects. No idle or continuous collision poll is added. MP selects targets on the server, using only the registered style settings; the client sends no target list. Replicated reactions are deduplicated and use bounded deferred delivery if the target is temporarily unloaded. The throw request must match the current grab ID and its original source impact time before any primary damage or secondary reaction is accepted.

Other styles opt in with their own `throwCrowd` table, or omit/set it false. Radius is 0.25–2 tiles, forward offset 0–1 tile, target cap an integer 1–8, and force 0–1.5. Optional `throwContactMs` and `throwDuration` author the server timing gate; DoD uses source frame 70 of 77 at 30 fps. All values are validated when registering the style. Existing animations, sound and effect assets are reused.


## Committed holds (0.86.0)

DoD sets `actions.grab.releaseOnAimLoss=false`. Aiming is required to initiate the grab, but releasing RMB afterward cannot release the held zombie. Walking, grab strikes and the configured Grab button remain available; a fresh Grab press throws without requiring RMB to be held again. The vanilla safety-key handler is suppressed for the active Grab binding during a grab even after aim release.

The flag changes only aim-loss cancellation. Death, physical hit reactions, exhaustion, invalid victim state, equipment/style changes and world/disconnect cleanup still restore the owned locks safely. Guard and new-grab initiation still require aiming. Custom styles may omit the flag for the existing aim-loss behavior; supplied values must be boolean. Wall Heat Actions retain their RMB requirement.

## Animated break-outs (0.86.0)

DoD enables a 5% escape roll every 1000 ms while in the held phase, starting after the first full second. All zombies qualify; no hidden Strength field or health proxy is used. Strike, enter and throw phases do not roll. Delayed frames perform one roll, without catch-up bursts. Single-player pause shifts the timer. Multiplayer rolls only on the server.

The complete original `sy0/sy1_gsp_sprt` separation pair plays for 70/30 seconds, with both actors held in position until completion. Other enemies can still interrupt the player. Grab strikes, throws and wall Heat Actions cannot override the break-out. Completion, interruption and server timeout restore native flags and acquired AI locks. Replay-safe grab IDs prevent late packets from reviving an ended hold.

Configure `actions.grab.breakout` with `chance` (0–1), `intervalMs` (250–10000), optional `firstCheckMs` (0–10000), supplied `animation`, `targetAnimation`, and `duration` (positive, at most 10 seconds). Omit it or set false to disable escape. Supply matching owner/victim nodes for the `escape` phase, using the existing PerformingAction parent and DefensePhase/GrabPhase variables. Optional `escape_started` and `escape_done` markers use the existing DefenseMarker/GrabMarker channels. Do not add native collision events. `grabBroken(player,victim)` reports the transition. See `grab-escape-assets.json` for source hashes and complete frame counts.

## Open-space shoulder throw (0.108.0)

The original Yakuza 6 h23600_seoi_oi scene has one player and one victim, with no wall, weapon, prop or second enemy required. It retains all 225 samples at 30 fps over 224/30 seconds. Original damage frames 117 and 167 drive the throw and follow-up, retaining the existing total five-times canonical unarmed multiplier and deferring lethal damage until completion. Nine original non-voice bank streams and the original voice-label timing use the shared presentation system. Native limb proportions, actor sole grounding and victim floor clearance adapt the supplied poses; no new textures or models are added. See OPEN_GRAB_HEAT_ACTION.md.

DoD declares actions.grabHeat as an enabled slot with variants.default for the original wall move and variants.open for the open-space move. Each variant supplies grabHeat=true, its original animation/targetAnimation/motionId, duration, contacts, one-stock price and enabled flag. requiresWall=false identifies the open variant; wall variants retain requiresWall=true. Existing non-variant grabHeat definitions keep their wall selection behavior. The input and server use the current style definitions rather than a global action override.


## Reach attempts (1.0.4)

Dragon plays the complete original 1.6-second Yakuza 6 grab-attempt and recovery motion when Grab is pressed. The target is searched in the original BEP interaction window, frames 10–12 at 30 fps. Before this contact, zombies retain their movement, targeting and reactions. A miss completes the reach and restores movement. Interruptions before contact leave victims untouched.

Multiplayer requests server ownership at reach contact. An accepted grant branches from the attempt to paired entry; a denied or expired attempt continues its failed-reach recovery. A grant arriving after cancellation is released. Existing held walking, strikes, throws and Heat Action handoffs continue after attachment.

Style authors can opt into this flow with grab.attemptAnimation, grab.attemptContactMs, optional grab.attemptContactEndMs and grab.attemptDurationMs, and requiresTarget=false. Timing is sampled from the animation track. The configured contact must precede the end of the clip, and the attempt must last no more than two seconds. Dragon uses ProjectYakuza_DD_GrabAttempt, contact from 333.33 to 400 ms and a 1600 ms full duration. Its dedicated attempt node is selected by ProjectYakuzaDefensePhase=attempt. Successful attachment changes that phase to enter; a miss keeps the full original recovery. Source frame order and speed are unchanged.


## Entry polish (1.0.5)

Client and server share a time-based blend from the victim's actual position to the complete grip offset, including lateral placement. The default is 180 ms. Styles can set grab.entryBlendMs between 80 and 400. Both readiness markers and completed alignment are required before hold begins. A late MP grant must still pass range, facing, visibility and path checks. Obstructed entry releases the actors. Pause adjusts entry and approval clocks; a finished missed animation cannot retain its movement lock simply because the track disappeared.

While a victim is held, a tick hook restores native aiming after input polling clears it. Cleanup restores the current native aim-control state and removes that hook when the final held victim is released. It respects remapped native aim controls.

## Outcome feedback (1.0.8)

The controller emits grabConnected(player,victim,action) once after attachment and ownership, grabMissed(player,candidate,action) once after a failed reach resolves, and grabEnded(player,victim,action) after cleanup releases active action ownership. The candidate may be nil. Interrupted attempts before contact do not emit a miss. Multiplayer pending approval emits neither outcome until the grant succeeds or expires.

Default local feedback moves the existing grip cue to successful attachment and shows a 650 ms connection or miss notice. Reaching keeps its supplied whoosh; misses do not play a false impact. The held prompt lists the current Light and Grab bindings. A matching action context prevents stale cleanup from removing a later grab's feedback state.

## Native aim ownership

When releaseOnAimLoss=false, grab ownership sets native forced aim and suppresses run/sprint permissions. This persists across native input polling after RMB release, keeping combat walking speed and stance. Completion, cancellation and handoff restore the previous forced-aim and permission values. Current reach movement is defined below.

## Consistent parent frames and early reach (1.0.10)

Optional attemptDistance is bounded to 0..0.75 tiles. attemptMoveMs must be positive and no later than attemptContactMs. Dragon advances up to 0.28 tiles over 240 ms from the original attempt track, with an ease-out curve and 0.06-tile maximum increment. A target within the approach path limits movement to preserve 0.35 tiles of clearance. This scan does not reserve the target; attachment remains in the source contact window. Movement stops after obstruction and never catches up after a late first sample.

holdOffset and walkOffset override the default paired offset, with the same bounds as other phase offsets. Dragon's stationary forward/right offset is 0.21/0.357359544; walking uses 0.315023962/0.320104175. These use the actual source upper-body pose under native root, pelvis and lower-spine parents. The stationary planar hand/collar reference has less than 0.016 tiles of clearance. This is a source-pose check rather than proof of the final live blended skeleton.

Dragon's four strikes keep those native parents and retain original upper-body and leg joints. Their pairOffset overrides are removed so the victim root stays at the held offset through strike transitions. Ordinary native damage is applied once; no-knockback contacts suppress native staggering during that call and restore its old value afterward. Client and server use the same walking-offset blend. The open-space scene uses its authored initial separation to orient the pair without placing the victim behind the held direction.
