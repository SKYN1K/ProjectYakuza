# Project Yakuza 0.39.0

- Completed the approved taunt-aura colour change: RGB moves 25% toward white using non-AI colour-only copies of the existing 96 standard aura frames. Alpha, shapes, original dimensions and frame order are identical; no resizing or new particle shapes.
- Colour blends smoothly to/from the original blue during the existing fades. The taunt echo still grows by 20%, lasts 0.75 seconds, and uses the standard aura animation without stacking a brightness pulse.
- Punch effects, all combat behavior, normal/Extreme Heat effects, sound and controls are unchanged from v0.38.0. Grabs remain disabled.

## Validation

3,969 offline Kahlua assertions pass; all 40 production Lua files compile. Pixel checks compare every copied RGBA pixel with its source and prove exact colour mapping and identical alpha/dimensions. Native B42 ImageData decodes all 226 aura/copy PNGs and all 325 effect-loader paths resolve. Original media are byte-identical to v0.38.0. See [validation](VALIDATION_0.39.0.md) and [provenance](taunt-aura-assets.json).

Installed locally and published with a versioned install ZIP. PZ was not launched; live appearance remains unverified. Fully restart the game; server and clients need the same version.
