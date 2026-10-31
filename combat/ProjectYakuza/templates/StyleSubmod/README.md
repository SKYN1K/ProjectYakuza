# Inactive API-2 style starter

Copy to your addon root under Zomboid/mods; keep common/. This folder is not loaded by the framework.

1. Rename 42/mod.info.example to mod.info.
2. Activate both shared/client Lua examples and both melee/actions XML examples by removing .example. The shared module name must stay ExampleStyle_Style.lua until you change all requires consistently.
3. Replace example mod/style/action/binding/node prefixes before publishing. Dependency is ProjectYakuza, API 2.
4. Select the addon in the inventory menu or assign through the wheel's bottom slot.
5. LMB uses an existing native punch with one MeleeSwing. Assign the unbound Example style flourish in Mods settings to try the custom action. This separate punch-shaped flourish is visual-only: no damage, heat or protection; walking cancels it.
6. For MP run ProjectYakuza/tools/build_style_observers.py --mod-root YourAddon --style-id example_mod.my_style --prefix ExampleStyle_ --dry-run, inspect, then run without dry-run. Install generated XML/Lua plus addon on all peers. New gameplay still needs server support.

Music/sounds/heat/Kiryu effects are off. Leave the sound script inactive until recordings exist; use two distinct tracks for continuous non-repeating shuffle. Existing PZ playback is referenced, not generated. See [authoring](../../docs/STYLE_AUTHORING.md), [actions](../../docs/ACTIONS.md) and [testing](../../docs/TESTING.md).

Custom actions can use the shared ProjectYakuza.QTE sequence engine with configurable timing, registered bindings and result/cancellation events. See the framework docs/QTE.md guide; style handlers still own supplied animations, UI, effects and multiplayer authority.

Optional heatAttackSpeed={max=1.25} adds a captured per-attack Heat multiplier for your style, provided its native nodes use the framework speed variables. See docs/HEAT_ATTACK_SPEED.md for weapon overrides, Extreme policy, MP bounds and fixed-speed clip limits. DoD does not opt in.
