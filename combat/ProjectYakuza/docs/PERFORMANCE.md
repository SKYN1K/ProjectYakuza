# Code maintenance and lookup costs (0.46.0)

The gameplay timing, animation events/assets, attack damage, input bindings, disabled grabs and future-style hooks are preserved. This update changes code work, source annotations and internal lookup ownership.

## Runtime changes

NetworkProtocol.clip now uses a lazy ID index keyed by catalogue reference and length. NetworkProtocol.selectors compiles groups/normalised condition values once for that catalogue. Official registerNetworkAnimations publishes a new catalogue table, which invalidates both indexes on the next lookup. Priority/order is the original registered order. Unknown style/clip IDs do not create unbounded per-request entries.

NetworkClient.pickClip walks only the requested native group. It shares each animator-variable read within that selection and compares against pre-normalised condition values. Values are read afresh every selection; no pose state is cached across frames. The real-module fixture chooses the same third long-blade light as the baseline scan while reducing native GetVariable reads from 14 to 5 in that scenario. This is an operation-count result, not an FPS benchmark.

Weapons.findMove lazily indexes each base/equipment style view by nodeValue using weak table keys. Re-registering a style clears its index, including reusing the same table object. A 1,000-lookup fixture checks warm move/clip queries perform zero array scans. Existing public objects/move identity and disabled definitions stay available. getStyle/listStyles/base IDs and MP protocol 2 remain unchanged.

Registry.isEquipped checks the base identity and current real item directly rather than resolving the equipment view again just to test existence. Weapon profile matching reads the item type once, and remote equipment views prefer the server-validated packet without a redundant native hand/profile lookup.

HeatAura.draw reads the actor position and render offsets once for the body pass. A six-emitter draw goes from 30 such native reads to 5, preserving the same positions, scale, colour, alpha and frame clocks. Stable aura updates no longer rescan all actors for render-hook ownership; fresh/profile-changed/trimmed instances still synchronise the hook, and cleanup releases it. Cached sprite resources remain reusable. Cleared inactive states skip repeated detach/hook work.

## Retired code and annotations

Removed the unused hard-coded finisher mouse-button constant; configurable bindings already own input. Removed the retired spark/alternate-colour branch from the aura burst helper, whose active caller only builds the existing activation smoke. Removed the redundant registration-results array in favour of a count. No disabled feature, dormant action node, future juggling/limb provider API, saved-item damage restoration or required equipment repair was removed. No media files were deleted or regenerated.

All authored project source, addon templates, tests/build tools and documentation code examples are comment-free. Prose documentation remains. Test insertion markers are no-op Lua string data, rather than comments. Addon-generated observer ownership uses an XML processing instruction and Lua local string data, retaining deterministic generation and overwrite protection without comments. Code-only limb-track provenance hashes changed because their source headers were removed; numeric source/FK samples are identical.

## Maintenance and limits

Treat registered definition/catalogue tables as configuration. Use registerStyle/registerNetworkAnimations and register weapon profiles before play; do not mutate registered nested move/selector data directly. Existing style authoring docs already require this. These cache rules retain those supported registration paths.

Run tools/combat-tests/check_source_comments.py to reject comments while preserving quoted strings, long Lua strings, XML CDATA and command-line flags. Six lexical tests cover those cases and Unicode Python docstrings. The cleanup compares non-comment token signatures for Lua, item scripts, Java and PowerShell. Full Kahlua/native/parser/provenance checks still apply. No game/FPS or live multiplayer benchmark was performed; PZ was not launched.

## Multiplayer hot paths (0.63.0)

NetworkProtocol.supports(style,clip) indexes native attack animations and enabled action animation contracts once per definition. NetworkProtocol.kind reuses the same action index instead of walking every action/variant. Base styles and equipment views have separate weak-keyed indexes. Replacing collection references rebuilds the index, and official registerStyle invalidates same-table registration. Registered nested configuration remains immutable during play; re-register after editing definitions. Disabled action metadata remains available to kind lookups while supports rejects disabled actions.

Server snapshots reuse the already validated equipment-view move rather than resolving the same node through every profile again. Support authorization retains enabled action/profile checks. Recipient distance checks read the sender's coordinates once per fanout; online recipients and their positions remain fresh for every message. Range, line-of-travel, ownership, replay/session, damage and target-count checks stay active on every attack.

NetworkProtocol.path retains the existing .08-tile sample positions and identical wall/diagonal crossing tests, but reads each visited tile once within that synchronous call. No geometry or permission result is cached across calls or ticks. A 1.6-tile open path uses 2 grid lookups instead of 40. Regression tests compare 288 direction/origin/obstacle combinations and their ordered wall crossings against the prior algorithm. Zombie-ID searches visit the same 49-tile region in distance order, starting at the actor's tile; a same-tile target uses one tile lookup. Missing IDs still inspect at most all 49 tiles. There is no persistent victim/negative lookup cache.

Client state change detection compares typed packet fields instead of repeatedly constructing the old concatenated signature. Integer Heat/fuel, stock changes and tenths-of-charge thresholds remain; ground-state changes are now explicitly compared. Changed state and forced sends are immediate through the existing capture cadence. Active equipment keeps its one-second heartbeat; inactive equipment uses three seconds, reducing unchanged inactive heartbeat traffic by two thirds. No combat packet rate, quickstep timing or attack animation timing is reduced.

Remote protection-hook ownership is rescanned only on protection transitions and cleanup, instead of every heartbeat. Deferred replay allocates its key batch only when jobs exist, reads the housekeeping timestamp once and skips jobs removed by session/lifecycle cleanup during that batch. Retry deadlines, budgets and remote timeouts are unchanged. All clients still apply their own volume/effect preferences.

The MP fixture checks complete source-catalogue support agreement and 1,000 warm support/kind lookups with zero definition-array rescans, official same-table invalidation, disabled action metadata, path equivalence/counts, local/unknown zombie search bounds, typed state detection, inactive heartbeat timing, prompt reactivation, protection transitions and replay cleanup. These are offline operation counts and regressions, not measured FPS, bandwidth or server latency benchmarks.

Removed the replaced concatenated state-signature path and repeated definition/path scans, two unused internal attached-sprite search/removal helpers (WorldEffects.contains/remove), and stale barrage sound-slot documentation. The active attachment helper remains. Disabled grabs, retained source clips/effects, provenance, action/QTE/juggling/limb hooks and the separate voice-pack project are preserved. No media/native definitions or visual/audio assets were changed.
