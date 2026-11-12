# Project Yakuza 0.102.0 validation

Dragon of Dojima now gains full confirmed-hit Heat from the first eligible unique victim in a swing and 25% from subsequent victims. Repeated callbacks remain deduplicated. A new swing restores full first-target gain. Weapon views inherit the style rule; other styles retain the default multiplier of 1 and can opt in through heatConfig.secondaryTargetGain (0..1). Damage, hit caps, stamina, action prices, banked stocks and normal/Extreme drain are unchanged.

Taunts require a live, non-useless zombie targeting the player within five tiles on the same level with an unobstructed native path. Tests reject idle, dead, distant and obstructed targets and allow an actively attacking threat. Request, queued start and completion recheck eligibility. Losing the threat prevents reward and completion signaling while restoring controls. MP refuses an unqualified lease and rejects completion attention when the threat disappears. The attention reaction retains its existing standing/non-attacking filter.

Tiger Drop now accepts at most 160 ms of observed frontal attack windup and has a 20,000 ms cooldown in both client and authoritative server rules. Tests exercise 160/161 ms, duplicate victims, the final millisecond before cooldown expiry and the exact ready boundary. The existing server burst window for collateral packets remains separate from input eligibility.

First equip retains the full installed Lost Judgment dod source motion, 151 samples at 60 fps for 2.5 seconds. Selecting while a style is already equipped uses the source battle-control/cancel start at 31/30 seconds, followed by the existing idle fade. Source timing is an adapted cancel handoff, not a claimed playback multiplier or full LJ state-controller port. Native motion playback stays 1x. Per-action duration is copied so a fast selection never modifies the registered full entry. Equipment readiness retries, same-slot selection and MP acknowledgement preserve the prior-equipped choice.

All 30 Kahlua suites pass offline. Selected suite counts:

- heat-speed-tests.lua: 177 checks.
- taunt-tests.lua: 241 checks.
- mp-tests.lua: 1891 checks.
- style-entry-tests.lua: 40 checks.
- style-item-tests.lua: 27 checks.
- style-selector-tests.lua: 174 checks.
- repair-tests.lua: 20 checks.

All 83 production Lua files compile in the native Kahlua compiler. The source-comment gate reports zero comments across 1004 checked source files; its six lexical regression tests pass. The runtime-reference gate verifies 258 retired assets remain absent, all 167 active motion clips, 263 textures, 111 audio files, Lua imports and dynamic selectors.

validate_combat_entry.py checks the supplied archive entry hash and original BEP control-window node, original source/mapping hashes and unchanged output motion. Its full native path imports 35 channels and 151 right-hand keys, verifies 302 native hand/prop pairs (maximum matrix error 0.00000746), all 151 grounded support frames, 3775 preserved body/finger samples, and native entry/relaxed/RMB/armed selector behavior. All existing motion, model, texture, audio and native animation-selector bytes match v0.101.1. No assets were generated or rebuilt.

Local installation verifies the existing v0.101.1 ZIP baseline, backs up only changed existing files, writes the update and verifies every installed byte. The release ZIP and installed/source file sets are verified again after publication. Project Zomboid was not launched. Live visual blending, threat behavior with actual AI and MP latency remain gameplay checks after a matching client/server restart.
