# Dragon of Dojima reference style

Project Yakuza v1.0.13 packages version **1.0.13**, Lua API **3** and multiplayer protocol **2**. For independent style development, start with [Style authoring](docs/STYLE_AUTHORING.md) and the [API reference](docs/API_REFERENCE.md).

## Install and select

Download the named B42 install ZIP from [v1.0.13](https://github.com/SKYN1K/ProjectYakuza/releases/tag/v1.0.13). Extract it so `Zomboid/mods/ProjectYakuza/42/mod.info` exists, enable Project Yakuza for the save and restart PZ. Servers and clients need matching framework and add-on versions.

Hold Z, point at a slot and release Z to equip it. Left defaults to Dragon of Dojima; right starts empty. The bottom slot opens assignments and settings. The top slot unequips the style. The wheel does not pause gameplay. Other registered styles appear in the assignment list automatically.

The v1 player packages contain vanilla bat/club, knife and blade support and their supported Heat Actions. Custom beer crates, bicycles, intact bottles and Lau Ka Long's spear are development-only and are excluded from both player ZIPs. Removed custom items are skipped by PZ's inventory loader when older saves are loaded.

## Default controls

| Input | Action |
| --- | --- |
| RMB + LMB | Light chain; a fresh click advances each attack |
| RMB + MMB | Heavy attack / finisher; hold to charge; a valid Tiger Drop takes priority |
| RMB + MMB outside a combo, with an eligible Heat Action target | Heat Action; uses its separately rebindable input |
| RMB + Space and direction | Quickstep; stationary input steps backward |
| LMB during quickstep | One directional quickstep attack |
| Running without RMB + LMB | Running strike |
| Running without RMB + MMB | Dropkick |
| RMB + X | Guard; supported blade and blunt profiles also have guard |
| RMB + G | Grab; a fresh G press during the hold throws |
| LMB while holding a zombie | Grab strike |
| RMB + Q | Taunt; a nearby pursuing threat is required for Heat reward |
| RMB + N | Activate Extreme Heat |
| Hold Z | Style wheel |

Configure controls, HUD scale and Music/Sounds/Voices under **Options > Mods > Project Yakuza**. Light Attack controls the light chain, running strikes and quickstep attacks. Heavy Attack / Finisher controls heavy attacks, finishers, the running dropkick and correctly timed Tiger Drops. Heat Action remains independently configurable and also defaults to MMB. Heat Actions still require physical RMB. [Controls](docs/CONTROLS.md) covers priority and timing.

World/server **Sandbox Options > Project Yakuza** controls Dragon Tiger Drop, its timing/cooldown, Heat Actions, grabs and Extreme Heat. Tiger Drop defaults to a 160 ms observed-windup window and a 20-second cooldown.

## Heat Actions and combat behavior

Weapon Heat Actions are available for the configured vanilla bats, Base.Katana and the supported knives. Hold physical RMB and press Heat Action outside combos near a valid target. One complete stock is enough. Supported weapon Heat Actions can spend equivalent fuel during Extreme Heat.

Grab holding uses separately calibrated stationary/walking grips. Strikes retain the same native body parents and a stable victim offset. Entry blends into the grip in both directions, with late-grant visibility/path checks and pause-safe recovery. Counters, fully charged impacts and grab reaches have distinct supplied feedback. Grabs confirm a connection or missed reach briefly. Standing source flinches vary by punch, kick, blade or blunt contact; rapid hits preserve animation continuity while native knockback, stuns and paired scenes keep priority.

Running strikes gain an early-input buffer, stronger stagger and 25 percent more native damage; the dropkick gains knockdown and 75 percent more damage. Source animation speeds stay unchanged.

Unarmed grabs retain native combat aim and walking speed after RMB is released. The reach eases forward from its opening frames, up to 0.28 tiles while respecting obstacles and nearby targets. Grab throws; Light strikes. With RMB held, Heat Action chooses the wall action beside a suitable wall or the open-space action when there is clearance. A downed zombie can qualify for the separate unarmed ground Heat Action. See [Heat Actions](docs/HEAT_ACTIONS.md) and [Grabs](docs/GRABS.md).

Extreme Heat's paired punch rush follows the eighth confirmed unarmed light-chain strike against a surviving eligible target. Follow the displayed Light / Heavy / Grab prompts with fresh presses; a held button does not count. A failed prompt transitions to the original ending kick. Playback keeps its authored speed.

Charged heavies and first finishers automatically release at the 1.2-second charge limit. Second finishers cannot charge. Initial style entry uses the full 2.5-second Lost Judgment blue Dragon clip; switching or reselecting an equipped style uses its approximately 1.03-second handoff. Entry and charging remain vulnerable. Relaxed idle is vanilla; armed and exhausted movement retain their appropriate native behavior.

Heat gain is reduced for additional targets in a swing. Completed stocks remain banked during ordinary idle/damage loss; Extreme Heat drains separate fuel. [Heat rules](docs/HEAT.md) lists the tuning and examples. The low-health bar flashes without LOW HEALTH/CRITICAL text.

## Developer resources and limits

The [documentation index](docs/INDEX.md) covers custom actions, animation contracts, weapon profiles, paired motion, presentation and multiplayer. The [starter add-on](templates/StyleSubmod/README.md) is inactive until its examples are renamed and assigned unique IDs.

The release uses ordinary Lua/native PZ APIs. Extreme Heat impacts use the existing blood effect. Local Heat Action contacts begin tint and bounded camera shake up to 120 ms before impact, then decay for roughly 0.49–0.62 seconds afterward. Chromatic aberration and imitation contact sparks are not included. Dragon uses the original 1.6-second failed-reach motion, branching into the paired entry on a successful source contact. Held grabs preserve the combat stance after RMB is released. Offline checks verify configuration, native imports/APIs and file contents. Live animation appearance, performance and multiplayer sessions still require in-game testing. [Validation](docs/VALIDATION.md) describes the current coverage.

The playlist entries include supplied artist, album and duration metadata. Local playback controls support manual listening, previous/next, stop, saved shuffle/repeat/favorites and restoration of automatic combat music; see the music API section in the API reference.
