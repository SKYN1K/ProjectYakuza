# Project Yakuza 0.107.0

- Removed the bundled Majima, Lau Ka Long and Kiryu cutscene emotes from combat. Their Lua hooks, selectors, animation assets and dedicated documents now belong to the standalone Project Yakuza Emotes 0.1.0 mod.
- Install and enable the separate addon if you want the gestures. It works without Project Yakuza combat or Custom Voice Framework and remains compatible with either.
- Combat gameplay and all retained combat media are unchanged. The addon preserves Majima/Kiryu and extends Lau by 2.5 seconds using original continuation frames, with support for all native spears and modded spear-class fallback. Native cancellable playback is retained.
- All 31 offline Kahlua suites, independent Lua compilation, native motion checks, split/reference validation, CVF load-order integrations and zero-comment checks pass. Local migration backs up changed/removed files and verifies both installed mod trees. Project Zomboid was not launched; live visual/MP testing remains outstanding.
