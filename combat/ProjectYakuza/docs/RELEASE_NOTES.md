# Project Yakuza 0.48.0

- Added original animated Yakuza 6 blood splashes to confirmed Dragon of Dojima hits, alongside existing sparks. Heavy/charged hits have slightly larger bursts; downed targets use a low world anchor.
- Blood uses 16 exact original atlas crops, normal transparency and detached native world sprites. No AI, upscaling, invented artwork or audio changes.
- Existing multiplayer confirmed-impact presentation uses the same blood path. Misses/duplicate hit callbacks do not add bursts. Cached sprites, four-per-attacker/sixteen-global limits, pooled instances and idle hook removal bound the effect's cost.
- Renamed the existing menu toggle to Toggle hit effects; it controls sparks and blood together.
- Added source-pixel/provenance, native B42 image decoder and actual-module lifecycle tests. See VALIDATION_0.48.0.md. PZ was not launched.

Fully restart with matching server/client versions. Native damage, wounds, decals and blood on real equipment remain unchanged. Grabs remain disabled; separate voice pack untouched.
