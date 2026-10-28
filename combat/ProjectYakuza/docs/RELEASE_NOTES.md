# Project Yakuza 0.36.0

- Pulled first-punch glow centres inside the forearm span, shortened trails, and made tiny spark emissions follow the current limb instead of lingering beyond a retracting hand. Punch effects are white-bluish in normal and Extreme Heat states.
- Rebuilt charging VFX around native B42 arm/leg paths for each first-finisher wind-up/hold; neutral charge covers both forearms. Removed the fixed facing offset and wide orbit. Existing original glints/flames/sparks only; no media was generated or changed.
- DoD charges automatically release at full power after 1.2 seconds of charge-action time (pause excluded). Earlier releases deal less damage: neutral x1..x2, first finishers x1.25..x2. Second finishers remain unchargeable. One-use tickets carry the fraction; shared style data is not mutated. Additional MP hit targets use the same bounded fraction.
- Wind-up handoff now follows a native last-frame marker, rather than a wall-clock cut; adjusted short wind-up/hold blends. Stationary charging avoids redundant tile-position updates. Pausing also suspends missing-hold acknowledgement timeout.
- Made the taunt completion flare more visible and added a 480 ms, maximum .12-gain pulse of the actual aura. It still appears only after successful taunt completion.
- Activation and sustained smoke now use the exact Extreme Heat aura tint. The existing one-second smoke cloud size, motion and transparency are preserved.
- Updated framework fields, provenance, offline tests and event-free MP observer blends. Damage/controls outside charged attacks, voice-pack files and audio assets are unchanged. Grabs remain disabled.

## Validation

4,053 offline Kahlua assertions pass; all 40 production Lua files compile. Native checks verify nine charge limb paths/87 source sample times, handoff nodes, fourteen charge nodes, 188 event-free MP observers and original media pixels/hashes. See [validation](VALIDATION_0.36.0.md).

All 455 animation/image/audio files are byte-identical to v0.35.0. PZ was not launched. Live alignment, smoothness and multiplayer appearance remain unverified; code-sampled paths still approximate final blended bones. Fully restart PZ after updating and use the same version on server/clients.
