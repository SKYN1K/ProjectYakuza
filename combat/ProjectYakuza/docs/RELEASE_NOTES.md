# Project Yakuza 0.132.0

- Added the user-supplied Technical Difficulties to Dragon of Dojima's combat shuffle playlist as its twentieth track, with a readable Advanced Audio label.
- Converted the supplied FLAC directly to MP3 at 160 kbps CBR, 44.1 kHz stereo using libmp3lame's highest compression-quality setting. This matches the existing playlist target bitrate and dominant sample rate. The existing entries are Vorbis; MP3 is used here as requested. No trimming, gain change or normalization was applied. Source metadata and embedded artwork are omitted.
- Complete FLAC and MP3 decoding retains all 7,414,272 samples per channel, or 168.124 seconds. The MP3 occupies 3,363,526 bytes. Provenance and codec checks are recorded in technical-difficulties-audio.json; the original FLAC is excluded from the runtime package.
- Offline checks pass the actual twenty-entry playlist registration/new-track selection/no-repeat test, 2,773 existing combat/aura/music lifecycle assertions, all twenty native music sound definitions and audio paths, and compilation of all 92 production Lua modules. Comment, runtime asset-reference and privacy checks precede publication. PZ and an audio device were not launched.

The optional phone menu remains compatible through its existing combat dependency. Standalone emotes and the separate voice pack are unchanged.
