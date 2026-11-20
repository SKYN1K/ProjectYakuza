# Project Yakuza

A Lua combat framework for **Project Zomboid Build 42**, designed for independent fighting-style add-ons. Styles register their own moves, actions, controls, weapon profiles, effects and multiplayer presentation. Dragon of Dojima is the included reference implementation.

**[Download v1](https://github.com/SKYN1K/ProjectYakuza/releases/tag/v1)** · Lua API **3** · Multiplayer protocol **2** · Version **1.0.0**

## Create a style

1. Install the framework's named **B42 install ZIP** from the release page. Enable Project Yakuza in PZ. Install the same framework and add-on versions on the server and every client.
2. Clone or download this repository for its authoring tools and [starter add-on](combat/ProjectYakuza/templates/StyleSubmod). The player ZIP contains runtime files only.
3. Copy the starter to a separate mod folder. Activate `42/mod.info.example`, the Lua examples and the animation-node XML examples by removing `.example`. Keep `common/` present and empty; exclude the starter README and inactive examples from your published add-on.
4. Give the mod, style, actions, bindings and animation nodes unique identifiers. Keep `require=ProjectYakuza` in your add-on's `42/mod.info`.
5. Register the style in shared Lua and provide matching native animation nodes. Assign it to a slot through the style wheel's bottom settings slot, then select that slot to equip it.

A minimal shared definition looks like this:

```lua
require "ProjectYakuza/Registry"
assert(ProjectYakuza.API_VERSION>=3,"This style requires Project Yakuza API 3")
ProjectYakuza.registerStyle({
    id="my_mod.my_style",
    name="My Style",
    description="An independent fighting style.",
    attackSpeed=1,
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

The definition alone does not create a working attack. Match the style ID and `nodeValue` in the starter XML, use a playable PZ animation, and place one native collision event at the strike. Raw GMT files cannot be played directly. The starter also demonstrates a separate, non-damaging custom action with its own binding and cleanup.

## Authoring guides

| Task | Guide |
| --- | --- |
| Build and register your first style | [Style authoring](combat/ProjectYakuza/docs/STYLE_AUTHORING.md) |
| Find fields, functions and events | [Lua API reference](combat/ProjectYakuza/docs/API_REFERENCE.md) |
| Implement a custom action/controller | [Action lifecycle](combat/ProjectYakuza/docs/ACTIONS.md) |
| Define native nodes, collisions and markers | [Animation contracts](combat/ProjectYakuza/docs/ANIMATIONS.md) |
| Add weapon-specific move sets | [Weapon profiles](combat/ProjectYakuza/docs/WEAPONS.md) |
| Add grabs, paired Heat Actions or QTEs | [Grabs](combat/ProjectYakuza/docs/GRABS.md), [Heat Actions](combat/ProjectYakuza/docs/HEAT_ACTIONS.md), [QTE API](combat/ProjectYakuza/docs/QTE.md) |
| Configure Heat gain, drain and capacity | [Heat configuration](combat/ProjectYakuza/docs/HEAT_CONFIGURATION.md) |
| Add sounds, music, effects and style UI | [Presentation](combat/ProjectYakuza/docs/PRESENTATION.md), [Style UI](combat/ProjectYakuza/docs/STYLE_UI.md) |
| Add multiplayer observers and authority checks | [Multiplayer](combat/ProjectYakuza/docs/MULTIPLAYER.md) |
| Validate and distribute an add-on | [Testing](combat/ProjectYakuza/docs/TESTING.md), [Workshop publishing](docs/WORKSHOP.md) |
| Browse all documentation | [Documentation index](combat/ProjectYakuza/docs/INDEX.md) |

## Reference style and release contents

Dragon of Dojima demonstrates light chains, normal/reverse/charged finishers, quicksteps, running attacks, guard, Tiger Drop, grabs, Heat and Extreme Heat. The v1 player build supports vanilla bat/club, knife and blade profiles, with bat, katana and knife Heat Actions. [Controls and reference-style behavior](combat/ProjectYakuza/README.md) are documented separately.

Custom beer-crate, bicycle, intact-bottle and Lau Ka Long spear work remains in the development source and is excluded from the player packages. Build the core packages through `tools/Build-GamePackage.py` to apply the release filter; copying the entire source mod folder installs the development content.

[Cutscene emotes](emotes/ProjectYakuzaEmotes/README.md) and the [experimental phone UI](phone-dev/ProjectYakuzaPhoneDev/docs/README.md) are separate source projects. Neither is required by the framework or included in v1. Custom Voice Framework and compatible voice packs are optional integrations; voice packs are not bundled.

## Multiplayer and distribution

Shared style definitions and observer catalogs must agree across peers. Observer registration supplies playback; it does not implement authoritative damage, target ownership or new physics. Custom mechanics need explicit server validation. Split-screen/gamepad menus, full PvP parity and a Java bridge are outside the current framework.

Distribute your add-on with a dependency on ProjectYakuza, rather than bundling another framework copy. Include only runtime code and the assets your add-on needs. Keep source-game archives, authoring tools, templates, test logs and local configuration outside the upload. Asset references and provenance are retained in the source documentation.

GitHub's automatic **Source code** archives are for development. Use the named runtime or Workshop ZIP for installation and uploading. The mod version is 1.0.0 (v1); Lua API and multiplayer protocol versions are independent compatibility identifiers.
