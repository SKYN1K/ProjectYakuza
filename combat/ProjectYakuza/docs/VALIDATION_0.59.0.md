# Validation: 0.59.0

No PZ launch, live gameplay or audio playback was performed. The complete offline runner passes 75 steps and all 24 Kahlua fixtures. Subsequent focused checks pass for the final prompt-overlay and charge-branch changes, bringing the fixture assertion total to 7,656. All 56 production Lua modules compile; all 658 checked source files contain zero comments, with six lexical-preservation tests passing. Source/native verification cannot establish live pose fit, visual quality or network latency.

## Gameplay and reusable API

Directional checks cover all turn sectors and the actual Runtime route for all four reverse first/double branches, including queued second finishers during the first, normal side turns, timing, damage, interruption and weapon/style isolation. Multihit regression now covers 42 existing light, finisher, running, quickstep and ground entries, including repeated boost-chain links and all eight reverse finishers.

The dedicated QTE fixture passes 79 checks. It exercises a custom 32-prompt/two-binding sequence, malformed/oversized definitions, held buttons, missed prompts, rewind/replay rejection, eighth-contact eligibility, source-track timing, canonical damage with exactly one Extreme Heat bonus, cached B42 item creation, paired movement/AI locks, pause, interruption, complete cleanup, remote explicit-false flag restoration, stale sessions, delayed end/pose ordering and empty non-mouse-capturing UI outside prompt windows. Three timed prompts do not create damage on input alone; only their consumed source contacts can do so.

The MP fixture passes 258 checks, including actual server target/action leases, source-order proof, wall rejection, fresh prompt authorization, wrong serial rejection without cancelling the real lease, canonical server damage, duplicate suppression, completion and target cleanup. Weapon MP and all existing controls, Heat, charge, taunt, sound, music, HUD/effects, style-item, custom-action and CVF regression fixtures remain green. Grabs remain disabled and the separate voice pack is untouched.

## Approved source motion and native importer

Eight reverse-finisher clips use the verified fighter_command.cfc AttackRevFin/AttackRevFinW mappings. All original body poses are retained; branch-2's second clip removes only one leading source frame to match its source pose handoff. The first finisher remains complete when no follow-up is queued.

The paired clips come directly from h23590_3combo.par, preserving 131 original source frames per actor, original scene-vector rotations and numeric movement paths. Resource actor names establish Kiryu and victim assignment. SHA256 provenance is recorded in reverse-finisher-assets.json and heat-rush-assets.json. The validator checks archive/GMT/BEP hashes, source command mappings, 25,840 finite unchanged retarget-body samples and the extracted original movement paths. Prompt contacts are PZ adaptations from motion contact estimates; no claim is made that the Dragon Engine QTE state machine was imported.

All ten new motion files import through B42's native importer. Native FK checks 1,520 hand/prop pairs with maximum matrix error below 0.00001. Nine player owners parse/select with eight single native collision events and event-only paired playback. All three victim nodes select only while their explicit flag is active. All 344 event-free MP observer nodes parse/select in two repeat cycles and retain their source clip settings. Four retained boost-light source clips also pass original-frame/source checks.

The removed payload contains two converted automatic attack clips, their two owners/eight observers and two Lua modules. No old barrage code references remain in production. All 484 existing sound/texture files match 0.58.1 byte-for-byte. There are no generated images, audio recordings, upscales, invented animation frames or voice-pack changes. Only the explicitly approved original-motion conversions add media.

## Installation and release

Verify the prior installed tree against the published 0.58.1 ZIP. Back up replaced and removed existing files only, delete only verified obsolete paths under the named ProjectYakuza mod folder, install the new files and compare the complete source/install/ZIP trees. Publish unique v0.59.0 using Publish-CombatRelease.ps1, check the uploaded asset digest and confirm a clean Git worktree. Matching server and client installs need restarting before live tests.
