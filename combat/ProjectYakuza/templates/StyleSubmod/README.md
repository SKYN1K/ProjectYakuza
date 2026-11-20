# Fighting-style starter

An inactive starter for independent Project Yakuza add-ons. It uses the API 2 subset supported by the current API 3 framework.

1. Copy this directory to a separate add-on under `Zomboid/mods` and keep an empty `common/` directory.
2. Rename `42/mod.info.example` to `mod.info`. Remove `.example` from both Lua modules and both XML nodes. Keep the music script inactive until you provide its recordings.
3. Replace the mod ID, `example_mod.my_style`, action/binding IDs, file/module names and XML prefixes consistently. Keep `require=ProjectYakuza` in mod.info.
4. Enable the framework and add-on. Open the style wheel with Z, use the bottom slot to assign the new style, then select that slot to equip it.
5. LMB uses the existing native punch. Assign the initially unbound flourish in **Options > Mods > Project Yakuza**. The flourish demonstrates custom action input and cleanup; it does not deal damage or award Heat.
6. Build multiplayer observers from the repository root:

```text
python combat/ProjectYakuza/tools/build_style_observers.py --mod-root YourAddon --style-id example_mod.my_style --prefix ExampleStyle_ --dry-run
```

Inspect the output, then run without `--dry-run`. Publish the generated XML/Lua with the add-on and install matching versions on all peers. Observer generation supplies presentation; a new damaging mechanic still needs server validation.

The starter does not enable Heat, music or Kiryu-specific effects. Add those explicitly through the framework contracts. Supply playable PZ clips and matching collision/animation markers; raw GMT files are not supported. Remove this README, the common-directory placeholder and unused `.example` files from the published add-on.

See [Style authoring](../../docs/STYLE_AUTHORING.md), [Actions](../../docs/ACTIONS.md), [Animation contracts](../../docs/ANIMATIONS.md), [Multiplayer](../../docs/MULTIPLAYER.md) and [Testing](../../docs/TESTING.md).
