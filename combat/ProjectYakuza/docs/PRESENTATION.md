# Presentation, audio and resources

New styles do not inherit DoD's playlist, HUD, aura, impact renderer or counter. Profiles are explicit. Supply existing assets with provenance; do not generate/upscale missing media.

| Field | Supplied profile |
| --- | --- |
| heatHud="yakuza6" | Dragon/main orb and six stock-orb HUD, requires heat |
| heatAura="kiryu" | World torso/arms/head aura, fade-in, taunt end flash; exclusive, equally sized cyan replacement during Extreme Heat |
| hitEffects="yakuza6" | Animated world impact glints/sparks |
| selectorIcon | Existing texture path in selector circle |
| enemyReactions=true | Configured supplied victim mappings |

HUD/selector are UI; aura/impacts use the world renderer. MP observers render relayed state/results. For a new visual profile implement scoped listeners/rendering using your own supplied textures; an arbitrary profile string is not a renderer. Never apply gameplay damage from a particle callback.

## Music

music is false/omitted for silence, or a unique list such as `{{sound="MyMod_ThemeA",title="A"},{sound="MyMod_ThemeB",title="B"}}`. Each name references a real PZ definition: category=Music, master=Music, is3D=false, **loop=false**. Use at least two distinct recordings for continuous shuffle without immediate repeat. Natural completion in continuing combat selects a different name; the encounter has a 12-second quiet grace. Native music ducking/restoration and pause/cleanup are retained. DoD's 19 tracks belong only to DoD. Playback is whole-track/local, not segmented/MP-synchronized music.

## Sounds and volume

Supported cue keys: punchImpact, kickImpact, heatImpact, punchSwing, kickSwing, finisher, grab, throwImpact, guardHit, guardBreak, heatGain, heatFull, heatStart, heatOnA, heatOnB, heatOff. Values are existing PZ sound-definition names. Omitted cues add nothing; native unarmed fallback remains. Optional heatOnB follows after 300 ms; other sequences need their own controller. The charge fades into the flare over 140 ms, and delayed layers survive successful animation completion. Source recordings remain unchanged; runtime handle volumes provide the softer mix. See [activation SFX](EXTREME_HEAT_AUDIO.md).

Options > Mods > Project Yakuza has **Music, Sounds, Voices**, each 0-200%, zero mutes. Music applies to registered playlists; Sounds applies to registered profile sound names; Voices affects combat-originated CVF playback only. Native Advanced Audio remains available for individual definitions. PZ sound resources/user volumes are global: give addon sounds unique names. Clip gains and per-style voice mix remain separate.

## Voices

Optional CVF resolves the selected character voice. Reserved ProjectYakuza IDs: CombatLightAttack, CombatHeavyAttack, CombatSpecialMove, CombatTaunt, CombatExtremeHeatActivation, CombatStanceEntry, CombatGettingHit, CombatGettingStunned. combatVoices=false opts out, combatVoiceVolume defaults to 1, quickstepVoices=false suppresses movement-only step cues. Missing provider/recordings stay silent without blocking attacks.

CombatStanceEntry belongs to actual styleEntryStarted, not RMB aiming. Taunt/activation cues belong to actual action start. Custom moves can call CombatVoices.play(player,id) for an appropriate existing cue; do not duplicate a cue already subscribed to an event. See [CVF](CVF_COMBAT_VOICES.md) and its template. The separate voice-pack project is not modified.

Extreme Heat replaces normal heat with four original Yakuza 6 blue flame sequences, looping in roughly .6-.8 seconds. Their black-backed RGBA source uses one scoped additive world pass, with no static wisp/cloud or separate bloom layer. Tint/opacity are runtime code; original atlas pixels are unchanged. Upper-body bounds, fade-in, pause and mode cleanup remain in place. Normal aura returns only when eligible. See [flame profile](EXTREME_HEAT_AURA.md).

## Custom style UI

API 3 adds client-side `registerStyleUI`/`unregisterStyleUI`. Styles opt into individual heat, status, selector, selectorSlot and setup renderers using `ui`. Providers can draw supplied textures/atlas crops, animate them using a paused clock, and own panel resources through create/update/render/destroy. Missing or failed providers fall back to the existing UI; false explicitly hides that channel. See [Style UI](STYLE_UI.md). Extreme Heat also uses a subtle native silhouette outline; it is an approximation rather than the Yakuza lighting shader.

During Extreme Heat, the original dark/blue dragon body/head, six dark orb rings/glasses, connectors and tail replace their white counterparts using runtime atlas crops. The existing original glow pieces pulse purple-blue; stock orbs stay dark and the main orb displays fuel. Mode exit restores the normal white HUD and stock fills. No HUD image is generated or altered; see extreme-hud-crops.json. Low original animated smoke accompanies the purple-blue world flames, using alpha blending separately from the additive fire.

## 0.32.1 loader and activation correction

Animated pages follow native `LoadFramesNoDirPageDirect(prefix,kind,count)` naming: `prefix_kind_0.png` through `prefix_kind_<count-1>.png`. This applies to normal aura, Extreme Heat flame/smoke and taunt bursts. Export/decode checks alone do not verify native path resolution; run validate_effect_loader_paths.py too. Extreme Heat fire/smoke now begin during the actual started activation action, continue into fuel mode, and restore/clear on interruption or observer clip exit. The HUD uses a protected normal-alpha pass with purple glow behind the solid orb artwork.

0.33.0 uses original alpha-bearing flame crops with normal blending to avoid black rectangles; only Extreme Heat flame frame speeds are multiplied by .55. Charging effects reuse those transparent cells, original ChargeSpark and HitGlint with a ready pulse. No new graphical artwork or audio was generated.

## Move-specific hit responses (0.40.0)

Optional style.hitResponses defines named flinch/stagger/knockdown profiles with finite force 0..1.5 and optional full-charge threshold/response. Moves may select a profile with hitResponse="name" or opt out with false. Defaults distinguish lights, first/double finishers and charged heavies. Ground attacks are excluded. Styles without profiles keep their existing behavior. See [Hit responses](HIT_RESPONSES.md) for fields, native timing, MP ownership and limits.

## Feedback polish (0.53.0)

Optional style sound keys include guardHit and doubleFinisher; doubleFinisher falls back to finisher when absent. They use the mod Sounds group, leaving Voices and Music independent. Built-in unarmed whooshes use current native clip phase when the exposed track API is available; custom moves retain the timing fallback. No audio waveform is generated.

HitEffects.guard(player,zombie) presents a short defender-side spark burst without blood. Existing confirmed heavy/charged impacts add a low-opacity original shock texture. Both use detached world sprites and existing presentation budgets. The existing MP guard/impact messages relay them without additional packets. Pure Lua punch positions are corrected source samples, not final blended bone attachments; an optional live limb provider can supply those coordinates.

## Scripted sound variety (0.58.0)

Styles can opt in with `soundVariety=true` and register existing multi-clip sound pools with `ProjectYakuza.SoundVariety.registerPool(name, count)` in shared code. Scripted Feedback uses shuffled native clips with original parent volumes and validated MP relays. See [Sound variety](SOUND_VARIETY.md) for configuration, heavy/counter sound slots, limits and lifecycle.


Version 0.66.0 expands the style-owned attack coating to all active DoD attack clips, including weapon profiles and finisher contacts. Existing source motion and game textures are reused. Contact-specific arm/leg tracks, bounded irregular movement and observer reconstruction use the existing animation phase and protocol; no additional particle packets are sent. Explicit move configuration takes priority and other styles remain opt-in. See [Attack effects](ATTACK_EFFECTS.md).
