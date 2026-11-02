# QTE framework API (0.73.0)

ProjectYakuza.QTE is a shared code-only sequence engine for custom style actions. It does not create artwork/audio, choose targets, start animations, grant immunity or deal damage. An action handler owns its animation, lifecycle, presentation and multiplayer authorization; QTE supplies bounded prompt validation, fresh-input tracking and result events. DoD's paired Heat Rush is one consumer rather than a global handler for every style.

## Definition

An action may contain a qte table. Style validation checks it against the action duration. For example:

```lua
qte={prompts={
    {atMs=900,windowMs=300,binding="light",damageMultiplier=.75},
    {atMs=1500,windowMs=300,binding="finisher",damageMultiplier=2},
}}
```

The sequence contains 1..32 prompts, in increasing contact time, with non-overlapping windows. atMs must be finite, positive and at most 120000; windowMs is 50..2000 and must fit before the contact. The optional damageMultiplier is 0..10; it is metadata for your handler, not permission to apply damage. Register addon action bindings through ProjectYakuza.Bindings before starting the action. Binding names must be nonempty namespaced identifiers. Do not trust definitions or damage values received from a client.

## Functions

| Call | Meaning |
| --- | --- |
| QTE.valid(definition,durationMs) | Returns true, or false and an error; optional duration bounds the last prompt. |
| QTE.create(definition,down,context) | Creates a fresh session and primes held-button states; down(binding) returns a boolean. Invalid definitions raise an authoring error. |
| QTE.window(definition,index,timeMs,earlyMs,lateMs) | Tests an input window. Optional tolerance is for your validated network backend. |
| QTE.update(session,timeMs,down,callback) | Advances using monotonic animation time. Rejects invalid/backward time and ignores closed sessions. |
| QTE.cancel(session,reason) | Closes an active sequence once and emits cancellation. |

Use native animation-track phase times 1000 for timeMs, rather than assuming wall-clock time equals animation time. Stop updating while paused, and cancel on interruption, animation restart, style/equipment change and world exit. Do not reuse sessions. The built-in paired action skips contacts more than 120 ms late to avoid a catch-up burst.

callback(kind,index,success,prompt) receives input when a new valid press is accepted, and result at the contact time. Result success is false when a prompt is missed. Results are consumed once; keeping a button held or calling update repeatedly cannot repeat them. When a configured failure limit is reached, callback also receives `failure`; the session closes with `failed=true` and does not emit a normal completion. The contact time itself is outside the input window. A late update can mark a missed prompt without ever displaying it.

The session exposes definition, context, index, accepted, results, successes, failures, consecutiveFailures, failed, failedIndex, inputAt, closed and lastTime. Read these for UI; keep state mutation in QTE. Use the registered binding's current label rather than hardcoding MMB. The built-in prompt animates supplied Y6 ring textures using native drawing and source animation time. It displays the currently bound control, has no preparatory message/panel background and cannot capture mouse input. Custom styles may render their own prompts with supplied assets.

## Events

Events preserve the context passed to create, which can contain player, style, action and variant:

- qtePrompt(context,index,prompt) fires once when the current prompt window is observed.
- qteInput(context,index,prompt) reports one accepted new press.
- qteResult(context,index,success,prompt) reports each contact result, including failure.
- qteFinished(context,successfulCount,totalCount) fires once after the last contact.
- qteCancelled(context,reason) fires once when an active sequence is cancelled.

Filter callbacks by your style/action identity. Completing a QTE does not automatically finish the body animation: play its original recovery, then complete the action. This avoids cutting source clips merely because the final prompt ended.

## Multiplayer

The shared engine is deterministic sequence logic, not an authority bypass. Your server must bind a style/action/target lease, use its own registered definition, validate timing and input indices, deduplicate results, calculate damage and restore target state on every exit. Observers render confirmed results without replaying native Hit. DoD's HeatRushServer provides a concrete implementation with canonical token damage, proof of eight boost inputs and the final contact, one target reservation and stale-session protection. Other move types should register their own scoped backend.

No new graphical/audio assets are needed to use this API. Retargeting or extracting additional supplied assets still requires the project's explicit asset approval.


## DoD eighth-input finish (0.68.0)

The controller follows the eight-input boost chain rather than counting confirmed earlier hits. Inputs one through seven may miss or hit any targets. The eighth input must land on a surviving standing character. Every contact from that strike replaces the candidate, so its final character target wins. An ineligible final target does not fall back to an earlier one. Target range, facing and clear paired-movement paths are still checked.

The server observes the ordered boost-input snapshots, deduplicated by native swing serial, without requiring seven damage reports. The final native/supplemental contact records a typed zombie/player target. Supplemental server damage carries its source swing; the owner waits for outstanding contacts up to 500 ms. Stale replies cannot retarget another swing, and timed-out contacts skip the sequence rather than choosing an unconfirmed target. Temporary native recovery still retries within its bounded handoff window.

