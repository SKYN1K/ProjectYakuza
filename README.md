# Project Yakuza

Project Zomboid Build 42 combat framework with the Dragon of Dojima style.

Current version: **0.61.0**. Source mod folder: [combat/ProjectYakuza](combat/ProjectYakuza). See its [README](combat/ProjectYakuza/README.md) and [release notes](combat/ProjectYakuza/docs/RELEASE_NOTES.md) for controls, features and validation.

Download the ZIP from this repository's Releases page. Extract its `ProjectYakuza` folder into `Zomboid/mods`, enable the mod and restart PZ. Install the same version on server and clients. Custom Voice Framework and a compatible voice pack are optional; they are not bundled in the combat ZIP.

All graphical/audio assets originate from supplied local game files. No generative artwork/audio or upscaling is used. This repository is private. Motion/texture provenance and framework authoring guides are in the mod's docs folder.

## Publishing updates

Each installed, validated update receives a new version and GitHub release with its install ZIP. Run `tools/Publish-CombatRelease.ps1` after updating the version, release notes and validation. It builds the ZIP, commits only the combat project files, pushes main, and publishes a unique version tag. Preview-only work is not a mod release.

The local workspace also contains a separate Kiryu CVF voice-pack project, preview renders and extraction tools. Those are excluded from this combat repository.

Lua API 3 supports independent styles, custom action lifecycles, addon controls and registered multiplayer observers. Start with the [manual index](combat/ProjectYakuza/docs/INDEX.md) and [starter addon](combat/ProjectYakuza/templates/StyleSubmod/README.md). Grabs remain disabled. The separate voice pack is untouched.
