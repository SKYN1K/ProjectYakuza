# Project Yakuza 0.72.0

- Replaced the demo-era Heat Rush pair with Yakuza 6's verified retail repeated-punch/kick attacker and victim motion, preserving all 225 source frames.
- Added six rebindable QTEs: Light → Heavy → Grab → Light → Heavy → Grab. Ordinary grabs remain disabled. Circular timing cues reuse unchanged original game texture pixels.
- Successful cues play original-contact punch feedback. One automatic finishing kick delivers earned damage; missed cues reduce it. The maximum payoff is unchanged, and the full recovery plays.
- Updated limb trails to six verified right-arm punches and the finishing right-leg kick. Fixed MP pose acceptance for the full 7.4667-second sequence and validated mapped inputs, deferred damage, deduplication and cleanup.
- Documented reusable prompt/contact mappings and automatic summed-payoff contacts for framework authors.

No generated artwork/audio, AI or upscaling. The normal PZ camera remains; cinematic close-ups require capabilities outside this Lua-only setup. Project Zomboid was not launched. See [offline validation](VALIDATION_0.72.0.md). Install the same version on server and clients, then restart.
