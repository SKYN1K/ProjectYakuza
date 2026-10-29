# Style-owned weapons

Available in Project Yakuza 0.44.0, Lua API 3. A weapon profile is an equipment view of an existing style. It is not another selector slot, inventory item or global weapon replacement.

## Playing Dragon of Dojima with a weapon

Select Dragon of Dojima, then equip a supported real weapon normally. You can also select Dragon of Dojima while already holding a supported weapon: it stays in your hands. The style, HUD, music, heat gains and optional combat voices remain Dragon of Dojima's. A fresh character holding a bat does not opt in automatically: select the style explicitly first.

While aiming, use the existing light binding (LMB by default) for three source weapon attacks, heavy/finisher (MMB) for the heavy swing, X for a moving weapon guard, and Space plus direction for the existing quota-limited quickstep. Heavy works alone or queues after a light; no charged or double weapon heavy in this first profile. Ordinary floor targeting uses the source weapon ground strike. Lights can cancel into quicksteps after their native post-contact markers, using the existing short input buffer and three-per-15-second quota.

Supported B42 item IDs: Base.BaseballBat, Base.BaseballBat_Crafted, Base.BaseballBat_Metal, Base.BaseballBat_Nails, Base.ShortBat, Base.ShortBat_Nails, Base.Nightstick, Base.MetalBar, Base.MetalPipe, Base.BoneClub, Base.LargeBoneClub, Base.LongSpikedClub. Other items, broken weapons, firearms and other styles retain native weapon combat unless explicitly registered by their author.

The actual item provides its held model, reach, native primary damage calculation, impact/swing audio and native condition/durability handling. Lights use its damage at x1; heavy temporarily uses x1.25. End, cancellation and equipment changes restore the item's saved damage values. The framework neither repairs condition nor applies a second manual durability charge. It does not create/re-skin weapons or replace their item scripts. Hit sparks and heat gain work on native weapon hits. Weapon audio remains Zomboid's own audio rather than layered punch sounds.

This initial armed profile supports lights, a standalone heavy, ground strikes, guard and quicksteps. Unarmed Tiger Drop, charges, double finishers, running/quickstep strikes, taunt, combat entry and Extreme Heat activation are unavailable while holding it; equip the existing style item to return to the unarmed moveset. Changing equipment ends any running Extreme Heat session, as before. Stored heat remains. Disable style keeps an ordinary weapon equipped. Grabs remain disabled.

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

`lightAttacks`, optional `groundAttacks`, and `actions` replace the base style's corresponding move collections. All use the existing validated move contracts. There is no implicit action inheritance: explicitly reuse a base action object when wanted, such as its quicksteps. `attackSpeed` defaults to 1. `quickstepCancelLights` defaults false; cancelling lights still need their owner marker events. `standaloneHeavy=true` routes heavy input to `actions.finisher.variants.default`, including a single queued heavy behind a light. Omit it for ordinary branch-based finishers. No weapon charging is enabled by this DoD profile; authors can define their own complete action slots and native clips.

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

The existing normal launcher/Lua-only MP flow remains. The server verifies the actual inventory ID, item type/condition and owning style; acknowledges it without replacing it with a token; derives the equipment profile itself; and accepts only matching profile moves/clips. Peers receive weaponProfile and event-free observer selections. Late acknowledgements cannot exchange a newly equipped weapon, and swings retain exact item ownership for extra victims. Extra-target damage comes from the server's real held weapon, subject to the existing supplementary damage/range/count limits. Primary native hits are never replayed. Server and clients must all install 0.44.0.

All ten animations retain the original supplied WPA frames retargeted to B42, with native bat finger grip and in-place horizontal root. The shared blunt profile does not reproduce Yakuza's runtime prop/IK constraints. Native importer/selector checks verify files and isolation, not live grip appearance or multiplayer timing. PZ has not been launched for this release; test those in game after a full restart.
