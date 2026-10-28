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
   parser/selector against both cycles of all 188 observer nodes. Its `game`
   path defaults to the same local F: installation; adjust it if needed.

The full local regression harness contains additional single-player, input,
taunt, voice, sound and selector suites. Generated fixtures, compiled classes,
engine-inspection outputs and game-supplied libraries are excluded from Git.

For the locked style entry fixture, run `python tools/combat-tests/build_style_entry_tests.py` from the root, then `LuaRunner style-entry-tests.lua` with the same classpath. It checks movement and native attack locks, normal vulnerability, full clip completion, hit interruption, missing clips, pause handling, queue rejection and world-exit cleanup.

## API 2 and addon starter

Run `python tools/combat-tests/build_extension_api_tests.py` from the root, then run `LuaRunner extension-api-tests.lua` and `LuaRunner addon-starter-tests.lua` separately from this directory. These embed actual production code and the shipped starter. They verify custom action routing, locks, pause/hit/save cleanup, context-safe completion, key registration and atomic catalog batches.

`python tools/combat-tests/test_style_observer_builder.py` activates the starter in a temporary workspace folder, builds both observer cycles, checks deterministic/non-destructive output, and (when the installed game and compiled probes exist) uses native parsing and Kahlua compilation. No game/server is launched. MPObserverProbe accepts optional prefix/count arguments for addon checks; its default still validates each 94-node core cycle.

Aura source checks: `python tools/combat-tests/validate_extreme_assets.py --source-dir "path/to/extracted/Lost Judgment DDS files"` verifies original pixels and provenance. Compile NativeAuraTextureProbe.java, then run it with the mod texture directory on the PZ JAR/native-library classpath to check all 66 PNG decodes through B42 ImageData. These are standalone CPU/native probes, not a game launch.

Activation SFX: build_heat_audio_tests.py embeds the shipped Feedback.lua into heat-audio-tests.lua. Run through LuaRunner in a separate JVM. Checks cover original layer delay, runtime crossfade/mix, successful tails, interruption, pause, invalid handles, independent swing jobs and owner-only playback without invoking character voices.

One-strike quicksteps: build_quickstep_once_tests.py embeds production modules into quickstep-once-tests.lua. Run via LuaRunner separately to test all four directions, rapid inputs, ticket replay/retry, native attack gating, key release and asynchronous first swings.

## API 3 charged heavy and style UI

Run `python tools/combat-tests/build_charged_ui_tests.py` from the repository root,
then `LuaRunner charged-ui-tests.lua` from this directory. Its 150 checks embed
production Registry/Combo/Bindings/Runtime/ChargedHeavy/StyleUI/HeatOutline/
WorldEffects/ChargeEffects/HitEffects. They cover tap/double release, Tiger Drop
priority, lock/anchor/restoration, pause, interruption, queue rejection, exactly
one ticket, native rejection/retry, asynchronous callbacks, expiry, addon UI
lifecycle/error fallback/additive restoration, native packed-color restoration,
all-facing world particles and bounded cleanup. It imports no generated media.

Compile `OutlineProbe.java` and `ChargeAssetProbe.java` with your JDK. Using the
installed B42 runtime and JARs, run `OutlineProbe`, then
`ChargeAssetProbe ../../combat/ProjectYakuza/42/media`. These use reflection to
check native outline flags/color, the original-size decoded PNG and native XML
parsing/collision counts without launching PZ. Source GMT/PNG hashes and conversion
operations are recorded in `combat/ProjectYakuza/docs/charged-heavy-assets.json`.
GPU appearance/live MP still require a separate authorized gameplay test.

For 0.32.0 original assets, run `python tools/combat-tests/validate_finisher_reference_assets.py --hud-dds <supplied btl_hact.dds>` from the repository root. It validates all eight split-motion hashes/ranges and identical handover poses across 105 native channels per branch, all 64 original smoke crops, and the unchanged original HUD atlas/crop bounds. NativeAuraTextureProbe now checks all 130 aura PNGs; ChargeAssetProbe checks ten hold/release nodes and exactly one collision per strike.

Run `python tools/combat-tests/validate_effect_loader_paths.py` from the root after any animated texture export. It checks native IsoAnim naming recipes and resolves all 229 aura/burst filenames. This prevents exported PNGs passing decoder tests while remaining invisible through the native loader. No game JAR is changed or game launched.

For 0.33.0 run validate_charge_source_timing.py against supplied local BEPs: it independently verifies type-206 pause frames, first hit windows, native looping holds, source playback, alpha-bearing flame pixels and .55 frame speed. validate_finisher_reference_assets.py checks all twelve wind-up/hold/release outputs and their identical endpoint poses. ChargeAssetProbe now parses fourteen nodes with no hold collisions and one collision per release.


## Source-tracked first punch (0.34.0)

Compile PunchTrackProbe.java against the installed B42 JARs (`javac -cp "F:/SteamLibrary/steamapps/common/ProjectZomboid/*" tools/combat-tests/PunchTrackProbe.java`). Run build_punch_effects_tests.py from the root; it invokes the offline native importer/FK/projection probe, verifies the shipped numeric path and unchanged media hashes, then embeds current AttackTracks/AttackEffects/Feedback production code. Run LuaRunner punch-effects-tests.lua from this directory in its own JVM. Its 259 assertions cover source-clock visual/audio timing, cached native lookup, eight facings, sprite/lifecycle/MP budgets, cancellation, pause and failure restoration. The native probe writes only ignored JSON code-position data, not media, and does not launch PZ.


For 0.35.0, compile/run DetachedEffectProbe.java with B42's runtime/JARs to reproduce the native shared sprite-offset overwrite and validate detached pool instances without GPU/game startup. The punch fixture now embeds WorldEffects and has 342 assertions, including eighteen instances, several visible particles and independent per-scale centring. The taunt fixture has 189 assertions and embeds HeatOutline, checking immediate activation outline, a one-second four-particle cloud, pause/retrigger prevention, remote cleanup and the replacement eight-particle normal-alpha completion flare.


For 0.36.0 compile ChargeTrackProbe.java against the installed B42 JARs, then run validate_charge_limb_tracks.py. It validates nine existing clips/87 source samples and last-frame handoff markers against ChargeTracks.lua, writing only ignored numeric JSON. The charge/UI fixture has 176 assertions, MP 104, taunt 190 and limb-presentation 528. Source .x/image/audio files remain unchanged; native owner/observer metadata and source-pose checks still apply.
