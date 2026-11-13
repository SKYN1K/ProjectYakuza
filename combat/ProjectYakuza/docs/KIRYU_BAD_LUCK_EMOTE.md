# Kiryu: Bad Luck

Empty both hands, stand still without aiming, then choose Emote wheel → Project Yakuza → Kiryu: Bad Luck. No combat style is required. Majima's bat point and Lau Ka Long's spear strike remain in the same category with their existing weapon requirements.

The motion comes from the supplied Kiwami 1 puppy-rescue cutscene, main06_s01. The CMN16 actor GUID identifies c_at_kiryu_U1_S185 and resolves cut 006 to main06_006_9.gmt. The original scene's English subtitles identify the rough-day and bad-luck dialogue. This emote preserves source frames 90..444, including Kiryu's neck/head gesture and closing lean: 355 samples at the original 30 fps, lasting 11.8 seconds. It includes a short lead-in and finishes at the original end of his dialogue shot.

PZ's native Human skeleton receives the original head, neck and body rotations. Constant yaw normalization faces the gesture forward; native proportions fit the arm directions, native idle supplies the limited finger channels, and the native skinned sole plane keeps the feet grounded. The root stays in place. There is no thrown stone, other scene actor, voice playback, damage, Heat gain/cost, equipment replacement or custom network packet.

The gesture uses PZ's native cancellable emote state, replicated emote parameters and end event. Moving, aiming, busy, sleeping, seated, driving, dead, remote, already-emoting, queued-action and active-combat states are rejected. Either occupied hand prevents starting it. Native and Custom Voice Framework entries remain available in either provider load order; the separate framework and voice pack are unchanged. Multiplayer peers need matching mod files.

Source archive/resource hashes, dialogue timing, exact source frames and native conversion inputs are recorded in kiryu-bad-luck-emote-assets.json. Offline native importer, geometry and menu checks pass. Project Zomboid was not launched, so visual blending and live multiplayer playback remain untested.
