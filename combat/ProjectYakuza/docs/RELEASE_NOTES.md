# Project Yakuza 0.32.0

- Each of the four first finishers now charges in its own original wind-up and releases into its matching strike. The eight clips use exact frame splits/retargets of supplied Kiryu motions; no poses or animation frames were generated. Neutral charged heavy remains available.
- Second finishers are unchargeable: a fresh press queues the ordinary follow-up immediately. Charged first finishers can still flow into their matching second finishers. Tickets bind each charged release to its branch; source contact/link markers are preserved and rebased.
- Extreme Heat now has a more purple-blue flame/outline hue and two low animated smoke emitters around the legs, using the original Yakuza 6 smoke atlas. Regular heat retains its existing layout.
- Extreme Heat HUD uses the supplied atlas's original dark dragon, orb rings/glasses, connectors and tail with purple-blue original glow pieces. All six stock orbs remain dark during mode; normal artwork/fills return afterward.
- No visual/audio asset was generated or upscaled. Grabs remain disabled and the separate voice pack was untouched. New owner/observer clips use the existing MP protocol.

## Validation

Offline Kahlua tests, native B42 clip import/node selection/texture decode and original-pixel/hash checks pass. Native split-pose checks verify every wind-up endpoint matches its release start. PZ was not launched, so final GPU appearance and live input/MP still need gameplay verification. See [validation](VALIDATION_0.32.0.md). Installation backs up only changed files and verifies all installed bytes.
