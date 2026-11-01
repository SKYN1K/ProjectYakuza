# Project Yakuza 0.70.0

- Added the original Yakuza 6 katana Heat Action from h23720_buki_e.par to Dragon of Dojima while holding Base.Katana. The attacker and victim retain all 141 source frames at 30 fps, with native weapon grip repair.
- Added a separate Heat Action control, default MMB, rebindable under Options > Mods > Project Yakuza. Physical RMB remains mandatory. The action starts only outside combos, near an eligible standing target, and costs one heat stock (or the equivalent Extreme Heat fuel). Combo MMB finishers retain their existing behavior.
- Added shared HeatActions protection for current and future action handlers. Invulnerability lasts only during the action; zombie targeting protection lasts through it and for 500 ms afterward. Native flags are restored on completion, interruption, watchdog expiry and world exit. Existing paired Heat Rush uses this lifecycle too.
- Extended paired playback and server authorization to the katana motion, automatic source-timed contacts, typed player/zombie targets, victim clip isolation and event-free MP observers. The final source contact applies weapon damage; earlier contacts provide presentation without prematurely interrupting the victim motion.
- Added source provenance, native importer/grip/node validation and offline input/protection/MP regression coverage. No AI, generated artwork/audio or upscaling is used. The relaxed-idle preview remains outside the mod.

Project Zomboid was not launched. See [validation](VALIDATION_0.70.0.md). Install the same release on the server and clients and restart after updating.
