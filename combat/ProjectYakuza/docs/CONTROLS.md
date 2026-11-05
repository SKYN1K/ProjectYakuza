# Controls and settings

The [README control table](../README.md#install-and-play) lists defaults. Every mod action has mouse/keyboard mode and key options under Options > Mods > Project Yakuza. Keyboard code 0 is unbound. Aim, movement, run and sprint use native PZ binds; Shift has no mod dash shortcut.

MMB counter takes priority on initial press when valid. While aiming, tap-release performs the neutral heavy with no combo, or queues the normal finisher/double finisher after lights. First-finisher charges use their source 5/6/7-frame pause timings at 30 fps; neutral charge recognition remains 350 ms. Charging is stationary and vulnerable, holds its source pose until release/interruption and uses x2 native strike damage. There is no fixed DoD auto-release. Other styles retain press-triggered finishers unless they opt into heavyCharge. Space replaces shove for an enabled quickstep style; stationary steps backward. Three accepted quicksteps per rolling 15 seconds are saved on the character. Normal ground attacks use registered floor moves. RMB + Grab (G) grabs a standing zombie; a fresh Grab press throws it. Light strikes while held. Releasing RMB keeps the grab active; throw with Grab instead. An eligible wall Heat Action takes priority on its own binding (MMB by default). See [Grabs](GRABS.md).

The selector top is reserved, sides are assigned styles, bottom opens setup; assignments do not immediately switch. Empty slots do not disable the current style. The wheel does not pause the world. Entry locks movement/attacks but remains vulnerable. UI targets the first local keyboard/mouse player.

Music/Sounds/Voices are separate 0-200% sliders. Music controls combat tracks independently of the vanilla Music option. Sounds applies to style sound profiles, Voices only combat CVF cues. Native Advanced Audio can adjust individual sound/voice definitions; combat track gain is owned by the mod Music slider. Built-in PZAPI.ModOptions persists settings without a third-party dependency. Addon Bindings.register controls appear in the same page; vanilla key interception is not automatic.

A quickstep grants at most one quickstep attack. Rapid release/repress or held attack input cannot restart/stack that strike; releasing Space cannot lift its active attack lock. Each new valid quickstep can grant a new strike. The three-step rolling quota, multihit target cap and other attacks retain their existing behavior.

Holding heavy after 1â€“4 lights charges that first-finisher branch using its own wind-up and strike. A second-finisher press queues immediately and cannot charge; holding it does not grant another charge afterward. The neutral heavy still uses its generic charge animation.

In 0.33.0, charged first finishers use source pause frames and persistent holds; there is no fixed DoD auto-release. Release heavy or interrupt aiming to leave charging. Source movement timing is verified, but engine-wide/full-charge skill thresholds are not claimed as exact.

## Light quickstep cancels (0.43.0)

While aiming, the bound quickstep input can cancel DoD lights after their native post-hit cancel marker. It has a 150ms input buffer and a 400ms native handoff timeout; quota/cooldown/wall checks are preserved. Other move types are unchanged. Future styles opt in with quickstepCancelLights=true and eligible light.quickstepCancelAt plus the matching native marker. See [Light quickstep cancels](LIGHT_QUICKSTEP_CANCELS.md).

With DoD selected and a [supported bat/club](WEAPONS.md) equipped: RMB+LMB runs a three-hit weapon combo, RMB+MMB performs/queues one weapon heavy, RMB+X guards with native walking legs, and ground targeting uses the weapon ground strike. Quicksteps retain their existing binding/quota and can cancel lights. Unarmed special moves require the style item.

The same weapon controls now apply to supported knives and longer blades. X guard is available on the sweeping-blade profile (cleavers/machetes/swords); the knife profile has no source guard and does not block. Full item lists and supplementary-hit rules: [Weapons](WEAPONS.md#sharp-weapons-0450).

Heavy input (MMB by default) checks Tiger Drop before charging/finishers during the first 300ms of an observed frontal zombie attack windup. Damage already registered or a completed bite cannot be undone. The existing 60-second cooldown and unarmed DoD requirement remain. A separately bound counter key also works.

In Extreme Heat, the eighth light input can flow into DoD's paired retail punch rush and finishing kick if that strike hits a surviving, standing zombie or eligible PvP player and there is clear space. The first seven inputs may miss or hit different targets. The last character hit by the eighth strike is selected; earlier targets are not substituted. Follow Light → Heavy → Grab → Light → Heavy → Grab (default LMB → MMB → G twice), using a fresh press for each prompt. All three action bindings are respected; QTE presses do not trigger ordinary grab/throw actions. A held button does not count. The QTE uses animated original ring graphics without an extra ready cue. The first miss ends DoD’s rush with the original automatic paired kick. The paired handoff starts after the eighth confirmed contact, with unrelated supplemental settlement bounded to 80 ms. PvP settings, safety, factions, non-PvP zones and protected players remain respected. Boost lights stun zombies in place for 250 ms and suppress native push/knockdown for the swing. Turning at least 145 degrees between a light and a first finisher selects its original reverse variant; a second finisher retains the matching variant.

DoD attacks now consume [graded endurance](EXERTION.md): lights cost the least, heavies/finishers and charged attacks cost more. Misses count; repeated hit effects and multihit victims do not add costs. PZ handles the exertion moodle and recovery.


## Katana Heat Action (0.70.0)

The separate Heat Action binding defaults to MMB and is fully rebindable. Physical RMB must still be held. With DoD and Base.Katana equipped, use it outside a combo near a standing target with at least one stock. Combo follow-up windows retain normal heavies. The action grants invulnerability until it ends and zombie targeting protection for another 0.5 seconds. See [Heat Actions](HEAT_ACTIONS.md).


Version 0.71.0 adds three separate [intact bottle weapons](BOTTLE_WEAPONS.md) and their DoD-exclusive original Heat Action. Use the same rebindable Heat Action input while physically holding RMB, outside combos. Ordinary drink bottles are unchanged.

A quickstep pressed while RMB is physically held can wait up to 350 ms for the native aim transition to become ready. A brief tap is retained; releasing RMB, interruption, style change or timeout discards it. Walls, cooldown, quota and unsafe states still reject the action. Supported [beer crates](BEER_CRATE.md) use DoD's Short Blunt profile.

## Quickstep startup and QTE timing (0.74.0)

Space followed immediately by RMB re-arms the native quickstep during the short aim transition. The quota and cooldown begin only when a live animation produces movement. A failed startup restores the old movement flags without spending a charge or displaying a job progress bar. Root movement follows native track time and retains the original distance.

Heat Rush uses the earlier recovery-cancel entry again. Its six press windows are all 600 ms and the next bound input appears immediately after a correct press, with impacts still timed to the original animation.

The beer-crate Heat Action uses RMB plus the configured Heat Action binding outside combos, then two fresh presses of that binding per one-second mash stage. Three stages maximum. Releasing RMB during an ordinary DoD grab keeps it held; the Grab binding throws. Any zombie can break out at a 5% per-second chance during hold.
