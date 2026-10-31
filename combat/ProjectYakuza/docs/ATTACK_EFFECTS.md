# Source-tracked punch effects (0.53.0)

Dragon of Dojima's first light uses existing white-blue glints, small flames and sparks along its imported PZ forearm/hand path. No new artwork or audio is created. The source track comes from B42's importer for the converted clip, not the original Yakuza skeleton's proportions.

The move opts in with attackEffects={track="dd_light_01",from=2/30,to=14/30,swingFrame=3}. Track rows are model-space forearm, wrist and knuckle XYZ at 30fps. The core is 35% from wrist toward knuckle. The prior elbow-to-wrist inset and fixed screen-height drop are removed. Native clip phase is refreshed once per actor draw, with a cached track slot; source phase controls the whoosh as well. Model-to-world projection uses continuous rendered body angle and native scaling. All layers use normal alpha and restore the previous blend mode.

The source path is interpolated; it is not the final pose after native blending, IK or character proportions. PZ suppresses torso twist while attacking, so no extra blanket shoulder rotation is applied. Exact rigid bone attachment requires a suitable live provider. No Java bridge or launcher was added.

An optional addon can register ProjectYakuza.AttackEffects.registerLimbProvider("live",fn). It receives player, animationName and sourceTime and returns six finite absolute world coordinates: forearm XYZ and desired hand centre XYZ. A move may choose another attackEffects.limbProvider ID. The provider is queried once per actor draw; invalid/errors fall back with a one-second retry throttle. removeLimbProvider(id,fn) unregisters it. Live coordinates bypass sampled yaw and legacy insets.

Each active actor uses 18 detached pooled world sprites, capped at eight actors. No zombie scan or additional packet is needed. Pause, cancellation, clip changes, style changes, death and world exit clean up the scoped hooks/instances. Charge effects retain their separate supplied limb paths. See punch-effect-assets.json and feedback-polish-assets.json for provenance. GPU appearance and live alignment need checking after restarting.
