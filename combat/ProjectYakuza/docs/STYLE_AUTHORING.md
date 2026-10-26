# Adding styles — framework API 1

Create a separate B42 submod that requires `ProjectYakuza`. Keep its animations, XML, audio definitions and registration Lua inside that submod. Updating the framework then does not overwrite your style. An inactive starter is supplied under `templates/StyleSubmod`; it uses an existing PZ punch, so no new animation asset is needed to try the API.

## Minimal registration

Put a shared Lua file under your submod's `42/media/lua/shared/`:

```lua

require "ProjectYakuza/Registry"

local ProjectYakuza=ProjectYakuza

assert(ProjectYakuza.API_VERSION>=1,"This style requires Project Yakuza API 1")

ProjectYakuza.registerStyle({

    id="my_mod.my_style", -- use your own namespace

    name="My Style",

    attackSpeed=1,

    comboResetMs=500,

    lightBufferLimit=1,

    lightAttacks={

        {animation="Bob_AttackPunch01_Hit",nodeValue="my_mod_light_01",

         duration=1,impact=.25,chainAt=.65,damageMultiplier=1},

    },

    actions={},

    heat=false,

    music=false,

    sounds=false,

})

```

Your style appears automatically in the existing Combat styles inventory menu. Its ID is saved on the player. `ProjectYakuza.selectStyle(player,id)` selects a registered style; `ProjectYakuza.equipStyle(player,id)` is the client helper that also equips the framework token. The token's native base damage remains 0.35–0.65; each move's `damageMultiplier` changes that base for its swing.

`ProjectYakuza.validateStyle(definition)` returns `valid, errors` without registering anything. `registerStyle` validates and reports actionable errors for malformed moves, unknown action kinds, invalid timing, duplicate music entries and malformed sound profiles. `ProjectYakuza.listStyles()` returns independent menu descriptors. Existing `registerStyle` calls remain supported; use unique namespaced IDs to avoid replacing another author's registration.

## Animation files and collision markers

The registration describes the move; it does not create an animation or replace PZ's native AnimSet system. Supply your own existing/ported clip in `media/anims_X/Bob/` and an XML node under `media/AnimSets/player/melee/`. Native PZ clips may be referenced without copying them. Raw GMT files are not directly playable in PZ.

The included XML example shows all required parts:

- Conditions for `ProjectYakuzaActive=true`, your exact `ProjectYakuzaStyle`, your unique `ProjectYakuzaMove`, and `AimFloorAnim=false`.

- `m_AnimName` matching an existing clip.

- `AttackAnim` on/off at clip start/end.

- `ProjectYakuzaClipStarted=<nodeValue>` at start, `ProjectYakuzaHitMarker=<nodeValue>` at contact, and exactly one `AttackCollisionCheck` with `MeleeSwing` at that contact time.

- Optional `ProjectYakuzaChainReady=<nodeValue>` after contact to allow a buffered follow-up to shorten recovery. Without a queued follow-up the full animation plays.

- `SetMeleeDelay=0` at end.

Times in XML are clip fractions, from 0 to 1. Lua `duration` is the real playback duration in seconds, after speed adjustments. `attackSpeed` controls `ProjectYakuzaCombatSpeed`; it defaults to 1 for new styles. Use a constant XML speed for a clip with a different individual speed and keep its Lua duration consistent. The separate `runningKneeSpeed` option exists for compatibility with the DoD running-knee node.

The sample node uses the whole body to preserve its source motion. To retain native walking legs for an appropriate upper-body pose, use a Spine1-and-descendants mask instead. A mask alone does not implement a new movement/input policy.

## Music belongs to the style

```lua

music={

    {sound="MyMod_ThemeA",title="My first supplied track"},

    {sound="MyMod_ThemeB",title="My second supplied track"},

},

```

Each `sound` must name a real PZ sound definition supplied by your submod. Use `category=Music`, `master=Music`, `is3D=false`, and **`loop=false`**. The framework detects natural playback completion and chooses another entry whose sound name differs from the completed track. Keep at least two distinct tracks for continuous non-repeating playback. An empty/omitted/false playlist plays no framework music; there is no DoD fallback. The encounter's existing 12-second quiet grace, pause handling and vanilla-music restoration are retained. A handoff does not reset combat activity or recapture the ducked music volume.

DoD's 19 supplied recordings are defined only in its own `music` field. Creating another style never adds those tracks to it. Sound definitions are global PZ resources, but playlist ownership is per style.

## Sounds, heat and visual profiles are opt-in

`sounds` is a table of existing sound-definition names. Omit a cue to leave its extra feedback silent. Supported keys:

`punchImpact`, `kickImpact`, `heatImpact`, `punchSwing`, `kickSwing`, `finisher`, `grab`, `throwImpact`, `guardHit`, `guardBreak`, `heatGain`, `heatFull`, `heatStart`, `heatOnA`, `heatOnB`, `heatOff`.

Without a sound profile, ordinary weapon impacts use native `BareHandsHit`; Kiryu's sounds do not carry over. An explicitly supplied profile can reuse any existing sound assets. Optional `heatOnB` uses the built-in 300 ms second-layer delay; use a custom handler for a different activation sound sequence.

Set `heat=true` only if the style should use the shared heat system. Switching style ends active Extreme Heat and restores damage/speed modifiers. Stored heat is a player resource, but styles without heat neither gain it nor expose activation. The shared heat API is available through `ProjectYakuza.Heat.stocks`, `display`, `start`, `stop` and `isExtreme`.

The provided visual profiles are selected explicitly:

- `heatHud="yakuza6"`: use the existing dragon/orb HUD, when heat is enabled.

- `heatAura="kiryu"`: use the existing Kiryu aura, when heat is enabled.

