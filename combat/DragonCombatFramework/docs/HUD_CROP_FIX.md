# HUD atlas crop correction and aura size

The dragon, head, glass, core and native glow use explicit source rectangles through ISUIElement.drawSubTexture / UIElement.DrawSubTextureRGBA. Runtime Texture.split objects are no longer passed to drawTextureScaled. The explicit native path computes source UV coordinates for each draw. The original 512 by 512 atlas and all its pixels are unchanged.

The four aura sprite scales are multiplied by exactly 1.2. Animation, colors, source textures, world render path and anchor positions are unchanged. Every other byte in HeatAura.lua and all 96 aura PNGs match v0.15.3. See aura-size-adjustment.json.

837 native Kahlua assertions pass, including explicit source-rectangle routing, heat-state glow, clipping cleanup and aura lifecycle. Native Build 42 Lua/UI implementation was inspected for the crop API. GPU appearance still needs an in-game check after a full restart.
