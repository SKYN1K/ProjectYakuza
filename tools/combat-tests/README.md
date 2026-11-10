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

For 0.93.0, that quickstep suite also checks aim changes after visible playback, fading/disappearing terminal tracks, exactly-once native exit and bounded cleanup. build_heat_rush_tests.py adds nearest-placeable crowd selection beyond sixteen weapon candidates, ground searches beyond 96 moving objects, forced preview refresh and preservation of feasible combo victims after blocked or ineligible contacts. Both tests first reproduced failures against the previous production modules. Heat-speed, heat-shove, MP, weapon, weapon-MP, grab, charged-UI, directional and Extreme-attack suites cover surrounding behavior without starting PZ.

For 0.93.1, heat-rush tests invoke the real OnPlayerUpdate callbacks for startup, native-track confirmation, contacts and completion. They reproduce the previous missing-dispatch bug, cover ground/grab definitions through the same update loop, and verify no cost for missing playback, one payment on visible playback, pause-safe startup, resource loss before playback and the final Extreme fuel stock. Presentation, damage, extension API and addon starter suites also run with current production code. Manually calling a timed action's start method alone does not establish that Runtime dispatches it.

For 0.94.0, build_katana_heat_assets.py uses katana_prop_motion.py to convert the independent source sword GMT into the actor's right prop channel. Use --stage for an isolated build. validate_katana_heat_assets.py supports that same option and checks all source samples, unchanged body/victim bytes, release/catch/reversed grip, sharp-axis direction and actual native importer/FK behavior. PropAttachmentProbe accepts either one constant matrix or frame-separated matrices per prop. Its katana negative contract requires the old rigid grip to fail at source frame 44; other static grip users retain their existing contracts. No preview rendering or game launch is involved.

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

## 0.57.0 directional moves and taunt attention

Build and run directional-tests.lua through build_directional_tests.py. It embeds actual Runtime, heading selection, move damage and quickstep readiness. Compile DirectionalAttackProbe.java, then run validate_directional_assets.py for native import/selectors, all original frames and command mappings, BEP contact markers, native AI methods and hand-prop FK. MP/weapon fixtures cover completion-only taunt leases, early/replay rejection, target eligibility, blocked paths, zombie ownership, streaming retries, hard path budgets and directional damage/profile isolation. Taunt lifecycle tests retain SP completion/interruption reward checks and attention timing. All tests run offline without launching PZ.

## Sound variety

Run build_sound_variety_tests.py, then LuaRunner sound-variety-tests.lua from this directory. SoundVarietyProbe parses the unchanged sound definitions and checks native clip parent volumes, public methods through the PZ Kahlua exposer and world-emitter method signatures without playback. MP fixtures cover selected-clip relay, style/index/gain validation, throttling and duplicate/owner suppression.

## Attack endurance

Build build_exertion_tests.py and run LuaRunner exertion-tests.lua from this directory. The fixture covers committed native attacks, ground deduplication, weapon profiles, misses, rejected attempts, native modifiers, owner-only stats and cost bounds. ExertionProbe verifies the installed native fitness/trait/stat API and actual endurance removal clamp without game launch.

## Optional Heat speed

Build build_heat_speed_tests.py and run LuaRunner heat-speed-tests.lua. Checks cover 0..100 interpolation, curve validation, native swing sampling, Extreme fuel, unmodified DoD speeds, weapon overrides, cleanup and fallback/source-phase feedback. MP fixtures cover bounded frozen factors and observer relay.

## Weapon feedback and pose selectors

The blood fixture covers captured unarmed/blunt/blade particles, native-alpha world anchors in eight facings, blood timing/size, guard isolation, pool cleanup and authoritative family overrides. Heat-audio and weapon fixtures cover profile validation/inheritance, separate heavy/ground cues, native-light silence, per-swing multihit deduplication and owner-only playback. Weapon MP checks derive family/strength on the server, reject client family overrides, preserve native primary damage and relay matching primary/supplementary observer feedback. validate_weapon_assets.py also verifies weapon-pose-selectors.json and nine scoped existing-native hold/run references. WeaponAssetProbe and LocomotionAssetProbe parse the selectors through the native importer. No game launch is needed.

## MP hot-path regressions