Player victims reuse the existing converted victim clip through two scoped player state definitions. Native movement, attack authorization and action variables are saved and restored on every exit. Typed target IDs prevent player/zombie ID collisions. PvP must be enabled, both safety flags cannot protect the pair, protected players and non-PvP zones are rejected, and faction PvP settings apply. The server rechecks permissions during the sequence and aborts if they change. No animation motion or graphical/audio asset is created or changed. This path is offline-validated and still needs live multiplayer presentation/latency testing.

Boost lights use the `boostStun` response and `noKnockback=true`; their prior damage multiplier remains 0.525. The shared stun lasts 250 ms, refreshes without overwriting saved flags, suppresses root movement and zombie AI, and restores native state on expiry. A paired action releases an existing stun before taking its own movement/AI lease.

## Paired contact mapping (0.72.0)

A paired action can supply both `qte.prompts` and `contacts`. Each prompt maps to exactly one contact using its one-based `qteIndex`; the contact must use the same `atMs`. Duplicate or missing mappings are rejected. A mapped contact runs only after that prompt succeeds. Unmapped contacts run automatically at their source time. Contacts without QTE definitions retain their existing automatic behavior; QTE definitions without a contacts array retain the previous one-contact-per-prompt behavior.

`damageMultiplier=0` makes a contact presentation-only. `strong=false` selects the smaller existing hit feedback. `cue` selects the registered impact sound. An automatic contact with `sumQTE=true` must follow the final prompt; it sums `damageMultiplier` from successful mapped prompts. This lets an original final blow deliver the earned payoff while intermediate punches preserve victim animation. The server uses only its own validated contact flags, never client damage. For example, within an action with a sufficient duration:

```lua
qte={prompts={
    {atMs=1000,windowMs=300,binding="light",damageMultiplier=1},
    {atMs=1500,windowMs=300,binding="grab",damageMultiplier=1},
}},
contacts={
    {atMs=1000,qteIndex=1,damageMultiplier=0,cue="punchImpact",strong=false},
    {atMs=1500,qteIndex=2,damageMultiplier=0,cue="punchImpact",strong=false},
    {atMs=2000,sumQTE=true,cue="heavyImpact",strong=true},
},
```

`HeatRushRules.contacts(action)` resolves the contact list, `promptContact(action,index)` resolves a prompt to its contact, and `amount(action,index,weapon,successfulContacts)` calculates canonical paired damage. These helpers serve the built-in DoD handler; registering another style's QTE still requires a scoped lifecycle and server backend. Full source motion plays beyond the last QTE. See [retail timing and bindings](EXTREME_ATTACKS.md).

## Configurable misses and sounds (0.73.0)

Every prompt keeps its own `binding`, `atMs` and `windowMs`. Only a fresh press of that action inside the window succeeds. An incorrect control is ignored and becomes a miss when the contact time passes. Existing non-overlapping timing bounds are unchanged. For example:

```lua
qte={
    failureLimit=2,
    failureMode="consecutive",
    feedback={success="qteSuccess",miss="qteMiss",failure="qteFailure",gain=.4},
    prompts={
        {atMs=1000,windowMs=350,binding="light"},
        {atMs=1600,windowMs=250,binding="finisher"},
        {atMs=2200,windowMs=400,binding="grab"},
    },
},
```

`failureLimit` is optional, integer 1..32. Without it, missed prompts are reported but do not abort the sequence. `failureMode` is `consecutive` by default or `total`. A correct press resets consecutive misses; total misses remain counted. `failedIndex` identifies the prompt that crossed the limit. `qteFailed(context,index,totalMisses,consecutiveMisses)` fires once, followed by the callback's failure notification. `qteFinished` is reserved for reaching the normal sequence end. `qteResult` now also supplies the session as its fifth event argument; existing listeners can ignore that extra argument.

Load `ProjectYakuza/QTEFeedback` on clients for automatic feedback. The context must contain `player` and `action`, where `action.qte.feedback` maps success, tolerated miss and terminal failure to keys in that style's `sounds` table. Register those native sound events using supplied assets. `gain` is 0..1, default .4, and playback uses the combat Sounds volume. The final miss plays only terminal-failure feedback, avoiding two stacked failure cues. The module plays locally and uses the existing supported SFX networking; it adds no voice or audio asset.

The pure QTE engine still does not choose animations. A custom handler listens for failure or checks `session.failed`, then plays its own supplied ending and restores its owned flags. The built-in DoD paired handler accepts `qteFailure={animation="...",nodeValue="...",duration=...}` for an original recovery clip, limited to 10 seconds. It releases the victim, retains actor movement/protection through the recovery and skips further contacts. `deferFinalDamage=true` banks the final earned native hit until normal paired completion, preserving the victim animation. The server derives misses from its registered timing and accepted inputs, rechecks the failure policy, deduplicates the ending and rejects damage after failure. Future style backends must enforce their own registered policy in the same way.
