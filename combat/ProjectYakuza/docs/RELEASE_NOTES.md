# Project Yakuza 0.58.0

- Added DoD sound variety using seven existing Yakuza 6 pools: swings, scripted punch/kick impacts, Heat impacts, guard impacts and heavy strikes. Scripted choices use shuffle bags, exhausting each pool before reuse and avoiding immediate repeats across bag boundaries.
- Normal heavies, charged hits, Tiger Drop and barrage endings now use the existing three-clip heavy-impact pool. Standard first finishers retain their signature sound. Native weapon collision audio remains unchanged.
- Selected clips retain their original GameSound parent, Sounds slider and Advanced volume settings. No extra volume entries, audio files, voice cues, pitch changes or generated assets are added.
- Added validated, deduplicated multiplayer sound relays for the selected clip, with style/weapon checks and a bounded rate. Listeners use their own volume settings; muting the attacker's client does not mute everyone else.
- Added an opt-in sound-pool API for addon styles, native Java-to-Lua API checks, shuffle/feedback/MP regression coverage and authoring documentation. Clip discovery is bounded and cached; there is no new per-frame sound polling.

All existing animation, texture and audio assets are unchanged. PZ stayed closed; live listening and network latency still need an in-game check. Restart matching 0.58.0 server/client installs before testing. See VALIDATION_0.58.0.md and SOUND_VARIETY.md.