The MP fixture compares indexed support with the original full catalogue scan, checks 1,000 warm support/kind queries without definition-array scans, and verifies official registration invalidation. It compares 288 path/obstacle/direction cases and ordered collision crossings with the prior algorithm, measures 40-to-2 tile reads, checks nearest/unknown zombie lookup limits, typed ground changes, inactive heartbeat timing/reactivation, protection-hook transitions and lifecycle cancellation during deferred retries. Full existing MP authority, session, equipment, QTE, sound and hit-feedback tests still run. These counts are not live performance benchmarks.

## Passive RMB and per-style Heat

Compile PassiveUIProbe.java with the local JDK and run it through B42's bundled Java with the client ProjectYakuza Lua directory as its argument. It reproduces native UIElement right-button consumption by nil handlers, then compiles the actual four overlay press/release bodies and verifies false return through native routing. No game/UI startup occurs. Heat-speed fixture coverage also exercises real Heat configuration gain, damage/idle loss, retention, Extreme fuel, registration invalidation, profile merging and unchanged DoD defaults. MP tests cover custom activation stock thresholds. Charged-UI tests check 1/3/8/32 stock rows, labels and RMB pass-through. Existing six-stock HUD regressions remain.

## Full-arm trail rebuild

PunchTrackProbe now exports both upper-arm positions as well as both forearm/hand/knuckle triplets from the unchanged imported PZ clip. build_punch_effects_tests.py independently verifies all shipped original rows and the new left shoulder rows, track provenance and unchanged textures/sounds. The punch fixture checks continuous whole-arm coverage across 32 facings and throughout the configured source window, world-space history under rotation/movement, teleport reset, fixed history/sprite budgets, pause/same-clock behavior, optional six/nine-coordinate providers, MP observer selection and cleanup. Existing charge and source-clock audio regressions remain in the fixture. This checks numeric geometry/lifecycle rather than live blended skeleton attachment or final GPU appearance.


## Complete attack coating coverage

Compile LimbTrailProbe.java against the local B42 classes, then run build_attack_trails.py to import all 61 active DoD attack clips and compare the shipped numeric catalogue/provenance with native FK. The --write option writes code-side numeric tracks only. No motion, texture, model or audio assets are produced. Contact windows use native collision markers, Heat Rush QTE timing and the documented counter fallback. The expanded punch fixture checks 66 contacts at eight facings, bounded irregular movement, per-contact limb selection, action-context cleanup, category deduplication, observer reconstruction and foreign-style isolation. Extreme-attack regressions exercise ending Heat after steps 5..8 before another player input.


## Eighth-input finish and in-place stun

StunRushProbe checks native weapon push/knockdown setters, native player Hit/control and PvP permission APIs, and both scoped player victim state definitions. Heat Rush regressions cover seven missed inputs, the eighth strike's final target, bounded source-swing supplemental acknowledgements, protected PvP targets and player control restoration. Extreme-attack regressions verify temporary no-knockback settings and restoration after injected native failures. Server regressions use actual input snapshots, typed target IDs, deduplicated native contacts and cancellation when PvP permission changes. No new motion, texture, audio or model is produced; native victim state definitions reference the existing converted clip. Live PvP rendering/latency remains untested.


## Katana Heat Action and shared protection

Run validate_katana_heat_assets.py for supplied archive/scene/GMT hashes, complete source-body retention, native clip import, native hand-to-prop offsets and scoped actor/victim/observer selection. KatanaHeatProbe checks the eight new native nodes and protection APIs. The paired fixture covers independent Heat Action rebinding, physical RMB, neutral combo eligibility, source-phase contacts, one-stock payment and action-only invulnerability with 500 ms targeting grace. Multiplayer tests validate the matching server lease, resource/input gates, contact timing, weapon damage and cleanup. Validate both cycles with validate_mp_nodes.py; observers remain event-free. These checks load native classes but never launch PZ.


Paired path repair checks retain raw source vectors and canonical scene rotation in provenance. paired_paths.py removes shared staging cuts and bridges their small relative residual over six frames. Native root checks require both katana and bottle victims to start at standing height. Heat Action UI regressions cover cached eligibility, 120/80 ms fades, native-size original atlas pixels, keyboard rebinding and style UI overrides. HeatPromptAssetProbe decodes the copied original flame atlas with native B42 ImageData.

