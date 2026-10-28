# Validation — 0.34.0

No PZ client/server was launched. Live GPU appearance and multiplayer gameplay remain unverified.

- **3,793 Kahlua assertions pass**: existing 3,534 plus 259 for source-tracked punch effects. Each suite runs in a separate installed B42 JVM.
- All **39 production Lua files compile** through B42's Kahlua compiler.
- Native Jassimp/ProcessedAiScene imports the unchanged first punch (35 skeleton bones, 31 samples). Native HelperFunctions/FK reproduces every numeric forearm/wrist/knuckle sample embedded in AttackTracks.lua.
- Native Model.vectorToWorldCoords/IsoUtils results match the Lua projection for eight facings. The required scalar character methods exist in the installed B42 engine.
- Effects fixture checks all source samples, subframe interpolation, cached lookup, outgoing/new duplicate track selection, source-clock timing, first-light scope, no idle callbacks, ten-instance/eight-actor bounds, pause, missing clip timeout, hit/move/style interruption, restart, MP observer route, world transitions, cleanup and blend-flag restoration on injected error.
- Sound fixture checks one original whoosh at native source frame 3, no duplicate/late/interrupted/missing-clip playback, pause and owner-only audio.
- **All 455 animation/image/audio files are byte-identical to v0.33.0.** The reused 66 texture hashes and four original whoosh waveform hashes match the provenance report. No new graphical/audio assets exist in this update.
- Existing native checks still pass: 130 aura PNG decodes; 14 charge nodes; 188 event-free observer nodes; addon observer-builder safety; original BEP pause/release timings; .55 flame speed and no visible black matte; 229 loader filenames; 12 source pose splits; original smoke crops/HUD atlas.

The Lua-only effect follows source samples and native playback time rather than final blended bone transforms. Mesh-surface glow, exact blending/proportions, depth occlusion, visual quality and live MP latency are not established by these offline checks. The update changes presentation only, with no collision, damage, input or body-aura changes.

Installation is preflighted against the prior release, backs up only changed installed files, and verifies every source/install byte. Publishing uses a fresh v0.34.0 tag and install ZIP; source/install/ZIP bytes and remote asset digest are checked after publication.
