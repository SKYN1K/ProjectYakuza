# Project Yakuza 0.42.0

- Reduced damage-based heat gain by 50%: min(damage,2) * 1.25 raw points instead of * 2.5.
- Completed taunts still award one orb. Heat losses, stock count, Extreme Heat duration/costs and no-gain behavior during mode remain unchanged.
- No visual/audio/animation assets changed. Hitstop remains deferred; grabs remain disabled.

## Validation

2,872 relevant offline Kahlua assertions pass across framework/heat, heat-control and taunt fixtures; all 41 production Lua files compile. Tests cover exact half-rate gains, per-victim deduplication, capped damage contribution, preserved stock/duration rules, blocked gains in Extreme Heat and the unchanged taunt reward. See [validation](VALIDATION_0.42.0.md).

Installed locally and published with a separate versioned ZIP. PZ was not launched. Fully restart; server and clients need the same version.
