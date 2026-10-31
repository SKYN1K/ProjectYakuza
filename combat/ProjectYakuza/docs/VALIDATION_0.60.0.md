# Validation: 0.60.0

PZ was not launched. Offline validation passes 52 code/native-API steps and all 25 Kahlua fixtures. Final targeted exertion checks bring the fixture assertion total to 7,730. All 57 production Lua modules compile; all 662 checked source files contain zero comments and six lexical preservation tests pass. Live endurance balance and multiplayer stat timing still need an in-game check.

## Attack endurance

The dedicated fixture passes 72 checks using the actual Exertion and Runtime modules. It covers every configured attack class and cost ordering; actual committed lights, first finishers and floor attacks; misses; rejected native attempts; queue-only requests; repeated victim/hit feedback; automatic floor rerouting; real weapon inheritance; per-style/per-move overrides; finite/bounded values; zero/low endurance; actual capped spent-event amounts; native fitness/trait scaling; dead/remote actors; unlimited-endurance mode; weak-stamp cleanup and one payment per committed attack.

Paired-action regression now verifies one commitment at motion start and no extra commitments for QTE contacts. Tiger Drop publishes one commitment outside its multi-target kill loop. Ordinary Runtime commitments are separate from combatHit/network impact feedback. Existing 25-fixture coverage for weapons, counters, movement, charge, Heat, QTEs, UI, audio, networking and addon registration remains green.

Native reflection confirms getFatigueMod, getCharacterTraits/getTraitEnduranceLossModifier, isUnlimitedEndurance, owner detection and Stats.get/remove/set with CharacterStat.ENDURANCE. Instantiating native Stats and removing 0.02 from 0.01 returns zero. Installed CombatManager bytecode confirms PZ uses the same native fitness/trait factors in its own weapon expenditure. The mod adds one graded style cost and does not rerun that weapon calculation. Physical ENDURANCE is changed; sleepiness/FATIGUE and native exhaustion/recovery rules are unchanged.

## Documentation and asset integrity

Removed 109 superseded docs files: old release validations, historical feature notes, raw native test logs, obsolete verification/tuning reports and the old removed Extreme Heat variant manifest. Retained current guides and source-asset records, including disabled grab provenance and the HUD source-coordinate report used by a current validator. Updated references to removed validations and checked local Markdown links. Git history and previous release ZIPs preserve the old documents.

All 1132 existing non-Lua media/native-definition files match 0.59.0 byte-for-byte. No motion, image, audio or separate voice-pack files are created or modified. Source asset/importer checks were not repeated because those exact files are unchanged from the validated prior release. Extractions, compiled probes, logs, backups and credentials stay outside Git and the install payload.

## Installation and publication

Verify the complete prior 0.59.0 installation against its release ZIP. Back up changed and removed existing files only, remove only obsolete docs under the named mod folder, copy updated files, verify full source/install/ZIP equality, and publish unique v0.60.0 through Publish-CombatRelease.ps1. Verify the uploaded asset digest and clean Git status. Restart matching server/client versions for live testing.
