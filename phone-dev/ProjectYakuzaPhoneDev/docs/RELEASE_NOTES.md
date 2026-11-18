# Project Yakuza Phone (Dev) 0.1.1

Optional phone add-on for Project Yakuza 0.128.0 or newer. Enable both mods, then hold the style-selector key, choose Settings and release. Both installations share the larger, softer blue limb effects from combat 0.128.0.

- Fixed choppy opening, closing and pointer tilt by advancing the phone in the parent prerender callback, before native model rendering and the projected screen. PZ throttles Lua UI update callbacks to roughly 100ms; they now handle safety checks and data refresh rather than visual motion. The existing user-selected UI render rate is respected.
- Removed eight native scene projection calls per screen frame, using the same orthographic mapping verified against the original native UI3DScene/JOML references. Reduced projected screen quads from 57 to 39, cached icon placement and header values, and stopped rewriting native transforms once the pose settles.
- Equipment names are read once per weapon before sorting. The carried-item list refreshes every 1.5 seconds rather than every 0.4 seconds; selecting an item still rechecks that it exists and can be equipped. Page changes and actions refresh immediately.
- Offline validation: 38,952 projection, inverse input, frame-cadence, draw-budget, inventory-refresh, page-action and cleanup assertions; all five production Lua modules compile. Native validation retains 4,316 original triangles, 1,132,164 original pixels and 3,510 projection references. Runtime packages exclude tools, notes, provenance, private paths and credentials.

No model, texture or audio asset changes. The native 3D prototype uses orthographic rendering, upright dynamic text and a dimmed world. PZ was not launched; live appearance and frame-rate improvement still need an in-game check.
