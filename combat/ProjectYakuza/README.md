# Project Yakuza

Project Yakuza is a Build 42 combat mod and a framework for independent fighting-style addons. Dragon of Dojima uses supplied Yakuza/Kiwami/Lost Judgment animations, textures and sounds. Other styles register their own moves, assets and controllers without copying the framework.

**Version 0.118.0 · Lua API 3 · MP protocol 2.** API 1 style registrations remain supported. Internal namespace/mod dependency: `ProjectYakuza`. Display name: Project Yakuza.

## Install and play

Extract the ZIP so `Zomboid/mods/ProjectYakuza/42/mod.info` exists. Enable Project Yakuza for the save. The server and every MP client need the same framework and addons. Restart after updating files.

Hold Z, choose Dragon of Dojima in the left slot, then release Z to equip the style token. Left defaults to DoD, right starts empty, bottom opens settings and style assignments, top unequips the style. Selecting/reselecting DoD plays the 2.5-second blue Dragon entry from the installed Lost Judgment dod mod: movement and attacks are locked, but the player remains vulnerable.

Ground-trample Heat Actions use RMB plus the rebindable Heat Action input near a downed zombie outside a combo, costing one heat stock. Ordinary paired actions move both actors to nearby clear space; wall actions face their selected wall. The compact red HUD bar shows native overall health.

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

All mod controls are rebindable under **Options > Mods > Project Yakuza**. Shift only uses native running. RMB + G grabs, a fresh G press throws the held zombie, and LMB strikes while holding. Releasing RMB keeps the grab active; there is no manual let-go input. With RMB held, MMB performs a Heat Action on the grabbed zombie: the wall action takes priority beside a suitable wall, otherwise the original Yakuza 6 shoulder throw and follow-up is available in clear open space. Both cost one full heat stock. Throws can knock down up to four nearby standing zombies. See [Grabs](docs/GRABS.md). Normal ground attacks use the supplied stomps.

## Included systems

- Native melee collisions, short buffers, conditional recovery, pose-linked double finishers, multihit capped at three targets and ground/running/dash strikes. DoD lights use x0.75 damage and finishers x1.25 before heat modifiers.
- Walking guard, Tiger Drop's 160 ms observed-windup timing and 20-second cooldown, and Lua knockback approximating a launch.
- Six heat stocks, damage-scaled gain with 25% secondary-target gain per swing, banked stocks, threat-gated taunt reward, multiple activation clips and Extreme Heat. Gain stops during mode; fuel expires naturally. Activation temporarily protects the player; taunts and style entry do not.
- Extreme Heat outline begins with activation, accompanied by a one-second foot smoke cloud; completed taunts use a short animated torso flare and sparks without a body-brightness pulse.
- Supplied dragon/orb HUD, world-rendered aura/impacts, native-leg stance, combat feedback, optional selected-character CVF voices and a DoD-only 19-track non-repeating-shuffle playlist.
- Animated limb coating and short sparks cover all current DoD attacks and finishers using supplied Y6 assets, source-sampled arm/leg paths and bounded world-space trails. See docs/ATTACK_EFFECTS.md.
- Yakuza 6 branch-specific charge stance/release, limb-bound original VFX, automatic release after 1.2 seconds and partial-to-x2 charged damage and a subtle native Extreme Heat outline.
- Per-style UI providers for heat, status, selector, slot art and setup; see [Style UI API](docs/STYLE_UI.md).
- Independent Music/Sounds/Voices sliders, persistent style slots, MP equipment/hit/observer synchronization and addon APIs.

Paired Heat Actions and zombie grabs are included. Camera control, direct ragdoll impulses, a Java bridge, full PvP parity and a gamepad/split-screen interface are not implemented.

## Build an addon

Start with [Style authoring](docs/STYLE_AUTHORING.md) and the inactive [starter](templates/StyleSubmod/README.md). The [documentation index](docs/INDEX.md) links the API, custom actions, animation contracts, multiplayer tools, presentation and testing. No tool synthesizes visual/audio media; supply the assets your addon needs.

[Release notes](docs/RELEASE_NOTES.md) cover this version. Asset/source reports remain as provenance; old development notes are not the current manual.

## Bats and clubs

