# Validation — 0.38.0

No Project Zomboid client/server was launched. GPU visibility, native final-pose alignment and live multiplayer appearance remain unverified.

All 40 production Lua files compile. Fourteen Kahlua fixtures pass 3,966 assertions: framework 2,647; charge/UI 181; quickstep 71; MP 104; extension 42; starter 9; heat/shove 23; heat audio 35; entry 21; taunt/aura 195; CVF 63; selector 50; settings 94; limb effects 431.

Punch tests inspect every rendered layer for normal transparency, exact 1.25 scale multipliers, preserved native world-depth anchors, and sixteen continuous facings with different degree-valued shoulder turns. Native reflection confirms getShoulderTwist is present. This is a scalar yaw correction, not exact access to blended bone transforms; distributed spine twist and custom proportions can still differ.

Taunt tests verify four original HeatWisp emitters, original animation speed, 1.20 peak scale, a 750ms unpaused lifetime, smooth 100ms-in/150ms-out envelope, no duplicated normal body pass, no additive pulse, pause/cleanup, remote completion and error restoration. Extreme Heat smoke/outline/flames retain their prior checks.

Native checks retain punch import/FK, detached-instance contracts, 130 aura PNG decodes, 188 event-free observer nodes, nine charge paths/87 samples, source timing/pose continuity, all 229 loader paths, original flame alpha and source smoke/HUD pixels. All 455 animation/image/audio files remain byte-identical to v0.37.0. No new visuals/audio were made; whitened frames await explicit user approval.

Installation preflights the existing v0.37.0 bytes, backs up only changed files, then compares all source/install files. A unique v0.38.0 ZIP/release is published and its bytes/digest are verified.
