# Project Yakuza Emotes 0.2.3

- Fixed custom emotes silently refusing to play near zombies. PZ’s isCurrentlyBusy flag includes one very close zombie or three chasing zombies, which blocked both this addon and CVF while vanilla emotes remained available.
- Playback now checks actual native actions, reading, Lua queues and active Project Yakuza combat actions. Existing movement, aiming, vehicle, sleep, death, equipment and replay guards remain in place.
- The addon applies the same correction to optional CVF emotes after providers load. CVF framework and separate voice-pack files remain unchanged; vanilla emote dispatch remains delegated.
- All animation, selector, model, texture and audio bytes remain unchanged. Native B42 reproduction, Kahlua playback/provider-order checks, compilation, isolation and zero-comment gates pass offline. Installed locally without launching Project Zomboid; live gameplay and multiplayer remain untested.
