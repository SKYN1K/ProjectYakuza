# Project Yakuza Emotes 0.2.9 validation

The spark trigger now uses the final ground-contact entry at emote frame 75, or 2.5 seconds. This corresponds to original Kiwami cut 007 frame 187. The unchanged native reference motion has two floor-contact entries, at frames 9 and 75; the later entry is selected. The extended floor-rest interval emits no repeated bursts.

All 23 contact positions are measured again from each unchanged animated model at the later hit. Their lowest vertices match the exported contact coordinates and the floor within 0.001 native model units. The custom Lau model is within 0.000192 units at frame 75 and fully grounded by the next 120 Hz sample. The same contact time is written into the shared runtime data and source report.

The Kahlua spark fixture explicitly rejects sparks at 0.3, 1.0, 2.0 and 2.499 seconds, then expects one burst at 2.5. It retains local/remote playback, duplicate enumeration, clock-correction, slightly late and stale observation, all spear mappings, fixed ground anchors, map hiding, pause/resume, cancellation, visibility, particle limits and disposal coverage. Standalone and CVF menu checks and production Lua compilation remain applicable.

validate_lau_weapon_emote.py --spark-only checks source provenance, unchanged original spark pixels, every animation/selector/texture byte against the 0.2.8 ZIP, the final ground-contact entry and all 23 measured later contact points. SpearSparkProbe checks the actual native clock/actor/sprite APIs and pixel layout. Geometry and playback speed are unchanged, so the full grip/limb/movement validation from 0.2.8 still applies.

Packaging privacy, local changed-file backups, native Workshop layout and installed/staged/release byte agreement are verified during publication. No game launch, new artwork, sound, animation samples or Steam upload.
