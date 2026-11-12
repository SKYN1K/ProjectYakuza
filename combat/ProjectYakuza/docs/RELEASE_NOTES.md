# Project Yakuza 0.101.0

- Removed 258 confirmed obsolete files: 56 unused animations, 30 permanently disabled pose selectors, 171 unused textures and one unused sound file, saving about 20.94 MiB of uncompressed mod data.
- Removed the unused ChargeEnd sound definition/label and duplicated legacy punch-tracking dataset. Current effects use the existing generated attack catalogue.
- Preserved every retained motion/model/texture/audio byte, current gameplay, source references, public API and addon templates.
- Added a publishing check for missing references, unreferenced assets, disabled pose selectors and reintroduced retired outputs. The audit includes dynamic texture sequences and engine-resolved item/model textures.
- All 30 Kahlua suites and 83 production Lua compilations pass. All 167 remaining motions import natively; all 263 textures retain their original pixels. Native observers, source comments and installation/archive bytes are checked offline. Project Zomboid was not launched.

See [asset cleanup](ASSET_CLEANUP.md), [removal ledger](asset-cleanup.json) and [validation](VALIDATION_0.101.0.md).
