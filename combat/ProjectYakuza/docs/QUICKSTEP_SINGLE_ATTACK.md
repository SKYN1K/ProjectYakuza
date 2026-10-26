# One attack per quickstep - 0.30.4

Each quickstep may issue only one handover ticket, and an accepted native strike consumes it. Rapid input cannot restart/stack a second quickstep strike. Native attack input is gated during the strike, including while releasing the quickstep/shove key. A duplicate swing notification cannot classify another move or reset strike state. Completion immediately restores the normal light node; the next valid quickstep receives its own entitlement.

Native-busy or truly rejected submissions may retry inside the original handover window because no attack occurred. Expired, consumed, cancelled or direction-mismatched tickets cannot dispatch a strike. Synchronous and delayed native swing events are supported. Duplicate/late timed-action completion is inert.

This introduces no new cooldown and does not change three quicksteps per rolling 15 seconds, animation/hit timing, damage, multihit, heat or other move types. All changes are code/configuration documentation; existing media and the separate voice pack are untouched.

Validation: 71 focused checks embed production Registry/Bindings/Combo/Runtime/Quicksteps and the DoD style. They cover all four directions, rapid taps, native permission restoration, shove-release interaction, duplicate callbacks, consumed tickets, true failure retries, delayed first swing and late cancelled completion. Broader combat/aura/music, addon API and shove/heat checks also pass; 33 runtime Lua files compile. No PZ client/server was launched.
