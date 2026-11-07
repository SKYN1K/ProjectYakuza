# Project Yakuza 0.93.0 validation

PZ was not launched. Changes are limited to Lua control logic, regression fixtures, version metadata and documentation. All animation, texture and audio files retain their previous release bytes, so no media conversion or generation is involved.

The new quickstep checks first reproduced the visible-animation restart on an aim change. The repaired production module passes all four directions with fading track weights, one native timed-action exit, duplicate completion/update suppression, an End marker after track removal, temporary track loss and bounded fallback cleanup. Existing one-strike handoff, asynchronous native attacks, quota, startup retry and light-cancel regressions remain intact.

The new crowd checks first reproduced the failure to reach a placeable eighteenth weapon target. The repaired production module tries placement in distance order, refreshes on actual input, excludes dead cached victims and preserves feasible same-strike tickets after blocked or ineligible contacts. Ground selection also reaches a feasible victim after 100 unrelated moving objects and seventeen unplaceable victims. Existing last-valid-hit, PvP permission, multiplayer settlement, input, cost and paired lifecycle checks remain intact.

The selected Kahlua suites are quickstep-once, heat-rush, heat-speed, heat-shove, mp, weapon, weapon-mp, grab, charged-ui, directional and extreme-attack. Each runs in its own JVM with the installed B42 Kahlua runtime and freshly embedded production modules. All 75 production Lua files compile. The source comment scanner and its six lexical-preservation tests pass.

The native StopTimedActionAnim contract was checked against the installed-engine inspection: it clears TimedActionType, reports Event_TA_Exit and requests a model reset. Quickstep invokes it only while its own PerformingAction selector is active. The regression fixture checks that cleanup calls it exactly once.

Heat defaults were traced through Registry.lua, Heat.lua and accepted action payment. Six stocks divide the normalized 100-point meter. Ordinary loss retains completed stocks; Extreme Heat transfers the meter into fuel, drains one stock per 3.75 seconds, and adds swing/damage/knockdown costs. No Heat tuning was edited.

Installation verifies the previous release, backs up only changed installed files and verifies every installed source byte. The release archive is checked against source, and publication uses a fresh version tag. Backups, portable tools, authentication state and the separate CVF project remain outside the combat repository and install ZIP.

These checks establish offline control logic and cleanup behavior. Live visual smoothness and dense-crowd multiplayer behavior still require a gameplay check after restart.
