# Project Yakuza 0.47.0

- Added Kiryu's ordinary neutral heavy: aim and tap-release MMB without a combo. Holding still charges; combo finishers, doubles and Tiger Drop retain their routing.
- Repaired hand-following prop tracks for all bat/knife/blade clips and four quicksteps using native B42 grip offsets. Body/finger motion is preserved.
- Kept the unarmed style item, with cleanliness and normal drop/transfer protection. Manually unequipping it disables the style and deletes it. Supported weapon equips retain the style; removing a real weapon restores the temporary unarmed item without entry replay.
- Top style-selector circle now unequips the style. Real weapons remain equipped; left/right style slots and bottom setup remain.
- Added actual-module equipment/heavy tests and native prop attachment/provenance checks. No game startup or live MP test; see VALIDATION_0.47.0.md for offline evidence and limits.

Install the same version on server and clients, then fully restart. Approved source animation edits only; no new generated graphical/audio assets. Grabs remain temporarily disabled. Separate voice pack unchanged.
