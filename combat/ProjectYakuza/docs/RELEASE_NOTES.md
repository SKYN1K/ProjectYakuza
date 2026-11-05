# Project Yakuza 0.84.0

- Increased the walking grab distance from about 0.29 to 0.5 tiles while preserving individual strike/throw contact offsets and short position blends.
- Completed grab throws now settle the victim directly in the native face-up ground state. Standing hit/stumble reactions and residual push force are cleared after cleanup, including MP release/damage packet handling.
- Rebuilt Extreme Heat Rush around six QTE sections with two automatic punches per section: twelve punches total, followed by the automatic kick. The input order remains light, heavy, grab, light, heavy, grab.
- Split/replayed supplied source sections at their original 30-fps speed. Each prompt has a full one-second section. Removed the ineffective live-speed-variable approach; no slow-motion retiming is applied.
- The original kick now also plays as the paired ending after a QTE failure. Both actors stay paired through it; only passed QTE sections contribute to its damage. The kick never requires another input.
- Added framework support for stage-based QTEs with independent physical contacts and supplied paired failure endings. Existing per-move timing, failure-count and binding options remain.

Only user-approved source-motion conversion was used: existing poses were split and replayed, without AI, invented motion, new artwork, audio or upscaling. Voices and the separate voice pack are unchanged. See [validation](VALIDATION_0.84.0.md) and [QTE authoring](QTE.md). PZ was not launched; restart with matching MP versions.
