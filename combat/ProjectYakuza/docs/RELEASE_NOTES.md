# Project Yakuza 0.56.0

- Fixed remote melee attacks restarting when their timed-action context counter arrived after the native swing. Melee/stomp and timed-action clips now use separate restart counters; repeated barrages still restart correctly.
- Added server-assigned player sessions so reconnects/recycled IDs can restart counters safely. Old-session hits/states are discarded and only that peer's replay/deferred caches are reset. Replaced actors release temporary protection and retained leases.
- Fixed stale remote players retaining weapon-profile, charge/link flags, Heat state and limb effects. Aura/outline and observer actions are released with the old actor. Missing addon styles clear presentation safely.
- Reduced redundant snapshots during hits, dash samples and barrages while preserving changed-state-before-command ordering and heartbeats.
- Corrected server hit-response/juggling lookup to use the equipped weapon profile, matching SP behavior.
- Fixed RMB-released bat/knife/blade idle and walking poses by selecting existing native relaxed weapon holds, including run/walk blend entries. The former frozen combat-ready arm pose no longer applies there. Custom attacks, aimed stances and Kiryu's compensated running cadence are unchanged.
- Updated multiplayer and locomotion documentation and regression coverage. No motion, image, audio or voice-pack assets were created or modified.

Offline Kahlua, source/native selector and protocol checks pass. PZ was not launched; live multiplayer latency/ownership and visual behavior still need an in-game test. Restart the server and all clients with matching 0.56.0 files. Grabs remain disabled. See VALIDATION_0.56.0.md.
