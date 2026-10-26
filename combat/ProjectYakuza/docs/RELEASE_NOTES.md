# 0.30.4 - One quickstep attack per step

- A quickstep can issue one handover and one accepted quickstep strike. Duplicate completion callbacks and consumed/expired/direction-mismatched tickets cannot replay it.
- Native attack input stays locked during the strike, including when Space is released. Repeated swing callbacks cannot restart it, and completion immediately selects the normal light node.
- Real native submission failures can still retry within the existing window; the first delayed native swing is accepted normally. Each new valid quickstep can grant a fresh strike.
- No new cooldown, damage, animation, hit timing, multihit, quota or other proposed mechanics were added. All existing media and the separate voice pack are untouched.

## Validation

2,765 targeted Kahlua checks pass: 71 one-strike quickstep checks, 2,629 combat/aura/music checks, 42 addon API checks and 23 heat/shove checks. All 33 production Lua files compile. All 376 animation/image/audio files retain v0.30.3 bytes. No game was launched. Installation backs up only changed files and verifies installed source bytes.
