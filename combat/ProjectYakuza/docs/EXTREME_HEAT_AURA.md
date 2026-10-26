# Extreme Heat aura - original Lost Judgment assets (0.30.2)

The previous bright HeatWisp-based Extreme Heat profile is removed. Normal heat remains unchanged, but its instances are released for the full duration of Extreme Heat.

The replacement uses original Lost Judgment runtime/media/data/particle.par entries e_j_0076_aura_ga8l8.dds, e_j_0073_aura_ca8l8.dds and e_j_0073_aura_da8l8.dds. The 256x256 flame atlas is split into its 64 existing 32x32 cells in row order. The two 64x128 wisps are decoded at native size. No procedural advection, turbulence, image resizing, alpha editing, compositing, upscaling or generated frames are used. See extreme-heat-assets.json for source/archive metadata, exact crop rectangles and SHA256s.

Two small animated flame patches and two narrow wisps cover chest/arms/head. The same world-render path works for every character facing. Particle bounds fit within the former upper-body patch sizes; no leg aura or large cloud is added. Native atlas playback uses approximately 2.6/2.9-second loops. Wisps use gentle bounded runtime drift; pause freezes motion.

Runtime opacity maxima are 0.15, 0.22, 0.20 and 0.12 before source alpha/fade. Tint is RGB (0.22, 0.54, 0.78). Continuous rendering uses ordinary alpha blending only: the old 16% additive bloom is removed. Taunt completion keeps its existing short scoped flash. Sprite caching, exclusive mode switching, fade-in, death/unequip/save/toggle cleanup and relayed MP heat state remain intact.

Validation: all 66 PNGs exactly match native-size source DDS pixels/crops; PZ's native ImageData decodes every file. 121 taunt/aura and 2,629 broader combat/aura/music checks pass; 33 production Lua files compile. All 310 pre-existing media files are unchanged. No PZ client/server was launched, so the final GPU appearance still needs in-game viewing.

Non-voice Extreme Heat sounds are already supplied by the Yakuza 6 charge-up, mode-on layers and mode-off cues in the style sound profile. This update changes aura presentation, not those audio files or the separate voice pack.
