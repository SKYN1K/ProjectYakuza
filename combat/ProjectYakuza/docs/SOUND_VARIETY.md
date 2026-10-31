# Combat sound variety

Version 0.58.0 adds opt-in shuffle selection for scripted combat sounds. Dragon of Dojima enables it. The existing 31 clips across seven pools are reused without conversion or editing. Native primary collision sounds still use Zomboid's random selection; shuffle guarantees apply to scripted Feedback playback, not every native collision.

## Style configuration

Set `soundVariety=true` on a registered style and configure `sounds` normally. Existing default pool names and clip counts are:

| Sound name prefix: ProjectYakuza_Y6_ | Clips |
| --- | ---: |
| PunchImpact | 9 |
| KickImpact | 5 |
| HeatImpact | 4 |
| PunchSwing | 4 |
| KickSwing | 3 |
| GuardImpact | 3 |
| HeavyFinisher | 3 |

`Feedback.play(player, cue, gain)` selects shuffled clips only when the active style opts in and the cue appears in that style's `sounds` table. Other cues/styles retain the normal `player:playSound` path. Gains remain 0..1. Weapon views use their own sound configuration, preserving native weapon audio rather than inheriting unarmed strikes.

Optional `sounds.heavyImpact`, `chargedImpact`, `parryImpact` and `barrageFinisher` override the scripted confirmed-hit accent for normal heavy, charged, Tiger Drop and final barrage contacts. Missing overrides fall back to `sounds.finisher`. Existing `doubleFinisher`, `guardHit`, `punchSwing` and `kickSwing` slots retain their roles. Only one heavy accent is emitted per attack stamp, including multihit.

## Addon pools

Require `ProjectYakuza/SoundVariety` from shared addon code, after your sound definitions are available, and call `ProjectYakuza.SoundVariety.registerPool(soundName, clipCount)`. Use a namespaced sound name and an integer count from 2 through 32. Every clip must use a distinct nonempty file path; all peers need identical definitions and files. The sound must also be configured in the style's `sounds` table. Re-registering the same count is safe; changing an existing pool count is rejected.

The public `GameSound:getRandomClip()` and `GameSoundClip:getFile()` methods discover a bounded set once per sound object, then sort by file path so network clip indices agree across clients. Discovery does not play audio. It makes at most count times 32 draws, caches successes or failure, and falls back to ordinary native cue playback if discovery is incomplete. Empty, duplicate-file, event-only or mismatched pools are unsupported. Reload the world after altering definitions; save/menu cleanup clears caches.

Do not use public Java instance fields such as `sound.clips`: they are not Lua properties. Selected native clips are played by a pooled world emitter at the actor's position, retaining their original GameSound parent and volume identity. There are no helper aliases or extra audio slider rows. These are short one-shot sounds; they do not follow a moving limb. Keep long activation/tail sounds on the existing character-emitter path so their stop/fade handles remain valid. Do not register those cues as shuffled pools.

## Multiplayer and lifecycle

The owner sends the chosen cue/index/gain. The server validates the equipped active style, current weapon profile, pool membership, numeric bounds, event/session and a maximum of 12 relayed sounds per actor per second, within the existing generic command budget. Remote clients ignore owner echoes and duplicate events. Missing streamed actors drop these short cues rather than replaying stale sounds. This path does not deal damage or attract AI.

Personal volume settings apply separately on each listener. A zero playback handle still permits the selected clip relay, preserving remote playback when the owner's local audio is muted. Shuffle history is per player/style/pool and clears on style change, save and menu entry. No new tick/render loop is installed.

The standalone sound-variety Kahlua fixture exercises actual production Feedback/SoundVariety code. SoundVarietyProbe parses the original definitions, verifies original parent identity/files and executes the public clip methods through Zomboid's Java-to-Lua exposer without launching PZ or playing audio.
