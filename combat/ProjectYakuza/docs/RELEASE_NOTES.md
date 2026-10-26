# 0.30.3 - Extreme Heat activation sound polish

- Softer runtime mix for the existing non-voice Yakuza 6 charge, flare layers and ending cue. The charge fades into the native flare marker over 140 ms instead of overlapping at full level.
- Preserves the original 300 ms second-layer timing after successful short animations; its job no longer shares/competes with swing SFX. Successful native End provides a fallback when a slow frame skips the transient flare marker.
- Duplicate events do not stack cues. Pause preserves timing, natural tails release cleanly, and interrupted/lifecycle cleanup stops only owned SFX with no false ending flourish.
- Existing voice cues, sound files/definitions, Sounds slider, combat timing and aura visuals are unchanged. No audio/visual asset generation or edits.

## Validation

2,664 targeted Kahlua checks pass: 35 activation-audio checks plus 2,629 combat/aura/music regressions. All 33 production Lua files compile. Tests cover crossfade levels, original delay, short completion, independent swing scheduling, duplicate events, pause, missed-marker fallback, native tail completion/watchdog, invalid handles, optional profiles, owner-only playback and cleanup that preserves unrelated audio. All 376 media files are byte-identical to v0.30.2. No PZ client/server was launched. Changed installed files are backed up and all installed bytes verified.
