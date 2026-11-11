# Style-owned weapons

Available in Project Yakuza 0.44.0, Lua API 3. A weapon profile is an equipment view of an existing style. It is not another selector slot, inventory item or global weapon replacement.

## Object profiles and restored movement (0.75.0)

Bottles and the beer crate now have separate equipment views, bottle and crate, within DoD. The three ProjectYakuza.IntactBeerBottle/IntactWineBottle/IntactWhiskeyBottle IDs use original WPA one-handed blunt gestures with bottle grips; ProjectYakuza.BeerCrate uses original WPC bulky-object gestures. Both supply three lights, a standalone/queued heavy, ground strike and moving guard. Damage/condition/range remain native. As of 0.97.0, crate and bicycle ordinary attacks use the original Yakuza 5 WPC combo and overhead heavy, with one calibrated native contact per attack. The floor strike reuses the overhead heavy; see y5-object-attacks.json. Bottle Heat Actions remain bottle-exclusive.

Bat, blade, bottle and crate have corrected source ready/relaxed holds, native-legged weapon walking and Kiryu running/sprinting. The katana uses WPD rather than the mismatched WPN hold source. See [locomotion](LOCOMOTION.md), [motion provenance](weapon-motion-assets.json) and [validation](VALIDATION_0.75.0.md). Other styles and unmapped native items are unaffected.

## Sharp weapons (0.45.0)

Dragon of Dojima now also owns two distinct supplied-source blade profiles. Select DoD and equip the actual item; existing bindings apply. Each profile has three lights, a standalone/queued x1.25 heavy, a native-targeted ground strike, an upper-body source stance with native walking legs, and post-contact light quickstep cancels. Lights use x1 of the held weapon's damage. The sweeping-blade profile adds source guard entry/hold/hit/exit with native walking legs. The knife source set supplies no guard clips, so knife blocking is unavailable.

| Profile | Explicit supported B42 IDs (Base module) |
| --- | --- |
| knife (23) | HuntingKnife, HuntingKnifeForged, KitchenKnife, KitchenKnifeForged, SteakKnife, BreadKnife, FightingKnife, KnifeButterfly, KnifeFillet, KnifeParing, KnifePocket, KnifeShiv, KnifeSushi, LargeKnife, LargeKnife_Scrap, SmallKnife, SwitchKnife, CrudeKnife, LongCrudeKnife, MacheteKnife, StoneKnifeLong, FlintKnife, RailroadSpikeKnife |
| blade (13) | Katana, Machete, Machete_Crude, MacheteForged, ShortSword, ShortSword_Scrap, Sword, Sword_Scrap, CrudeShortSword, CrudeSword, MeatCleaver, MeatCleaverForged, MeatCleaver_Scrap |

Heavy axes, spears, firearms and unmapped items retain native combat. These profiles belong only to DoD; other styles must explicitly register their own mappings. Item models, critical/close-kill handling on primary hits, condition/durability and native weapon sounds remain PZ-owned. No item script, blade model, texture or sound is replaced. Existing unarmed special moves still require the style item, as with the bat profile.

Supplementary victims now use the real registered weapon's declared maximum reach, bounded to .25â€“1.65 world tiles by the existing path/scan budget. Primary collision is unchanged. SP extras copy no more than that weapon's current maximum damage (hard cap 20); this prevents a native primary-only knife jaw kill/critical from becoming an area instant kill. Server extras derive damage from the real item's average min/max, bounded to 20 before the move/Extreme multiplier, retaining x1/x1.25 weapon attack rules instead of the old unarmed 2-point cap. Primary native hits are never replayed; native durability stays native. Different armour/critical outcomes can still make primary and secondary damage differ.

`Weapons.hitRange(item)` and `Weapons.extraDamage(item,observedPrimaryDamage)` implement those supplementary limits. Only recognised real combat weapons use them; unarmed token rules are unchanged. Pending SP extras also retain exact held-item ownership, matching MP's existing swap protection.