- `hitEffects="yakuza6"`: use the provided original-glint impact renderer.

- `tigerDrop=true`: enable the existing Kiryu counter tracker; also configure a working `actions.parry` slot.

- `enemyReactions=true`: permit existing reaction mappings on moves with a `reaction` key.

These profiles are off when omitted. For custom visuals, use your supplied assets and subscribe to scoped framework events; the framework does not generate them.

## Actions and custom inputs

Built-in kinds are `finisher`, `grab`, `parry`, `block`, `quickstep`, `quickstepAttack`, `runningAttack`, `heatAction` and `heatActivation`. An omitted/disabled slot has no effect. A slot is enabled with `enabled=true` and either an `animation` or a `variants` table of move definitions. Targeted paired actions also require `requiresTarget=true` and a `targetAnimation`. Finishers may specify `afterLight`; heat costs may use `heatStocks` or `heatCost`.

Use `ProjectYakuza.registerStyleActionHandler(styleId,kind,handler)` to override a kind for your style only. `registerActionHandler` still supplies a common default. A handler has `start(context)`, optional `canStart(context)` and optional idempotent `cancel(context,reason)`. It receives player, style, action, variant, target and combo step. Start returns `true` only after the action is actually queued/started. Failed starts invoke available cancellation cleanup without spending heat. Cancellation uses the handler captured at start, even if another addon later changes handler registration.

For custom mechanics, register a namespaced kind with `ProjectYakuza.registerActionKind("my_mod.taunt")` before registering its slot. Call `ProjectYakuza.requestAction(player,"my_mod.taunt",variant,target)` to start; call `completeAction` or `cancelAction` to finish and release ownership. Your handler must restore its own movement/AI overrides. The built-in input controllers expect their existing timed-action context protocol; a new namespaced kind avoids those assumptions.

`ProjectYakuza.registerStyleInputHandler(styleId,function(player,input) ... end)` adds client input routing for that style. `input` contains `aiming`, `lightDown`, `heavyPressed` and `heavyDown` (MMB). Return `true` to consume that player's normal framework input for this update; otherwise normal combos continue. The callback also runs while the style's action is active, so it can handle release/cancellation. It must not install a global input override for every style.

`ProjectYakuza.on(event,fn)` returns the listener. `ProjectYakuza.off(event,fn)` removes it. Useful events include `styleChanged`, `styleRegistered`, `lightAttackStarted/Finished`, `finisherStarted/Finished`, `groundAttackStarted/Finished`, `runningAttackStarted/Finished`, `quickstepAttackStarted/Finished`, `combatHit`, `comboCancelled`, `heatChanged`, `extremeHeatStarted/Ended`, `actionStarted/Completed/Cancelled`, `guardHit`, `guardBroken`, `grabHeld`, `throwHit` and `tigerDrop`. Check the selected style ID before applying your own effects. Emit listeners are protected so one addon error does not stop the rest.

## Before sharing an addon

Use unique mod/style IDs, sound names, clip names and XML node values. Test selection, every collision marker, missing-asset behavior, cancellation, death, unequip, save/load, pause and switching back to another style. Do not copy the framework itself into your addon. Existing paired combat is single-player focused; multiplayer needs authoritative synchronization rather than assuming a local Lua handler replicates its effects.

Extreme Heat activation selects among the enabled variants in the selected style’s `heatActivation` slot, avoiding the previous variant when another is available. Variant keys do not need Kiryu-specific names.

The four-way selector and optional supplied `selectorIcon` are described in [STYLE_SELECTOR.md](STYLE_SELECTOR.md). Styles appear in its assignment menu automatically.

Multiplayer observer metadata and server/client ownership are described in [MULTIPLAYER.md](MULTIPLAYER.md). Custom styles need their own shared catalogue and event-free observer nodes.

Optional selected-character combat voices use [the CVF integration](CVF_COMBAT_VOICES.md). Styles may set combatVoices=false. Taunt animations can emit tauntStarted once when accepted; throwStarted now marks an accepted paired throw before its impact.

## Built-in taunts (0.26.1)

An optional `actions.taunt={enabled=true,animation="YourClip",duration=4.0}` slot uses the shared movement-locked handler. Supply a full-body actions node conditioned on PerformingAction=YourClip, with SetVariable events `ProjectYakuzaTaunt=started` at Start and `ProjectYakuzaTaunt=done` at End. The original end marker is required to award one heat stock. Missing playback, cancellation and interruption never reward heat; Extreme Heat never gains heat. The same Q/shout binding is intercepted only while aiming with an equipped style that enables this slot. No taunt is inherited by a style without this slot. Emit `tauntStarted`/`tauntStopped` only from custom handlers if replacing this handler. Register the observer animation in your style's NetworkCatalog for remote playback. The stock-based reward assumes the style enables heat; disable the slot for styles without a heat mechanic.

Style voice options: `combatVoiceVolume=1.5` raises the native handle mix for that style only. `quickstepVoices=false` silences movement-only quickstep voice cues; quickstep attacks retain their attack cue. Defaults are normal mix and enabled quickstep voices.


## Optional style entry

A style can opt into the shared in-place entry handler with `actions.styleEntry={enabled=true, animation="YourEntryClip", duration=1.67}`. Supply a non-looping player/actions node with `PerformingAction=YourEntryClip`, plus Start/End SetVariable markers `ProjectYakuzaStyleEntry=started` and `ProjectYakuzaStyleEntry=done`. Use the actual clip duration. Selection and explicit reselection request this action; styles without it remain unaffected. Entry blocks movement and attacks, grants no protection or heat, and stops on damage/hit reaction, death or unequip. `styleEntryStarted(player,style)` supplies the existing CombatStanceEntry voice hook. Regenerate or extend the multiplayer catalog/observer nodes when adding a custom animation.
