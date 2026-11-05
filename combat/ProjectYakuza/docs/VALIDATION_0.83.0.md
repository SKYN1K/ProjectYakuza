# Validation: 0.83.0

Validation was offline. Project Zomboid was not launched; actual appearance and live latency still need an in-game check after restart.

- All 28 Kahlua gameplay regression suites passed, including 1,264 grab checks, 1,805 MP checks, 852 Heat Rush/QTE checks and 90 CVF integration checks against the existing upstream registry/playback fixtures.
- All 69 production Lua files compiled with the game's Kahlua compiler. Native passive-UI routing, stun/PvP APIs and original settings-background import checks passed.
- All ten actor/victim/observer Heat Rush nodes parsed through the native animation importer with `ProjectYakuzaHeatRushSpeed`; the native `isFallOnFront` posture API was verified.
- All 418 MP observer selectors passed native selection/event checks, with four repeat-hit definitions and all four source-frame quickstep-cancel markers preserved.
- All 30 disabled custom weapon/walk selectors and 120 native selection controls passed. 718 protected source-motion/combat files remain byte-identical to their fallback baseline; intentional style-entry blend changes and paced Heat Rush speed variables are compared structurally.
- Every visual/audio file remains byte-identical to v0.82.0: 207 animation clips, 433 PNG textures and 64 OGG files. No new visual/audio asset or motion was generated.
- Six grab hold/strike/throw offsets were recomputed from the original converted PZ left-hand and victim neck transforms in Blender; all configured coordinates match within 0.000002 tiles. See `grab-position-calibration.json` and `tools/combat-tests/validate_grab_alignment.py`. Shared pair staging is checked across eight headings with smooth entry/return transitions; geometry checks still reject blocked paths.
- Full countdown tests cover source/wall-clock round trips, custom per-cue durations, legacy identity, invalid pacing, six late-but-valid presses, stable consecutive countdowns and MP source-timed contacts/completion. The original source collision poses and timings remain authoritative.
- Handoff tests reject cancellation before the eighth contact, allow it before the late chain marker after a confirmed hit, retain the last confirmed target and bound supplemental settlement. Existing MP replay, damage, ownership, recovery and failure cleanup checks remain green.
- Ground action checks reject face-down, not-yet-landed and getting-up targets. MP rejects a face-down target before acquiring a lease or applying protection.
- DoD's multiplier and taunt gain override were removed. The Voices slider is tested at half volume without a style boost. The separate CVF voice-pack project was not modified.

The source-comment policy scanner reports no comments. Installation backs up only changed existing files and verifies complete source/install byte equality. The versioned release ZIP is checked against those same source bytes.
