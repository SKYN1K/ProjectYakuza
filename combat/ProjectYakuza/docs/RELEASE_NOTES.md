# Project Yakuza 0.92.0

- Replaced guessed katana timing with the original Yakuza 6 CMN scene data. Three damage hits occur at source frames 24, 44 and 64. Total damage is unchanged, with the original 1:1:2 weighting.
- Added the action's five original sound-bank cues at their authored starts: swing, slash, punch, thrust and landing. Removed generic layered impacts from this action; landing does not create a fourth hit.
- Repaired the original paired clips for native PZ arm lengths, retained all 141 frames at original speed, and adjusted victim spacing smoothly for the face punch. Rebuilt blood anchors from original particle-bone offsets and regenerated the three right-arm trails.
- Added validated, independent audioEvents and voiceEvents to the framework. Katana uses the source actor voice timings through existing CVF combat entries. No separate voice pack or voice volume was changed.
- Moved built-in paired Heat Actions out of the cancellable native timed-action queue. Cancel inputs cannot remove them, and ordinary queued actions cannot replace them during playback. Pause and required world/server cleanup remain available.

Lethal damage remains held until the full paired animation ends. QTE windows, other combat moves and other supplied media are unchanged. Only approved original source animation repairs and audio decoding were used: no AI, invented motion, generated artwork or synthesized sounds. Offline validation only; PZ was not launched. See [validation](VALIDATION_0.92.0.md) and [presentation](HEAT_ACTION_PRESENTATION.md). Restart the game; server and clients must use matching versions.
