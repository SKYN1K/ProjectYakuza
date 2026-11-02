# Beer crate weapon

Spawn ID: `ProjectYakuza.BeerCrate`. Display name: Beer Crate (Yakuza 6).

This is a separately spawnable one-handed Short Blunt weapon: 2.5 weight, 0.8..1.3 native damage, eight condition points and two native hit targets. Find it in the debug/admin item spawner. Outside a combat style it uses native weapon combat. With Dragon of Dojima selected it uses the existing Short Blunt weapon profile, native durability, guard and weapon feedback. The bottle Heat Action whitelist remains specific to bottles.

The intact LOD0 mesh is the original `stg0010_beercase_a_na.gmd` from Yakuza 6's asset.par, with its original diffuse texture decoded at native resolution. Its 1004 source vertices and 1052 triangles retain normals and UVs; geometry is rebased to the source right-hand grip. Broken fragments and lower-detail duplicates are excluded. Held/world model attachments use PZ's normal model system. The inventory icon reuses PZ's supplied crate icon. No loot distribution is added.

[Provenance](beer-crate-assets.json) records archive entries, source/output hashes, topology, grip and exact texture pixels. Conversion uses [Yakuza GMD IO](https://github.com/theturboturnip/yk_gmd_io) by Samuel Stark (TheTurboTurnip). The native importer, static mesh processor, item/model script parser and texture decoder are checked offline. Live grip, floor placement and multiplayer presentation need in-game assessment; PZ is not launched during validation.
