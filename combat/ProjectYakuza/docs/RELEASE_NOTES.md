# Project Yakuza 0.83.0

- Gave all six Dragon of Dojima Extreme Heat Rush QTEs a full one-second countdown. Original source contact poses remain intact; actor/victim playback, timers and MP authority share a paced clock. Other styles keep their authored timing.
- Added per-cue `countdownMs` and optional `sourceStartMs` for developers, with bounded validation and unchanged legacy timing.
- Starts the DoD Rush handoff after the eighth confirmed contact without waiting for the late chain marker. MP reservations overlap recovery; unrelated supplemental hit settlement is bounded to 80 ms.
- Face stomp now requires a living zombie lying face-up on the floor, excluding falling/getting-up targets; rechecked when the action starts and by the server.
- Recalibrated grab holds, all four grab strikes and throws against the converted Zomboid skeleton. Added per-move forward/lateral offsets, short position blends, stable strike/throw facing and continued victim following through throws. MP uses the same staging rules.
- Removed DoD's voice loudness multiplier and taunt gain override. The combat Voices slider remains; the separate CVF voice pack is untouched.

Code/XML changes only. No animation, artwork or audio files were created or changed. Validated offline without launching PZ; see [validation](VALIDATION_0.83.0.md). Restart with matching client/server versions.
