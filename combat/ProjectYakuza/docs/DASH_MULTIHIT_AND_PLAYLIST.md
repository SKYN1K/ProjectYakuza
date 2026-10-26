> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Dashes, multi-hit, world sparks and playlist — 0.17.1

## Quicksteps

All four quicksteps now move 1.2 tiles instead of 0.8 (1.5x distance). Animation speed increases from 1.35 to 1.6875 (25% faster playback). Native clip duration is now about 0.435 seconds. Existing input, cooldown and LMB quickstep-attack handover remain intact.

Movement follows the original progress markers. Every movement span is checked in segments no longer than 0.08 tiles using a staged world position. This lets a delayed frame reach the requested progress without discarding distance or skipping intermediate wall/floor checks. The normal native collision solver applies the resulting movement; no coordinate setters are used.

## Multi-hit

All 22 current strike animations support up to three distinct nearby targets: four lights, four finishers, four double finishers, four quickstep strikes, four running strikes and two stomps. Tiger Drop also hits up to three frontal targets; only its primary counter target must satisfy the timed parry window. One successful counter still consumes one 60-second cooldown and plays one animation.

The style token uses native MaxHitCount=3; already-created tokens migrate automatically. When native multi-hit already reports multiple victims, those targets are counted and never hit again. After the native collision finishes reporting hits, a bounded supplement fills any remaining slots through each additional zombie's native Hit method. This supports saves with native multi-hit disabled and the native bare-hand single-target stomp restriction without changing sandbox options or other weapons.

A real confirmed hit is required; misses never create an area attack. Targets must be close, in the forward cone, visible, on the same floor and reachable through small collision-checked path segments. Stomps select downed targets; standing strikes select standing targets. Each target gets normal native damage, armor/death processing and the existing heat/reaction/effect callbacks. Per-swing identity and victim sets prevent recursion and repeated callback damage. Pending supplements are discarded if the player dies, changes equipment or the swing is interrupted. There are no idle target scans or permanent multi-hit tick callbacks.

## Hit sparks

The 32 existing 64x64 frames retain identical RGB pixels and dimensions. Only alpha changes: min(255, round(originalAlpha * 1.1)), making the sparks approximately 10% more opaque. The original timing, shape, position and sprite pool are retained.

Sparks remain native IsoSprite world animations attached to each struck zombie. There is no HUD panel, UI mouse capture or screen-coordinate projection. Instance alpha and target alpha are set to 1 so character fade does not reduce their opacity. The heat HUD and character aura are byte-identical to 0.17.0.

## Combat music

The Dragon of Dojima encounter playlist contains Funk Goes On, Bring It On and Receive You Ver. 7. A uniform random choice is made once when a confirmed combat hit starts the music. Later hits retain that track and its playback position, including when reversing an encounter fade-out. A later encounter makes a new random choice; repeats are possible. The existing quiet timeout, fades, volume control and vanilla-music ducking remain unchanged.

Both newly supplied MP3 recordings are included in full as stereo 44.1 kHz Vorbis quality 5. There are no edits, generated music or authored seamless loop points. The native sound definitions loop each full recording. Provenance and output hashes are in combat-music-playlist.json.

## Validation

1099 Kahlua assertions cover existing combat/heat/aura behavior, every strike's multi-hit, native multi-hit deduplication, ground/standing/range/arc/visibility/obstacle filters, interruption and pause, all three playlist choices and no mid-combat reselection. Native animation selection validates all four faster quicksteps; the native sound-script loader validates all three music definitions. Packaging verifies unchanged spark RGB, exact alpha conversion, unchanged heat aura/HUD and preserved other combat animations.

Live game movement, multi-hit visuals and audio playback have not been tested in this update. Fully restart PZ to load it.
