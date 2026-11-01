# Validation: 0.66.0

Project Zomboid was not launched. All 56 offline validation steps pass, including 26 Kahlua fixtures, compilation of 58 production Lua modules, native API checks and zero comments across 668 checked source files. Six lexical-preservation tests also pass. Live GPU appearance and multiplayer latency remain untested.

The Extreme Heat fixture now tests depletion after each extended combo step 5..8, runs the normal player update before another input and verifies a valid ready pose plus normal-chain restart. The active depletion swing keeps its original boost pose. This reproduces the nil-move condition shown in the supplied screenshot.

The native batch importer independently samples 60 existing converted attack clips and produces code-side limb FK only. The deterministic builder compares every shipped track and provenance hash to the native output; 62 contact windows are covered. Existing native collision events supply contact phases, QTE prompts supply Heat Rush contacts, and Tiger Drop uses a documented visual fallback. Limb selection is kinematic or derived from existing verified mappings, not decoded Yakuza hitbox bone enums.

The punch/charge/audio fixture passes 9,991 checks, including every contact at eight facings, bounded irregular displacement, fixed instance budgets, committed/category deduplication, action-context cleanup, foreign-style isolation and observer reconstruction. Original first-punch source samples, 32-facing projection, historical world trails, teleport/reset, pause, provider fallback and source-phase audio checks remain covered. Source definitions, authority, input, heat, QTE, UI, weapons and MP fixtures are retained.

All existing non-Lua media and native animation definitions are compared byte-for-byte with v0.65.0. No visual/audio/motion/model assets or separate voice-pack files are changed. The source-pose approximation does not attach to the final blended skeleton and adds no Java integration or launcher requirement. Offline Java probes are tooling only.

Installation verifies the prior v0.65.0 tree against its released ZIP, backs up only changed existing files and removes the superseded validation report. Source/install/release ZIP payloads and the published archive digest are compared. The unique v0.66.0 release is published through Publish-CombatRelease.ps1. Older validation is retained in Git/release history.
