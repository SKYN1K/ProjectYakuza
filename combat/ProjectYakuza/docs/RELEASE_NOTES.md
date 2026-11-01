# Project Yakuza 0.67.0

- Fixed Heat Rush ready attempts being consumed during temporary native recovery. They now wait and retry within a bounded window, including granted multiplayer attempts; expired grants release their server reservation.
- Allowed a standing, facing target within two tiles after normal hit knockback. The same rule applies to owner and server, retaining eight confirmed boost lights, survival, clear paths/space and MP proof checks.
- Fixed multi-hit target mismatch between the owner and server. The first eligible surviving target is retained, and same-swing contacts cannot inflate proof counts.
- Added connected-light progress and a ready handoff label before the existing source-timed MMB prompts, using native text only.
- Reduced all eight Extreme Heat boost-light entries by 30% (damage multiplier 0.75 to 0.525). Normal lights, finishers and QTE contact damage retain their existing values.

Offline checks pass; Project Zomboid was not launched. No graphical, audio, animation or model assets were generated or modified for this update. Grabs remain disabled and the separate voice pack is unchanged. Restart matching server/client installations. See VALIDATION_0.67.0.md.
