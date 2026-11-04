# Validation: Project Yakuza 0.80.0

Validation is offline; Project Zomboid was not launched.

The real Kahlua grab suite passes 57 checks covering walking holds beyond the old expiry, all four paired strikes, original contact timing, single damage, knockdown suppression, exhaustion/interruption cleanup, wall/door/window and obstruction eligibility, and protected grab-to-action transfer. The multiplayer suite passes 1,795 checks, including unique grab leases, canonical strike timing and damage, renewal, stale/replayed packets, owned-target wall authorization, atomic transfer and observer isolation. The paired Heat Action/QTE suite passes 258 checks, including observer timeout cleanup after a grab and owner cancellation on a server abort. The remaining combat, style/settings, weapon, input, sound, heat and presentation regression suites also pass.

All 67 production Lua files compile. B42 exposes the native state-lock setter but not StateMachine.isLocked to Lua. Production uses only the exposed character APIs, tracks locks acquired after an observed native reaction transition, and releases only owned locks. It does not use debug reflection or a Java bridge. Native passive UI routing still passes RMB through.

The native animation importer accepts all ten newly converted clips. Source hashes, original paired roles, 30 fps frame counts, original grab collision frames and wall scene contacts are verified. The validator compares 19,856 body sample matrices with the original retarget output and 1,168 native hand/prop pose pairs with native grip offsets (maximum matrix error below 0.000007). Wall movement preserves original standing-victim height and continuous source paths, with no inserted scene jump. Thirty new native owner/victim/observer selectors pass phase selection and reject unrelated phases without duplicate attack events.

All 416 multiplayer observer selectors pass native selection and remain event-free. The existing 30 disabled custom weapon/walk pose selectors and native walking fallback pass 120 selection checks; 727 existing motion/combat XML files remain unchanged. The source-comment and lexical-preservation checks pass. No artwork/audio was synthesized and the separate voice pack was not modified.

Local installation backs up only changed existing files and verifies every installed file against the source. The versioned release ZIP is checked against both. Live appearance, actual wall geometry in loaded maps and two-client latency behavior still need in-game testing after restart with matching versions.
