# Project Yakuza 0.93.0

- Fixed quickstep cleanup when its native animation fades below the startup weight or disappears before the final update. End markers and a bounded missing-track fallback release movement, and cleanup explicitly exits the owned native timed-action animation once.
- Limited quickstep startup retries to the period before visible playback. Changing aim or RMB during an established dodge no longer restarts it. Directional attacks and the three-per-15-second quota keep their existing rules.
- Fixed crowded weapon and ground Heat Action selection. Candidates are tried nearest first until the paired animation fits. The weapon search no longer drops candidates after the first sixteen, and the ground search no longer stops after the first 96 moving objects.
- Preserved a feasible combo Heat Action victim when later crowd contacts are blocked or ineligible. Valid later confirmed victims still follow the existing last-hit rule; a pending or granted multiplayer request keeps its feasible target.
- Documented the existing Heat drain rules and stock retention. Heat tuning and action costs are unchanged.

Validated offline without launching PZ. All 11 selected Kahlua suites pass, all 75 production Lua files compile, and source checks find zero code comments. No motion, texture or audio assets changed. See [validation](VALIDATION_0.93.0.md) and [Heat rules](HEAT.md). Restart PZ after updating; server and clients must use matching versions.
