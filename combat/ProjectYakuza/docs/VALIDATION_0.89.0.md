# Project Yakuza 0.89.0 validation

Offline only. Project Zomboid was not launched.

Native B42 IsoGameCharacter weapon-hit bytecode fires OnPlayerGetDamage with the damaged character as its first argument, followed by WEAPONHIT and damage. That victim can be an IsoZombie. The previous callback incorrectly assumed every first argument exposed IsoPlayer:isLocalPlayer(). The hotfix checks instanceof(character,"IsoPlayer") before any player-only call in marking, polling and eligibility.

The focused low-health suite passes 46 checks, including 512 registered zombie-damage event deliveries with a member-access trap, direct zombie/invalid inputs, local-player immediate damage refresh, remote-player exclusion and all prior threshold, HUD, audio, pause, recovery and cleanup cases. All 29 Kahlua suites pass, all 73 production Lua files compile, and the native low-health API/sound check passes. The source comment scan reports zero comments across 920 source files.

All 1393 non-Lua media files, including sound registrations, animations and textures, are byte-identical to v0.88.0. No voice-pack changes are made. Local installation verifies the complete v0.88.0 baseline, backs up only changed files and checks all installed bytes. The installed files, source and fresh v0.89.0 release ZIP are compared exactly before completion. Restart to load the fixed Lua callback.
