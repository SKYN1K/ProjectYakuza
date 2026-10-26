# Presentation, audio and resources

New styles do not inherit DoD's playlist, HUD, aura, impact renderer or counter. Profiles are explicit. Supply existing assets with provenance; do not generate/upscale missing media.

| Field | Supplied profile |
| --- | --- |
| heatHud="yakuza6" | Dragon/main orb and six stock-orb HUD, requires heat |
| heatAura="kiryu" | World torso/arms/head aura, fade-in, taunt end flash and brighter Extreme Heat |
| hitEffects="yakuza6" | Animated world impact glints/sparks |
| selectorIcon | Existing texture path in selector circle |
| enemyReactions=true | Configured supplied victim mappings |

HUD/selector are UI; aura/impacts use the world renderer. MP observers render relayed state/results. For a new visual profile implement scoped listeners/rendering using your own supplied textures; an arbitrary profile string is not a renderer. Never apply gameplay damage from a particle callback.

## Music

music is false/omitted for silence, or a unique list such as `{{sound="MyMod_ThemeA",title="A"},{sound="MyMod_ThemeB",title="B"}}`. Each name references a real PZ definition: category=Music, master=Music, is3D=false, **loop=false**. Use at least two distinct recordings for continuous shuffle without immediate repeat. Natural completion in continuing combat selects a different name; the encounter has a 12-second quiet grace. Native music ducking/restoration and pause/cleanup are retained. DoD's 19 tracks belong only to DoD. Playback is whole-track/local, not segmented/MP-synchronized music.

## Sounds and volume

Supported cue keys: punchImpact, kickImpact, heatImpact, punchSwing, kickSwing, finisher, grab, throwImpact, guardHit, guardBreak, heatGain, heatFull, heatStart, heatOnA, heatOnB, heatOff. Values are existing PZ sound-definition names. Omitted cues add nothing; native unarmed fallback remains. Optional heatOnB follows after 300 ms; other sequences need their own controller.

Options > Mods > Project Yakuza has **Music, Sounds, Voices**, each 0-200%, zero mutes. Music applies to registered playlists; Sounds applies to registered profile sound names; Voices affects combat-originated CVF playback only. Native Advanced Audio remains available for individual definitions. PZ sound resources/user volumes are global: give addon sounds unique names. Clip gains and per-style voice mix remain separate.

## Voices

Optional CVF resolves the selected character voice. Reserved ProjectYakuza IDs: CombatLightAttack, CombatHeavyAttack, CombatSpecialMove, CombatTaunt, CombatExtremeHeatActivation, CombatStanceEntry, CombatGettingHit, CombatGettingStunned. combatVoices=false opts out, combatVoiceVolume defaults to 1, quickstepVoices=false suppresses movement-only step cues. Missing provider/recordings stay silent without blocking attacks.

CombatStanceEntry belongs to actual styleEntryStarted, not RMB aiming. Taunt/activation cues belong to actual action start. Custom moves can call CombatVoices.play(player,id) for an appropriate existing cue; do not duplicate a cue already subscribed to an event. See [CVF](CVF_COMBAT_VOICES.md) and its template. The separate voice-pack project is not modified.
