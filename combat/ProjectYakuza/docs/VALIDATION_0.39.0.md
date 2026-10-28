# Validation — 0.39.0

No game/client/server was launched. GPU appearance and live MP rendering remain unverified.

Fourteen Kahlua fixtures pass 3,969 assertions, including 198 taunt lifecycle/aura checks. All 40 production Lua files compile. New assertions verify full whitening at peak and smooth colour interpolation on both fades; existing checks retain the 750ms duration, 100ms/150ms fades, 20% peak enlargement, no normal-aura double draw, pause, remote completion and cleanup.

Pixel checks compare all 96 TauntAura copies against unchanged HeatWisp source hashes: channel mapping (3*c+257)//4, exact alpha, RGBA mode and 128x256 dimensions. Visible RGB changes from (80,195,255) to (124,210,255), representing a 25% move toward white with integer rounding. No shape, resampling or animation edits. Per-frame hashes and explicit user authorization are recorded in taunt-aura-assets.json.

Native B42 ImageData decodes all 226 ExtremeHeat/TauntAura frames. Native loader recipes resolve all 325 aura/burst paths. Full offline validation retains punch FK/projection, detached instance contracts, 188 observers, source charge paths/timing and original texture/clip checks. All 455 pre-existing motion/image/audio files are byte-identical to v0.38.0; only the 96 approved colour copies were added.

The installer preflights against v0.38.0, backs up only changed installed files, verifies the complete installed source, then publishes a unique v0.39.0 ZIP. Source/install/ZIP bytes and the release digest are verified after publication.
