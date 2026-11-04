# Project Yakuza 0.80.0

- Enabled unarmed Dragon of Dojima grabs with walking, maintained victim pairing and explicit native AI-state ownership. The old short hold expiry is removed, and release/interruption/exhaustion/disconnect restore saved flags.
- Added four original paired grab strikes on the Light binding. Contacts use original source collision frames, damage once, and retain a surviving victim in the hold. Movement locks only during each strike.
- Added the original Yakuza 6 wall Heat Action while holding a zombie near a solid wall, costing one heat stock. The configured Heat Action input takes priority over throwing when eligible, with the existing game-art input prompt.
- Wall actions use paired source movement, timed existing hit effects/sounds and optional combat voices, full-action invulnerability and the existing targeting grace. Doors/windows and blocked pair paths reject activation.
- Added MP grab IDs, source-timed strike validation, replay/stale-packet guards and an authoritative grab-to-Heat-Action transfer. Owner and observer cancellation restore AI locks. Existing weapon-pose fallback and selector/settings fixes remain active.

Only approved original motion was converted. No generated artwork/audio, AI, upscaling, game JAR changes or separate voice-pack edits. Project Zomboid was not launched. See [grabs](GRABS.md) and [validation](VALIDATION_0.80.0.md). Restart PZ and use matching versions on server and clients.