Six WPB short-blade clips and ten WPD sweeping-blade/guard clips were retargeted with explicit authorization. See blade-assets.json for every original GMT/BEP/rig/grip/output hash and frame range. All source frames are retained. PZ's native knife finger grip is used for short blades and native bat grip for long blades; Yakuza runtime prop IK is not imported. Importer/selector checks do not prove live grip appearance. Restart with 0.45.0 on server and all clients.

## Playing Dragon of Dojima with a weapon

Select Dragon of Dojima, then equip a supported real weapon normally. You can also select Dragon of Dojima while already holding a supported weapon: it stays in your hands. The style, HUD, music, heat gains and optional combat voices remain Dragon of Dojima's. A fresh character holding a bat does not opt in automatically: select the style explicitly first.

While aiming, use the existing light binding (LMB by default) for three source weapon attacks, heavy/finisher (MMB) for the heavy swing, X for a moving weapon guard, and Space plus direction for the existing quota-limited quickstep. Heavy works alone or queues after a light; no charged or double weapon heavy in this first profile. Ordinary floor targeting uses the source weapon ground strike. Lights can cancel into quicksteps after their native post-contact markers, using the existing short input buffer and three-per-15-second quota.

Supported B42 item IDs: Base.BaseballBat, Base.BaseballBat_Crafted, Base.BaseballBat_Metal, Base.BaseballBat_Nails, Base.ShortBat, Base.ShortBat_Nails, Base.Nightstick, Base.MetalBar, Base.MetalPipe, Base.BoneClub, Base.LargeBoneClub, Base.LongSpikedClub. Other items, broken weapons, firearms and other styles retain native weapon combat unless explicitly registered by their author.

The actual item provides its held model, reach, native primary damage calculation, impact/swing audio and native condition/durability handling. Lights use its damage at x1; heavy temporarily uses x1.25. End, cancellation and equipment changes restore the item's saved damage values. The framework neither repairs condition nor applies a second manual durability charge. It does not create/re-skin weapons or replace their item scripts. Hit sparks and heat gain work on native weapon hits. Base weapon audio remains Zomboid's own audio. Configured heavy and ground strikes add one restrained supplied Y6 accent per swing; lights add no extra punch layer.

This armed profile supports lights, a standalone heavy, ground strikes, guard, quicksteps and the base style-selection entry. Unarmed Tiger Drop, charges, double finishers, running/quickstep strikes, taunt and Extreme Heat activation are unavailable while holding it; equip the existing style item to return to the unarmed moveset. Changing equipment ends any running Extreme Heat session, as before. Stored heat remains. Disable style keeps an ordinary weapon equipped. Grabs remain unavailable in armed profiles; DoD enables them while unarmed.

## Registering a profile for an addon

Require ProjectYakuza/Registry; it loads ProjectYakuza/Weapons. Register the base style first, then call:

```lua
ProjectYakuza.Weapons.register("myaddon.style", {
    id="club", items={"MyAddon.Club"}, attackSpeed=1,
    standaloneHeavy=true, quickstepCancelLights=false,
    lightAttacks={
        {animation="MyAddon_ClubLight",nodeValue="myaddon_club_light",duration=1,impact=.3},
    },
    actions={finisher={enabled=true,variants={default={
        enabled=true,animation="MyAddon_ClubHeavy",nodeValue="myaddon_club_heavy",
        duration=1.2,impact=.4,damageMultiplier=1.25,
    }}}},
})
```

These example clip names are placeholders: the addon must supply its own permitted animation assets, owner selectors and registered event-free MP observers. Registration alone does not create animations. Explicit full item IDs prevent category/name guesses from taking over unrelated items. IDs map within the owning style only; the same weapon can have a different profile in another style.

`lightAttacks`, optional `groundAttacks`, and `actions` replace the base style's corresponding move collections. All use the existing validated move contracts. Only styleEntry inherits from the base style when omitted; set actions.styleEntry=false to disable it or provide a replacement. Other actions must be explicitly supplied or reused, such as quicksteps. `attackSpeed` defaults to 1. `quickstepCancelLights` defaults false; cancelling lights still need their owner marker events. `standaloneHeavy=true` routes heavy input to `actions.finisher.variants.default`, including a single queued heavy behind a light. Omit it for ordinary branch-based finishers. No weapon charging is enabled by this DoD profile; authors can define their own complete action slots and native clips.

