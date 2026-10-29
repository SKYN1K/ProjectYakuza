# Validation — 0.43.0

No PZ game/client/server was launched. Live timing/feel and MP observer transitions remain unverified.

Fourteen Kahlua fixtures pass 4,133 assertions: framework 2,647; charge/UI 181; quickstep 124; MP 192; extension 42; starter 9; heat/shove 27; heat audio 35; entry 21; taunt 198; CVF 63; selector 50; settings 94; limb effects 450. All 41 production Lua files compile.

The quickstep fixture adds 53 checks over its prior 71: all four lights traverse marker-gated recovery exit, native hand ownership remains a prerequisite, the real quickstep handler queues, and native action start spends exactly one quota unit. Tests cover opt-out, 150ms early input, hit-marker prerequisites, stale inputs, existing quota/cooldown, walls, finisher/charged exclusions, swing identity, damage interruption, pause, 400ms exit timeout, resets, save/menu cleanup and actual bound-key/hold edges. Existing one-strike entitlement/retry/MP tests remain passing.

ChargeAssetProbe parses the 14 previous charge nodes plus four light owner nodes through the native importer; each strike retains exactly one collision. validate_mp_nodes confirms four owner cancel markers at 7/30,9/47,12/42,12/47 and all 188 observer nodes remain event-free with unchanged clip/speed/mask/blend contracts. Existing source clip/FK/timing/pixel/native decoding checks pass. All 551 motion/image/audio assets are byte-identical to v0.42.0. The four new XML events are code, not newly authored animation motion.

Installation preflights against v0.42.0, backs up only changed installed files and compares complete installed bytes. The unique v0.43.0 ZIP/release is published and source/install/ZIP bytes plus remote asset digest are verified afterward.
