# Controls and settings

The [README control table](../README.md#install-and-play) lists defaults. Every mod action has mouse/keyboard mode and key options under Options > Mods > Project Yakuza. Keyboard code 0 is unbound. Aim, movement, run and sprint use native PZ binds; Shift has no mod dash shortcut.

MMB counter takes priority on initial press when valid. While aiming, tap-release queues the normal finisher/double finisher. First-finisher charges use their source 5/6/7-frame pause timings at 30 fps; neutral charge recognition remains 350 ms. Charging is stationary and vulnerable, holds its source pose until release/interruption and uses x2 native strike damage. There is no fixed DoD auto-release. Other styles retain press-triggered finishers unless they opt into heavyCharge. Space replaces shove for an enabled quickstep style; stationary steps backward. Three accepted quicksteps per rolling 15 seconds are saved on the character. Normal ground attacks use registered floor moves. Grabs/throws are temporarily disabled, including reserved G/MMB behavior.

The selector top is reserved, sides are assigned styles, bottom opens setup; assignments do not immediately switch. Empty slots do not disable the current style. The wheel does not pause the world. Entry locks movement/attacks but remains vulnerable. UI targets the first local keyboard/mouse player.

Music/Sounds/Voices are separate 0-200% sliders. Sounds applies to style sound profiles, Voices only combat CVF cues. Native Advanced Audio can adjust individual definitions. Built-in PZAPI.ModOptions persists settings without a third-party dependency. Addon Bindings.register controls appear in the same page; vanilla key interception is not automatic.

A quickstep grants at most one quickstep attack. Rapid release/repress or held attack input cannot restart/stack that strike; releasing Space cannot lift its active attack lock. Each new valid quickstep can grant a new strike. The three-step rolling quota, multihit target cap and other attacks retain their existing behavior.

Holding heavy after 1–4 lights charges that first-finisher branch using its own wind-up and strike. A second-finisher press queues immediately and cannot charge; holding it does not grant another charge afterward. The neutral heavy still uses its generic charge animation.

In 0.33.0, charged first finishers use source pause frames and persistent holds; there is no fixed DoD auto-release. Release heavy or interrupt aiming to leave charging. Source movement timing is verified, but engine-wide/full-charge skill thresholds are not claimed as exact.

## Light quickstep cancels (0.43.0)

While aiming, the bound quickstep input can cancel DoD lights after their native post-hit cancel marker. It has a 150ms input buffer and a 400ms native handoff timeout; quota/cooldown/wall checks are preserved. Other move types are unchanged. Future styles opt in with quickstepCancelLights=true and eligible light.quickstepCancelAt plus the matching native marker. See [Light quickstep cancels](LIGHT_QUICKSTEP_CANCELS.md).
