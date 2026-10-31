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
   parser/selector against both cycles of all 304 observer nodes. Its `game`
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


0.37.0: native PunchTrackProbe additionally exports world XYZ for the eight projection checks. Limb tests have 401 assertions covering compensated limb-height depth, lowered centres, mixed glow/alpha scoping, synchronous start before action publication and missing-track retry/fallback. Charge/UI has 181 assertions including marker-gated charge recovery and stance retention; taunt has 190, including absence of an additive brightness pulse. validate_charge_limb_tracks.py checks .14 entry blends. No game/GPU test is implied.

## 0.44.0 style-owned weapons

Build with build_weapon_tests.py and build_weapon_mp_tests.py, then run LuaRunner weapon-tests.lua weapon-mp-tests.lua. WeaponAssetProbe.java uses the native B42 importer/selector without launching PZ. validate_weapon_assets.py verifies supplied GMT/output/rig provenance, BEP contacts and actual B42 item IDs. The weapon docs distinguish these offline checks from live grip/MP appearance.

The 0.45.0 weapon fixtures also exercise short/sweeping blades, real supplementary reach and native maximum damage, prevention of spreading a primary knife close kill, actual SP extra-hit queue ownership, high-damage sword MP extras, source blade guard and remote profile resolution. Native weapon validation now covers weapon-assets.json plus blade-assets.json (26 source clips, 32 owner nodes, 276 observers and 48 explicit item IDs).

## Source maintenance

Run check_source_comments.py and test_source_comments.py for comment-free source/templates/tests and lexical preservation. Fixtures use fixture_markers.py data markers. The actual-module weapon/MP and aura fixtures count bridge calls and array scans, check registration invalidation, and retain all behavioural checks. See the shipped PERFORMANCE.md for measured scope; no FPS benchmark is implied.

## 0.47.0 equipment and props

Build/run style-item-tests.lua with build_style_item_tests.py and LuaRunner. It embeds the real policy, inventory wrappers, menu and Runtime for manual disable/delete, supported weapon transitions, client authority and neutral-heavy routing. The weapon MP fixture now also loads the policy to check authoritative cleanup and real-weapon preservation. The selector fixture covers top removal; charge/UI checks neutral tap-release alongside hold/double paths.

Compile StyleItemProbe.java and PropAttachmentProbe.java against the local B42 JARs. Run validate_prop_attachments.py with the previous 0.46.0 release ZIP in dist. It verifies supplied/native/output hashes, unchanged body/finger bytes, native FK hand-to-prop offsets across every frame, a failing prior detached-prop regression, and source-heavy contact timing. WeaponAssetProbe covers the extra heavy clip and isolated selector; ChargeAssetProbe covers its single native contact. These tools never launch PZ.

## 0.48.0 original blood

Run build_blood_tests.py, then LuaRunner blood-tests.lua from this directory. The fixture embeds WorldEffects/BloodEffects/HitEffects and verifies real confirmed-hit routing, per-victim deduplication, every source frame, pause/expiry, detached world coordinates in eight facings, grounded height, observer presentation, style opt-in, budgets, idle hooks, pooled disposal and render-failure blend restoration. Run validate_blood_assets.py for exact DDS crop/alpha/hash checks. Compile BloodAssetProbe.java and run it against the texture directory using B42 runtime/JARs to validate native ImageData decoding without launching the game.

## 0.49.0 Extreme attack variations

Build/run extreme-attack-tests.lua with build_extreme_attack_tests.py and LuaRunner. It embeds actual Heat, Runtime and weapon/style modules for active mode, original fallbacks, four branch pairs, marker-gated recovery, full playback without input, depletion, matching follow-ups, expiry, damage and weapon/style isolation. The weapon MP fixture covers mode gating, repeat/depleted swings, pairing leases and final cost depletion.

Compile ExtremeAttackProbe.java and run validate_extreme_attacks.py. It checks original fighter command strings, GMT/BEP/rig/output hashes, all finite native channels, original single contacts, source-only pair poses/root gaps, prop attachments through B42 FK, and native owner selection without style/weapon leaks. If the local converter intermediates exist it also compares every retained non-prop numeric sample against the original full retarget. No game startup or graphics synthesis.

## 0.50.0 style-owned encounter intros

