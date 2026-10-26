# 0.28.0 - Project Yakuza

- Full clean rename: display name Project Yakuza; mod ID, Lua API/modules, items/models, animator identifiers, texture/sound references, multiplayer channel, settings and optional combat-voice namespace use ProjectYakuza.
- No legacy identifiers, aliases, loaders or setting migration. Enable Project Yakuza for the save/server and equip its new fighting-style item. Settings use a fresh ProjectYakuza entry.
- Grabs are temporarily disabled through both the local action API and server command handler. Grab/throw implementation and supplied clips remain available for future work; the controls are labeled inactive.
- The separate voice-pack project is untouched. Its combat entries must be updated separately to the ProjectYakuza namespace before those recordings can play through this mod. No compatibility fallback is included.
- Preserve current combat, heat, particles, quickstep limits and multiplayer equipment/position/hit synchronization.

## Validation

3,094 Kahlua assertions passed. Default-disabled grabs have dedicated checks; dormant grab lifecycle tests enable the mechanic only inside their isolated fixture. All 31 runtime Lua files compile. All 148 event-free MP observer selectors validate in PZ native classes. Native animation import succeeds for renamed light, idle, taunt and guard clips. Every animation retains the same numeric motion data; image/audio bytes are unchanged. Only identifiers and text metadata change. No game was launched and no visual/audio asset was generated.
