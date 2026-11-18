# Project Yakuza Phone (Dev) 0.1.0

Optional phone-menu development add-on for Project Yakuza 0.127.0 or newer. Enable both mods, then open the normal style wheel and choose Settings. Disable the add-on to restore the existing mod menu after restarting PZ. The shared combat dependency supplies the polished hit effects in both setups; the add-on does not fork gameplay or effect code.

- Supplied Yakuza 6 Xperia hardware rendered with PZ's native 3D UI, original diffuse, original second UV channel and original topology.
- Adapted opening, closing and pointer tilt, projected and visibly centred app icons, the original blue Heat flame, inverse-projected clicking, scrolling, keyboard navigation and controller focus handling.
- Nine pages for styles/slots, equipment, combat, heat, audio, effects, grabs, controls and preferences. Uses the existing equip, sandbox, options and local menu-audio APIs. Advanced settings still opens the original panel.
- Offline native validation covers 4,316 source triangles, normals and UVs, all 1,132,164 original pixels across thirteen textures, 3,510 projection cases and normal Lua bindings. All five production Lua modules compile, and 35,379 Kahlua assertions pass for native projection references, input mapping, icon centring, page actions, scrolling, persisted audio, clean close/cancel, fallback and focus restoration. The runtime ZIP contains no tools, notes, provenance, local paths, credentials or Java bridge.

This is a prerelease prototype. It has not been launched in PZ. Native UI rendering is orthographic, dynamic text stays upright, and the world is dimmed rather than using Yakuza 6's blur. The adapted menu animation is not an exact port of the original camera data. Live appearance and interaction still need an in-game check.
