# v1.0.1

The running dropkick now coats and trails both legs using separate native foot paths, including multiplayer observers. Both effects share the animation clock and retain independent history and cleanup.

Running light attacks and quickstep attacks now use the Light Attack binding. The running dropkick and Tiger Drop use Heavy Attack / Finisher. Tiger Drop takes priority on a correctly timed heavy press; otherwise heavy/finisher input keeps its normal behavior. Their four separate binding settings have been removed.

Control settings now display readable names such as Light Attack keybind type and Light Attack keyboard bind, including a fallback when translations are unavailable. Existing Light Attack and Heavy Attack / Finisher assignments are preserved.

Validation: native ModOptions and input checks; fresh native 257-pose dropkick import; 23,424 native projection cases; 48,804 effect tracking/lifecycle/observer checks; player-package compilation and privacy checks. Existing texture hashes are unchanged. The full Gaiden archive pixel recheck is unavailable because its source archive is no longer installed. No game launch.

# v1

Project Yakuza is a Lua combat framework for independent fighting-style add-ons for Project Zomboid Build 42. This release is version 1.0.0, Lua API 3 and multiplayer protocol 2.

## For style creators

Install the B42 runtime ZIP, then use the repository's starter add-on and style-authoring guide. Register shared style definitions, provide matching native animation nodes, and keep your add-on under its own mod ID with require=ProjectYakuza. Observer registration supplies multiplayer presentation; new gameplay mechanics still need server validation.

- [Style authoring](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/STYLE_AUTHORING.md)
- [Lua API reference](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/API_REFERENCE.md)
- [Starter add-on](https://github.com/SKYN1K/ProjectYakuza/tree/main/combat/ProjectYakuza/templates/StyleSubmod)
- [Testing and packaging](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/TESTING.md)

## Reference implementation

Dragon of Dojima demonstrates combo/finisher routing, charged attacks, quicksteps, guard, counters, grabs, paired Heat Actions, Heat, effects and style-owned audio. The player build retains vanilla bat/club, blade and knife profiles and supported bat, katana and knife Heat Actions. Experimental custom-object content and voice packs are excluded.

## Downloads

Use the named B42 ZIP for local installation or the Workshop ZIP for upload preparation. The mod metadata and package filenames use version 1.0.0 (v1). GitHub's automatic Source code archives contain developer material and are not player packages. Server and clients need matching framework and add-on versions.

[Workshop guide](https://github.com/SKYN1K/ProjectYakuza/blob/main/docs/WORKSHOP.md) ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· [Controls](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/CONTROLS.md) ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· [Validation coverage](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/VALIDATION.md)
