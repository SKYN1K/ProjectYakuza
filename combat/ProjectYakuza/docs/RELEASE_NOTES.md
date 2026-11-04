# Project Yakuza 0.81.0

- Removed the decorative line beneath each style-selector slot.
- Corrected wall Heat Action facing and scene depth for all four wall directions. MP validates the selected wall after pair staging.
- Ordinary Heat Actions now search nearby positions for clearance around both participants' paths. They move the pair together and refuse to start when no safe placement fits. Wall-specific actions keep their wall anchor.
- Added Kiryu's original ground-trample Heat Action against a living downed zombie, on the rebindable Heat Action input while holding RMB and outside a combo. It costs one heat stock, uses source-timed feedback and the existing action-only protection/targeting grace.
- Added a full-length red health bar above the heat HUD, using the retained frame assets and Zomboid overall body health.
- The blue radial QTE arc now shows exactly the accepted interval: fresh presses anywhere in its visible 0.6-second window pass; expiry fails. Framework prompt windows remain customizable.
- Ground searches cache empty results and examine at most 96 objects in 25 nearby squares per query. Added MP authorization, replay and cleanup checks for the ground action.

Only the approved original ground motion was converted. No AI, invented artwork/audio, upscaling, game JAR changes or voice-pack edits. The Kiwami 2 game-over preview remains outside the mod. PZ was not launched. See [validation](VALIDATION_0.81.0.md) and [Heat Actions](HEAT_ACTIONS.md). Restart and use matching server/client versions.
