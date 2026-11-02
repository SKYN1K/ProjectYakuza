# Project Yakuza

Project Yakuza is a Build 42 combat mod and a framework for independent fighting-style addons. Dragon of Dojima uses supplied Yakuza/Kiwami animations, textures and sounds. Other styles register their own moves, assets and controllers without copying the framework.

**Version 0.73.0 · Lua API 3 · MP protocol 2.** API 1 style registrations remain supported. Internal namespace/mod dependency: `ProjectYakuza`. Display name: Project Yakuza.

## Install and play

Extract the ZIP so `Zomboid/mods/ProjectYakuza/42/mod.info` exists. Enable Project Yakuza for the save. The server and every MP client need the same framework and addons. Restart after updating files.

Choose **Inventory context menu > Combat styles > Dragon of Dojima** to equip the style token. Hold Z, choose a slot, then release Z. Left defaults to DoD, right starts empty, bottom opens assignments, top unequips the style. Selecting/reselecting DoD plays its 1.67-second entry: movement and attacks are locked, but the player remains vulnerable.

Katana Heat Actions use a separate rebindable control (default RMB + MMB), only outside combos, costing one stock. Invulnerability ends with the action; zombie targeting protection lasts another 0.5 seconds. See [Heat Actions](docs/HEAT_ACTIONS.md).

| Default input | Action |
| --- | --- |
| RMB + LMB | Light chain; fresh click per attack |
| RMB + MMB | Tap-release: neutral heavy or combo finisher/double finisher; hold: charged heavy; Tiger Drop on initial press takes priority |
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
- Walking guard, Tiger Drop's 0.3-second observed-windup timing and 60-second cooldown, and Lua knockback approximating a launch.
- Six heat stocks, damage-scaled gain, banked stocks, taunt reward, multiple activation clips and Extreme Heat. Gain stops during mode; fuel expires naturally. Activation temporarily protects the player; taunts and style entry do not.
- Extreme Heat outline begins with activation, accompanied by a one-second foot smoke cloud; completed taunts use a short animated torso flare and sparks without a body-brightness pulse.
- Supplied dragon/orb HUD, world-rendered aura/impacts, native-leg stance, combat feedback, optional selected-character CVF voices and a DoD-only 19-track non-repeating-shuffle playlist.
- Animated limb coating and short sparks cover all current DoD attacks and finishers using supplied Y6 assets, source-sampled arm/leg paths and bounded world-space trails. See docs/ATTACK_EFFECTS.md.
- Yakuza 6 branch-specific charge stance/release, limb-bound original VFX, automatic release after 1.2 seconds and partial-to-x2 charged damage and a subtle native Extreme Heat outline.
- Per-style UI providers for heat, status, selector, slot art and setup; see [Style UI API](docs/STYLE_UI.md).
- Independent Music/Sounds/Voices sliders, persistent style slots, MP equipment/hit/observer synchronization and addon APIs.

Grabs remain disabled. Cinematic heat actions, camera control, direct ragdoll impulses, a Java bridge, PvP parity and a gamepad/split-screen interface are not implemented.

## Build an addon

Start with [Style authoring](docs/STYLE_AUTHORING.md) and the inactive [starter](templates/StyleSubmod/README.md). The [documentation index](docs/INDEX.md) links the API, custom actions, animation contracts, multiplayer tools, presentation and testing. No tool synthesizes visual/audio media; supply the assets your addon needs.

[Release notes](docs/RELEASE_NOTES.md) cover this version. Asset/source reports remain as provenance; old development notes are not the current manual.

## Bats and clubs

Select Dragon of Dojima and equip a [supported real bat/club](docs/WEAPONS.md). LMB uses its three-hit source weapon combo; MMB uses a standalone or queued heavy; X uses its moving guard. Native models, damage/condition and ordinary item handling remain. Profiles belong to their style and are available to addon developers. Unarmed special moves require the style item. Fully restart after installing; offline checks do not verify live grip/MP appearance.

## Sharp weapons

DoD also supports [23 knives and 13 cleavers/machetes/swords](docs/WEAPONS.md#sharp-weapons-0450). Equip a supported real blade while the style is selected: LMB runs its distinct three-hit combo, MMB performs/queues its heavy, and ordinary ground targeting uses its ground strike. The longer-blade set supports X guard; the supplied knife set has no guard. Both support light quickstep cancels. Native held models, damage, durability and sounds remain; supplementary targets respect blade reach and do not inherit knife jaw-kill damage. Heavy axes/spears retain native behavior.

The style item remains required for unarmed combat. It is temporary, kept clean and protected from normal dropping/transfers. Manually unequipping it disables the style and deletes it. The selector top slot also unequips the style. Supported real weapons stay equipped on style removal; unequipping a real weapon while retaining the style restores its unarmed item without replaying entry. See [Style item and neutral heavy](docs/STYLE_ITEM_AND_HEAVY.md).

Confirmed DoD hits now include [original animated Yakuza 6 blood](docs/BLOOD_EFFECTS.md), rendered at the zombie in world space. Heavy/charged hits use a slightly larger burst. Inventory context menu > Combat styles > Toggle hit effects controls sparks and blood together.

[Extreme Heat variations](docs/EXTREME_ATTACKS.md) now replace the unarmed neutral heavy and four first/double finisher pairs automatically during the mode, using supplied Kiryu motions. Controls and damage bonuses stay the same; the normal LMB chain and charged attacks retain their current clips.

[Encounter intros](docs/ENCOUNTER_INTROS.md) add a DoD-only Edo SZ title animation: 0–10 nearby zombies show “A bunch of brain eaters”, 11–39 “Zombies”, and 40+ “The Horde”, within 12 tiles. The framework supports independent per-style title rules, renderers and supplied sounds; other styles have no automatic intro.

[DoD locomotion](docs/LOCOMOTION.md) adds Kiryu running and relaxed weapon holds, with native walking legs and 0.25-second crossfades. Sprinting and special movement keep native behavior.

The original Yakuza 6 beer-crate conversion uses [Yakuza GMD IO](https://github.com/theturboturnip/yk_gmd_io) by Samuel Stark (TheTurboTurnip). See [crate assets and spawn ID](docs/BEER_CRATE.md).
