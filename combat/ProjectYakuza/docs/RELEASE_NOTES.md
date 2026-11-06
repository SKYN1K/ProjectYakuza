# Project Yakuza 0.88.0

- Added Dragon of Dojima low-health feedback: a restrained red pulse on the original health-bar frame and a low-health/critical label. Warning begins at 30% overall body health and intensifies at 15%; recovery at 35% prevents threshold flicker.
- Added a quiet private 2D heartbeat during confirmed combat or native nearby/chasing threats. It uses PZ's existing Character/Foley/Heartbeat event through a separate mod sound definition, follows Sounds volume, and yields to the vanilla heartbeat instead of stacking it.
- Heartbeat stops after six quiet seconds, healing, pausing, sleep, vehicle entry, death or style unequip. It does not broadcast to MP peers or attract zombies. The HUD warning remains while health is low outside combat.
- Framework developers can opt styles into configurable thresholds, recovery, audio gain/cue, quiet timeout and HUD visibility. Custom style UI receives the current low-health pulse strength. Other styles remain opted out.

Code-only update using existing HUD textures and the installed game's heartbeat event. No visual/audio/motion assets were generated or converted, no voice pack changes, and no damage/health/AI changes. Offline checks passed; PZ was not launched. See [validation](VALIDATION_0.88.0.md). Restart game/server and use matching versions for MP.
