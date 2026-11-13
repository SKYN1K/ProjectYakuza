# Kiryu: Step Up

Empty both hands, stand still without aiming, and choose Emote wheel → Project Yakuza Emotes → Kiryu: Step Up. No combat style, combat mod or Custom Voice Framework is required.

This is Kiryu's original Kiwami 1 final-chapter challenge to the large crowd while protecting Haruka, from main16_s02 cut 012. The quoted English-dub line identifies that scene; the supplied Kiwami subtitle track phrases the closing challenge as “If you want to die, come at me!” The CMN16 Kiryu character/motion GUID resolves to main16_012_1.gmt. The emote contains the entire original shot, frames 0..219: 220 samples at 30 fps over 7.3 seconds, including the lead-in and ending.

The native Human skeleton retains original head, neck and body rotations. Constant yaw faces the gesture forward, native limb proportions fit the arm directions, native idle supplies PZ's limited finger channels, and the native skinned sole plane keeps the feet grounded. Root XZ remains in place. There is no crowd, Haruka actor, voice playback, weapon substitution, damage, Heat or protection added by the emote.

Playback uses the native cancellable emote state, replicated parameters and end event. Either occupied hand, movement, aiming, busy/queued actions and unsafe player states prevent starting it. Active Project Yakuza combat actions also block it when the optional combat mod is loaded. Existing vanilla and CVF gestures remain available. Multiplayer peers need matching addon files.

See kiryu-step-up-emote-assets.json for archive, scene, actor, resource, subtitle, timeline, exact sample and native-conversion provenance. Offline original-source, native import, geometry and menu checks pass. Project Zomboid was not launched; visual blending and live multiplayer remain untested.
