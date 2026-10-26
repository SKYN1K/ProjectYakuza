# Mad Dog addon validation

Tested against the current repository's 0.29.0 framework (`c5c2408`) and locally installed Project Zomboid Build 42.21.0. This is an unmerged feature branch, not a release or local installation.

- **153 addon Kahlua assertions:** production registry validation, real Runtime/Combo swings, all four finisher branches, marker-gated recovery, per-move damage restoration, optional held-model switching, style isolation, movement cleanup, save/load ground-variant reset, split-screen lease separation and network catalogue/protocol lookups.
- **21 Mad Dog entry assertions:** production StyleEntry handler with the addon's original one-second transition; movement/input lock, vulnerability, contact interruption, pause, missing playback, queue rejection, completion and cleanup.
- **96 existing multiplayer assertions:** server-owned equipment, duplicate/range validation, bounded leases, cooldowns, observer state, acknowledgements and throttling remain passing.
- **21 existing Dragon of Dojima entry assertions:** upstream entry behavior remains passing.
- **36 production Lua files** compile in the installed game's Kahlua compiler, including all addon modules.
- **26 clips** pass the installed Jassimp importer and `ProcessedAiScene` animation processing, with 36 channels each, finite normalized rotations and no horizontal root drift. Source timing is retained before the explicit playback speed.
- **28 owner nodes** pass native AnimNode/AnimState parsing and selection alongside every framework node in the same group. They select for Mad Dog and do not override DoD.
- **82 observer nodes** pass both network cycles, with zero animation/collision events and no local-player leakage.
- Asset checks verify all 26 output SHA-256 hashes, all clip references, exact style conditions and all **15 single-collision nodes**, including native stomp/floor routes. Source GMT and original Majima GMD hashes are checked directly against the supplied local game archives.
- Reviewed skeletal pose samples across all four lights, all four finishers and the stance. Native bone lengths, original body turns/crouches and source frame timing are preserved, with bind-pose direction correction and the native PZ knife grip.

Reproduction commands and pinned importer revisions are in [tools/mad-dog/README.md](../../../tools/mad-dog/README.md).

No game was launched. These checks do not prove live contact timing, final mesh deformation, knife alignment, transitions, multiplayer latency behavior or compatibility with pending changes outside the repository. Test those on this branch before merging. No installed mod or save was changed.
