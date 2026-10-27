# Controls and settings

The [README control table](../README.md#install-and-play) lists defaults. Every mod action has mouse/keyboard mode and key options under Options > Mods > Project Yakuza. Keyboard code 0 is unbound. Aim, movement, run and sprint use native PZ binds; Shift has no mod dash shortcut.

MMB counter takes priority on initial press when valid. While aiming, tap-release queues the normal finisher/double finisher. Hold at least 350 ms while free to start a stationary, vulnerable charge; release after its 350 ms minimum charge pose for the x2 native strike. Holding automatically releases after 3.5 seconds in the charge pose. Other styles retain press-triggered finishers unless they opt into heavyCharge. Space replaces shove for an enabled quickstep style; stationary steps backward. Three accepted quicksteps per rolling 15 seconds are saved on the character. Normal ground attacks use registered floor moves. Grabs/throws are temporarily disabled, including reserved G/MMB behavior.

The selector top is reserved, sides are assigned styles, bottom opens setup; assignments do not immediately switch. Empty slots do not disable the current style. The wheel does not pause the world. Entry locks movement/attacks but remains vulnerable. UI targets the first local keyboard/mouse player.

Music/Sounds/Voices are separate 0-200% sliders. Sounds applies to style sound profiles, Voices only combat CVF cues. Native Advanced Audio can adjust individual definitions. Built-in PZAPI.ModOptions persists settings without a third-party dependency. Addon Bindings.register controls appear in the same page; vanilla key interception is not automatic.

A quickstep grants at most one quickstep attack. Rapid release/repress or held attack input cannot restart/stack that strike; releasing Space cannot lift its active attack lock. Each new valid quickstep can grant a new strike. The three-step rolling quota, multihit target cap and other attacks retain their existing behavior.
