# Validation: 0.58.0

PZ was not launched and no audio was played. Offline validation passes 72 steps, 23 Kahlua fixtures and 7,494 assertions. All 53 production Lua modules compile; 611 source files contain zero comments, and all six lexical preservation checks pass. Live listening, spatial balance and multiplayer latency remain in-game verification items.

## Sound checks

The dedicated production-code sound fixture passes 1,269 checks covering shuffle exhaustion across twenty bags per built-in pool, no adjacent repeats, actual Feedback playback, parent volume identity, gain/mute behavior, native fallback, cached discovery, player/style isolation, zero handles, remote-origin suppression, distinct heavy/charged accents and once-per-attack multihit accents. Signature first-finisher audio is retained.

The native probe parses seven pools and 31 existing clips, verifies each original parent sound and file, and successfully executes getRandomClip/getFile through PZ's actual LuaManager.Exposer and Kahlua without launching the game. This caught inaccessible Java instance fields during development; production uses public methods only. Reflection confirms the pooled world-emitter playClip/setVolume signatures. The existing native parser also accepts all 18 combat sound definitions and 51 source clip references.

MP fixtures verify exact selected clip/gain relay, rejection of unrelated music cues, invalid indices/gains, twelve-per-second actor sound throttling, duplicate suppression and owner-echo rejection. Existing weapon MP, animation/physics ownership, damage, session, controls, heat, charge, barrage, counter, taunt, visuals, UI, music, CVF and style-isolation fixtures remain green. There is no new tick or render callback for shuffle playback.

## Asset and installation integrity

All 1083 existing non-Lua media/native-definition files match the published 0.57.0 ZIP byte-for-byte, including every audio recording, texture, animation and native XML/script definition. No assets are created, edited, upscaled or synthesized. No separate voice-pack files are touched.

Before installation, compare the entire installed 0.57.0 tree against its published ZIP. Back up only replaced existing files, then verify source/install/0.58.0 ZIP equality. Publish a unique v0.58.0 through Publish-CombatRelease.ps1 and compare the GitHub asset digest. Extraction, native-inspection, previews, backups and credentials remain outside Git and the payload. Restart matching server/client installations before live testing.
