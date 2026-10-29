# Light-attack quickstep cancels — 0.43.0

Dragon of Dojima can cancel any of its four light attacks into the existing quickstep. While aiming, press the bound quickstep input (Space by default) plus a movement direction; no direction requests a backstep. Light windup/collision must complete first. Finishers, charged strikes, ground attacks, running attacks, quickstep attacks, taunts and entry are not cancellable through this route.

## Timing and handoff

Four owner-node events emit ProjectYakuzaQuickstepCancelReady one source frame after each light's collision marker: 7/30, 9/47, 12/42, 12/47 of the original clips. The hit marker must also match the current move. This permits both landed and missed light strikes to cancel after their attack window; confirmed damage is not required. No cancel input lets the full animation play normally.

A fresh input can wait up to 150ms for the marker. Inputs earlier than that expire rather than producing a late dodge. Holding the key does not repeat. Before releasing recovery, the controller checks equipment, aiming, local action ownership, status, cooldown, the three-in-15-seconds quota and the first movement segment's wall/floor collision. Unavailable dodges do not intentionally cut the attack short.

On acceptance, buffered light/finisher input is cleared, native melee submission is gated, and ActiveAnimFinishing requests the same native recovery exit already used by combo handoffs. The controller waits until the actual native attack flags and SwipeStatePlayer ownership are released before resetting the old combo and requesting the existing quickstep action. It does not teleport the native state machine or submit another attack. Direction is re-evaluated relative to current facing, using the captured world movement vector.

The native handoff expires after 400ms. Interruption, invalid status/style/equipment, pause, a different swing, reset, save/menu cleanup, quota/cooldown or a newly blocked path clears the pending input and restores its input gate. A queue failure releases ownership instead of retrying indefinitely. If the native exit has already been requested, a later queue failure cannot replay the interrupted light's remainder. No movement/invulnerability is granted by the cancel itself.

The quickstep is charged against quota only when its existing native timed action starts. All existing quickstep distance, cooldown, MP position validation and the one-quickstep-attack entitlement remain unchanged. A held LMB does not become a fresh quickstep attack; press it again to use that feature.

## Future styles

Opt in with style.quickstepCancelLights=true (omission/false retains previous behavior). For each eligible light, provide quickstepCancelAt as a 0..1 source-clip fraction and an owner animation event:

```xml
<m_Events>
  <m_EventName>SetVariable</m_EventName>
  <m_TimePc>YOUR_SOURCE_FRACTION</m_TimePc>
  <m_ParameterValue>ProjectYakuzaQuickstepCancelReady=YOUR_MOVE_NODE_VALUE</m_ParameterValue>
</m_Events>
```

The native hit marker ProjectYakuzaHitMarker must already equal the same node value. Place the cancel event after the collision event, preferably at least one source frame later. The metadata is declarative: the framework waits for the actual native event rather than estimating pose progress from wall time. Do not copy events into event-free MP observer nodes. Runtime clears this marker on each swing/reset.

Quicksteps.requestLightCancel(player,direction,{dx=...,dy=...,shove=true}) uses the same validation as the bound input. Quicksteps.isCancelling(player) means native handoff in progress, not early input buffering. clearLightCancel(player) releases only that request. Normal callers should use the bound input; the existing action handler remains responsible for dodge movement and quota.

No animation/image/audio data were edited or added. Only four owner XML events and code changed. Offline native node parsing and state-handoff fixtures pass; PZ was not launched, so final feel and live MP transition quality still need gameplay verification.
