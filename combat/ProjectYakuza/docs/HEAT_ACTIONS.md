# Paired Heat Actions

The v1 player build includes unarmed ground, wall/open-space grab and Extreme Heat rush scenes, plus the supported vanilla bat, katana and knife scenes. Custom-object Heat Actions in the development source are excluded from player packages.

## Reference-style activation

Hold physical RMB and press the configured Heat Action input, default MMB, outside an active combo or follow-up window. A complete Heat stock is enough for the stock-priced scenes. Weapon scenes require their registered equipped item and an eligible standing target. Base.Katana has the katana scene; other blade-profile items do not automatically receive it. Registered bat and knife item lists are documented in [Weapons](WEAPONS.md).

With an unarmed zombie grab active, the same input chooses the wall scene beside a valid wall or the open-space scene when there is enough clear space. Near a living downed zombie it can select the unarmed ground action. [Grabs](GRABS.md) describes held-target ownership. Armed profiles do not inherit unarmed grab/ground actions.

Supported weapon actions use equivalent active fuel when Extreme Heat is enabled. The paired punch rush has separate eight-light eligibility and displayed Light / Heavy / Grab QTE prompts. The six nineteen-frame sections run at their original speed, with 633 ms press windows; failure enters the original kick ending.

## Payment, damage and playback

Built-in paired actions pay once at the first confirmed native playback sample. Missing animation, failed startup or cancellation before that point does not consume resource. Cancellation after payment retains the committed cost. `HeatRules.canAfford` uses the same small float tolerance as the stock counter.

The built-in controllers own native playback through their action lifecycle rather than a cancellable inventory queue entry. Death, invalid actors, server aborts and framework/world cleanup still terminate the action and restore owned state. Pose and effects follow native animation phase. Server contacts own multiplayer health changes; observer feedback does not apply damage again.

[Scene contracts](HEAT_SCENES.md) map source damage, sound, voice and blood events independently. [Presentation](HEAT_ACTION_PRESENTATION.md) handles sound starts and victim anchors. [Damage](HEAT_ACTION_DAMAGE.md) applies nonlethal contacts immediately and holds lethal settlement through paired recovery. Per-contact limb trails follow the striking arm or leg, including the katana's left punch and the knife's right kick.

The ground scene aligns its original sound's attack with the frame-30 contact: playback starts at 875 ms and the visual contact occurs at 1000 ms. Its single existing impact uses the victim-head anchor. Confirmed Heat Action contacts apply a short cool full-viewport tint and bounded local camera shake. The UI remains outside the camera motion. Chromatic aberration and imitation chromatic sparks are not included. Extreme Heat impacts retain the existing blood effect.

## Protection and placement

Playback temporarily grants invulnerability and zombie-targeting protection while preserving prior flags. Completion restores invulnerability immediately and targeting after the configured grace, 500 ms by default. The grace is not extra invulnerability. Pause is excluded from watchdog time. Multiplayer uses scoped target protection rather than enabling ghost mode for the owner.

Ordinary paired placement checks bounded nearby offsets, both paths and wall clearance. Wall actions use their selected wall geometry. The server validates ownership, target state, resource, range and placement independently. A blocked placement refuses activation.

## Implementing a style's paired action

Register the action under the appropriate `heatAction`, `grabHeat` or `groundHeat` kind. Supply native actor/victim nodes and animations, paired paths under `ProjectYakuza.PairedMotions`, a `motionId`, duration, resource cost and authored contacts. A ground scene additionally declares `groundHeat=true`; a held-target scene declares `grabHeat=true`. Arbitrary clips still require a compatible controller and authoritative target protocol.

`useExtremeFuel` opts a stock-priced action into active fuel payment. `ProjectYakuza.actionHeat(player,action)` reports the selected resource. Built-in paired handlers call `payActionHeat(context)` only after native playback is confirmed. Custom handlers must follow their own [action lifecycle](ACTIONS.md) and must not debit a resource a second time.

## Reusable protection helper

Custom handlers can use the shared protection lease with the same owner object at start and finish:

```lua
local protection=ProjectYakuza.HeatActions
protection.begin(player,owner,{duration=4.5,targetGraceMs=500})
protection.finish(player,owner)
```

Call `begin` only after playback starts, and `finish` from every completion or interruption path. A stale owner cannot unlock a newer action. The helper supplies protection only; it does not implement targeting, staging, damage, motion or networking.