Select Dragon of Dojima and equip a [supported real bat/club](docs/WEAPONS.md). LMB uses its three-hit source weapon combo; MMB uses a standalone or queued heavy; X uses its moving guard. Native models, damage/condition and ordinary item handling remain. Profiles belong to their style and are available to addon developers. Unarmed special moves require the style item. Fully restart after installing; offline checks do not verify live grip/MP appearance.

## Sharp weapons

DoD also supports [23 knives and 13 cleavers/machetes/swords](docs/WEAPONS.md#sharp-weapons-0450). Equip a supported real blade while the style is selected: LMB runs its distinct three-hit combo, MMB performs/queues its heavy, and ordinary ground targeting uses its ground strike. The longer-blade set supports X guard; the supplied knife set has no guard. Both support light quickstep cancels. Native held models, damage, durability and sounds remain; supplementary targets respect blade reach and do not inherit knife jaw-kill damage. Heavy axes/spears retain native behavior.

The style item remains required for unarmed combat. It is temporary, kept clean and protected from normal dropping/transfers. Manually unequipping it disables the style and deletes it. The selector top slot also unequips the style. Supported real weapons stay equipped on style removal; unequipping a real weapon while retaining the style restores its unarmed item without replaying entry. See [Style item and neutral heavy](docs/STYLE_ITEM_AND_HEAVY.md).

Confirmed DoD hits now include [original animated Yakuza 6 blood](docs/BLOOD_EFFECTS.md), rendered at the zombie in world space. Heavy/charged hits use a slightly larger burst. Style wheel > bottom settings > Hit effects controls sparks and blood together.

[Extreme Heat variations](docs/EXTREME_ATTACKS.md) now replace the unarmed neutral heavy and four first/double finisher pairs automatically during the mode, using supplied Kiryu motions. Controls and damage bonuses stay the same; the normal LMB chain and charged attacks retain their current clips.

[Encounter intros](docs/ENCOUNTER_INTROS.md) add a DoD-only Edo SZ title animation: 0–10 nearby zombies show “A bunch of brain eaters”, 11–39 “Zombies”, and 40+ “The Horde”, within 12 tiles. The framework supports independent per-style title rules, renderers and supplied sounds; other styles have no automatic intro.

[DoD locomotion](docs/LOCOMOTION.md) adds Kiryu running and relaxed weapon holds, with native walking legs and 0.25-second crossfades. Kiryu walking and sprinting now use native PZ cadence/travel; weapon walking retains native legs. Special movement keeps native behavior.

The original Yakuza 6 beer-crate conversion uses [Yakuza GMD IO](https://github.com/theturboturnip/yk_gmd_io) by Samuel Stark (TheTurboTurnip). See [crate assets and spawn ID](docs/BEER_CRATE.md).

The bottom style-wheel slot opens settings: First Style, Second Style, hit effects, heat aura and diagnostics. Each style row previews its optional developer-supplied selectorIcon. Save applies changes; Cancel/Escape discards them. The inventory context submenu has been removed.

As of 0.92.0, weapon holds and ordinary armed movement use vanilla Zomboid poses. Ordinary unarmed walking also uses vanilla animation timing. Custom weapon attack/guard/Heat Action clips remain active; the converted hold and walking clips are retained but disabled.

Beer-crate Essence of Crushing uses the rebound Heat Action button: two fresh presses per one-second stage, capped at three stages. Held zombies can escape at a 5% chance per second using the original paired separation. See docs/HEAT_ACTIONS.md, docs/GRABS.md and docs/QTE.md for controls and framework authoring.

Dragon of Dojima low-health feedback starts at 30% health, becomes critical at 15%, and clears after healing to 35%. The original health-bar frame pulses gently; an existing PZ heartbeat plays privately during combat and follows Sounds volume. See docs/LOW_HEALTH_FEEDBACK.md for framework configuration.



The three cutscene gestures are now in the separate **Project Yakuza Emotes** mod. Install and enable that addon if you want them; combat no longer includes their Lua hooks or animation assets. See [validation](docs/VALIDATION_0.107.0.md).

Lau Ka Long’s Spear is available as ProjectYakuza.LauKaLongSpear, displayed as Lau Ka Long’s Spear in the native item list. It uses the original Kiwami model and reduced original diffuse, native two-handed spear attacks/carry/sounds, and the forged long spear’s damage, reach and durability. It does not select a custom Dragon weapon profile. With Project Yakuza Emotes enabled it qualifies for Lau’s spear gesture. Spawn it through the debug item list; this update adds no loot distribution or recipe.
