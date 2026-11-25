# Offline framework checks

These fixtures exercise framework registration, native animation contracts, input routing, multiplayer authority, presentation and packaging. Configure paths for your own Build 42 installation, Python, JVM and native libraries. Game JARs, extracted standard libraries and compiled probes are not distributed in this repository.

Style authors should start with [Testing](../../combat/ProjectYakuza/docs/TESTING.md) and the [API reference](../../combat/ProjectYakuza/docs/API_REFERENCE.md).

## Python and release-profile checks

Run from the repository root:

```text
python tools/combat-tests/test_game_package.py
python tools/combat-tests/test_combat_install.py
python tools/combat-tests/test_release_runtime.py
python tools/combat-tests/validate_release_runtime.py
python tools/combat-tests/check_source_comments.py
```

The release-profile validator compiles the filtered Lua payload, checks require/animation closure, preserves supported vanilla weapon profiles and Heat Actions, rejects excluded custom moves and verifies native missing-item record handling. It requires the configured native probe classes. The package tests check runtime allowlists, private metadata rejection, safe installation, backups and staged-copy verification.

## Kahlua fixtures

Builder scripts embed current production Lua into isolated fixture files. Rebuild a fixture after changing its source modules:

```text
python tools/combat-tests/build_mp_tests.py
python tools/combat-tests/build_weapon_mp_tests.py
python tools/combat-tests/build_heat_presentation_tests.py
python tools/combat-tests/build_punch_effects_tests.py
```

Compile LuaRunner.java with a suitable JDK. Put the installed game's stdlib.lua in this test directory; do not commit it. Run Java from tools/combat-tests so the Kahlua environment finds that file. On Windows, a configured classpath example is:

```text
java -Xms16m -Xmx128m -cp ".;PATH_TO_PZ/*" LuaRunner mp-tests.lua weapon-mp-tests.lua
```

Use the JVM shipped with the supported game build for native probes. Several native checks load game classes or libraries directly; generic Lua syntax tools do not establish compatibility with PZ's runtime.

## Native validation

- CompileCombatLua checks production Lua compilation against the installed Kahlua compiler.
- GrabFadeProbe checks actual native return-fade weights and continuing outgoing playback. GrabBlendProbe accepts --live-tail after its existing arguments to sample the moving strike tail with native easing and verify genuinely mixed midpoint poses.
- WorkshopPackageProbe validates the staged content layout, file types and preview without starting a game or uploading it.
- MPObserverProbe and validate_mp_nodes.py check observer selectors and event isolation.
- LimbImpactProbe, LimbRenderProjectionProbe and the attack-effect validators check source-sampled skeleton positions, projections, contact windows and texture data.
- RemovedItemLoadProbe checks that a missing item definition does not consume the following saved record.
- The scene_resource module resolves GUID-bound resource names for the combat source importers. It is independent of any other project.

Source conversion/import checks require the corresponding source files and matching installed game libraries. Configure their paths before running them. Build scripts may write code, clips or converted outputs; run validation-only modes when checking existing assets.

## Interpreting results

Offline checks cover API contracts, source hashes, native imports/selectors, lifecycle cleanup, timing, range/authority rules and byte-for-byte packages. They do not establish the final blended pose, GPU output, live frame pacing or real network latency. Complete the [gameplay and network checklist](../../combat/ProjectYakuza/docs/TESTING.md#gameplay-and-network-checklist) before making those claims for a new style or mechanic.
