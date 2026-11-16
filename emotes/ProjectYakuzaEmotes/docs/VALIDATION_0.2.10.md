# Project Yakuza Emotes 0.2.10 validation

The earlier whole-mesh minimum selected the shaft butt while Lau's blade was still above the floor. The contact builder now selects the original Yakuza 3 blade part through the existing source-face provenance. Its original shaft faces are excluded. Native spear variants use their distal mesh region and individual contact times.

Lau's blade reaches the floor at emote frame 79.75, or 319/120 seconds. The custom blade search uses a 0.0005 native-unit floor tolerance; the native variants allow 0.01 units for their existing fitted mesh clearances. The source animation, model, selector and texture bytes remain identical to 0.2.9. No new motion samples or artwork are created.

Sixteen positions per spear are sampled from the actual animated head over the late-observation window, at 120 Hz. Runtime interpolation uses the native track's observed time before converting that point to world coordinates. Height follows the head and is clamped to the ground only for tiny negative floor values. The burst remains at its world impact location after emission.

The independent geometry validator checks every head vertex index, the first accepted contact, mesh hashes and all 368 sampled poses. SpearSparkProbe imports the actual models and Human clips, samples AnimationTrack.get at each recorded time, rebuilds the native hierarchy and compares the resulting visible blade vertex. Maximum pose difference is below 0.000070 native units. Each point is also checked against Model.vectorToWorldCoords in eight directions, with maximum projection error below 0.00000112. Original spark pixels and native sprite APIs pass.

The Kahlua fixture passes 61 checks, including rejection of the old 2.5-second shaft hit, delayed-observation anchoring to the moving blade, curve interpolation, native facing projections, individual spear timings, duplicate prevention, cancellation, map suppression, pause, limits and disposal. The 228 standalone and 31/36/36 native/CVF menu checks pass; all three production Lua files compile. Source-comment and standalone-isolation checks are required before publication.

Installation uses changed-file backups and verifies installed/staged/runtime-ZIP bytes. The package excludes developer documents, tools, credentials and previews. The native Workshop layout is checked without launching the game or uploading to Steam. Live gameplay and multiplayer appearance remain untested.
