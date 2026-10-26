# Pose-matched double finishers, 0.12.0

No second MMB press: the first finisher keeps its complete original clip. A second press queues the follow-up; only the matching current hit marker plus the short branch-specific ProjectYakuzaDoubleReady window can interrupt the first. If the input misses the window, native completion happens first and the original double-finisher clip is used. The existing late-input combo timeout is unchanged.

| Branch | First source exit frame | Follow-up source entry | Entry correction frames |
| --- | --- | --- | --- |
| 1 | 25 | 0 | 4 |
| 2 | 31 | 4 | 5 |
| 3 | 26 | 0 | 4 |
| 4 | 26 | 2 | 6 |

Source clips are 30 fps and play at existing combat speed. Each window closes three source frames after opening. The first-finisher .x files and original double-finisher .x files are unchanged. Four new linked entry clips are derived from the matching original conversions. The first linked pose equals the selected first-finisher pose on every rotation and translation channel. A smooth quaternion/translation offset fades to zero over the correction frames; all remaining source motion is preserved. Contact markers are remapped for entry trims and still occur after the correction finishes.

First-finisher blend-out is 0.12s; follow-up blend-in is 0.10s. A temporary native movement-ignore hold spans the cleanup gap and linked follow-up so movement input cannot briefly select an aiming/walking pose. The hold restores the previous value and clears on completion, cancellation, unequip, aim-release without a follow-up, interruption or startup timeout. It does not add target scans or damage calls.

Runtime ProjectYakuzaLinkedDouble is cached with the existing visual variables. Native node selection chooses exactly one original or linked follow-up; both have one collision event. Package checks compare every linked entry channel to its first-finisher exit and all post-correction keys to the original follow-up, and validate window and collision fractions. The native importer processes all four new clips. Rendered contact sheets confirm entry pose agreement; 533 Kahlua checks cover unqueued, queued, late, cleanup and existing combat behavior.

Build scripts: work/analyze_finisher_pairs.py and work/build_linked_finishers.py. No GMT source files were changed. In-game visual blend and timing confirmation remain pending; renders cannot reproduce native frame pacing.
