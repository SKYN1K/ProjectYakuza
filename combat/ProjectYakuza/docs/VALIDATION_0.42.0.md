# Validation — 0.42.0

No game/client/server was launched. This is a single heat-gain coefficient change (2.5 to 1.25); no animation, graphics, audio, networking or control logic changed.

Relevant Kahlua checks: framework/heat 2,647; heat/shove 27; taunt/aura 198; total 2,872. All 41 production Lua files compile. New persistent assertions verify .4 damage gives .5 raw heat, repeat victims in the same swing give none, damage above two remains capped at 2.5 raw heat, and the stock size/mode duration remain unchanged. Existing taunt tests verify one-stock completion reward and no gain while mode is active.

The scoped installer checks installed bytes against v0.41.0, backs up only changed files, then verifies source/install files. The unique v0.42.0 install ZIP and remote release digest are compared after publication. No media file was changed or added. Hitstop remains deferred.
