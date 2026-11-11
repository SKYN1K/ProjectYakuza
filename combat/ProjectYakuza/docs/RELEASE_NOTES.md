# Project Yakuza 0.99.1

- Fixed a stale native action-busy flag after quickstep, combat entry or Heat Action cleanup when the animation selector had already cleared. Cleanup respects replacement mod contexts, foreign animation clips and unrelated native timed actions.
- Grabs now examine every candidate in their existing bounded nearby scan before selecting the nearest eligible victim. Eight closer busy zombies can no longer hide another valid target in reach.
- Bottle attacks retain their source recovery: automatic early-transition events are disabled for the three lights, heavy and ground attack, and buffered followups start two original frames before the light ends instead of cutting off its final third. Deliberate quickstep cancels remain available. Owner and multiplayer observer selectors agree; supplied animation/audio/texture bytes are unchanged.
- All 30 rebuilt Kahlua suites, 83 production Lua compilations, native bottle selectors/imports, 450 MP observer selectors and zero-comment checks pass offline. Project Zomboid was not launched.

See [validation](VALIDATION_0.99.1.md) and [Heat drain](HEAT.md).
