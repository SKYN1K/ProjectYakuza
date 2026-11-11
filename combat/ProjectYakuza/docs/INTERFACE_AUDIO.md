# Mod interface audio

Version 0.98.0 uses the supplied Kiwami dragon_change waveform when selecting or explicitly reselecting a combat style. Kiwami's dragon_change, sutegoro_change, rush_change and crusher_change cues reference this same original waveform, stream 60 of bank 466d.acb. It is decoded directly without synthesis, trimming, mixing, resampling or upscaling. Source-engine control, pitch and DSP graphs are not recreated.

Project Yakuza's style selector and settings panel use Yakuza 6 menu_default.acb: dec02 opens the UI, cursor01 marks changed highlights, dec01 confirms selections/saves, cancel01 handles cancel/back, and tgl_dec opens combo choices. The supplied PCM retains original channels, rate and sample count. Native volume levels are set in ProjectYakuza_Interface.txt; the interface events appear in the game's advanced sound options under ProjectYakuza_Interface.

UIAudio uses native playUISound for local 2D one-shot playback. It emits no network/world sound packets. Cursor cues are driven by actual selection changes and have a 65 ms debounce; duplicate same-style events within 150 ms are suppressed. Remote/dead players and unknown cues are ignored. Save/world/menu-entry cleanup resets transient audio state silently.

The mod uses its own combo subclass and per-button sound names. The native combo classes and global PZ menu sound definitions remain unchanged. Save/Cancel callbacks avoid playing an additional close cue after the button's own native activation sound. Escape uses the same Y6 cancel cue; world/save/death cleanup is silent.

interface-audio.json records the exact original archive entry, packed/plain hashes, cue IDs, waveform aliases/stream indices, PCM format, output hashes and native volume for all six assets. build_interface_audio.py reproduces them with --write; default mode compares fresh source decodes and declarations. InterfaceAudioProbe checks all six native definitions, local 2D/one-shot flags, file paths and the B42 UI playback API. Selector tests exercise interaction routing and prevent per-frame or callback duplication.
