# Project Yakuza 0.119.0

- Fixed the misplaced texture patterns on Lau Ka Long's spear. The exporter incorrectly inverted the original GMD V coordinate before the DirectX/Assimp/PZ conversion. It now writes the original top-down coordinate directly. Native GPU vertex data matches the source UVs, including negative/repeating coordinates.
- The original diffuse pixels, model geometry, normals, triangles, weapon stats, sounds and hand/world attachments are unchanged. Only the spear's exported UV orientation is corrected.
- Added a native GPU UV regression check to LauSpearProbe using the source-derived contract emitted by build_lau_spear_weapon.py. It rejects the published 0.118.0 model at the misplaced first UV and accepts all 1863 imported vertices in the repaired model, including 174 repeated coordinates. Deterministic source reconstruction, source texture pixels, native static import/item/model parsing and package/privacy/install checks pass offline. No game launch or Steam upload.