## Retail rush and dynamic QTE controls

The paired fixture checks Light/Heavy/Grab twice, actual keyboard rebinding, fresh presses, invalid prompt/contact mappings, skipped cues, deferred final damage, native-phase recovery and passive circular UI. Server tests check six mapped inputs, presentation-only intermediate punches, one summed finishing kick, replay rejection and permission changes. `validate_heat_rush_assets.py` checks both retail clips, all retained body samples, original motion paths and native import/prop contracts. `validate_rush_qte_assets.py` compares the supplied ui.par DDS bytes and every decoded RGBA pixel. `HeatPromptAssetProbe` accepts the optional timing atlas as its second argument and verifies its native ImageData decode plus the textured-quad/screen-coordinate APIs. These checks never launch PZ; live presentation and latency still need gameplay testing.

## Configurable failures and original beer crate

The paired fixture covers failure thresholds/modes, wrong and held controls, configurable feedback sounds, native damage deferred until paired completion, a real recovery animation and source-clock prompt animation. MP tests exercise server-derived misses, recovery snapshot support, replay rejection and stale victim-lease cleanup. The shove fixture covers a retained early-RMB press, one execution, release cancellation and expiry. `validate_crate_failure_assets.py` verifies original archive entries, all diffuse/QTE pixels, exact mesh/source-motion conversion and native B42 mesh/item/model/animation imports. It uses the ignored local Yakuza GMD IO checkout recorded in provenance. Native test JVMs can be capped with JAVA_TOOL_OPTIONS when Windows memory commit is constrained; this does not edit PZ's launch files.

## Heat Rush timing and native quickstep startup

The QTE fixture verifies consistent overlapping windows without early impacts, source-facing ground handoff, contact effect/sound layers and suppression/restoration of native stagger state. Quickstep startup tests use a live-track stub with Space/RMB transitions and verify no quota/cooldown on a missing animation, one spend after movement and exact distance. CVF integration checks contact-specific attack pools without changing the voice pack. Native stun probes verify idle/ground state and floor/ignore-stagger APIs; source paired validation checks the final 180-degree victim facing against the original GMTs. These checks remain offline.


Weapon motion repair validation compares original arm world rotations and untouched native walking/head/torso channels, source attack contacts, retimed source walk/sprint samples and native deferred travel. WeaponMotionProbe exercises style/profile selector isolation and walking crossfades. Native FK validates both props at every sample; the native katana mesh edges are checked against neck/head positions through source poses and sampled transitions. Build style-travel assets before weapon-motion assets using Blender, then rebuild MP observers and the numeric attack-trail catalogue. See weapon-motion-assets.json and style-travel-assets.json for original paths/hashes and conversion operations. No PZ launch is required.


The 0.76 hold regression samples original GMT joint positions, compares chest-relative segment directions on PZ anatomy, checks forearm-relative wrist articulation, and rejects the old v0.75 katana result. Native torso/head/legs and attack/guard output hashes remain unchanged. CVF integration now runs the actual Heat Action presentation function and feedback resolver against the provider API; paired-action tests cover late source frames and local-MP echo deduplication.


Input prompt tests exercise the shared mouse/keycap renderer, rebinding, layout, alpha and cache behavior. build_input_prompt_assets.py --validate compares the four PNG crops against the original ui.par DDS pixels; InputPromptAssetProbe uses native B42 ImageData and checks the text-measurement APIs without starting the game.


## Vanilla pose fallback (0.78.0)

vanilla_pose_fallback.py disables the DoD weapon-pose and ordinary custom-walk selectors without editing their motion clips. Current weapon/travel builders reapply this policy. Its two animation-gate variables have no production Lua producer and no runtime option; they exist only to keep the retained conversions dormant.

Compile VanillaPoseProbe.java with javac, then run validate_vanilla_poses.py with the bundled Python runtime. The validator checks all 30 selectors through B42's actual native selector, including unset/false rejection on owners/observers and an explicit true-gate negative control. It verifies the native walking clip in the run blend and compares 727 motion/combat XML files byte for byte with the v0.77.0 ZIP. It does not launch PZ or establish a live visual fix.

