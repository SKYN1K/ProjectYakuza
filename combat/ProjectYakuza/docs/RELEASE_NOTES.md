# Project Yakuza 0.98.0

- Added the original Yakuza 6 knife Heat Action from h23680_buki_b, retaining all 131 actor/victim samples at 30 fps, original weapon-bone motion and full recovery.
- Available to Dragon of Dojima with its 23 registered knife items. Hold physical RMB and press the Heat Action binding (default MMB) near an eligible standing target outside a combo. One stock or equivalent Extreme Heat fuel is paid once after confirmed playback.
- Original CMN damage frames 40/90 retain 1:3 weighting, totaling 1.5 canonical held-weapon damage. Six directly decoded original sound cues, two existing Combat voice roles and ten source blood-family emitters follow their independent starts. Native palm/hilt and wrist adaptation retain the source weapon departure from the hand.
- Added the original Kiwami dragon_change waveform for combat-style selection and explicit reselection. This original waveform is shared by Kiwami's four style-change cue aliases.
- Added original Yakuza 6 menu_default open, cursor, confirm, cancel and toggle sounds to Project Yakuza's selector/settings UI. Playback is local, 2D and change-driven. Mod combo boxes keep the original popup behavior through a scoped subclass, and Save/Cancel callbacks avoid duplicate sounds. Save/death/world cleanup stays silent.
- All 30 Kahlua suites, 82 production Lua compilations, source PCM/motion/native grip/contact checks and 450 event-free MP observer selectors pass offline. No models or texture pixels change. Project Zomboid was not launched.

See [knife controls/source contract](KNIFE_HEAT_ACTION.md), [interface sounds](INTERFACE_AUDIO.md) and [validation](VALIDATION_0.98.0.md).
