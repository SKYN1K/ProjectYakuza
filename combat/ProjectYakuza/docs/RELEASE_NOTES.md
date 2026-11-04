# Project Yakuza 0.82.0

- Lowered the health bar by 12 pixels at the default HUD scale and shortened it from 630 to 270 pixels, matching the reference more closely.
- Calibrated the ground-trample victim position from Zomboid's native male/female head meshes and the attacker's foot sole at impact. The fixed correction applies from the beginning and rotates with the pair, preserving original motion and wall-clearance checks.
- Prepared idle variables beneath style entry and enabled a 0.24-second native early blend into idle. Movement/attacks stay locked for the original source duration; entry remains vulnerable to hits.
- Replaced repetitive entry/taunt presentation with distinct original Kiwami 2 effects: curling wisps plus brief smoke while switching, and a soft blue spiral with fine rising streaks after a completed taunt. Entry effects last 0.38 seconds; the taunt burst lasts 0.45 seconds.
- Replicated entry effects trigger once per distinct MP action, without restarting on repeated snapshots. Existing regular/Extreme Heat effects and voice-pack files are preserved.

Four existing decoded game textures were copied with unchanged native pixels. No AI, invented artwork/audio, upscaling, source-motion edits or PZ launch. See [validation](VALIDATION_0.82.0.md), [Heat Actions](HEAT_ACTIONS.md) and the asset/calibration reports. Restart after updating with matching MP versions.
