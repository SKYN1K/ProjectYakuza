# Validation: 0.84.0

Validation was offline; PZ was not launched. Live appearance and actual network latency still need an in-game check after restarting.

- All 28 Kahlua gameplay suites pass, including 1,270 grab, 1,803 MP and 853 Heat Rush/QTE checks. All 71 production Lua files compile with the game's compiler.
- Source conversion checks compare 31,248 copied bone/prop transforms against the authorized source frame map. All four converted actor/victim clips preserve original poses within 0.00001 and original 30-fps spacing. Repeated section boundaries also preserve world-root continuity, with a six-frame victim staging blend instead of a teleport. The native B42 animation importer accepts both 327-frame Rush clips and both 107-frame kick endings. Provenance, baseline hashes, original frame ranges and twelve punch/six prompt timings are in `rush-twohit-sections.json`.
- Native animation checks preserve 1x Rush playback. The old speed-variable approach was removed after inspecting the installed B42 animation layer: speed is sampled at track creation, not updated from the variable during playback. No unsupported live speed API or Java bridge is used.
- The six one-second QTE windows cover two physical punches each. Checks cover late valid presses, no seventh QTE, independent automatic contacts, per-move custom timing, fresh remapped inputs, failure policies, one automatic kick on a failed section, earned-only failure payoff, native damage deduplication, paired cleanup and MP authority.
- Throw checks reproduce a native standing-hit/stagger result before cleanup and verify direct prone settling, cleared force/reaction and restored AI/movement flags afterward. MP landing state is included with both damage and grab release, retaining replay protection.
- Six grab offsets were recomputed from the source skeleton. Hold spacing includes the requested additional 0.208762-tile clearance; strike/throw contact offsets remain unchanged and rotate through eight headings.
- All 418 MP observer selectors remain event-free and pass native selection checks. All 30 disabled pose selectors and 120 native fallback controls pass. Apart from the three approved replaced motion files, 715 protected fallback motion/combat files remain unchanged.
- Native passive-UI routing, stun/PvP APIs and original settings-background import checks pass. No texture, music, sound or voice-pack asset is modified.

The source-comment scanner reports zero comments. Installation backs up only changed existing files and verifies complete source/install/ZIP byte equality.
