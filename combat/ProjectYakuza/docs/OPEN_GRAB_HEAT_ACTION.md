# Open-space grab Heat Action

The current move uses the supplied Yakuza 5 h11240_tomoenage front-grab sacrifice throw. Its CMN binds one actor and one victim, with 201 samples at 30 fps and original victim impact frame 78. No wall, prop or second opponent is required. Original clips, sound resources and contact timing are recorded in open-grab-heat-assets.json and open-grab-heat-scene.json.

The authored victim starts behind the scene's local forward axis. Placement derives the world scene axis from that original actor/victim separation and the current held pair, preserving actor position and the held side. The wall variant keeps its separate wall placement. Client and server share selection, ownership/range/path validation and placement. Twelve source/observer strike masks preserve grab parent continuity before the Heat Action handoff.

Source character motion, complete sample order, authored speed, damage frame and resource timing are unchanged. Native source import and geometry checks do not establish final live blended appearance; test the handoff and complete sequence in PZ and a real multiplayer session.
