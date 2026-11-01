# Test and package an addon

## Offline checks

1. Use a unique mod ID and require=ProjectYakuza. Activate only intended Lua/XML/sound examples; keep common/ and 42/ layout.
2. Run validateStyle and resolve all errors. Confirm files/native clip names; schema validation does not import assets.
3. Match IDs, node values, masks, XML speeds, Lua durations and source-frame contact/link windows. One native collision per strike; none in observers.
4. Run observer builder dry-run, inspect outputs/require paths, then generate. Do not overwrite another style's node IDs.
5. Compile with B42 Kahlua and import nodes/clips with native classes. Generic Lua syntax tools alone do not prove native compatibility.
6. Retain hashes/provenance when converting supplied media. Missing source assets must be supplied, not generated/upscaled.

The repository tools/combat-tests/README.md describes Kahlua/native probes. Rebuild embedded snapshots after production changes and run fixture JVMs separately. API-2/3 tests embed actual Registry/Bindings/Combo/NetworkExtensions/Runtime. Game libraries, extracted stdlib and compiled probes stay out of distributed addons.

## Gameplay and network checklist

Test selection/reselection, persistent/missing slots, chains/recovery, double handoffs, floor moves, all dash directions/quota, running strikes, walking guard, heat gain/depletion, distinct activation/taunt/entry protection, rebinding and volumes. Unprofiled styles must not inherit DoD music/effects.

For each custom action test accepted/rejected/failed starts, missing clip/end marker, move/aim input, hit reaction, knockdown/death, unequip, vehicle/climb, save/menu exit, pause and stale callbacks. Verify exact restoration and that the next ordinary attack works. Rejected/unfinished actions must not award rewards.

Use a real host plus client before advertising MP compatibility. Test delayed inventory/acknowledgement, repeated clips, late/streaming observers, walls/range, moving/owned zombies, duplicates, disconnects and latency. Damage must occur once regardless of observer count. New paired mechanics need their own server tests.

| Symptom | Check |
| --- | --- |
| Style absent | Addon/shared Lua load, dependency/API version, validation log |
| No playback | XML conditions, playable clip/native import, exact markers/speed |
| Visible punch but no damage | Visual-only action versus native strike, collision event and valid target |
| Double damage | Duplicate native events/health timer or observer events retained |
| Stuck/sliding | Queue cleanup, saved movement flags, root travel/native-leg mask |
| Custom action also lights | Namespaced kind/ownership, input routing and native gate |
| Remote clip missing | Shared catalog, style registered first, cycles/group, timedAction.started |
| Missing voice | CVF/selected voice/namespace/recording/slider/style opt-out |
| Music fails to shuffle | loop=false, two distinct tracks, natural-end detection and selected-style playlist |

Package only your addon code and supplied assets, with requirements/controls/license/provenance. Do not include framework copies, source-game archives, previews, backups, credentials, extracted tools or another voice pack.

API 3 additionally tests charged tap/hold/counter priority, single-use native release, interruption/paused cleanup, style UI provider failures/unregistration, original-pixel particle decoding and native outline preservation. See [0.31.0 validation](VALIDATION_0.65.0.md).

The distributed docs folder keeps only the current version's validation report. Historical validation files and raw native-import logs are preserved by previous Git commits/releases. Retained JSON asset records still support source/hash checks, including disabled features. For attack endurance, build_exertion_tests.py runs the actual Runtime/Exertion code, and ExertionProbe checks the installed native stat/fitness/trait API and the zero clamp without launching PZ.
