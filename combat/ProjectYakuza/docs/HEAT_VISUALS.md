> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Original dragon/orb HUD and world aura

The dragon body, head, glass core, blue core and glow draw directly from unchanged regions of Yakuza 6's e/texture/btl_hact.dds. The installed PNG is a lossless conversion of the entire 512 by 512 atlas, with identical RGBA pixels. No extra ring, repainting, grayscale conversion, upscaled dragon image or baked dragon/orb animation remains. The original white dragon variant retains its original shading. Every dragon/orb region renders smaller than its source.

The original glow texture animates through runtime opacity: no glow below full heat, a restrained glow at 100 heat, and the full glow during Extreme Heat. Activation briefly brightens the original blue core for 800 ms. The blue orb fills from bottom to top with available heat. One continuous bar frame contains both stock markers; there are no gaps between stock boxes. The existing bar textures remain.

The aura uses the original raw_event/e_j_0073_spdAura02.dds from particle.par, with bilinear upward UV flow and turbulence. Its frames are now 128 by 192 pixels and render at half the previous sprite scale, preserving world coverage while providing twice the texture density. Four native IsoSprite instances render at the player's world coordinates through the existing world render callback. There is no UI projection or UI element for the aura.

Validation: 836 native Kahlua assertions, including actual draw order, connected bar geometry, ready/Extreme/neutral states, activation pause/cancel and existing world-aura ownership and animation cleanup. Packaging checks source-to-PNG pixel identity, hashes, dimensions and upper-body coverage. Previews replay production HUD commands and actual aura frames; live appearance still needs confirmation.
