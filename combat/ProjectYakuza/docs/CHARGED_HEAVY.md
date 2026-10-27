# Charged heavy attacks

Dragon of Dojima: aim and tap-release the finisher binding (default MMB) for the usual finisher/double finisher. Holding 350 ms while free enters Kiryu's supplied Yakuza 6 charge loop. Release requests the strike after a minimum 350 ms in that pose; a 3.5-second pose timeout releases automatically. A valid Tiger Drop on the initial press takes priority. Holding during a light waits until the player is free; releasing before charge actually begins retains the finisher branch.

Charge locks walking, running, native attacks and root displacement. It grants no protection. Getting hit, losing aim, death, unequipping or an invalid character state cancels it and restores captured movement flags. Failed/missing native playback cancels rather than granting a strike. Pause does not advance hold-animation timers. Completion produces one short-lived handover; one accepted native submission consumes it. Rapid clicks, duplicate completion or duplicate swing callbacks cannot mint another strike. A rejected native submission may retry within the 600 ms handover window.

The native release uses `P_KRU_BTL_SUD_ath_hvy_chg_en.gmt`, following the matching `..._lp.gmt` pose. It plays at 1.35 speed, checks one MeleeSwing collision at original frame 10/55 and uses x2 base token damage before existing heat modifiers. It opens no double-finisher branch. Existing native targeting, armor, walls, hit events, multihit cap and MP authority remain in effect. Impact timing/appearance still need live visual verification.

## Addon opt-in

```lua
actions={
    heavyCharge={enabled=true,animation="MyMod_ChargeLoop",duration=3.5,
                 holdMs=350,minChargeMs=350},
    chargedHeavy={enabled=true,animation="MyMod_ChargedStrike",
        nodeValue="my_mod_charged",duration=1.2,speed=1.35,impact=.2,
        damageMultiplier=2,chargedHeavy=true,fullBody=true},
}
```

Provide your own compatible clips/native XML nodes. The action node matches `PerformingAction=MyMod_ChargeLoop`, loops, owns the full body and emits `ProjectYakuzaChargeClip=started` at Start. The melee node matches your style/move and emits the standard clip/hit markers, exactly one AttackCollisionCheck/MeleeSwing, native AttackAnim and BlockMovement start/end, and end delay reset. Use `ProjectYakuzaChargedHeavySpeed`: Heat.playback resolves the action's speed and existing Extreme Heat factor. Do not add damage in the charge action or a timer. Register event-free observer nodes/catalog entries as described in [Multiplayer](MULTIPLAYER.md); the built-in builder includes DoD's new nodes.

Lifecycle events: heavyChargeStarted(player,style,move), heavyChargeStopped(player,completed), chargedHeavyStarted(player,style,move), chargedHeavyFinished(player,move). Existing heavy CVF cues/swing/confirmed-hit sounds are reused; no audio recording was created or voice-pack file changed. Other styles keep press-triggered finishers unless heavyCharge is enabled.

## Visual assets and limits

`charged-heavy-assets.json` records both original GMT hashes, imported clip hashes and the original Y6 e_f_0006_spark01.dds export. ChargeSpark.png is an exact 16x32 RGBA decode: no generated frame, resize or upscale. Six small blue-tinted world instances animate around the lead-hand/upper-body area while charging; confirmed charged hits add eight bounded spark instances to the existing core. Placement follows facing in world space, not a new per-bone attachment API. Observer effects use the same particles; server impact metadata identifies the charged strike. Hooks exist only while particles are live and instances are disposed on completion/stale actors/world exit.

Extreme Heat's native blue silhouette outline is a separate subtle approximation of the reference shader. It applies through the existing aura lifecycle and restores the previous packed ABGR color/flag. Existing game/addon highlights are respected. No outline texture, generated visual or Java launcher is required. The native API and flags can be checked offline, but final GPU appearance requires an in-game test.

## Four charged first finishers — 0.32.0

After 1–4 lights, holding heavy selects that branch's unique original wind-up and matching first-finisher release. These are exact frame splits of the supplied P_KRU_BTL_SUD_ath_01/02/03/04_fin_md.gmt motions: wind-up frames 0–10/16/12/16 respectively, then release from the same pose through source end. The wind-up is non-looping and holds its final source pose while MMB remains held. No new poses or animation frames were invented. Minimum holds wait for the wind-up endpoint; source/hash/range metadata is in charged-finisher-assets.json.

Standing/no-light charged heavy keeps its original generic charge loop/release. All charged releases retain x2 base damage, native collision and the existing multihit cap. First-finisher releases preserve their branch and can lead into the matching ordinary double finisher. Link/contact markers are rebased to the retained source frames.

**Second finishers cannot charge.** A fresh heavy press during a first finisher, queued first finisher or valid follow-up window immediately requests its normal second finisher. Keeping the key held cannot start a new charge afterward. The public heavyCharge handler also rejects that follow-up window. A pending charge ticket records its variant/branch and cannot be substituted for another branch.

### Branch-aware authoring

Styles may use `heavyCharge.variants={default=...,after_1=...,...}` and matching `chargedHeavy.variants`. Keep heavyCharge.holdMs and chargedHeavy.speed on the slots. Each branch wind-up/release declares chargeBranch=<light index>; the release additionally declares chargedHeavy=true and chargedFinisher=true. Neutral variants omit chargeBranch/chargedFinisher. The default variant is used without a valid light branch. Preserve the source endpoint pose when splitting clips, and provide the usual full-body native action/melee nodes. The charged release must rebase native contact and double-link markers; it must not contain an additional collision in the hold animation. Register event-free MP observers for every new node. Existing non-variant charge styles remain supported.
