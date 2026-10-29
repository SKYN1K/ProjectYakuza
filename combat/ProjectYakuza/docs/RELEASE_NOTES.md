# Project Yakuza 0.41.0

- Fixed the taunt completion error: native colour userdata must be updated with :set(...), not by assigning .r/.g/.b/.a. A stricter read-only fixture catches the reported failure, and native Color/ColorInfo setter checks pass. The approved taunt tint, animation, size and timing are retained.
- Added opt-in juggling infrastructure for future styles: launcher/followup/ender declarations, bounded soft/hard windows, hit/relaunch limits, landing cooldowns, victim animation variables and lifecycle hooks. SP/server confirmed hits drive the state; MP relays resolved metadata and ordered landing/timeout results. DoD gains no juggle moves. Airborne animations/physical lift must be provided by a future addon; the core never fabricates them.
- Removed the approximate shoulder-yaw correction from punch particles, which could shift the arm when rotating. Added a live-limb adapter API consuming final forearm/hand world positions without sampled yaw/insets. No Java bridge/live provider is bundled; the current Lua fallback remains approximate.
- No visual/audio/animation assets were created or modified. Grabs remain disabled. See [Juggling](JUGGLING.md) and [punch effects](ATTACK_EFFECTS.md).

## Validation

4,076 offline Kahlua assertions pass and all 41 production Lua files compile. New checks cover juggling limits, actual SP/server hit integration, relay/order/cleanup, live-coordinate projection over eight facings, provider failures, and the native colour setter regression. All 551 media files remain byte-identical to v0.40.0. See [validation](VALIDATION_0.41.0.md).

Installed locally and published with a separate versioned ZIP. PZ was not launched. Live taunt rendering, residual punch alignment and multiplayer appearance remain unverified; fully restart and use matching versions on server/clients.
