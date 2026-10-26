> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# HUD polish and heat balance — 0.16.5

The HUD continues to use the two original, pixel-identical Yakuza 6 atlases. No artwork or texture files were generated, repainted or resized.

Energy fill now reveals a bottom-up source rectangle and a matching destination rectangle. Partial orbs retain their original proportions rather than stretching the cropped pixels. Source crops ease to the new heat level over 160 active milliseconds; glass highlights remain visible above them. Glow phase advances continuously rather than jumping every 50 ms. The 800 ms activation flash uses smooth easing. Pause freezes all animation. Heat polling remains limited to 10 Hz; partial fills no longer require per-orb stencil changes.

Each of the six visible orbs now corresponds to one banked heat stock (100/6 points). Stored normalized heat remains compatible with existing saves. Action stock costs, banking, Extreme Heat entry and aura eligibility use the same stock size. The action API fallback also uses six stocks.

Confirmed-hit heat gain is 2.5 points per native damage unit, down from 10 (75% slower). A 0.4-damage hit grants 1 point instead of 4. Damage capping and per-swing/victim deduplication remain unchanged.

Full-meter Extreme Heat lasts 22.5 seconds before attack/damage costs, up from 18 seconds (25% longer). Six stocks therefore contribute 3.75 seconds each. Doubling capacity does not accidentally double the full-meter duration. Attack and incoming-damage fuel costs are unchanged.

Validation: 880 checks in the game's Kahlua interpreter, including all six bank boundaries, reduced gain, full-meter duration, fill interpolation, UV proportions, pause, cached textures and existing combat/aura behavior. The actual native crop method accepts double coordinates. A preview was rendered from production draw commands. Package validation confirms that all texture, animation and world-aura assets are byte-identical to v0.16.4. Live GPU appearance has not been tested.
