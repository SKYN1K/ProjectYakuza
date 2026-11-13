# Lau Ka Long spear-ground emote

Hold a usable crafted spear, stand still without aiming, and open Emote wheel → Project Yakuza → Lau Ka Long: Spear Ground Strike. Majima: Bat Point remains in the same category and still requires a bat. Both gestures work without equipping a combat style and coexist with Custom Voice Framework.

The supplied Kiwami 1 cutscene is main12_s04. Its original CMN16 tree binds c_am_rau_U1_S185 and a12_03a_spear_rhau_1 to the independent character and spear motions. Cut 007 resolves to main12_007_9.gmt and main12_007_13.gmt. The emote retains original frames 112..190 at 30 fps: 79 samples over 2.6 seconds, including the floor strike and following spear flourish. Original frame 121 supplies the calibrated floor contact. No battle attack or invented motion samples replace the cutscene data.

The native character retains source arm directions at PZ proportions. Root Y follows the native sole plane. The original independent spear rotation directs the wrist and weapon, and the original sliding shaft grip is mapped to PZ's shorter spear. A bounded additional shaft slide prevents the reference spear from penetrating the floor while keeping its grip in the native palm. No character hand teleport, item substitution, new spear model or texture is introduced.

Supported native item IDs are Base.SpearCrafted, Base.SpearCrude, Base.SpearHandFork, Base.SpearHuntingKnife, Base.SpearKnife, Base.SpearScissors, Base.SpearScrewdriver and Base.SpearStoneLong. These models share the calibrated wooden-shaft butt position and provide enough shaft for the source grip. Other spear models are rejected rather than using an unverified attachment. The eight IDs are generated from the installed native item/model scripts and validated against their unchanged model vertices.

Playback uses PZ's native emote state, end event and replicated emote parameters. It adds no custom network packets, damage, Heat gain/cost, protection, voice or sound playback. Both peers need matching mod files. Native cancellation remains available. Moving, aiming, busy, sleeping, seated, driving, dead, remote, broken/hidden weapon and unrelated off-hand states are rejected.

See lau-spear-emote-assets.json for archive/resource hashes, exact source frames, native profiles, grip and floor calibration. Offline native rendering/import data is verified, but the game has not been launched for a visual or live multiplayer test.
