# 0.26.3 validation

- Rendered supplied idle A/B/C/D and guard loops for comparison. Changed the active hybrid idle source from stdA_lp to the relaxed stdB_lp.

- Existing lower-body validator passes: all 12,274 native lower-body rotation/position keys match, loop seam closes, upper body remains animated, and both standing/moving nodes retain the same upper-only mask and 0.28-second blends.

- Native PZ animation importer accepts ProjectYakuza_DD_CombatIdleLoop: 12 seconds, 35 channels and 361 hand keys.

- Inspected current hybrid clip while standing and over native walking legs on the existing PZ mannequin.

- Separate blocking, all other motion clips and all graphical/audio assets are byte-identical to 0.26.2. No game launched.

