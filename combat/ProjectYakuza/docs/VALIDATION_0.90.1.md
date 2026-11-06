# Project Yakuza 0.90.1 validation

Offline only; PZ was not launched. Original local reference frames around 06:18 were decoded in memory without saving or changing media. No animation, texture, audio or model assets changed.

The production HeatRush fixture checks that the katana has exactly three gameplay contacts, each applies damage once and emits one presentation cue, and total damage remains the original 1.5 times canonical weapon damage. The MP suite rejects contact index four and deduplicates each of the three valid contact packets. The presentation suite checks that its numeric catalogue contains three entries and index four cannot emit sound/effects/voice events. All 30 remaining presentation contacts retain their source animation clocks and native victim anchors. QTE timing and other Heat Actions are unchanged.

All 30 Kahlua regression suites passed, including 1,830 MP checks, 866 HeatRush checks and 1,085 presentation checks. All 75 production Lua files compiled. Native API/UI probes, deterministic native presentation rebuild, the zero-comment scan and comparison of 1,395 unchanged non-Lua runtime media files passed. The native numeric-data builder uses a 16 MB initial / 256 MB maximum Java heap to avoid reserving excessive host memory during offline checks.

Installation verifies the entire v0.90.0 baseline, backs up only changed existing files and checks installed bytes. Source, installed files and the fresh v0.90.1 release ZIP are compared exactly. In-game confirmation remains pending user testing after restart.
