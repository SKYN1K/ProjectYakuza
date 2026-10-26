# Project Yakuza

Project Zomboid Build 42 combat framework with the Dragon of Dojima style.

Current version: **0.28.0**. Source mod folder: [combat/ProjectYakuza](combat/ProjectYakuza). See its [README](combat/ProjectYakuza/README.md) and [release notes](combat/ProjectYakuza/docs/RELEASE_NOTES.md) for controls, features and validation.

Download the ZIP from this repository's Releases page. Extract its `ProjectYakuza` folder into `Zomboid/mods`, enable the mod and restart PZ. Install the same version on server and clients. Custom Voice Framework and a compatible voice pack are optional; they are not bundled in the combat ZIP.

All graphical/audio assets originate from supplied local game files. No generative artwork/audio or upscaling is used. This repository is private. Motion/texture provenance and framework authoring guides are in the mod's docs folder.

## Publishing updates

Each installed, validated update receives a new version and GitHub release with its install ZIP. Run `tools/Publish-CombatRelease.ps1` after updating the version, release notes and validation. It builds the ZIP, commits only the combat project files, pushes main, and publishes a unique version tag. Preview-only work is not a mod release.

The local workspace also contains a separate Kiryu CVF voice-pack project, preview renders and extraction tools. Those are excluded from this combat repository.

Version 0.28.0 uses a clean ProjectYakuza namespace with no compatibility aliases. Enable Project Yakuza and re-equip the style item. Grabs are temporarily disabled. The separate voice pack is not modified by this repository.
