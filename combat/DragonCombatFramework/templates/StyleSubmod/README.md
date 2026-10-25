# Inactive style-submod starter

This folder is documentation/code only and is not loaded by the framework.

1. Copy this folder to a new directory under your own Zomboid mods folder.
2. Rename `42/mod.info.example` to `mod.info`, `ExampleStyle.lua.example` to `.lua`, and `ExampleStyle_Light01.xml.example` to `.xml`.
3. Change the example mod/style IDs and display names. Keep IDs consistent in Lua and XML.
4. Enable the framework and your new addon. Its menu entry appears automatically.

The starter uses PZ's existing `Bob_AttackPunch01_Hit` animation at 1x speed, so its single punch needs no copied animation file. Replace it with your provided animation and adjust timing to create your own moves.

Music/sounds/heat/Kiryu effects are off. The optional music script remains `.example`; enable it only after supplying the referenced recording and configuring at least two distinct tracks for continuous shuffle. Do not copy any DoD playlist unless you intentionally want to reuse its provided tracks.

See `docs/STYLE_AUTHORING.md` in the framework for API, native XML markers and custom-handler instructions. Nothing in this starter creates graphical/audio assets.
