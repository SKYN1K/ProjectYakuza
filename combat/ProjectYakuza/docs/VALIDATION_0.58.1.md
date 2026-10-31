# Validation: 0.58.1

The supplied screenshot and local console log show repeated attempted index: CreateItem of non-table: null errors at Barrages.lua:70 during barrage pulses. Source audit found the same unavailable factory call in two server damage paths. All three now use the installed B42 Lua global instanceItem, also used by vanilla B42 scripts. No old factory references remain in production code.

Offline validation passes 48 steps and 23 Kahlua fixtures (7,501 assertions). The refreshed framework embed also passes independently. The dedicated barrage fixture passes 83 checks with the unavailable global absent, confirms exactly one cached base item for repeated contacts, verifies expected damage and feedback, and safely skips damage if item creation returns nil. MP fixtures pass 238 and 69 checks, including barrage contacts and supplementary hit damage through the supported global. Native reflection confirms LuaManager.GlobalObject.instanceItem(String) returns InventoryItem.

All 53 production Lua modules compile. All 611 checked source files are comment-free and six lexical checks pass. All 1086 existing non-Lua media/native-definition files are byte-identical to 0.58.0. No asset files or separate voice-pack files are created or modified. No live gameplay was automated or launched; gameplay after restarting remains the user's live test.

Install only after verifying the prior installed 0.58.0 tree against its release ZIP. Back up replaced existing files only, verify full source/install/ZIP byte equality, publish unique v0.58.1 through Publish-CombatRelease.ps1, verify the GitHub asset digest and confirm a clean Git worktree. Restart matching server/client installations before testing.