For 0.84.0 Rush sections, run `validate_rush_twohit_assets.py` for current pose maps and native imports. `rush-twohit-sections.json` supersedes the original full-clip and short-abort output hashes; the earlier reports and conversion tools describe the supplied source baseline. Run `NativeRushTimingProbe` for original-speed playback and the paired kick victim selectors. No live game is launched by these checks.

For 0.86.0, `validate_grab_crate_assets.py` checks the approved original separation and Y5 H3270 paired sections, preserved body transforms, source prop track, root height and native imports/selectors. `extract_crate_heat_assets.py`, `retarget_crate_heat.py` and `build_crate_heat_assets.py` reproduce the approved conversion from installed original sources. `validate_event_bursts.py` checks unchanged supplied textures, true source alpha and native ImageData decoding. Kahlua grab/MP/QTE/taunt suites cover escape rolls, cleanup, finite mash authoring and authority, plus broad fire/smoke event-cloud lifecycles. No tool launches the game.

For 0.87.0 attack trails, run `build_attack_trails.py` without `--write` to verify deterministic current native FK and catalogue provenance. The generated data is Lua code only, with no media conversion. The punch-effects suite covers actual linked clips, leg endpoints, current contacts, lingering world-space wakes and MP visual deduplication. The supplied v0.86.0 media files remain unchanged.

For 0.88.0, build_low_health_tests.py runs the current low-health rules, client controller and stock HUD with bounded native-audio mocks. LowHealthProbe.java checks the supplied PZ heartbeat event declaration, native sound parser and health/threat/emitter APIs without starting the game. SoundSettings tests cover the new private cue and preserve the base HeartBeat volume. No media conversion is used.

Build heat-damage-tests.lua with build_heat_damage_tests.py and run it using LuaRunner. This verifies the shared paired-contact health policy, lethal reservations, interruption, protection and terminal native consequences without starting PZ. The heat-rush and MP suites also exercise low-health katana sequences through production handlers.


For 0.92.0, read_katana_scene.py reads the supplied katana CMN18 scene without executing either game. validate_katana_scene.py verifies its damage/sound/voice/particle contracts and five native decoded audio outputs. build_katana_scene_audio.py reproduces approved original bank extraction. validate_katana_heat_assets.py checks retained source frames, native arm-segment directions, smooth paired-root adaptation, punch alignment, prop tracks and actual B42 imports/selectors. Heat presentation tests cover independent audioEvents/voiceEvents, blood-only source anchors, authoring errors and duplicate suppression. Heat Rush tests cover queue-free native variable playback and scoped rejection of replacement queued actions. No validation tool starts PZ.


For 0.95.0, read_heat_scene.py extends the CMN18 reader to the supplied big-endian CMN10 crate scene. cri_cue_table.py resolves CueId through the bank UTF tables. build_heat_scenes.py --write reproduces all six source contracts and 23 direct non-voice PCM decodes; default mode verifies deterministic results. build_heat_scene_anchors.py verifies 106 source emitter starts and numeric native bone points. validate_heat_scenes.py checks independent expected contacts, victim-only damage, preserved totals, source sound IDs, fresh PCM decodes and unchanged v0.94.0 media. Rebuild heat presentation and attack-trail numeric catalogs after contact edits. The heat-presentation suite exercises six main clips and both failure endings, original event starts, replay, late-frame dropping, clip switching and invalid ending events. No validator launches PZ.


For 0.96.0, extract_bat_heat_assets.py extracts the installed Y6 h23710 scene and original long-blunt model references into ignored provenance folders. Run build_bat_heat_assets.py inside Blender for direct source retargeting, animated buki1_r_n attachment, paired paths and six native owner/victim selectors. Run tools/build_mp_visuals.py --only-clip ProjectYakuza_DD_BatHeat for the two event-free observer cycle selectors and shared catalog, preserving all existing XML bytes. Rebuild CMN, bone-anchor, attack-trail and presentation data afterward. validate_bat_heat_assets.py checks source/resource roles, all 103 pose samples per actor, source arm directions, unchanged body channels, original weapon articulation, supplied model axes, native imports and eight selector gates. Heat Rush/MP fixtures cover every allowed bat, item rejection, normal Runtime startup, confirmed payment, both weighted hits, replay, full recovery and lethal settlement. Existing texture/model files remain unchanged.
