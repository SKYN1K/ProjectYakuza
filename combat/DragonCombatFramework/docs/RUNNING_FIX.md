# Running attack startup, 0.11.1

The user's console records running inputs selecting dd_run_02 and dd_run_03 but timing out in PlayerMovementState with action=run/sprint. The earlier test parsed the added transition XML directly, which did not verify that the game discovers those files. Native ActionGroup.load enumerates its physical media directories, so standalone mod transition files are not sufficient.

Running attack requests now save movement flags, hold movement, and clear native moving/running/sprinting. During the short arming phase they wait for native idle or movement, then call AttemptAttack once. Existing native idle/movement-to-melee transitions handle entry; aim is not forced and the AI state is not changed directly. A startup timeout, interruptions, unequip and death release held movement. Travel starts only after OnWeaponSwing accepts the strike.

RunningEntryProbe loads the installed native player ActionGroup and updates an actual ActionContext: run -> idle -> melee and sprint -> idle -> melee both pass with aim false, without loading added transition files. Kahlua checks cover all four layouts, delayed entry, one submission, held input, cancellation and timeout cleanup. These checks do not replace live-game input confirmation.
