# Validation: 0.46.0

PZ was not launched. This report separates counted runtime work from a live FPS/gameplay benchmark.

## Functional and counted-work checks

All 4,301 Kahlua assertions across the existing 16 fixtures pass. The expanded MP/weapon fixture has 41 checks and verifies 1,000 warm clip/move lookups do not rescan arrays, re-registering the same style invalidates its weak index, network registration refreshes catalogue caches, and case/priority/selected clip remain unchanged. In its actual third long-blade light scenario, native animator reads fall from 14 to 5. No actor-variable values are reused across selections.

The taunt/aura fixture now has 200 checks. A body-only draw of six emitters reads five actor position/offset methods once instead of 30 calls. One hundred stable aura updates perform zero global render-hook scans. Existing tests verify pause, disposal/pooling, alpha blend restoration, original frame timing, source colours, taunt fade/size, activation foot-cloud and normal/Extreme handoff. The tint assertion checks actual rendered smoke colours after removal of the unused old colour field.

All 42 production Lua files compile. Existing MP ownership, cooldowns, duplicate prevention, real sharp/blunt weapon damage/reach, style isolation, charging, controls/settings, style selector, CVF adapter, addon APIs and future juggling/limb hooks remain tested. Disabled grabs and reserved action definitions remain present.

## Comment/source cleanup

check_source_comments.py reports zero comments across 498 tracked/whitelisted source files and supported fenced documentation code examples. The scanner handles Lua quoted/long strings, Java/item-script strings, Python token comments/docstrings, PowerShell strings and XML CDATA. Lua/C/PowerShell removal verifies identical non-comment token signatures. Six Python tests cover literal comment markers, URL strings, long Lua delimiters, Unicode docstrings, empty documented function bodies, PowerShell and XML ownership/CDATA preservation.

All nine tracked Java probe sources recompile; the PowerShell publisher parses with its native parser. Test module injection uses executable no-op string markers, not source comments. The shipped addon observer builder generates comment-free XML processing-instruction/Lua string ownership stamps. Native addon selector/importer/compile and deterministic generation/overwrite-safety checks pass. Runtime limb-track headers were removed and their code provenance hashes updated; native numeric samples are identical.

## Assets/install/release

All 577 existing motion/image/audio files are byte-identical to 0.45.0. Existing native animation XML remains unchanged. Native import of 26 weapon clips/39,935 bone samples, 32 weapon owner selectors, 276 event-free observer selectors, original source contact windows, persistent charge holds, native colour/instance contracts and exact aura/HUD pixel/provenance checks pass. No media was generated or deleted. Separate voice-pack content is untouched.

Install by preflighting against the prior release, backing up only existing changed installed files, then verifying all source/install bytes. Publish a unique 0.46.0 tag/install ZIP with Publish-CombatRelease.ps1 and compare ZIP/source/install payloads and GitHub asset digest. Local detailed reports/backups remain ignored. Fully restart on matching server/client versions to assess actual FPS, blend appearance and MP timing in game; those were not tested here.
