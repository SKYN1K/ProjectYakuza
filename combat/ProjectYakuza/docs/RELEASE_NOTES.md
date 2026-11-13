# Project Yakuza 0.104.0

- Added Majima: Bat Point to the normal emote wheel under Project Yakuza, based on Custom Voice Framework's native-emote approach. Hold a usable baseball bat and stand still without aiming to select it. No combat style or voice pack is required.
- Uses the original Kiwami 1 batting-center scene: Majima raises his bat toward Kiryu, holds the point and lowers it. All 152 contiguous source samples play at their original 30 fps over 5.033 seconds. The independent source bat track directs the grip; native body proportions and foot grounding keep the gesture in place.
- Preserves native and CVF emote menus, variants, shout behavior and controller aim reset. Movement/action cancellation and completion use PZ's native emote state and replicated parameters. Both clients need this release to display the custom animation.
- Requires an actual held bat; creates no items, voice recordings, Heat, damage, targeting or invulnerability. Busy, moving, aiming, seated, sleeping and unsafe equipment states are rejected.
- Offline source extraction, motion directions, native Human import/masks, hand/prop grip, menu load orders, Kahlua compilation and regression checks pass. Project Zomboid was not launched, and no local installation was performed. Live playback and multiplayer remain gameplay checks.
