# Project Yakuza 0.64.0

- Fixed RMB interception by the full-screen QTE prompt and other passive overlays. B42 treats inherited empty right-button handlers as consuming the click even when mouse consumption is disabled. Explicit false handlers now preserve aiming and context menus; no global mouse or keybinding settings were changed.
- Added optional per-style Heat gain, loss, idle grace/drain, knockdown loss, Extreme duration/attack fuel cost and 1..32 stock capacity, plus optional continuous normal-stock drain.
- Added merged weapon-profile overrides, effective rule APIs and validation. Taunt rewards, stock-priced actions, HUD/custom UI capacity and server activation protection use the effective settings.
- Dragon of Dojima keeps its previous six-stock configuration and current gain/drain values. Built-in six-orb coordinates are unchanged; additional capacities reuse the supplied textures. No visual/audio/animation assets or separate voice-pack files changed. Grabs remain disabled.

All offline fixtures and a native B42 right-button routing probe pass. PZ was not launched; live input/MP appearance still needs an in-game check. Restart server and clients with matching 0.64.0. See HEAT_CONFIGURATION.md and VALIDATION_0.64.0.md.
