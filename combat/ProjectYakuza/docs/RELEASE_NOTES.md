# Project Yakuza 0.65.0

- Rebuilt the configured punch trail as overlapping animated coating from the PZ shoulder to fist, with soft inner cores and short white-blue hand sparks. All layers use normal alpha and existing supplied assets.
- Added native-imported shoulder positions to the existing numeric PZ source track. The current pose uses continuous rendered facing; recent trail poses remain in world space when turning. Teleports reset history.
- Added fixed twelve-pose history and a 22-sprite/eight-actor budget, reused native clip slots, same-clock animation suppression, pause/interruption cleanup and MP observer reconstruction without extra packets.
- Kept the Lua-only normal launcher. This remains source-pose tracking rather than live blended-bone attachment, as selected by the user. Optional limb providers may supply a shoulder endpoint. Existing move scope, charge effects, body aura, victim impacts and combat rules are unchanged.
- No graphical/audio/animation/model assets or separate voice-pack files were changed. Only code-side numeric positions and rendering code changed; grabs remain disabled. Source remains comment-free.

All offline Lua fixtures and native source/projection checks pass. PZ was not launched and live appearance has not been verified. Restart matching server/client installations. See ATTACK_EFFECTS.md and VALIDATION_0.65.0.md.
