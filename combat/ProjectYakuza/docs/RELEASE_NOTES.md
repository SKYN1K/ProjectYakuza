# Project Yakuza 0.68.0

- Extreme Heat boost lights now stun zombies in place for 250 ms, refreshing on repeated hits. Native push/knockdown is suppressed for the swing and original weapon/AI/movement flags restore safely.
- Heat Rush now follows eight light inputs. The first seven may miss or hit any targets; only the eighth must connect. Its last character target wins, including supplemental hits, without falling back to earlier targets.
- Server proof now tracks ordered input snapshots rather than earlier damage. Outstanding supplemental hits are confirmed by source swing before handoff, with a bounded timeout and stale-reply rejection.
- Added typed player targets using the existing victim motion and two player state definitions. PvP/safety/faction/zone protections remain enforced; interruption or permission changes restore movement and attack controls.
- Preserved the 0.525 boost-light damage multiplier, existing QTE timings, Lua-only normal launcher, disabled grabs and separate voice pack. No image, audio, model or animation-motion assets were generated or edited.

Offline checks pass; Project Zomboid was not launched. Live PvP presentation and multiplayer latency still need in-game testing. Restart matching server/client installations. See VALIDATION_0.68.0.md.
