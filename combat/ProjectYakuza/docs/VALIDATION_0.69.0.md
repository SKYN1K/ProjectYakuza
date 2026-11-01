# Validation: 0.69.0

Project Zomboid was not launched. The existing CVF fixture passes 63 checks and the mod-sound settings fixture passes 94. All 58 production Lua files compile. Source-comment and six lexical-preservation checks pass before installation. A focused Kahlua playback check verifies actual taunt gain 2.25 times 0.85 = 1.9125, unaffected non-taunt gain 2.25, correct composition with the Voices slider and zero-cue muting. This uses the existing supplied CVF playback implementation without editing it.

All non-Lua/native assets match v0.68.0, and the DoD style change is confined to its taunt cue gain. Documentation links and consistent versions are checked. No graphical, audio, animation or model assets and no separate voice-pack files are modified. Live listening remains untested.

Verify the prior v0.68.0 installation against its ZIP, back up only replaced existing files and the superseded validation, install locally, then compare source/install/ZIP bytes. Publish unique v0.69.0 through Publish-CombatRelease.ps1 and verify the uploaded archive digest. Previous validation remains in Git/release history.
