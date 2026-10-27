# Project Yakuza 0.31.1

- Replaced the faint Extreme Heat flame atlas with its supplied Yakuza 6 RGBA variant. All 64 frames are exact original-size crops; no visual/audio asset was generated or upscaled.
- Extreme Heat now uses four animated blue flame patches instead of two slow flames and two static wisps. Loops run at roughly .6-.8 seconds around the upper body; no leg emitters or broad cloud/bloom layer are added.
- Corrected the source texture's blend mode: black-backed RGB uses a scoped additive world pass. Bounded opacity and saturated blue tint improve visibility without a near-white sheet. The renderer state is restored after success or failure.
- Preserved normal heat visuals, the 350 ms appearance fade, taunt flash, outline, controls, gameplay and sounds. No voice-pack files were touched.

## Validation

2,923 offline Kahlua assertions pass, all 37 production Lua files compile, all 66 aura textures decode through B42 ImageData, and every crop/hash matches the supplied DDS. PZ was not launched; final GPU appearance and live MP still need gameplay verification. See [validation](VALIDATION_0.31.1.md). Local installation backs up changed files only and verifies installed bytes.
