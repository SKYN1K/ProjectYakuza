# Combat music

Funk Goes On is the first theme for Dragon of Dojima. It starts on the first confirmed damaging zombie hit while the style is equipped. Further hits keep the same playback running. After 12 seconds without a hit, it fades out over 1.25 seconds; another hit reverses that fade. Fade-in takes 0.8 seconds.

The entire supplied recording repeats, including its original ending. It has not been edited into a seamless intro/loop arrangement. The original MP3 is unchanged.

Use Combat styles -> Toggle combat music in the inventory context menu. The game Music volume controls this track. Native music is ducked during the theme and restored on exit, death, unequip, style changes, saving, or disabling the option. Music uses a private 2D local emitter and produces no zombie-attracting world noise.

No nearby-zombie scans or idle update hook are added. A single update hook runs only while the theme is playing.

Validation: 818 native Kahlua assertions covering existing combat/aura behavior and music triggers, fade reversal, pause, volume changes, failure backoff and cleanup. Build 42's actual GameSoundScript parser accepted the track definition, loop flag, Music master, file path and clip volume. FFmpeg decoded the entire OGG without errors. Audible mixing and timing still need an in-game check.