Build/run encounter-tests.lua via build_encounter_tests.py and LuaRunner. It embeds current Registry, DoD config, StyleUI, detector, font metrics and real renderer. Checks include inclusive 0/10/11/39/40+ boundaries, circular radius/floor/death exclusion, a 64-entry tick budget and capped counts, throttled native threat reads, pause/rearm, no duplicate intros, mouse-transparent panels, viewport placement, custom providers/sounds, cleanup and no cross-style fallback. validate_encounter_assets.py reconstructs the exact supplied Edo SZ rasterization and original Y6 flare pixels. EncounterAssetProbe verifies native ImageData decode and native Stats/IsoCell API contracts without launching PZ.

## 0.51.0 entry, counter, audio and intro regression

Build/run repair-tests.lua using build_repair_tests.py and LuaRunner for actual heavy-input Tiger Drop timing, cooldown, MP age and independent music gain. Style-entry fixture covers deferred equipment readiness and interruption. build_sound_mod_options_tests.py embeds the installed native ModOptions implementation for persistence and group gain checks.

Run validate_repair_assets.py with the previous 0.50.0 ZIP in dist and supplied DDS sources available. It verifies exact impact pixels/hashes, byte-identical non-prop entry blocks and 102 native hand-prop pairs. Recompile EncounterAssetProbe.java to decode all four intro textures and check native detection APIs without starting PZ.

## 0.52.0 running and unlocked weapon holds

Use Blender in background mode with build_locomotion_assets.py to retarget the supplied local sources and combine their upper body with native walking legs. build_locomotion_nodes_052.py installs the 10 scoped selectors. Run validate_locomotion_assets.py for source/native sample, loop, hash and hand-prop checks; it invokes Blender only for math, then native Java probes without starting PZ. Compile LocomotionAssetProbe.java first. It also rejects missing deferred travel and tests native selection/fallback conditions. Source/extraction/intermediate files remain local and are not bundled in Git.

## 0.53.0 feedback, carry and encounter repair

CombatSoundProbe.java natively parses all combat sound definitions and resolves original source paths. Punch tests cover rotated palm coordinates, removed screen inset, render-time phase and heavy whoosh timing. Blood/impact tests include detached ownership, guard/no-blood, subtle shock rings and error cleanup. Encounter tests exercise near-grid counting, distant-zombie exclusion, three-tick ordinary counts and one enlarged nonrepeating explosion.

repair_carry_053.py combines the existing source arm pose with native torso/head/legs and idle grips. The locomotion builder applies that repair; the existing source/native/FK probes verify every output. The validator requires native hierarchy and body samples to remain intact. These tools never start PZ.

## 0.54.0 style-owned intro triggers

The encounter fixture checks larger bounded text, long-title fitting, per-style player visibility/seen-by-player, range/occlusion/death/facing rejection, bounded player-list cursors and cached targets, native player-hit opt-in, no-count intros, minimum rejection/retry, detector registration/throttling/removal/quarantine and invalid config rejection. EncounterAssetProbe reflects the native online/local player and LOS/facing APIs without starting PZ. Existing per-style renderer and cleanup tests remain.

## 0.55.0 boost barrages and running cadence

build_boost_assets.py retargets the six approved original bct_ath clips through Blender. validate_extreme_attacks.py verifies every source frame, source BEP contacts, native hand-prop offsets and six isolated native owners. ExtremeAttackProbe.java must be compiled first. The Kahlua boost fixture checks mode/depletion, native lights, source-time barrage contacts, pause/skip/cleanup and actual SP damage. Weapon MP regressions cover ordered/timed contacts, authoritative damage, target/path limits, duplicates and lease depletion. validate_mp_nodes.py now imports 304 event-free observers.

adjust_run_cadence.py slows run playback from 1.28 to 1.0 and scales only the existing Translation_Data track by 1.28. The locomotion builder applies it after the carry repair. The source/native validator checks unchanged body poses and equal travel-per-second products. All checks run without starting PZ.

## 0.56.0 multiplayer lifecycle and relaxed holds

MP fixtures cover split melee/action restart counters, fresh session counters on recycled player IDs, old-session state/damage rejection, scoped replay/deferred reset, actor replacement, stale heat/limb-effect cleanup, unavailable styles and old protection release. Weapon MP fixtures verify profile-specific hit-response/juggling lookup for native and supplemental hits. Native locomotion validation imports the six existing relaxed hold clips, verifies their hashes, and rejects frozen source-arm composites in relaxed selectors. No asset files are created or edited by this update.
