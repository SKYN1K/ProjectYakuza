# Extreme Heat — fast original Yakuza 6 flames (0.31.1)

Extreme Heat replaces normal heat's emitters with four animated blue flames around the chest, shoulders/arms and head. Static wisps are no longer used by this profile. Normal heat, taunt flash, outline, controls and audio retain their previous behavior.

The source is the supplied Yakuza 6 `e_j_0076_aura_g.dds` RGBA atlas. Its 64 original 32x32 cells are decoded/cropped without resizing, alpha editing, compositing, upscaling or generated frames. These replace the previous low-luminance/alpha flame exports at the same filenames. The old c/d wisps remain as unused source assets; their supplied Y6 pixels/hashes are identical to the earlier Lost Judgment exports. See [provenance](extreme-heat-assets.json).

The prior alpha atlas had very low effective opacity after the source alpha, tint and .20-.22 runtime opacity combined. The RGBA variant's RGB has a black background, so it uses **scoped additive world rendering** rather than ordinary alpha blending. Black contributes no light instead of obscuring the world. The previous renderer state is restored even if a flame draw fails. There is one flame pass, no broad bloom image and no normal aura underneath Extreme Heat.

Four native atlas sequences run at approximately .65/.73/.81/.59 seconds per loop (normal native timing). Runtime tint is (.08,.38,1), with opacity limits .48/.42/.44/.36 before fade and modulation. Native resolution remains 32x32 per frame; runtime world sizing does not resample files. The same upper-body anchors and bounds are retained; there are no leg emitters. All facings use the same non-directional world rendering path. Atlas animation advances once per base pass; taunt flashes do not advance it again. The 350 ms appearance fade and pause remain active.

Offline validation: 2,923 Kahlua assertions pass (combat/aura/music, taunt/mode, charged/UI/outline and MP), all 37 production Lua files compile, and B42 ImageData decodes all 66 aura textures. All exported pixels and hashes match supplied DDS source crops exactly. PZ was not launched; final GPU appearance/live multiplayer are not verified. See [validation](VALIDATION_0.31.1.md).
