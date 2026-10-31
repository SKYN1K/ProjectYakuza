# Project Yakuza 0.55.0

- Replaced DoD's reversing Extreme Heat finishers with four supplied Yakuza 6 boost lights and two source-timed barrages. While aiming in Extreme Heat, press LMB after the fourth light for the punch barrage, or MMB for the kick barrage. Tiger Drop retains priority. Ordinary non-Extreme attacks and weapon profiles retain their own moves.
- Punch/kick barrages retain all original source frames and 13/five BEP contact windows. They lock movement, remain interruptible by injury and use up to three nearby frontal targets. Late contacts are skipped rather than replayed together. Existing supplied hit effects, blood and sounds provide feedback.
- Added bounded server-side barrage contact authorization, source timing, duplicate protection, target/path limits and server-calculated damage. An already-started barrage can finish after Heat depletes, without retaining its damage bonus or authorizing a new barrage.
- Slowed Kiryu's running stride by 21.875% across unarmed/bat/knife/blade profiles. Compensated the native deferred-movement track to preserve actual running speed. Body poses, source frame times, native walking legs and carry holds are unchanged.
- Removed the nine obsolete directional animation assets and their 45 owner/observer nodes. Added six boost/barrage assets and matching isolated nodes. No image/audio assets or voice-pack files changed. No AI assets were generated.

Offline Kahlua, source/native animation and multiplayer protocol checks pass. PZ was not launched; live rendering and multiplayer latency remain untested. Fully restart matching client/server installations after updating. Grabs remain disabled. See VALIDATION_0.55.0.md.
