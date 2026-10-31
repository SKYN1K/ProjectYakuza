# Validation: 0.61.0

PZ was not launched. All 54 offline code/native-API steps and 26 Kahlua fixtures pass (7,879 assertions). All 57 production Lua modules compile; 664 checked source files contain zero comments and six lexical-preservation tests pass. Live addon animation/MP latency remains untested.

The dedicated Heat-speed fixture passes 136 checks using actual Registry/Heat/Runtime/Weapons/Feedback code. It verifies the entire 0..100 linear curve, clamping, malformed/nonfinite configuration, registration validation, exponent and fuel behavior, native swing sampling, stable captured values across Heat/fuel changes, cleanup, weapon opt-out, variable playback and source/fallback whoosh timing. Real DoD attacks retain x1.6 normal playback and x1.92 during its existing Extreme mode. Its base and weapon definitions remain unconfigured.

The MP fixture passes 271 checks. New checks verify absent factors for the current style, transient opt-in relay, unchanged capture while Heat grows, rejection of mid-clip changes, NaN and over-limit factors, a new factor on the next swing, observer playback and rejection of invalid observer packets. Existing weapons, QTEs, endurance, charge, timing, effects, UI, sound, controls, authority and addon fixtures remain green. The curve only speeds clips up; existing conservative attack deadlines are preserved.

The complete DragonOfDojima.lua and all 1132 existing non-Lua media/native-definition files match 0.60.0 byte-for-byte. No assets were generated or modified, and the separate voice pack is untouched. Source/importer checks were not repeated because those exact media files did not change. Only this version's validation is distributed; previous reports remain in Git/release history.

Verify the prior 0.60.0 installation against its ZIP, back up changed existing source/docs files only, remove the superseded validation under the named mod folder, install and compare source/install/ZIP bytes, publish unique v0.61.0 through Publish-CombatRelease.ps1, verify its asset digest and confirm clean Git status. Documentation links are checked before installation. Matching versions are required for future addon tests.
