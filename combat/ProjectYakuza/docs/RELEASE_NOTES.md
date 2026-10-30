# Project Yakuza 0.46.0

- Optimised repeated animation lookups with registration-aware clip/move indexes and grouped selectors. Animator variables are read once per selection; the same fixture now uses 5 bridge reads rather than 14 while selecting the same clip.
- Reduced six-emitter aura position/offset reads from 30 to 5 per body draw. Stable aura updates skip global hook-ownership scans, and cleared inactive states avoid repeated detach/hook work. Current visuals, frame clocks, colours and blending are preserved.
- Reduced redundant equipment/view checks and registration allocations. Removed the unused hard-coded finisher mouse constant and retired aura spark/colour branches. Disabled grabs, future juggling/hooks, addon APIs, attack behaviour and assets are preserved.
- Removed comments/docstrings from project source, templates, tests/build tools and documentation code examples. Replaced test insertion/observer ownership comment markers with data/metadata, retaining native parsing and overwrite protection. Added a comment checker and lexical preservation tests. Prose documentation remains.

## Validation

4,301 offline Kahlua assertions across 16 fixtures pass; all 42 production Lua files compile. Cache tests cover 1,000 warm lookups without array scans, style/catalogue invalidation, selector priority/case and per-selection bridge reads. Aura tests verify the reduced bridge reads, skipped stable hook scans, current tints, pause, cleanup and particle ownership. Six Python lexical tests pass; the source/comment audit reports zero comments across 498 source files and checked documentation examples. All tracked Java probes compile and the publishing PowerShell script parses.

Native clip, observer, addon-builder, original frame/FK, texture/pixel, alpha, loader and provenance checks pass. All 577 motion/image/audio files and existing native animation nodes remain byte-identical to 0.45.0. See [performance notes](PERFORMANCE.md) and [validation](VALIDATION_0.46.0.md).

Installed locally and published as a new release ZIP. PZ was not launched; no live FPS or multiplayer timing measurement is claimed. Fully restart with matching server/client versions.
