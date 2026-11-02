# Project Yakuza 0.74.0

- Restored the previous Extreme Heat Heat Rush recovery-cancel entry and 80 ms paired blend.
- Made all six QTE windows consistently 400 ms, with the next input shown immediately after a valid press. Overlapping acceptance windows preserve sequential controls and original hit timing.
- Stabilized Heat Action endings: surviving zombies retain their source facing and settle directly to the native ground state, owned action clips clear cleanly, and deferred health settlement avoids an extra native stagger/fall reaction.
- Added varied existing impact SFX, stronger supplied spark presets and layered finishing-kick sounds at the original contacts. Rush punches and the final kick use the existing CVF light/heavy attack voice pools. The separate voice pack is untouched.
- Fixed Space then RMB quickstep startup: retry interrupted aim transitions, follow the live animation track, and spend quota/cooldown only after actual movement. Failed startup has no progress bar or spent charge.
- Extreme Heat lights now suppress native stagger animation while retaining the short in-place stun and restoring the original stagger flag afterward.

Only existing supplied assets are reused. Project Zomboid was not launched. See [validation](VALIDATION_0.74.0.md); restart after installing matching server/client versions.
