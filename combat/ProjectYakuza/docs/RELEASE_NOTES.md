# Project Yakuza 0.40.0

- Added move-specific standing-zombie responses for Dragon of Dojima: lights keep the four supplied Y6 flinches; first finishers and partial charges use native backward stagger; double finishers and fully charged strikes use native knockdown.
- Applies SP response flags after native damage/force calculation. Skips native deaths, floor/downed targets and hits without health loss; suppresses duplicate same-swing responses. Native movement/collisions handle knockback; no XY teleport or additional damage.
- MP resolves responses using the validated move and charge power locked per swing. Primary hits are never re-damaged. Existing impact/damage packets carry the result to the attacker and observers; extra victims use the same policy. Reaction work is bounded, and the local tick hook is removed when idle.
- Added optional, validated hitResponses profiles and per-move hitResponse selection/opt-out for style authors. Unconfigured addon styles keep their existing behavior. See [Hit responses](HIT_RESPONSES.md).
- No visual/audio/animation assets were created or changed. Combat damage, controls, charge timing, effects and voices are unchanged. Grabs remain disabled.

## Validation

4,014 offline Kahlua assertions pass; all 40 production Lua files compile. New tests exercise policy selection, partial/full power, native post-hit timing, zero-damage/dead/floor exclusions, duplicate suppression, pause/cleanup, owner/observer result handling, server locking and multihit without duplicate damage. Native reflection confirms the B42 setters used. All 551 motion/image/audio files are byte-identical to v0.39.0. See [validation](VALIDATION_0.40.0.md).

Installed locally and published with a versioned install ZIP. PZ was not launched; live response timing, knockback distance and multiplayer appearance remain unverified. Fully restart; server and clients need the same release.
