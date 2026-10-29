# Project Yakuza 0.43.0

- Added quickstep cancels for all four Dragon of Dojima lights while aiming. Use the normal quickstep binding plus direction (or backstep without movement). The window opens one original animation frame after the strike's collision; no input preserves full playback.
- Added a short 150ms input buffer and a bounded native recovery handoff. Buffered attacks are cleared, native hands/state must release before the quickstep starts, and failures/interruption restore input ownership.
- Preserved three quicksteps per 15 seconds, cooldown, movement collision and one quickstep attack per dash. Quota is spent by the actual quickstep start. Finishers, charged/ground/running/quickstep attacks and other actions do not gain this cancel.
- Added optional quickstepCancelLights/quickstepCancelAt authoring fields and four owner-only marker events. No motion/texture/audio assets changed. Hitstop stays deferred; grabs stay disabled.

## Validation

4,133 offline Kahlua assertions pass and all 41 production Lua files compile. Targeted checks cover each light, native exit ownership, exact quota spending, input buffering/expiry, duplicate/held input, cooldown/walls, excluded move types, interruption/pause/timeout/reset cleanup and opt-out. Native parsing covers all 18 charge/light owner nodes; the four cancel markers are exactly one source frame after collision. All 188 MP observers remain event-free. All 551 media files match v0.42.0. See [validation](VALIDATION_0.43.0.md).

Installed locally and published with a separate versioned ZIP. PZ was not launched; live cancel feel and MP transition timing remain unverified. Fully restart and use matching server/client versions.
