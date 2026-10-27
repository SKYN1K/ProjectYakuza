# Project Yakuza 0.33.0

- Fixed charging falling back to idle: each wind-up now transitions into a native looping hold of its original source pose. Missing hold playback cancels cleanly. No new animated poses were invented.
- Read Kiryu's actual source BEP Charge markers (frames 6/7/6/5 at 30 fps) and hit windows. Charged wind-ups/releases now use those source splits, source contact timing and 1x playback. Removed DoD's arbitrary 3.5-second forced release; hold until release/interruption. Global Dragon Engine/full-charge thresholds remain unverified, so this is not claimed as complete 1:1 engine logic.
- Added original-asset charge effects: ten sparks, a small animated transparent flame, a glint core and a brief ready pulse. All render in world space, pause and clean up; no UI overlay or generated graphic is added.
- Fixed Extreme Heat's black flame background by using the supplied original alpha-bearing texture variant and normal alpha blending. No alpha repainting/background generation is used.
- Slowed Extreme Heat flame playback by exactly 45% (speed x0.55, roughly 1.07–1.47-second loops). Smoke, normal heat, HUD appearance, damage, controls and voice-pack files are unchanged.
- Added four event-free hold observers per MP cycle; server/clients need the same version. Source hashes/pose matching, native loader paths, texture pixels and native import checks remain required.

## Validation

Offline Kahlua, native import/node selection/texture decode and source timing/pixel checks pass; see [validation](VALIDATION_0.33.0.md). PZ was not launched, so live GPU appearance, exact input feel and live MP remain unverified. Installation backs up changed files and verifies source/install/ZIP bytes.
