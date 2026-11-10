# Heat Action lifecycle

Version 0.94.0 restores the original katana prop track: the sword is released at source frame 44, caught with reversed grip at frame 54 and thrust sharp-end first at frame 64. Character poses and all three hit times remain unchanged. The attachment follows the supplied independent sword GMT instead of remaining rigidly pinned to the hand.

As of 0.93.1, the normal player-update loop starts and advances built-in weapon, ground and grab Heat Actions directly. Their stock or Extreme fuel cost is paid once when native playback is first confirmed. A missing animation, failed startup or cancellation before playback does not spend the cost. Repeated updates cannot charge again; cancellation after visible playback retains the committed cost. Multiplayer readiness is sent at that same confirmed-playback point.

Dragon of Dojima has an original katana action while Base.Katana is equipped. Hold physical RMB and press the Heat Action binding (default MMB) outside a combo, within two tiles of an eligible standing target. It costs one stock. In Extreme Heat the equivalent fuel pays the cost. MMB during an active combo retains normal weapon-heavy behavior. Other blade items do not receive this action.

The Heat Action input is separate from the finisher, counter and QTE prompt bindings. Configure its mouse mode or keyboard key in Options > Mods > Project Yakuza. Keyboard aim alone does not satisfy the physical RMB requirement. Input cannot queue a Heat Action through an active combo or its follow-up window.

## Reusable protection

Require ProjectYakuza/HeatActions in your handler. Call begin only when the native action actually starts, and finish from every completed/interrupted cleanup path. The owner key must be the same object on both calls. The module preserves pre-existing native invincibility/ghost flags and rejects another active owner. A stale finish cannot unlock a newer action.

```lua
local protection=ProjectYakuza.HeatActions
protection.begin(player,timedAction,{duration=4.5,targetGraceMs=500})
protection.finish(player,timedAction)
```

begin grants invulnerability and zombie targeting protection during playback. finish restores the original invulnerability immediately, then restores targeting after targetGraceMs (default 500, action validation permits 0..2000). This grace does not extend invulnerability. The duration plus one-second startup/watchdog allowance bounds abandoned protection; it is not an automatic animation completion trigger. Native pause time is excluded. Death/save/menu cleanup restores flags. Zombie updates clear only a protected target; they do not stun unrelated zombies. Protection tick and zombie hooks are installed only while a lease exists.

Apply the same lifecycle on the authoritative MP server after validating the action. Client begin is presentation/local AI protection, not server authorization. Do not accept a client-supplied duration, grace or arbitrary animation. The built-in paired controller uses registered definitions, restores victim movement/AI/input flags and preserves PvP, faction, safety and non-PvP-zone rules.

## Paired source timing

The katana definition lives in the DoD blade weapon view. motionId selects its registered numeric source paths. animation and targetAnimation name the original retargeted clips. contacts contains 1..32 increasing finite atMs values inside duration; damageMultiplier is 0..10. Zero damage gives presentation only. The native animation track supplies time. Repeated updates and replayed packets cannot duplicate a contact, and updates more than 120 ms late skip it. The three katana contacts at original frames 24, 44 and 64 deal 0.375/0.375/0.75 times the equipped katana's unscaled average base damage. The original frame-97 landing sound is not a damage contact. No camera override is added.

useExtremeFuel allows stock-priced actions to use fuel while Extreme Heat is active. ProjectYakuza.actionHeat(player,action) returns available resource and whether it is fuel. The request lifecycle spends it once after a successful start. Unarmed Heat Rush keeps its eight-input eligibility and original QTE bindings.

The supplied source archive, exact actor/victim role bindings, scene contact timings and clip hashes are documented in [katana provenance](katana-heat-assets.json). The generic protection helper does not supply targeting, paired motion, damage, sounds or new assets. New styles still own their action handler, native animator definitions and scoped network validation; use the existing [action lifecycle](ACTIONS.md) and [QTE engine](QTE.md) when appropriate.


Version 0.71.0 adds three separate [intact bottle weapons](BOTTLE_WEAPONS.md) and their DoD-exclusive original Heat Action. Use the same rebindable Heat Action input while physically holding RMB, outside combos. Ordinary drink bottles are unchanged.


## Source-scene alignment and eligibility prompt (0.71.0)

Paired clips are normalized to the attacker's original initial heading. The retarget root includes the source vector elevation, which is essential for the katana victim: that clip stores standing height in vector_c_n instead of ketu_c_n. Original body motion, frame counts and native grips remain intact. World paths remove shared cinematic stage translations at katana frames 33/77 and unarmed frame 35. Relative changes are bridged across six source frames instead of teleporting at the camera cut; no replacement body poses are invented. The same repaired paths are shared by owners, observers and the server.

The eligibility popup requires the same equipped item, heat stock, physical RMB, neutral combo, standing target and movement-space checks as the action. Target searches are cached for 200 ms and stop when basic requirements fail; a press forces a fresh check. The icon fades in over 120 ms and out over 80 ms. It reuses the original Y6 flame/glow atlas regions, with the current input rendered above the flame. Styles can override or hide it through ui.heatAction; see [Style UI](STYLE_UI.md).


