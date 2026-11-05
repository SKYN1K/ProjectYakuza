# Optional Custom Voice Framework integration

Compatible API: Custom Voice Framework 1.1+ from https://github.com/DmitryFisk/custom-voice-framework. Inspected source commit: 88d19f7b0a6574d341ed4129212909e3ebded658. The adapter uses registerLine/getLine/playLine and the selected character descriptor prefix; it does not vendor or modify CVF, install/change existing voice packs, or choose Kiryu just because Dragon of Dojima is equipped. Both CVF and a compatible voice pack must be enabled for custom recordings to play. ProjectYakuza still runs normally without them.

## Reserved entries

Namespace/modId: `ProjectYakuza`. All definitions are wheel=false and absent recordings have no fallback. Exact metadata for voice authors is in [the manifest fragment](../templates/CVFCombatLines/lines.json).
| Entry | Trigger |
|---|---|
| CombatLightAttack | Actual light swing, after native floor targeting is classified |
| CombatHeavyAttack | Finishers, double finishers and ground stomps |
| CombatSpecialMove | Running/quickstep attacks; accepted quicksteps, grabs, parries, throws and future heat actions |
| CombatTaunt | Actual animation-backed taunt start (tauntStarted) |
| CombatExtremeHeatActivation | The activation animation actually starts; not every heat update |
| CombatStanceEntry | Start the style-selection entry animation; raising RMB does not play this cue |
| CombatGettingHit | Confirmed acute damage to the local style user; not hunger, thirst or ongoing bleeding |
| CombatGettingStunned | Knockdown / stun, stagger, trip or bump reaction entry, or a guard break |

The Voices slider applies only to combat-originated playback. combatVoiceVolume is a per-style multiplier; quickstepVoices=false suppresses movement-only step cues.

Only the owning local player's client requests playback. CVF uses transmitPlayerVoiceSound once and enforces its server policy, voice-busy guard, 250 ms global interval and per-line cooldowns. ProjectYakuza does not replay voices through its MP effect messages. One attack queues one line, not one per zombie; native ground-target correction replaces the pending light line with the heavy line. Interrupted/stale attacks are discarded. Voices may be skipped when CVF reports busy/cooldown. Existing engine-triggered vanilla voices are not globally muted or rewritten by this adapter.

## Authoring

Merge templates/CVFCombatLines/lines.json into your voice pack's existing manifest.lines. Put your supplied files in the voice folder, for example `ProjectYakuza.CombatExtremeHeatActivation_01.ogg`. Build with CVF's own New-VoicePack.ps1. Its namespaced suffix is returned by `CustomVoice.getLineSuffix("ProjectYakuza","CombatLightAttack")`; the full script name is the character's voice prefix plus that suffix. Native old packs containing only Shove/Stomp/etc. do not automatically supply these new entries. There are no generated, extracted or added voice/audio assets in this update.

Dragon of Dojima has an animation-backed taunt, available without CVF or recordings. Its action emits `ProjectYakuza.emit("tauntStarted",player)` once on actual start. Other explicit calls can use `ProjectYakuza.CombatVoices.play(player,id)` with one of these registered IDs. A style can opt out with combatVoices=false. Missing/incompatible CVF and registration conflicts fail quietly for the affected entry; they never block attacks. Conflicts log once and retain CVF's first registration.

Validation uses the exact upstream Core/Lines/Playback code plus the shipped suffix catalogue, not a guessed provider API. No live game was launched. This integration itself does not enable or install CVF for the user.



Per-style `combatVoiceGains` optionally maps reserved line IDs to nonnegative volume multipliers. Missing IDs use 1, and 0 mutes that cue. The multiplier composes with `combatVoiceVolume` and the mod's Voices slider. DoD no longer authors a loudness multiplier or per-line gain override. Its combat voices follow the combat Voices slider and the supplied pack baseline. The separate CVF voice pack is not modified.
