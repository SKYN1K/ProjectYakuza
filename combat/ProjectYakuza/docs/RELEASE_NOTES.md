# Project Yakuza 0.101.1

- Fixed the built-in first-light effects override still pointing at the retired duplicate numeric track after cleanup. It now points at the identical generated dd_trail_light01_1 data, preserving its existing effect window.
- Added explicit override-to-track reference checks to publication validation and the punch fixture builder, so a stale built-in override is detected before packaging.
- No balance values, damage, costs, animation timing or supplied media bytes changed. Targeted native first-punch/effect tests, Lua compilation, asset-reference and zero-comment checks pass offline. Project Zomboid was not launched.
