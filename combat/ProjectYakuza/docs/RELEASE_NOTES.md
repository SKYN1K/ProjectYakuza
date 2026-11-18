# Project Yakuza 0.128.0

- Enlarged the limb smoke footprint by 26% and the inner flame footprint by 10%, keeping the corrected hand/foot anchors and short shrinking tail. The existing 48-sprite budget, movement variation, sparks and original source frames remain.
- Changed overlapping flame cores to ordinary alpha blending, reduced their opacity and used a saturated blue tint. This prevents the bright white arm coating shown in the supplied screenshot. Small embers and brief impact glints retain additive drawing.
- Shared by the regular combat installation and optional phone development add-on. No asset pixels, animations, audio, combat timing or damage change.
- Offline validation: 29,884 limb presentation, native projection, alpha blending, attachment, lifecycle and bounded multiplayer assertions; all production Lua compilation; source-comment and runtime package checks. Installed changed files are backed up and verified byte-for-byte. PZ was not launched, so final appearance and frame rate require an in-game check.
