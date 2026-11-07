# Project Yakuza 0.91.0

- Reworked paired Heat Action damage in the shared framework: nonlethal configured hits reduce health on contact; a lethal hit and subsequent damage are held until the entire paired animation, including recovery, finishes. Every authored hit retains its sounds, blood, sparks and voice feedback.
- Cinematic contact damage no longer calls ordinary native melee Hit, which could switch the victim animation or kill the target mid-sequence. Native terminal consequences handle death and kill credit after completion. Interrupted sequences discard held lethal damage while preserving nonlethal damage already dealt.
- Extended the native hitreaction-state latch to all paired Heat Actions and restore it on cleanup. This prevents katana contacts from restarting the victim's original paired clip.
- Rebuilt katana trails from the current three-contact move: sword-hand slash, opposite-hand punch and sword-hand thrust. Removed the stale fourth trail during recovery. Sparks/blood use source-pose neck/torso anchors for the sword hits.
- Server health snapshots accompany confirmed paired contacts and completion, including owner echoes. Replay guards prevent duplicate packets from applying an old health snapshot twice. Damage, input and target validation remain server-authoritative.

Original attacker/victim animation frames, speeds, durations, three katana strike times and supplied visual/audio assets are unchanged. Reference: the supplied Yakuza 6 video around 06:18. QTE windows are unchanged. Offline validation only; PZ was not launched. See [damage policy](HEAT_ACTION_DAMAGE.md) and [validation](VALIDATION_0.91.0.md). Restart matching game/server versions after installing.
