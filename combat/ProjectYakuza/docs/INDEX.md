# Framework documentation

Current release: **[v1](https://github.com/SKYN1K/ProjectYakuza/releases/tag/v1)** · version **1.0.0** · Lua API **3** · multiplayer protocol **2**.

## Start here

| Task | Guide |
| --- | --- |
| Create a separate fighting-style add-on | [Style authoring](STYLE_AUTHORING.md) |
| Activate the included example | [Starter add-on](../templates/StyleSubmod/README.md) |
| Look up fields, functions and events | [API reference](API_REFERENCE.md) |
| Install or play the reference style | [Dragon of Dojima](../README.md) and [Controls](CONTROLS.md) |
| Publish a runtime-only package | [Workshop publishing](../../../docs/WORKSHOP.md) |
| Understand validation coverage | [Testing](TESTING.md) and [Current validation](VALIDATION.md) |

## Gameplay contracts

| System | Documentation |
| --- | --- |
| Custom action kinds and cleanup | [Actions and lifecycle](ACTIONS.md) |
| Native animation nodes, collisions and markers | [Animation contracts](ANIMATIONS.md) |
| Equipment-specific move sets | [Weapon profiles](WEAPONS.md) |
| Grabs, strikes, throws and held-target actions | [Grabs](GRABS.md) |
| Paired weapon, ground and grab Heat Actions | [Heat Actions](HEAT_ACTIONS.md) |
| QTE timing, bindings and result events | [QTE API](QTE.md) |
| Stationary charges and native release | [Charged heavies](CHARGED_HEAVY.md) |
| Quickstep cancels | [Light quickstep cancels](LIGHT_QUICKSTEP_CANCELS.md) |
| Directional moves and threat-gated taunts | [Directional attacks and taunts](DIRECTIONAL_AND_TAUNTS.md) |
| Endurance costs | [Exertion](EXERTION.md) |
| Gain, stock retention and drain | [Heat rules](HEAT.md) and [Per-style Heat configuration](HEAT_CONFIGURATION.md) |
| Optional speed curves | [Heat attack speed](HEAT_ATTACK_SPEED.md) |
| Victim reactions and follow-up state | [Hit responses](HIT_RESPONSES.md) and [Juggling](JUGGLING.md) |

## Presentation and multiplayer

| System | Documentation |
| --- | --- |
| Shared/server authority and observer catalogs | [Multiplayer](MULTIPLAYER.md) |
| Music, sound, voices and effects | [Presentation](PRESENTATION.md) |
| Custom HUD, selector and setup providers | [Style UI API](STYLE_UI.md) and [Selector](STYLE_SELECTOR.md) |
| Source-tracked limb effects | [Attack effects](ATTACK_EFFECTS.md) |
| Paired scene events, anchors and damage | [Scene contracts](HEAT_SCENES.md), [Presentation](HEAT_ACTION_PRESENTATION.md), [Damage](HEAT_ACTION_DAMAGE.md) |
| Source entry and native movement | [Combat entry](COMBAT_ENTRY.md) and [Locomotion](LOCOMOTION.md) |
| Interface sounds and optional voices | [Interface audio](INTERFACE_AUDIO.md) and [CVF integration](CVF_COMBAT_VOICES.md) |
| Low-health feedback | [Low-health feedback](LOW_HEALTH_FEEDBACK.md) |
| Encounters and original blood | [Encounter intros](ENCOUNTER_INTROS.md) and [Blood effects](BLOOD_EFFECTS.md) |
| Runtime lookup and maintenance | [Performance](PERFORMANCE.md) |

## Source records

The player release contains vanilla bat/club, knife and blade profiles and their supported Heat Actions. [Bat](BAT_HEAT_ACTION.md), [knife](KNIFE_HEAT_ACTION.md) and [open-space grab](OPEN_GRAB_HEAT_ACTION.md) describe retained reference scenes.

[Beer crate](BEER_CRATE.md), [bicycle](BICYCLE.md) and [intact bottles](BOTTLE_WEAPONS.md) describe source-only development work excluded from v1. Their item-spawning and gameplay instructions are not part of the current player manual.


Version-labelled sections record historical implementation changes. Older validation notes are available in Git history rather than in the current manual. Current release filtering is recorded in [release-profile-1.0.0.json](release-profile-1.0.0.json). Asset JSON records preserve source identities, conversions and hashes. Documentation, tools and provenance records remain in the repository and are excluded from player ZIPs.
