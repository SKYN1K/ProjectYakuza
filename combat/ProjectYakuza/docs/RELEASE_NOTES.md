# Project Yakuza 0.66.0

- Fixed the post-Extreme Heat ready-stance crash when an eight-step boost chain ended beyond normal combo step four. Playing moves retain their pose; an unavailable ready index falls back to the first normal move.
- Expanded limb coating across all 60 active DoD attack clips and 62 contact windows, including all finishers, charged attacks, directional/running/quickstep/ground attacks, Tiger Drop, Heat Rush QTE and weapon profiles.
- Added restrained irregular flame/ember movement with centred endpoints. Contact-specific arm/leg motion follows numeric FK sampled from the existing converted clips. Separate contacts reset their trail history.
- Kept the fixed 22-sprite/eight-actor budget, native source-phase tracking, pause/cleanup behavior and MP observer reconstruction. Committed/category events share one effect state; unrelated action completions cannot remove it.
- No image, audio, animation or model assets were generated or modified. Lua-only setup and normal launcher retained. Other styles remain opt-in; disabled grabs and separate voice pack are unchanged.

Offline checks pass; the game was not launched. Live appearance and network latency need in-game verification. Restart matching server/client installations. See ATTACK_EFFECTS.md and VALIDATION_0.66.0.md.
