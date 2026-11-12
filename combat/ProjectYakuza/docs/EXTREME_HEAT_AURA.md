# Heat aura and event clouds

The sustained normal heat aura retains its four original upper-body patches. Sustained Extreme Heat replaces them with four original Y6 flame patches around the chest/arms/head and two low smoke emitters. Flame loops remain 45% slower than their original setting (about 1.07–1.47 seconds); smoke keeps its slower 1.6/1.85-second loops. The Extreme Heat runtime tint is purple-blue (.25,.15,1). Smoke and activation clouds match it. Native outline timing is unchanged.

The 350 ms appearance fade, pause handling, cached sprites, world anchoring for every facing and MP heat-state replication remain active. Leaving Extreme Heat releases its six instances and restores normal emitters. Normal alpha blending is scoped and restored on rendering success or failure.

## Event clouds (0.86.0)

Completed taunts, style entry and Extreme Heat activation use broad clouds instead of thin streaks. Each event has a fixed budget of three animated fire patches and three smoke puffs, using the existing 64-frame Y6 flame/smoke sequences. The opaque-black-backed Kiwami streak is no longer loaded by HeatAura. These sources contain actual alpha transparency and render without a black rectangle.

Taunts last 450 ms, style entry 380 ms and activation one second. The clouds expand, drift outward and rise with a smooth fade, at bounded opacity (.20–.48 before the envelope and original texture alpha). Fire covers the torso/arms/head region; activation smoke originates around the feet and rises. Normal events use blue (.28,.62,1); taunts or entry during Extreme Heat use the current purple-blue mode tint. Each original sequence has its own bounded playback speed; no synthetic frames or bright additive pulse is used.

All textures are unchanged supplied DDS decodes/crops. No new pixels, alpha edits, resizing, artwork, audio, AI or upscaling were added. Source provenance remains in extreme-heat-assets.json and extreme-smoke-assets.json. The older StyleFX textures are retained but unused by these bursts. `validate_event_bursts.py` verifies original pixel/hash identity, transparency, unchanged installed-source texture baseline and native ImageData loading. Live GPU appearance still requires an in-game check after restart.


As of 0.101.0, unused TauntAura copies, old TauntBurst/wisp-only crops and superseded StyleFX textures are removed. Current normal aura retains the original HeatWisp a/b/c sequences; Extreme Heat, entry, activation and taunt bursts retain the active flame/smoke sequences and their existing runtime layouts. Historical source/crop records remain provenance, rather than a list of shipped runtime files. See ASSET_CLEANUP.md.
