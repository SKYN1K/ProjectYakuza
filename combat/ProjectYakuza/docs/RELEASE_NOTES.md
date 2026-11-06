# Project Yakuza 0.89.0

- Fixed the low-health feedback error when hitting a zombie. B42 also fires OnPlayerGetDamage for non-player victims; the callback now checks the native IsoPlayer type before calling player-only methods.
- Applied the same local-player guard to low-health event marking, polling and eligibility checks. Zombie, invalid and remote-player payloads are ignored safely; real local-player damage still refreshes the warning immediately.
- Added a regression that sends 512 native-shaped zombie WEAPONHIT events using a zombie stub that throws on any player-method access.

Existing low-health thresholds, HUD/audio behaviour, combat timing, effects and assets are unchanged. Offline validation only; PZ was not launched. See [validation](VALIDATION_0.89.0.md). Restart game/server after updating matching MP versions.
