# Project Yakuza 0.93.1 validation

PZ was not launched. The reported stock loss without animation was traced to a missing dispatch in Runtime: the paired handler had an update method after leaving the native timed-action queue, while the ordinary player-update branch only waited for the action to start and timed it out. The previous fixture called start/update directly and could not establish this integration path.

The revised fixture first fails against the previous payment behavior, then reproduces the missing Runtime dispatch after payment is deferred. Production Runtime now invokes the paired handler before ordinary defense/input handling and cancels update exceptions against the owning context. The tests fire actual OnPlayerUpdate callbacks to request actor/victim playback, confirm native tracks, deliver contacts and complete the action. Actual groundHeat and grabHeat definitions also start and commit through that route.

Built-in paired costs are checked at acceptance and paid at the first native track sample meeting the existing playback threshold. payActionHeat(context) verifies ownership, available balance and the selected ordinary/fuel resource, and records exactly one debit. Other action kinds retain accepted-start payment. Swing commitment and multiplayer readiness now follow confirmed playback. Tests cover missing tracks, retry, paused startup, repeated updates, full sequence completion, cancellation before/after payment, resources disappearing before playback and paying the final Extreme fuel stock without premature depletion.

All 15 selected Kahlua suites pass: quickstep-once, heat-rush, heat-speed, heat-shove, mp, weapon, weapon-mp, grab, charged-ui, directional, extreme-attack, extension-api, addon-starter, heat-presentation and heat-damage. Each runs in a separate JVM with freshly embedded production modules. All 75 production Lua files compile. Source scanning reports zero comments, and the six lexical-preservation tests pass.

The installed native aim/strafe action-group transitions were inspected: IsPerformingAnAction=true selects the actions substate when not turning, and false exits it. The shipped paired owner nodes select the existing PerformingAction value, style and weapon profile. No animation, selector XML, texture or audio files were edited.

Installation checks the preceding release bytes, backs up only changed existing files and verifies the complete source/install match. The versioned ZIP is compared with both source and installation, and its remote digest and release tag are verified. All supplied media remain byte-identical to 0.93.0. Authentication state, portable tools, backups and the separate CVF project stay outside Git and the release ZIP.

This validates the normal update-loop logic and supplied native selectors offline. Live visual playback and multiplayer latency still need a gameplay check after restarting PZ with matching server/client versions.
