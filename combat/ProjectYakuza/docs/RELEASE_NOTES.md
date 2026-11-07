# Project Yakuza 0.93.1

- Fixed Heat Actions spending a stock without playing. The ordinary player-update loop now starts and advances queue-free weapon, ground and grab Heat Actions; the previous branch only waited for a start that never occurred.
- Paired Heat Actions now pay their stock or Extreme fuel cost once native playback is confirmed. Missing playback and cancellation before that point spend nothing. Repeated updates cannot charge twice, and cancellation after playback retains the committed cost.
- Moved swing commitment and multiplayer readiness to confirmed playback. Startup pause handling preserves the animation grace period; ordinary custom action kinds retain accepted-start payment.
- Replaced the misleading manual-start regression with checks through real player-update callbacks, including full contacts/completion, ground/grab startup, missing clips, pause, resource loss and the final Extreme fuel stock.

All 15 selected offline Kahlua suites pass; all 75 production Lua files compile and source checks report zero code comments. No supplied motion, texture or audio assets changed. PZ was not launched. See [validation](VALIDATION_0.93.1.md). Fully restart PZ after installation; servers and clients must use matching versions.
