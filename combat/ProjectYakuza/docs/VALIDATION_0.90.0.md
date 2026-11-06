# Project Yakuza 0.90.0 validation

Offline only. Project Zomboid was not launched. No visual/audio/model/animation assets were generated or changed.

The focused Kahlua presentation suite runs the existing HeatRush regression fixture before loading the production presentation controller and numeric data. It covers all eight main/ending clips and 31 contacts, exact per-clip preroll, live animation phases, observer playback, duplicate damage-message suppression, stale-frame dropping, source identity, interruption/completion, custom sound layers, custom QTE gating, failure clip selection, pause and rotating world contact anchors. The blood suite additionally verifies that sparks and blood copy the same physical point for eight orientations without retaining a mutable input table.

Native B42 imports and forward-kinematic sampling verify the unchanged paired clips; the numeric manifest records their SHA256 values. Original audio clips are decoded to memory to measure strong transient lead-ins without creating or editing media. The existing attack-trail catalogue must remain deterministic after adding head/torso sampling bones to the native probe. All non-Lua runtime media must match v0.89.0 byte-for-byte.

The full 30-suite offline regression run, compilation of all 75 production Lua files, native UI/API probes and the source-comment checker must pass before release. The native world emitter/GameSound interfaces are the same exposed playClip/setVolume path already used by SoundVariety, preserving the mod Sounds volume category. QTE inputs/windows, damage and server validation are unchanged.

Local installation verifies the complete v0.89.0 baseline and backs up only files being replaced or removed. Source, installed files and the fresh v0.90.0 release ZIP are compared exactly. This validates code and source contact geometry; perceived timing and paired rendering still need normal in-game confirmation after restarting with matching client/server versions.
