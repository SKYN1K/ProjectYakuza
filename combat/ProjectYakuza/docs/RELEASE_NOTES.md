# Project Yakuza 0.94.0

- Restored the katana Heat Action's original independent sword animation. It now leaves the hand, turns in midair and is caught in the reversed grip before the final sharp-end thrust.
- Converted all 141 samples from the supplied h23720_000_7.gmt sword track into the existing native right-prop attachment. The source release is at frame 44, the catch at frame 54 and the final thrust at frame 64.
- Replaced the previous fixed-grip check with source-derived animated attachment checks, native importer/FK validation and a regression that rejects the old rigid grip at the release frame. Verified that the native katana sharp axis faces the victim at the final thrust.
- Preserved all character/finger/left-prop bytes, the complete victim clip, hit timing, damage, audio and textures. Only the actor's right-prop animation block changes; dependent provenance hashes are refreshed.

This is a conversion of the supplied original sword motion, without invented motion or generated artwork/audio. Offline validation only; PZ was not launched. See [validation](VALIDATION_0.94.0.md). Restart PZ after updating, with matching server/client versions.
