# Project Yakuza 0.78.0

- Restored vanilla weapon idle, RMB aiming, walking, running and sprinting selection for Dragon of Dojima. The custom weapon-pose overrides are disabled, including the katana holds reported to clip through the neck.
- Restored vanilla ordinary walking and slow walking when unarmed. The existing unarmed run blend uses Bob_Walk instead of the custom walk clip, addressing the overly fast walking appearance without changing travel speed.
- Retained the converted source clips in a dormant state for future repair. Pose builders reapply the fallback so rebuilding conversions cannot accidentally reactivate these overrides.
- Custom attacks, guard actions, Heat Actions and unarmed running/sprinting retain their existing motion. Menu/settings changes from 0.77.0 remain available.

No animation, texture, model or sound assets were generated or edited. Project Zomboid was not launched. See [validation](VALIDATION_0.78.0.md). Restart PZ and use matching server/client versions.
