# Offline multiplayer regression checks

The fixture embeds the production registry/style, protocol, server, client and
reaction modules. It models independent client/server inventories and delayed
native delivery; it never starts Project Zomboid or a dedicated server.

1. Run `python tools/combat-tests/build_mp_tests.py` from the repository root.
2. Compile `LuaRunner.java` and `MPObserverProbe.java` with a Java 17+ JDK.
   They use reflection and require no game classes at compile time.
3. Obtain `stdlib.lua` from your installed Project Zomboid JAR and place it in
   this directory. Do not commit the game's library or JAR.
4. From this directory, run (Windows example, replace the install path):

       java -cp ".;F:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar" LuaRunner mp-tests.lua

5. `python validate_mp_nodes.py` additionally runs the native animation-node
   parser/selector against both cycles of all 150 observer nodes. Its `game`
   path defaults to the same local F: installation; adjust it if needed.

The full local regression harness contains additional single-player, input,
taunt, voice, sound and selector suites. Generated fixtures, compiled classes,
engine-inspection outputs and game-supplied libraries are excluded from Git.

For the locked style entry fixture, run `python tools/combat-tests/build_style_entry_tests.py` from the root, then `LuaRunner style-entry-tests.lua` with the same classpath. It checks movement and native attack locks, normal vulnerability, full clip completion, hit interruption, missing clips, pause handling, queue rejection and world-exit cleanup.

## API 2 and addon starter

Run `python tools/combat-tests/build_extension_api_tests.py` from the root, then run `LuaRunner extension-api-tests.lua` and `LuaRunner addon-starter-tests.lua` separately from this directory. These embed actual production code and the shipped starter. They verify custom action routing, locks, pause/hit/save cleanup, context-safe completion, key registration and atomic catalog batches.

`python tools/combat-tests/test_style_observer_builder.py` activates the starter in a temporary workspace folder, builds both observer cycles, checks deterministic/non-destructive output, and (when the installed game and compiled probes exist) uses native parsing and Kahlua compilation. No game/server is launched. MPObserverProbe accepts optional prefix/count arguments for addon checks; its default still validates each 75-node core cycle.

Aura source checks: `python tools/combat-tests/validate_extreme_assets.py --source-dir "path/to/extracted/Lost Judgment DDS files"` verifies original pixels and provenance. Compile NativeAuraTextureProbe.java, then run it with the mod texture directory on the PZ JAR/native-library classpath to check all 66 PNG decodes through B42 ImageData. These are standalone CPU/native probes, not a game launch.

Activation SFX: build_heat_audio_tests.py embeds the shipped Feedback.lua into heat-audio-tests.lua. Run through LuaRunner in a separate JVM. Checks cover original layer delay, runtime crossfade/mix, successful tails, interruption, pause, invalid handles, independent swing jobs and owner-only playback without invoking character voices.
