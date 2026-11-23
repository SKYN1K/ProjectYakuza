# Extreme Heat and charged-attack sounds

Activation plays supplied Yakuza 6 charge and flare cues, plus the existing Kiwami 2 wind-up, ignition and surge. No audio is generated or re-encoded. Direct character-emitter playback keeps the cues on their owning player. Actual mode entry supplies an idempotent fallback when an activation callback is missing.

| Cue | Per-handle level | Timing |
| --- | --- | --- |
| Yakuza 6 charge | 0.45 | Activation starts; fades over 140 ms at flare |
| Windy whoosh | 0.80 | Activation starts; full original 3.22-second swell and tail |
| Main flare | 0.80 | Native flare marker or successful completion fallback |
| Ignition | 0.45 | Flare |
| Secondary flare | 0.50 | 300 ms after flare |
| Surge | 0.35 | 650 ms after flare |
| Natural mode ending | 0.65 | Heat depletes |

Hit volume and each supplied clip's sound definition still control the final mix. Completed activation retains owned tails; interruption, death, unequip, style change and save/menu cleanup stop owned sounds. Duplicate events cannot stack the sequence. Remote observers do not request another owner sequence.

Dragon of Dojima also maps chargeStart, chargeReady and chargeRelease to existing supplied cues. Heavy-charge start plays at 0.55, full charge at 0.45 and successful release at 0.50. Releasing or cancelling stops owned charging handles. Cancellation has no release flourish. Styles can provide their own sound mappings or omit them. This does not alter the separate voice pack.

Validation embeds production Feedback.lua in native Kahlua checks for timing, duplicates, interruption, ownership and cleanup. Native PCM/script checks verify supplied files without launching the game. Final loudness still needs listening in the live game mix.
