# Project Yakuza 0.86.0

- Dragon of Dojima grabs stay held when RMB is released. Grab (G by default) throws; required interruptions still restore movement and AI safely.
- Every held zombie has a 5% escape chance checked once per second during the hold. The original complete Yakuza 6 paired separation plays before release. Multiplayer rolls on the server; stale or duplicate packets cannot restart it.
- Added the original Yakuza 5 H3270 Essence of Crushing sequence for the beer crate. Hold RMB and use the rebound Heat Action input outside a combo near a standing target. It costs one heat stock, or equivalent Extreme Heat fuel.
- The crate action has three one-second repeat sections. Two fresh Heat Action presses complete each section; holding the button does not count. Missing a section branches into the original ending. Repeats are capped, and the crate follows its original object track rather than the punching hand.
- Framework authors can configure grab break-outs and finite mash QTEs, including required presses, minimum press interval, feedback and base payoff damage. Existing single-press QTEs and the six Extreme Heat Rush prompts retain their behavior.

- Replaced the thin taunt/style-switch/Extreme Heat activation bursts with broader original animated Y6 fire and smoke clouds. Removed the opaque-black-backed streak from the live aura renderer. Clouds expand, drift and fade in the matching heat colour with a fixed six-particle budget. Sustained normal/Extreme Heat aura profiles are unchanged.

Only approved source-animation conversions were added. Existing graphical/audio assets and the separate voice pack are unchanged. Offline checks passed; PZ was not launched. See [validation](VALIDATION_0.86.0.md). Restart the game/server and use matching versions on every MP client.