`hitResponses`, `juggling` and `sounds` are optional profile-owned configuration. Sound omission disables style-specific sound layering for that profile; native weapon sounds remain. Weapon views disable Tiger Drop and custom enemy reaction clips by default. Base style UI, selector icon, music, heat opt-in and voice settings are inherited. A profile is not a separately selectable style. Do not mutate registered tables while playing or replace a base style definition after registering its profiles.

Registration rejects duplicate profile IDs, item IDs already mapped within the style, malformed moves, invalid booleans, and distinct moves shadowing an existing nodeValue under the same base style ID. Identical shared action objects can deliberately reuse their nodes. Validation is transactional: a rejected profile does not publish item mappings.

## Public helpers and state

- `Weapons.profile(styleId,item)` returns a profile ID or nil; zero condition does not qualify.
- `Weapons.view(baseStyle,profileId)` returns the cached view or base style.
- `Weapons.matches(player,item)` requires that exact primary-hand item and an explicitly selected compatible style.
- `getStyle(id)` and `listStyles()` keep base identity. `getPlayerStyle(player)` returns the current equipment view under the same style ID; `view.weaponProfile` identifies the active profile.
- `isEquipped(player)` accepts the style item or a registered, non-broken real primary weapon. Multiplayer still requires equipment acknowledgement.
- `isCombatWeapon(player,item)` recognizes the style item or a matching real weapon.
- `weaponProfileRegistered(styleId,profileId)` fires after a profile validates and publishes.
- `weaponProfileChanged(player,profileId,item)` fires on locally observed equipment changes; empty string means no active weapon profile.

`Weapons.sync(player)` observes the primary item/style/profile and clears combo/action ownership on change, restores scoped damage, resets ground variant, invalidates stale MP readiness and writes ProjectYakuzaWeaponProfile only when changed. There are no world/zombie scans for equipment detection.

Owner selectors must test ProjectYakuzaActive, ProjectYakuzaStyle and ProjectYakuzaWeaponProfile for shared animation groups. Use unique nodeValue IDs and source contact marker/collision events. Walking idle/guard should use upper-body/prop masks so native legs remain in control. See weapon-assets.json for the supplied-source conversions and BEP contact starts.

## Multiplayer and fidelity limits

The normal launcher/Lua-only MP flow remains. The server verifies the actual inventory ID, item type/condition and owning style; acknowledges it without replacing it with a token; derives the equipment profile itself; and accepts only matching profile moves/clips. Peers receive weaponProfile and event-free observer selections. Late acknowledgements cannot exchange a newly equipped weapon, and swings retain exact item ownership for extra victims. Extra-target damage comes from the server's real held weapon, subject to the supplementary damage/range/count limits described above. Primary native hits are never replayed. Server and clients must all install the same current version.

The ten original blunt animations retain the original supplied WPA frames retargeted to B42, with native bat finger grip and in-place horizontal root. The shared blunt profile does not reproduce Yakuza's runtime prop/IK constraints. Native importer/selector checks verify files and isolation, not live grip appearance or multiplayer timing. PZ has not been launched for this release; test those in game after a full restart.

## Native prop attachment repair (0.47.0)

B42 prop bones are parented to Bip01, not directly to hands. The 26 weapon clips and four quicksteps now animate both props from their corresponding hands using native authored bat/knife grip offsets. Body/finger channels and skeleton hierarchy remain identical. The new normal-heavy clip uses the same correction. See prop-attachment-repair.json for every output/native grip hash and normal-heavy-assets.json for the supplied heavy source. Native FK tests check 2,568 hand/prop pose pairs. Blends, walking overlays and custom player proportions still require in-game visual assessment.

Moving from the style item to a supported weapon keeps DoD selected and deletes unused temporary items. Unequipping the real weapon returns to the unarmed style without replaying entry. Manually unequipping the style item disables DoD and deletes it. Top selector removal keeps real weapons equipped.

## Attack endurance (0.60.0)

