# Beer crate weapon

Version 0.97.0 halves the model's previous linear size (native model scale 0.5) and uses its registered held/world model for dropping it. Original crate mesh, UVs and textures remain unchanged. Ordinary attacks now use Yakuza 5 P_WPC_CMB_01/02/03 and P_WPC_ATK_heavy. All 46/51/66/53 source samples remain; the floor strike reuses the overhead heavy. Native contacts are calibrated at frames 15/20/21/19, with one canonical collision per ordinary attack. Existing 1.4x combat playback, original guard and Yakuza 5 H3270 Heat Action remain. The earlier Yakuza 6 ordinary-attack records in weapon-motion-assets.json are superseded by y5-object-attacks.json.

Spawn ID: `ProjectYakuza.BeerCrate`. Display name: Beer Crate (Yakuza 6).

This is a separately spawnable one-handed Short Blunt weapon: 2.5 weight, 0.8..1.3 native damage, eight condition points and two native hit targets. Find it in the debug/admin item spawner. Outside a combat style it uses native weapon combat. With Dragon of Dojima selected it uses its separate crate weapon profile, native durability, guard and weapon feedback. The bottle Heat Action whitelist remains specific to bottles.

The intact LOD0 mesh is the original `stg0010_beercase_a_na.gmd` from Yakuza 6's asset.par, with its original diffuse texture decoded at native resolution. Its 1004 source vertices and 1052 triangles retain normals and UVs; geometry is rebased to the source right-hand grip. Broken fragments and lower-detail duplicates are excluded. Held/world model attachments use PZ's normal model system. The inventory icon reuses PZ's supplied crate icon. No loot distribution is added.

[Provenance](beer-crate-assets.json) records archive entries, source/output hashes, topology, grip and exact texture pixels. Conversion uses [Yakuza GMD IO](https://github.com/theturboturnip/yk_gmd_io) by Samuel Stark (TheTurboTurnip). The native importer, static mesh processor, item/model script parser and texture decoder are checked offline. Live grip, floor placement and multiplayer presentation need in-game assessment; PZ is not launched during validation.
