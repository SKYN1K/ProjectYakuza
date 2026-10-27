# Validation — Project Yakuza 0.31.0

No Project Zomboid game/server was launched. These checks run offline using the installed B42 Kahlua VM, animation importer/parser, texture decoder and API classes. Live multiplayer and GPU appearance are untested.

| Kahlua fixture | Passing assertions |
| --- | ---: |
| Combat, aura, music lifecycle | 2,629 |
| Charged heavy, UI providers, outline, world particles | 70 |
| One-strike quickstep | 71 |
| Multiplayer authority, observers, move catalog | 98 |
| Extension API | 42 |
| Shipped addon starter | 9 |
| Heat/shove routing | 23 |
| Activation SFX | 35 |
| Locked style entry | 21 |
| Taunt lifecycle/aura/MP | 121 |
| Optional CVF adapter (read-only upstream code) | 63 |
| Selector/persistence/assets | 50 |
| Native Mods volume settings | 94 |
| Total | **3,326** |

All 37 production Lua files compile with B42's compiler. The two source-derived charge clips import through the installed Assimp/JAssImp pipeline as one skeletal animation each: loop 1.666667 seconds/51 hand keys and release 1.833333 seconds/56 hand keys, each with 35 channels. The native charge node parses with no collision; the release node parses with exactly one MeleeSwing collision. Both MP cycles select only for their matching clip, with zero observer events: 156 nodes total. The addon observer builder also passes its deterministic/non-destructive dry-run, native parsing, Lua compilation and safety checks.

Native ImageData decodes the original-size 16x32 Y6 spark. Its decoded RGBA pixels match the supplied DDS exactly. Source GMT/DDS and output hashes match charged-heavy-assets.json. All 376 previously shipped animation/image/audio files retain v0.30.4 bytes; only two retargeted original animations and one lossless original texture decode are added. No generated media, AI tool or upscaling is used.

The native outline API probe confirms packed ABGR cc996633 for (.2,.4,.6,.8) and per-player highlight flags. Kahlua tests check previous color/flag restoration, existing highlights and external takeover. Final silhouette appearance is still a gameplay/GPU check.

Local installation compares changed installed files against the previous release before writing, backs up only replaced/removed files and verifies every installed source byte. The release ZIP is built from the source mod directory; generated fixtures, extracted libraries, previews, backups and the separate voice-pack project remain excluded.
