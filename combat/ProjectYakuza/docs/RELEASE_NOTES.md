# Project Yakuza 0.31.0

- While aiming, tap-release MMB requests the ordinary finisher/double finisher; hold starts a stationary charged heavy. Valid Tiger Drop keeps initial-press priority. Other styles retain their existing input until they opt in.
- The charged strike uses supplied Yakuza 6 Kiryu charge-loop/release animations, x2 base damage and one native collision check. It remains vulnerable, cancels safely on interruption, and retains the three-victim multihit cap.
- Original Yakuza 6 sparks animate in world space around the charging hand/upper body and on confirmed charged hits. No visual/audio asset was generated or upscaled. Both clips and the losslessly decoded spark have source/hash provenance.
- Extreme Heat gets a subtle native blue silhouette outline, with previous highlighting preserved/restored. This approximates the reference; it is not Yakuza's full character shader.
- Lua API 3 lets addon developers replace each style's heat display, combat text, style wheel, individual slots and assignment-screen presentation. Providers support supplied assets/atlas cropping, arbitrary layouts, paused animations, live heat/action data, lifecycle/resource cleanup and safe fallbacks. Default DoD HUD artwork is retained.
- Charge observers and impact metadata use the existing MP protocol. Grabs stay disabled; the separate voice pack is untouched. Existing optional heavy-attack CVF cues are used.

## Validation

Offline Kahlua regression checks, native B42 clip import, native animation-node/observer selection, native outline API and original-pixel/native-texture decode checks pass; see [validation](VALIDATION_0.31.0.md). No PZ game was launched. GPU appearance, live input feel and a live multiplayer session still need in-game verification. Local installation backs up changed files only and verifies every installed source file.
