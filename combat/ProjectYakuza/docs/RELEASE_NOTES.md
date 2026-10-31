# Project Yakuza 0.62.0

- Added style/profile-owned unarmed, blunt and blade impact feedback using existing unchanged Y6 textures. Blunt hits have a broader warm burst; blades have fewer short pale sparks and a stronger blood emphasis. Fists retain their existing feedback.
- Kept each real weapon's native audio. Weapon heavy/ground strikes add a quiet existing Y6 accent once per swing; light hits add no punch layer. Existing volume controls and sound-pool replication remain in use.
- Replicated server-derived visual family and heavy strength for primary and supplementary weapon impacts, with captured family, duplicate suppression and no additional primary damage.
- Replaced DoD armed ready/run selector references with existing B42 weapon-safe poses to address source torso/head twisting and long-blade neck clipping. Native walking legs and Yakuza attack/guard clips remain. No animation assets were created or edited; disabled source holds/runs remain available.
- Added regression coverage and developer documentation. Heat-based speed remains disabled for DoD; grabs remain disabled. No new graphical/audio assets, generated artwork, voice-pack edits or game launch.

Offline tests and native importer/selector checks pass. Live appearance and multiplayer latency were not tested. Restart the game and use matching 0.62.0 on server and clients. See VALIDATION_0.62.0.md and WEAPONS.md.
