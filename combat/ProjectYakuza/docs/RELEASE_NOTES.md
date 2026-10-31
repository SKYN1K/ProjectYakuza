# Project Yakuza 0.57.0

- Added DoD unarmed directional light strikes. While aiming, turn at least 65 degrees between light attacks for a side strike, or at least 145 degrees for the rear kick. Smaller changes keep the existing combo. Selection is manual and performs no target acquisition or steering.
- Converted the three approved supplied Kiryu directional clips, retaining source frames/root motion orientation and native hand-prop offsets. Directional strikes end the combo, retain x0.75 light damage and existing Extreme Heat bonuses, and support normal post-contact quickstep cancels.
- Completed taunts now draw up to eight eligible nearby zombies' attention through native AI aggro/targeting. They skip attacks in progress, downed/dead/unusable zombies and blocked paths. Existing heat reward and aura are unchanged.
- Added bounded, completion-only taunt scans and server-authorized MP reactions with duration/style/item checks, current sessions, target selection, ownership, deduplication and short streaming retries.
- Added style opt-in configuration, move lookup/validation, three native owners and twelve event-free MP observers, documentation and offline regression/source/native checks.

Only the approved supplied animation conversions create media files. Existing motion, image, audio and voice-pack files are unchanged; no AI, invented animation or new artwork/audio was used. PZ stayed closed. Restart matching 0.57.0 server/client installs before testing. See VALIDATION_0.57.0.md.
