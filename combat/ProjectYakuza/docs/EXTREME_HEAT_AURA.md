# Extreme Heat — purple-blue fire and low smoke (0.32.0)

Extreme Heat retains four fast original Yakuza 6 flames around the chest/arms/head, with a more purple-blue (.25,.15,1) runtime tint. The native outline uses the matching (.32,.22,.95) hue. The new leg-area smoke is explicitly requested for this mode; regular heat still has its original upper-body-only layout.

Two low emitters use the supplied e_f_0014_roop_smoke01.dds atlas, split into its exact 64 original 64x64 cells. They originate at heights 6/7, drift outward and rise 9/10 units around the legs. They use slower 1.6/1.85-second loops, ordinary alpha blending, restrained purple-grey tint (.48,.40,.72) and opacity limits .22/.18 before fade/cycle modulation. The upper flames keep their .59–.81-second loops and scoped additive material. Smoke does not receive the extra taunt-flash pass.

The 350 ms appearance fade, pause handling, cached sprites, world anchoring for every facing and MP heat-state replication remain active. Leaving Extreme Heat releases all six instances and restores the four normal emitters. Render state is restored on success or failure. No new gameplay/protection, audio, camera or voice changes are introduced.

All texture files are exact original DDS decodes/crops: no resize, alpha repainting, compositing, generated frames or upscaling. Source hashes, crop rectangles and output hashes are recorded in extreme-heat-assets.json and extreme-smoke-assets.json. B42 ImageData decodes all 130 aura images. See [validation](VALIDATION_0.32.0.md); live GPU appearance still requires in-game viewing.

## 0.32.1 loader and activation correction

Animated pages follow native `LoadFramesNoDirPageDirect(prefix,kind,count)` naming: `prefix_kind_0.png` through `prefix_kind_<count-1>.png`. This applies to normal aura, Extreme Heat flame/smoke and taunt bursts. Export/decode checks alone do not verify native path resolution; run validate_effect_loader_paths.py too. Extreme Heat fire/smoke now begin during the actual started activation action, continue into fuel mode, and restore/clear on interruption or observer clip exit. The HUD uses a protected normal-alpha pass with purple glow behind the solid orb artwork.
