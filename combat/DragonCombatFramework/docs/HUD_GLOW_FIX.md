# HUD glow transparency correction

The HUD's original game glow textures now use PZ's TransparentStyle rather than AdditiveStyle. This preserves the texture alpha feathering instead of flooding the surrounding area with cyan. Ready-state opacity is bounded to 0.075–0.125; Extreme Heat opacity is bounded to 0.24–0.36. The previous renderer state is restored after drawing.

No original texture pixels, sprite regions, orb layout, combat behavior or character-aura code/assets are changed. The main glow's source top-row alpha ranges from 0 to 1 out of 255; the connector's top-row alpha ranges from 0 to 2. With the correct transparency style, these edges fade rather than appearing as solid cutoffs. All glow quads fit within the HUD panel.

839 native Kahlua checks pass, including transparent glow style, bounded opacity, renderer-state restoration and prior HUD/combat checks. Headless previews validate the texture composition; live GPU appearance still needs confirmation. The separate character-world aura top-edge correction is documented in AURA_TOP_EDGE_FIX.md.
