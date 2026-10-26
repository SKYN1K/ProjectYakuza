> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Character aura top-edge correction

The world-aura frames now use a 128 by 256 power-of-two canvas instead of 128 by 192. Thirty-two transparent pixels are added above and below the previous frame. The attachment height calculation uses the new canvas height, so the visible effect keeps its existing body anchors and scale.

The first 24 rows of the visible aura receive an additional smooth fade, allowing the rising flow to disappear before the top boundary. All lower visible pixels are unchanged. Animation frames, phase offsets, speeds, color, emitter positions and the user's current enlarged size are preserved.

Validation: all 96 frames have transparent headroom; byte comparison against v0.16.2 confirms the lower image payload is unchanged. Native Build 42 projection checks pass for all four updated aura anchors. The complete 839-assertion Kahlua suite passes. GPU clipping must still be confirmed in-game after restarting.
