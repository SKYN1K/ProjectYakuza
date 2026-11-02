# Intact bottle weapons

Three separate spawnable weapons reuse Project Zomboid's original beer, red-wine and whiskey bottle icons/models. Ordinary drink containers and their fluids remain unchanged. These are one-handed Short Blunt weapons with normal native attacks when no combat style is equipped. They do not add loot distributions or automatically turn drink containers into weapons.

| Display name | Spawn ID |
| --- | --- |
| Intact Beer Bottle (Weapon) | ProjectYakuza.IntactBeerBottle |
| Intact Wine Bottle (Weapon) | ProjectYakuza.IntactWineBottle |
| Intact Whiskey Bottle (Weapon) | ProjectYakuza.IntactWhiskeyBottle |

Find these entries in the game's debug/admin item spawner, or use the full ID in the server's normal item-spawn command. Each has 0.6..1.0 base damage, one-tile native range, two native hit targets and four condition points. They use native condition loss and can break. They are weapon items rather than drinkable containers; there is no automatic broken-glass weapon conversion.

## Dragon of Dojima

With DoD active, equip a bottle in the primary hand. The existing Short Blunt profile supplies the light combo, heavy, ground attack, walking guard and quickstep support. Those weapon systems remain style exclusive.

Hold physical RMB and press the rebindable Heat Action input (default MMB) outside a combo near an eligible standing target. One heat stock is required; Extreme Heat can pay the equivalent fuel. Normal combo MMB heavies retain their existing behavior. Ordinary drink bottles, broken bottles and unrelated blunt weapons cannot trigger this action.

The original Yakuza 6 h23681_buki_a_plus sequence supplies all 151 attacker/victim frames at 30 fps, giving five seconds of paired motion. Existing supplied effects and sounds accompany the repeated-strike/final-strike/fall timings. Damage lands once at the fall contact, using 1.5 times the held weapon's unscaled average base damage (1.2 for these bottles). Earlier contacts provide presentation so a premature death does not cut off the paired victim animation. Surviving victims are knocked down at completion.

The shared [Heat Action framework](HEAT_ACTIONS.md) grants invulnerability only during the action and prevents zombie targeting through it plus 0.5 seconds afterward. It preserves PvP restrictions, interruption cleanup, source-timed contact deduplication and MP observer ownership. All clients and the server need this version for the new item IDs and clips.

## Assets and validation

[Motion provenance](bottle-heat-assets.json) records source archive/GMT/scene hashes, the original actor/victim GUID bindings, source timing and native grip offsets. [Item references](bottle-weapon-items.json) records unchanged PZ item/model-script sources. No visual/audio artwork, AI motion or upscaling is generated. See [current validation](VALIDATION_0.71.0.md); PZ is not launched during offline checks.