Styles can opt in with exertion={}, weapon profiles can override that table, and individual moves can provide enduranceCost. Actual attacks publish attackCommitted once; the local owner applies native fitness/trait scaling and reports attackEnduranceSpent. Hits, remote playback, charge holds and queue requests do not charge again. See [Exertion](EXERTION.md) for defaults, validation, custom actions and lifecycle.

## Optional Heat attack speed (0.61.0)

Addon styles can opt in with heatAttackSpeed={max=1.25,power=1,useExtremeFuel=false}, with per-weapon overrides. The curve is sampled per committed attack, applies to the existing native speed variables and is bounded/replicated in MP snapshots. Fixed-speed timed clips are not automatically retimed. Dragon of Dojima does not enable this feature. See [Heat-based attack speed](HEAT_ATTACK_SPEED.md) for validation, timing and authoring contracts.

## Impact feedback and safe holds (0.62.0)

Set `impactFeedback="blunt"` or `impactFeedback="blade"` on a weapon profile to replace the base style's visual preset. Omit it to inherit the style's preset; `false` selects legacy unarmed visuals. The base style may also declare `"unarmed"`. Unknown values fail style/profile validation. These presets work with the existing `hitEffects="yakuza6"` renderer; blood additionally requires `bloodEffects="yakuza6"`. Other renderers remain untouched.

DoD fists keep their existing punch/kick sounds, sparks and blood. Bats/clubs use a seven-particle warm burst and a small shock ring on heavy hits, with 15% smaller blood. Knives/long blades use a short three-particle pale glint without the blunt shock ring and 15% larger blood, playing the same sixteen source frames over 360 ms. Strong hits retain their additional scale. Charged and guard effects keep their existing explicit particle sets. All bursts reuse existing unchanged textures, ordinary alpha blending, victim-centred world anchoring and the existing pooling/burst budgets. The selected family is captured when the burst starts.

Profile `sounds.heavyImpact` and `sounds.groundImpact` configure optional confirmed-hit accents. `finisher` is the heavy fallback; a missing ground cue falls back to the heavy cue. Native impact/swing sounds remain owned by the actual item and are never rewritten. Weapon lights have no added sound layer. The accent plays once per committed swing, including multihits, at .32 gain for blunt/other profiles or .25 for blades through the existing mod Effects sound category. DoD uses its already-installed Y6 HeavyFinisher pool for blunt accents and its existing Y6 Finisher cue for blades. These are reused cues, not newly extracted weapon recordings. Shuffled pools retain their registered MP clip selection; ordinary native emitter cues retain their existing route.

The server derives primary/supplementary impact family and heavy strength from the registered equipment view. Clients cannot nominate a visual family in an attack request. Observer bursts use the server's captured family even if the displayed equipment has since changed; normal duplicate suppression still applies. There are no new polling loops or attack/damage changes.

The previous native-only ready/run workaround is superseded by the repaired supplied-motion selectors described above. Knife carry and ready clips remain native. Disabled older source reference assets remain available, while active bat/blade selectors use the corrected source motions. [Selector provenance](weapon-pose-selectors.json) records the updated paths and hashes.

## Per-style Heat rules (0.64.0)

Optional `heatConfig` sets per-style gain, normal/Extreme drain and 1..32 stock capacity. Weapon profiles inherit and merge field overrides. Taunt rewards, stock-priced actions, the built-in orb row, custom UI context and server activation protection use the effective capacity. Omitted configuration leaves DoD unchanged. See [Heat configuration](HEAT_CONFIGURATION.md) for bounds, defaults, APIs, stock retention and network requirements.


Base.Katana now supports the DoD-exclusive [katana Heat Action](HEAT_ACTIONS.md). Other blade items retain their existing combos/heavies. Its supplied motion preserves the complete paired recovery and repairs native hand-to-weapon offsets.


Version 0.71.0 adds three separate [intact bottle weapons](BOTTLE_WEAPONS.md) and their DoD-exclusive original Heat Action. Use the same rebindable Heat Action input while physically holding RMB, outside combos. Ordinary drink bottles are unchanged.
