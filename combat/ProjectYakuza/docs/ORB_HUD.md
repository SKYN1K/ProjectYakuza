# Connected heat stock orbs

The horizontal heat extension now uses three connected small orbs, one per heat stock. Partial charge fills the next orb from bottom to top. The main orb remains inside the original dragon frame. Original atlas regions provide the glass, blue core, small orb border and dragon glow; no added artwork or enlarged source textures are used.

The neutral white dragon, full-heat ready glow, Extreme Heat glow and 800 ms activation remain. The dragon/head and glow have eight pixels of internal padding to prevent edge clipping. The corrected horizontal bar implementation is preserved at reference/HeatUI-Bar-preserved.lua. Its textures are retained, but the active orb HUD only loads the original atlas.

The aura is 15% larger than v0.15.4. Only its four scale values changed. The renderer, anchor positions, animation, color and all 96 textures are unchanged; aura-size-adjustment.json records verification.

Validation: 837 native Kahlua assertions including three connected orb frames, partial stock clipping, original-source crop routing, foreground order, panel bounds, ready/Extreme glow, activation cleanup and existing combat/aura behavior. Package checks preserve original atlas pixels and the bar reference. Live alignment still needs an in-game check.
