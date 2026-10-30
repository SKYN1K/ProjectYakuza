# Validation: 0.47.0

PZ was not launched. No GPU appearance, live gameplay or live multiplayer test is implied.

## Runtime and item lifecycle

4,339 Kahlua assertions across 17 fixtures pass. All 44 production Lua files compile. The new 25-check actual-module item fixture covers cleanliness, mixed favourites, drop/transfer protection, deferred native hit blood cleanup, manual unequip/disable/delete, timed equipment transitions, supported/unsupported weapons, automatic return to unarmed without entry, client deletion authority and neutral heavy routing. The 45-check weapon MP fixture verifies actual server cleanup with native equipment acknowledgements while preserving real items. The selector fixture has 50 checks including top-slot style removal. Charge/UI has 183 checks including neutral tap-release, full cleanup, charging and doubles. The refreshed framework embeds current production modules, has 2,654 checks, and exercises the neutral heavy with multihit and expired combo routing.

Existing light quickstep limits/cancels, weapon profiles, native damage/reach, charges, finishers, MP packet/ownership protections, CVF adapters, music/settings, original texture effects, addon registration and disabled grab definitions remain covered. The double-routing regression caught by the new neutral tap sequence is fixed by requiring no pending/current finisher before choosing the neutral variant.

## Source motion and native import

The supplied normal heavy retains source frames 0–50 at 30 fps. Original BEP contact starts at frame 9; its owner node has exactly one collision at 9/50. Normal heavy uses 1.6 playback, x1.25 damage, and creates no double branch. Source GMT/BEP/output hashes and authorization are in normal-heavy-assets.json.

PropAttachmentProbe uses B42 Jassimp/ProcessedAiScene plus native FK to validate both hand-relative prop matrices at every frame: 31 clips, 2,568 pose pairs, maximum matrix error 0.000007212162 against a 0.0001 tolerance. Native authored bat/knife offsets and source/output hashes are recorded in prop-attachment-repair.json. The old 0.46.0 clip fails the same detached-prop assertion. All body/finger animation blocks and bytes outside the two prop blocks in the 30 existing clips match the prior ZIP exactly, including original line endings. Skeleton hierarchy, timing and source frames are unchanged. The extra clip is the explicitly approved source heavy conversion.

Native validation imports 27 weapon/normal-heavy clips and 41,720 finite bone samples; parses/selects 33 isolated owner nodes; checks 19 light/charge/heavy strike nodes and single contacts; and validates 280 event-free observers (140 per cycle). Native style item methods for blood/dirt/favourite, owner-container transfer and removal exist. Charge hold/source contact timing, limb paths, original HUD/aura pixels, no-black-matte flames and approved taunt colour copies retain their checks.

## Scope and release

No image, sound or model changes. Of 577 prior motion/image/audio files, only the 30 authorized prop-track clips change; one approved source heavy clip is added. The existing 397 native XML files remain unchanged; five new owner/observer XML files are added. Grabs remain disabled and the separate voice-pack project is untouched. Six lexical preservation tests pass; the comment audit reports zero comments in 512 tracked/whitelisted source files. The publisher passes native PowerShell parsing.

The installed 1,198-file 0.46.0 tree passes an exact prior-ZIP preflight. Back up only existing changed files, install the 0.47.0 payload, then compare the entire source/install tree and unique release ZIP. GitHub release asset digest must match the local ZIP. Runtime visual grip under walking overlays/blends and MP replication still require user testing after fully restarting matching server/client versions.
