# Project Yakuza 0.50.0

- Added a Dragon of Dojima-exclusive on-screen encounter intro using the supplied Edo SZ HQ font and original Yakuza 6 flare asset. Character entry animation and combat controls remain unchanged.
- Titles within 12 tiles: 0–10 “A bunch of brain eaters”, 11–39 “Zombies”, 40+ “The Horde”. Counts are performed once per encounter, in batches of at most 64 loaded zombie entries per tick, with an early stop at the highest tier.
- Added the encounter StyleUI channel, validated per-style configuration, custom renderer lifecycle, optional supplied sound key, title rules and lifecycle events for framework developers. Other styles have no intro unless they opt in.
- Intros use a mouse-transparent panel, pause-aware animation, quiet-time rearming, bounded/throttled detection and cleanup on style/eligibility changes. They do not lock the player or change the camera/world.
- Font conversion and original texture decoding were explicitly approved. No AI, upscaling, invented artwork or new audio. See VALIDATION_0.50.0.md for offline evidence; PZ was not launched.

Install matching server/client versions and fully restart. Existing combat animations, damage, heat effects, blood assets and the separate voice pack are unchanged. Grabs remain disabled.
