# Project Yakuza 0.61.0

- Added optional Heat-based attack-speed curves for addon styles: maximum multiplier, curve power and optional remaining-fuel scaling during Extreme Heat.
- Captured the curve once per committed attack, with weapon overrides and cleanup on swing/style/equipment changes. Native variable-speed clips and whoosh timing use the captured value; fixed-speed timed/QTE scenes keep their authored timing.
- Added bounded multiplayer factor replication and rejection of mid-clip factor changes, invalid values and attempts to enable the feature on unconfigured styles.
- Dragon of Dojima and its weapon profiles do not enable the feature. Its complete style definition and all existing media/native definitions are byte-identical to 0.60.0; its normal and Extreme speeds are unchanged.
- Added developer documentation and offline curve/lifecycle, fixed-style behavior, feedback and multiplayer checks. Code remains comment-free; no graphical/audio/animation assets or separate voice-pack files were changed.

PZ was not launched. The feature has no gameplay effect on the current style. Restart matching 0.61.0 installations before testing future addon styles. See HEAT_ATTACK_SPEED.md and VALIDATION_0.61.0.md.
