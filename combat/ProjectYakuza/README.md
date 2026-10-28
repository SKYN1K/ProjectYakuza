# Project Yakuza

Project Yakuza is a Build 42 combat mod and a framework for independent fighting-style addons. Dragon of Dojima uses supplied Yakuza/Kiwami animations, textures and sounds. Other styles register their own moves, assets and controllers without copying the framework.

**Version 0.34.0 · Lua API 3 · MP protocol 2.** API 1 style registrations remain supported. Internal namespace/mod dependency: `ProjectYakuza`. Display name: Project Yakuza.

## Install and play

Extract the ZIP so `Zomboid/mods/ProjectYakuza/42/mod.info` exists. Enable Project Yakuza for the save. The server and every MP client need the same framework and addons. Restart after updating files.

Choose **Inventory context menu > Combat styles > Dragon of Dojima** to equip the style token. Hold Z, choose a slot, then release Z. Left defaults to DoD, right starts empty, bottom opens assignments, top is reserved. Selecting/reselecting DoD plays its 1.67-second entry: movement and attacks are locked, but the player remains vulnerable.

| Default input | Action |
| --- | --- |
| RMB + LMB | Light chain; fresh click per attack |
| RMB + MMB | Tap-release: finisher/double finisher; hold: charged heavy; Tiger Drop on initial press takes priority |
| Space + direction | Quickstep; stationary steps backward; three per rolling 15 seconds |
| LMB during quickstep | Directional quickstep attack; one strike per step |
| Running, RMB released + LMB | Random side kick/jumping knee after run-up |
| Running, RMB released + MMB | Dropkick in travel direction |
| RMB + X | Walking block |
| RMB + Q | Taunt; completed playback grants one heat stock and brief aura flash |
| RMB + N | Extreme Heat activation; no manual off toggle |
| Hold Z | Style selector |

All mod controls are rebindable under **Options > Mods > Project Yakuza**. Shift only uses native running. G grab/MMB throw are reserved but temporarily disabled. Normal ground attacks use the supplied stomps.

## Included systems

- Native melee collisions, short buffers, conditional recovery, pose-linked double finishers, multihit capped at three targets and ground/running/dash strikes. DoD lights use x0.75 damage and finishers x1.25 before heat modifiers.
- Walking guard, Tiger Drop's final-0.2-second timing and 60-second cooldown, and Lua knockback approximating a launch.
- Six heat stocks, damage-scaled gain, banked stocks, taunt reward, multiple activation clips and Extreme Heat. Gain stops during mode; fuel expires naturally. Activation temporarily protects the player; taunts and style entry do not.
- Supplied dragon/orb HUD, world-rendered aura/impacts, native-leg stance, combat feedback, optional selected-character CVF voices and a DoD-only 19-track non-repeating-shuffle playlist.
- First-light left-fist/forearm glow, short trails and sparks use original Y6 assets and source-sampled positions; its existing whoosh follows the native clip clock. This is a scoped prototype; other attacks retain their effects.
- Yakuza 6 charge stance/release, blue world sparks, x2 charged-hit damage and a subtle native Extreme Heat outline.
- Per-style UI providers for heat, status, selector, slot art and setup; see [Style UI API](docs/STYLE_UI.md).
- Independent Music/Sounds/Voices sliders, persistent style slots, MP equipment/hit/observer synchronization and addon APIs.

Grabs remain disabled. Cinematic heat actions, camera control, direct ragdoll impulses, a Java bridge, PvP parity and a gamepad/split-screen interface are not implemented.

## Build an addon

Start with [Style authoring](docs/STYLE_AUTHORING.md) and the inactive [starter](templates/StyleSubmod/README.md). The [documentation index](docs/INDEX.md) links the API, custom actions, animation contracts, multiplayer tools, presentation and testing. No tool synthesizes visual/audio media; supply the assets your addon needs.

[Release notes](docs/RELEASE_NOTES.md) cover this version. Asset/source reports remain as provenance; old development notes are not the current manual.
