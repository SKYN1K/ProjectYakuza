# Project Yakuza 0.90.0

- Synchronized sounds, sparks and blood to the actual playing Heat Action animation for Extreme Heat Rush, katana, bottle, beer crate, wall and ground stomp, including paired failure endings.
- Measured the existing audio clips' transient lead-ins and start playback just before the corresponding contact. Bare punches and kicks use body-impact sounds; Rush no longer stacks rising boost effects over every second punch.
- Replaced fixed standing/ground effect heights with 31 head/torso contact samples from the existing native PZ victim animations. Impact effects and blood share the same copied world contact position in every direction.
- Prevented stale impact catch-up bursts and duplicate presentation from damage/network messages. Multiplayer observers reconstruct presentation from their playing paired animation. Interrupted actions stop their presentation sounds and remove idle hooks.

No animations, textures or audio assets were created or modified. QTE inputs/windows, hit damage and gameplay contact timing are unchanged. Offline validation only; PZ was not launched. See [validation](VALIDATION_0.90.0.md) and [presentation details](HEAT_ACTION_PRESENTATION.md). Restart game/server after installing matching MP versions.
