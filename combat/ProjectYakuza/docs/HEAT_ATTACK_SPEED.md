# Optional Heat-based attack speed (0.61.0)

This feature is available to addon styles and is disabled unless explicitly configured. Dragon of Dojima and all its existing weapon profiles remain unconfigured and retain their existing normal/Extreme speeds, move definitions and assets.

## Style configuration

```lua
heatAttackSpeed={max=1.25,power=1,useExtremeFuel=false}
```

The style must also use the framework's Heat system (heat=true). max is required and ranges from 1 to 2: 1.25 means up to 25% faster than the authored base speed. power is optional, defaults to 1 and ranges from 0.25 to 4. Higher powers concentrate the gain near full Heat; lower powers give more gain at low Heat. useExtremeFuel is an optional boolean, default false. Unknown keys and nonfinite values are rejected during style registration.

The curve is 1 + (max - 1) * (clamp(heat,0,100) / 100)^power. With max=1.25 and power=1, empty/half/full stored Heat give x1/x1.125/x1.25. These are speed-up multipliers; tune attackSpeed separately for your desired base speed. Omit heatAttackSpeed or set it to false for no additional Heat scaling.

By default Extreme Heat does not receive this curve, retaining the framework's existing mode speed bonus. Set useExtremeFuel=true to use remaining Extreme fuel instead of stored Heat during the mode. The curve then multiplies the existing mode bonus once. It samples before the attack's fuel cost. The new Heat multiplier remains captured for the current attack; existing activation/depletion of Extreme Heat's own bonus retains its normal lifecycle.

A weapon profile can override heatAttackSpeed with its own validated table or false. Without an override it inherits the base style setting. This does not modify weapon assets or another style's configuration.

## Playback contract

Heat.onSwing samples the curve once when an attack commits, including a miss. Later hit rewards, passive Heat loss and fuel drain do not resample that captured value. The next attack uses the updated Heat/fuel. End-swing and style/equipment cleanup discard the capture. There is no new polling loop and this does not speed up walking/running movement.

The curve scales the existing ProjectYakuzaCombatSpeed, ProjectYakuzaChargedHeavySpeed and ProjectYakuzaRunningKneeSpeed animation variables. Your supplied native owner and observer nodes must use the appropriate variable in m_SpeedScale. Clips with literal/fixed speed scales remain at their authored speed. Do not change source keyframes or bake faster motion to enable the feature.

Native animation events and source-track-driven hit/cancel effects follow actual clip phase. The built-in fallback whoosh schedule and source-phase lead account for the captured Heat multiplier. Canonical move.duration stays in authored base-speed units; don't rewrite it each time Heat changes. This curve only accelerates, so existing upper-bound watchdog/lease durations remain conservative.

Timed actions, charging holds, paired/QTE scenes, dashes, guards, entry/activation and other fixed-speed clips are not automatically retimed. A custom timed attack can sample through Heat.onSwing and use the speed variables, but its handler must schedule contacts, movement and completion from actual animation phase and clear its capture on exit. Fixed-speed source/QTE actions should keep their authored timing. Charge-hold recognition windows are unchanged; variable-speed charged release clips can use the captured multiplier.

## API

- ProjectYakuza.HeatSpeed.valid(config) checks the optional authoring table.
- HeatSpeed.factor(style,storedHeat,fuel,extreme) previews the bounded curve without mutating player state; disabled/non-Heat styles return 1.
- HeatSpeed.allowed(style,value,extreme) validates a transmitted factor against the registered configuration, including opt-out/default Extreme policy.
- ProjectYakuza.Heat.attackHeatMultiplier(player) reads the captured curve component, or 1 outside a captured swing.
- Heat.playback(player,extreme,optionalHeatFactor) updates the three native speed variables. It preserves the capture unless an explicit valid factor is supplied. Prefer the normal onSwing/endSwing lifecycle for attacks.

## Multiplayer

Opted-in active clips advertise attackHeatSpeed in existing state snapshots. The server bounds it to the current style/weapon configuration and rejects factor changes within the same active clip/swing/action. Observers use that captured factor rather than recalculating it from later Heat gains. Invalid/nonfinite/out-of-range factors are rejected on both sides. An unconfigured style keeps the old packet shape and playback values.

Heat remains client-owned, as in the existing framework; this is bounded playback replication rather than a new server-authoritative Heat model. Use matching addon definitions and framework versions on clients/server. Authoring the curve does not create compatible animation nodes by itself: supply your matching approved owner/observer assets and use the documented animation variables.
