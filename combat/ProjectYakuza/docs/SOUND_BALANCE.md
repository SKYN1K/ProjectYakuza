# Sound balance 0.21.1

`ProjectYakuza_Y6_PunchImpact` clips: 0.700 → 0.595 (×0.85).

`ProjectYakuza_Y6_HeatGain` and `ProjectYakuza_Y6_HeatFull` clips: 0.700 → 0.910 (×1.30).

The existing feedback gain remains 0.55, so effective orb-cue gain changes from 0.385 to 0.5005. Punch whooshes, kick impacts, Extreme Heat impacts, activation layers and music retain their previous levels. No audio waveform was modified or generated.

Local bank inspection found `battle_common/hactmode_on` (waveforms 14/15, AWB 21/19; 2.312/2.269 seconds), `hactmode_off`, and the distinct voice cue `gv_fighter_kiryu/boost_on`. The two activation effect layers already play at the activation flare, with the original 300 ms second-layer delay. The voice label suggests an activation voice; this update does not claim a listening verification or add that voice. `gage_up` and `gage_full` are separate gauge cues.

## Native volume controls

Options → Audio → Advanced opens PZ’s native persisted per-sound sliders and previews. Select Project Yakuza - Effects for punch, kick, orb and activation groups; select Dragon of Dojima - Music for individual track volumes. Zero mutes a sound. Both context-menu sound toggles and their saved disable flags have been retired. This mod enables the stock Advanced button; slider storage and playback gain remain handled by PZ.

Version 0.23.0 adds native Options → Mods → Project Yakuza grouped music and combat-hit sliders (0–200%). They set GameSound user levels and persist with the built-in PZAPI.ModOptions. Heat orb/activation cues retain independent native Advanced Audio levels.

