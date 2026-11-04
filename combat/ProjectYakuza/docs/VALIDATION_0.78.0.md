# Validation: Project Yakuza 0.78.0

Project Zomboid was not launched. This is a selector fallback, with no animation-file edits or new graphical/audio assets. Actual visual appearance still requires the user's in-game check after restarting.

The native B42 animation selector probe checks 30 affected selectors in the idle, movement, run, sprint, aim and aim-strafe states. With the complete original conditions satisfied, each override is rejected when its new gate is unset or false. A positive control explicitly enables that gate and reproduces the old selection, establishing that the test exercises the real selector. Disabled selectors also reject remote-observer state. Both gate names have no producer in production Lua, so native weapon selection and ordinary walking remain available by default on owners and observers.

The unarmed run's healthy walking blend references the existing Bob_Walk clip. The complete custom motion files and all melee/stomp/action selector bytes match the 0.77.0 release, including custom attacks and event-free observers. Native MP observer validation and focused Kahlua weapon, MP, framework and repair checks pass. All production Lua compiles, and the source-comment policy and lexical-preservation checks pass.

The converted weapon/walk source assets and their provenance remain retained. Updated selector hashes describe their dormant gated state. Historical offline geometry/clearance checks are not evidence that the live clipped pose was fixed; this update disables it instead. Rebuilding the current weapon/travel assets reapplies the fallback policy.

Local installation backs up only changed existing files and verifies the complete installed file set. Publication uses a fresh version tag and an install ZIP whose bytes match source and installation.
