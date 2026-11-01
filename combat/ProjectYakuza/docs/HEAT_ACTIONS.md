# Heat Action lifecycle

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

The katana definition lives in the DoD blade weapon view. motionId selects its registered numeric source paths. animation and targetAnimation name the original retargeted clips. contacts contains 1..32 increasing finite atMs values inside duration; damageMultiplier is 0..10. Zero damage gives presentation only. The native animation track supplies time. Repeated updates and replayed packets cannot duplicate a contact, and updates more than 120 ms late skip it. The final fall contact deals 1.5 times the equipped katana's unscaled average base damage; earlier slash/punch/thrust timings preserve the full victim animation. No camera override is added.

useExtremeFuel allows stock-priced actions to use fuel while Extreme Heat is active. ProjectYakuza.actionHeat(player,action) returns available resource and whether it is fuel. The request lifecycle spends it once after a successful start. Unarmed Heat Rush keeps its eight-input eligibility and original QTE bindings.

The supplied source archive, exact actor/victim role bindings, scene contact timings and clip hashes are documented in [katana provenance](katana-heat-assets.json). The generic protection helper does not supply targeting, paired motion, damage, sounds or new assets. New styles still own their action handler, native animator definitions and scoped network validation; use the existing [action lifecycle](ACTIONS.md) and [QTE engine](QTE.md) when appropriate.
