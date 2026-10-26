# Mad Dog 0.1.1 validation

Based on current upstream **Project Yakuza 0.30.1 / API 2** (`f5bac37`), tested with the installed PZ Build 42.21.0 classes and native importer. This remains an unmerged PR, with no published framework release.

## Orientation regression and native Human rig

The original exporter treated matching left/up axes as a complete coordinate conversion and reused a saved animation-node pose as its target reference. That did not account for Yakuza's +Z forward versus PZ's -Z forward. The replacement reads the original GMT/GMD local keys directly, reflects Z while preserving anatomical left/right, and calibrates segment/palm axes against the actual inverse-skin bind in PZ's MaleBody.x.

All **26 clips** were rebuilt from the same supplied source files. Original frame order/rate, explicit playback speeds and native bone lengths are retained. The source root's height is uniformly scaled; horizontal root travel remains fixed because framework movement owns collision-aware displacement. There is no IK, floor solver, generated pose or timeline reversal. The existing PZ knife prop/finger grip remains in use.

- **19,216 source-reader joint samples** agree with the established GMTImporter on the original Majima rig after removing only planar actor travel (maximum positional discrepancy below 0.000034 source units). Original key interpolation is checked with linear Blender curves.
- **28,824 independent direction checks** compare the original GMT forward-kinematic limb segments with native playback on both MaleBody and FemaleBody, across every frame of every clip. The checker derives forward and left from source joints and actual PZ inverse-skin/toe data; it imports no exporter calibration or reference poses.
- **2,402 native Human poses** pass the actual Jassimp loader flags, shared Human `SkinningData`, engine animation processing and `HelperFunctions` PRS-to-matrix path. Hierarchies remain unchanged and transforms stay finite and rigid.
- Negative control: the previously installed 0.1.0 clips fail the same independent checker for **all 52 body/clip pairs**, with reversed limb directions. The rebuilt clips pass every pair. This catches the defect that the original import-only checks missed.
- All 26 clips have **35 Human animation channels**, normalized quaternions, original source durations and no planar root drift. All output/source SHA-256 hashes and the native bind/grip references are recorded in `motion-provenance.json`.

## Framework and control regressions

- **463 Kahlua assertions:** 153 addon/runtime checks, 21 Mad Dog entry checks, 96 existing multiplayer checks, 21 DoD entry checks, 42 upstream API-extension checks, 9 shipped-starter lifecycle checks and 121 upstream taunt/aura checks.
- All **37 production Lua files** compile in the installed Kahlua compiler.
- **28 owner nodes** pass native selection alongside the framework, including style isolation and priority conflict checks.
- **82 observer nodes** pass both network cycles with no collision/animation events and no local-player leakage.
- All clip references, exact style conditions and **15 single-collision nodes** pass asset validation, including native floor/stomp routing.
- Upstream observer-builder tests pass: deterministic generation, native parsing, compilation, overwrite protection and complex-condition validation.

Reproduction commands are in [tools/mad-dog/README.md](../../../tools/mad-dog/README.md). Extraction folders, reference/runtime JSON, old files and logs stay outside Git.

Project Zomboid was not launched for validation. Live mesh/knife alignment, transition feel and two-client latency behavior still require gameplay confirmation; the checks above verify source direction through actual engine transforms without claiming a live game test.
