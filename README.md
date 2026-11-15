# Project Yakuza

Project Zomboid Build 42 combat framework with the Dragon of Dojima style.

Current combat version: **0.119.0**. Source mod folder: [combat/ProjectYakuza](combat/ProjectYakuza). See its [README](combat/ProjectYakuza/README.md) and [release notes](combat/ProjectYakuza/docs/RELEASE_NOTES.md) for controls, features and validation.

Download the ZIP from this repository's Releases page. Extract its `ProjectYakuza` folder into `Zomboid/mods`, enable the mod and restart PZ. Install the same version on server and clients. Custom Voice Framework and a compatible voice pack are optional; they are not bundled in the combat ZIP.

All graphical/audio assets originate from supplied local game files. No generative artwork/audio or upscaling is used. This repository is private. Motion/texture provenance and framework authoring guides are in the mod's docs folder.

## Publishing updates

Each installed, validated update receives a new version and GitHub release with its install ZIP. Run `tools/Publish-CombatRelease.ps1` after updating the version, release notes and validation. It builds the runtime and Workshop ZIPs, installs and verifies the local update, archives obsolete Workshop staging copies outside the game cache, commits the project changes, pushes main, and publishes a unique version tag. Use -SkipLocalInstall only when an update should not be installed locally. Preview-only work is not a mod release.

The local workspace also contains a separate Kiryu CVF voice-pack project, preview renders and extraction tools. Those are excluded from this combat repository.

Lua API 3 supports independent styles, custom action lifecycles, addon controls and registered multiplayer observers. Start with the [manual index](combat/ProjectYakuza/docs/INDEX.md) and [starter addon](combat/ProjectYakuza/templates/StyleSubmod/README.md). Unarmed grabs, four grab strikes and a wall Heat Action are enabled per style. The separate voice pack is untouched.

[Project Yakuza Emotes](emotes/ProjectYakuzaEmotes/README.md) is a separate, optional Build 42 mod, version **0.2.7**, containing Majima, Lau Ka Long, Kiryu and Shimano cutscene gestures. It works without the combat mod or Custom Voice Framework and has its own install ZIP and release.

Install and Workshop archives contain only runtime game files. See [Workshop publishing](docs/WORKSHOP.md) for the prepared folder, privacy checks and upload steps. Sandbox Options now includes Dragon Tiger Drop timing/cooldown and feature switches; local audio and controls use readable labels.
