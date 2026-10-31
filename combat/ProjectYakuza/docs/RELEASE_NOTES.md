# Project Yakuza 0.58.1

- Fixed the barrage error at Barrages.lua:70: the client used a Java item-factory global that is not exposed in this B42 build. Base-damage item creation now uses the native Lua instanceItem function.
- Fixed the same API calls in multiplayer barrage and supplementary-hit damage paths. Existing damage factors, source contact timing, item caching and missing-item handling remain unchanged.
- Regression fixtures now leave InventoryItemFactory absent, exercise SP barrage contacts and MP damage through instanceItem, and verify item reuse and safe missing-item behavior. A native probe checks the installed B42 global function signature.

No visual/audio/animation assets were created or changed. PZ was not launched or operated during this update. Quit and restart PZ after installation; servers and clients must use the same version. See VALIDATION_0.58.1.md.
