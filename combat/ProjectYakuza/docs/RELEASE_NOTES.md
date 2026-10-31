# Project Yakuza 0.60.0

- Added graded attack-endurance costs to Dragon of Dojima, including its supported weapon profiles. Lights cost the least; heavies, finishers, charged attacks and paired finishes cost more. Normal PZ exhaustion and recovery handle the resulting endurance loss.
- Costs apply once when an attack commits, including misses, with native fitness/trait scaling. Rejected/queued input and cancelled charge holds are free. Multi-target hits, automatic ground rerouting, QTE hits and remote observers do not stack duplicate costs. Unlimited-endurance mode is respected and costs cannot exceed available endurance.
- Native weapon expenditure remains intact. Added optional per-style/per-weapon cost tables, per-move enduranceCost and documented commitment/spending events for addon authors.
- Removed 109 obsolete docs files: superseded feature notes, old release validations, raw test logs and outdated verification reports. Retained current guides and asset-source records, including disabled grab assets. Only the current validation report is distributed; history remains in earlier Git commits/releases.
- Added offline Runtime/exertion, paired-action commitment and native API checks. All new source and tools are comment-free. No visual/audio/animation assets were created or modified, and the separate voice pack is untouched.

PZ was not launched. Restart matching 0.60.0 client/server installations before testing. See EXERTION.md and VALIDATION_0.60.0.md.
