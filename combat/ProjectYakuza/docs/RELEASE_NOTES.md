# Unreleased PR — Mad Dog of Shimano

- Separate original-motion style addon and optional per-style held-weapon appearance. Based on framework 0.30.0. PR remains unmerged and unpublished.

# 0.30.0 - Addon authoring and Lua API 2

- Replaced the chronological prototype README with a current install/player guide and a single documentation index. Added complete style/API/action/animation/presentation/testing guides and rewrote multiplayer, heat, controls, playlists and extension entry points. Older implementation notes are clearly labeled historical; source/provenance reports remain intact.
- Custom namespaced action kinds now own combat routing while active. Their optional update callback runs through Runtime; normal attacks/dashes do not leak through. Native attacks are blocked by default, with an explicit advanced-controller opt-out. Hit reaction, unequip/death, save/menu exit and update errors release ownership through captured cleanup handlers.
- Optional expected-context arguments on completion/cancellation prevent stale callbacks ending a newer move. Style validation checks additional flags, costs, travel and combo branches.
- Addons can register their own persisted controls in the existing Mods page, including registration after its options object is created.
- Added validated, copied, priority-sorted and atomic multiplayer catalog registration, plus a standard-library Python tool that writes event-free observer XML/Lua for an addon's supplied owner nodes. It refuses author-file overwrites, preserves native playback settings and generates no media.
- Updated the inactive starter with an existing native light and an unbound, non-damaging custom flourish demonstrating a complete action lifecycle. API 1 style registrations remain supported. MP protocol remains 2. Grabs remain disabled; the separate voice-pack project is untouched.

## Validation

3,173 Kahlua assertions pass, including 42 actual-Runtime addon API checks and nine shipped-starter lifecycle checks. All 33 production Lua files compile. The activated addon has three compiling Lua files; all six generated addon observers parse/select through native B42 classes with zero events. The existing 150 core observer selectors and repeat-hit nodes remain valid. Builder dry-run/determinism, original-file preservation, overwrite refusal and unsupported-condition rejection pass. Current-manual links resolve. All 310 previously shipped visual/audio files are byte-identical and no new media was added. No game/server was launched. The local installation backs up changed/removed files and verifies source bytes.
