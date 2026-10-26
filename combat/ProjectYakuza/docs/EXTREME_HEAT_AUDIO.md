# Extreme Heat activation SFX - 0.30.3

Uses the existing supplied Yakuza 6 non-voice recordings: charge_st (ChargeStart), both hactmode_on layers (HeatOnA/HeatOnB) and hactmode_off (HeatOff). Audio bytes, native sound definitions, Sounds user-volume settings and the separate character-voice integration are unchanged. No recording was generated, edited or added.

| Stage | Timing | Runtime level |
| --- | --- | --- |
| Charge | Actual native action start | 0.28 (previously 0.40) |
| Main flare | Native flare marker; successful End fallback if a slow frame skips it | 0.50 (previously 0.65) |
| Charge fade | 140 ms after flare | Linear fade to zero, then stop only that handle |
| Secondary flare | Original 300 ms after main flare | 0.32 (previously 0.50) |
| Mode ending | Actual natural depletion | 0.42 (previously 0.65) |

These are per-handle mix levels, separate from the player's Sounds slider and each original clip's gain. The original flare recordings last about 2.31/2.27 seconds; a bounded 2.8-second post-completion ownership window covers their tails and source delay. When native handles stop naturally, the callback releases sooner. No idle tick callback remains.

Activation sequencing now has its own session instead of sharing the swing-sound queue. A completed animation retains its delayed layer and tails; starting an ordinary strike cannot overwrite them. Duplicate start/flare/success notifications do not stack new cues. Pause preserves the remaining delay and fade. Interrupted/failed actions, style changes, death, unequip and save/menu exit clear owned sounds/jobs. Cleanup reasons do not play a misleading natural mode-ending cue. No other emitter handles (music/voices) are stopped. Remote observers do not request duplicate owner SFX.

Validation: 35 focused checks embed production Feedback.lua; 2,629 broader combat/aura/music checks also pass. All 33 production Lua files compile. Source hashes confirm all 376 visual/audio files match v0.30.2. No game was launched and final loudness has not been auditioned in the live PZ mix.