## Source-time audio (0.76.0)

Contact cue keys resolve through the active style/equipment sound table, with heavyImpact/finisher as the optional-cue fallback. Katana and bottle contacts configure existing CombatLightAttack/CombatHeavyAttack entries, using the selected compatible CVF voice. Provider-busy/cooldown results can retry for 600 ms while that exact action remains active; stale requests are dropped. No voice recording or pack is created or modified.

MP owners present feedback from their source-animation contacts and suppress matching server echoes by session/action/index. Health remains authoritative on the server. Contact catch-up uses the existing 650 ms server grace; it does not widen the QTE input windows or auto-complete missed inputs. See [validation](VALIDATION_0.76.0.md).

## Ground actions and placement

DoD's unarmed actions.groundHeat uses the shared groundHeat handler, original h1500 ground-trample pair and one heat stock. Hold RMB and press the configured Heat Action binding (MMB by default) near a living downed zombie, outside a combo. The usual game-art eligibility/input prompt is reused. Armed profiles do not inherit it. Invulnerability ends with the sequence; targeting grace lasts 0.5 seconds afterward. Interruption restores the downed victim.

A groundHeat definition supplies enabled=true, groundHeat=true, requiresTarget=true, animation, targetAnimation, nodeValue, motionId, duration, heatStocks, contacts and optional useExtremeFuel. Register original paired paths in PairedMotions. The standard Heat Action UI provider channel can replace its prompt. Ground actions remain zombie-only, with shared server validation rather than client-directed health changes. Existing CombatHeavyAttack voice entries and hit cues provide timed feedback.

HeatRushRules.placement(player,victim,action) returns a nearby paired pose or nil. Ordinary paired actions use up to nine bounded offsets, require a clear route for both participants, and check a 0.42-tile wall margin along both source paths. They do not cross walls to stage the pair. A blocked search refuses activation. Wall actions retain their own wall geometry; GrabRules.wallPresent checks the selected solid boundary after canonical staging. Source clips are not edited for these placement changes.

Ground eligibility scans at most 25 squares and 96 objects, cached for 200 ms including empty results. It is local presentation/eligibility work; the server independently selects the allowed action and computes its canonical pose. See ground-heat-assets.json for original source provenance and the motion-derived contact frame.

Ground-trample head contact is calibrated for native Zomboid male/female geometry. PairedMotions.dod_ground.contactOffset supplies a constant victim-only forward/right translation. HeatRushRules.point rotates it with the action heading from frame zero, so placement, clearance, SP, server and observer positions agree without a mid-sequence snap. Other motions can optionally provide contactOffset for their own verified paired alignment. See ground-contact-alignment.json and calibrate_ground_contact.py; no animation body channels are modified.

## Beer crate: Essence of Crushing (0.86.0)

Only DoD's `crate` weapon profile receives this action, requiring the supplied `ProjectYakuza.BeerCrate` item. Hold physical RMB and press the rebound Heat Action binding outside a combo near a standing target. It costs one stock or equivalent Extreme Heat fuel. Ordinary crates, bottles and other styles do not inherit it.

The approved Yakuza 5 `H3270_kaburikasa` source supplies Kiryu, victim and object motion. Frames 34–63 repeat at most three times, at original 30 fps. Each section requires two fresh presses within one second. A missed section immediately plays original closing frames 63–129; success continues into frames 64–129 after the final repeat. The action always ends. Both normal and early endings include original closing contact feedback, bank damage until completion and share the standard paired protection/cleanup lifecycle.

The crate uses its supplied source object track after placement on the victim's head; it does not follow the punching hand. Retargeting retains source root height and uses PZ skeleton lengths. `crate-heat-assets.json` records archive and clip hashes, role verification, source frame maps, prop calibration and code-side paths. No artwork, audio, AI or invented body animation was added. Appearance still needs a live check after restart.

Heat Action sound/visual presentation follows the native playing clip independently of authoritative contacts. See [Heat Action presentation](HEAT_ACTION_PRESENTATION.md) for sound preroll, shared victim contact anchors, custom cue/layer fallback, observer playback and cleanup. QTE and damage timing are unchanged.

The shared [paired damage policy](HEAT_ACTION_DAMAGE.md) applies nonlethal damage on contact and holds lethal damage through full recovery. Presentation and three-contact katana trails remain tied to the playing source clip.


## Uncancellable paired playback

The built-in heatAction, grabHeat and groundHeat handlers own their paired controller directly through the framework update lifecycle. PerformingAction and IsPerformingAnAction drive the native animation without placing a cancellable item in ISTimedActionQueue. Normal queue clearing, including the cancel input, cannot remove the Heat Action controller. New ordinary queued actions for that actor are rejected while its Heat Action owns playback; unrelated actors retain their normal queues. Pause/menu input is not intercepted. Death, invalid actors, explicit framework/world cleanup and authoritative server aborts still restore flags and terminate safely.

Custom handlers remain responsible for their own playback and cancellation policy. Existing protection and damage APIs do not automatically replace a custom handler's action queue. Optional [authored presentation events](HEAT_ACTION_PRESENTATION.md) separate a sound bank's original starts from damage and VFX contacts.
