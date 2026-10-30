# Validation: 0.51.0

PZ was not launched. Live visuals, physical input, gameplay and MP latency are untested.

## Regression coverage

5,489 Kahlua assertions across 21 fixtures pass, including 20 new heavy-input/window/music checks, 27 style-entry checks, 772 encounter presentation/detection checks, and 193 MP authority checks. All 48 production Lua modules compile. Six lexical preservation tests pass. The comment audit reports zero comments across 578 source files.

The actual-module counter fixture tests first-observed attack windup, inclusive 300ms boundary, rejection at 301ms, already-attacking discovery, damage/completed-bite/rear/outcome exclusion, MMB priority with a remapped dedicated counter, gesture cleanup, 60-second cooldown, and MP observed age. The server rejects age beyond 300ms while retaining existing target/attack/cooldown checks and bounded supplementary-hit bursts. Guard retains its native collision-marker timing independently; the broad fixture checks frontal protection and rear/late rejection.

Style-entry tests cover equipment readiness, one bounded deferred request, retry success, attack gating, interruption and expiry, alongside movement locks, vulnerability, completion and cleanup. Weapon views inherit only base styleEntry by default and preserve profile overrides. Other unarmed actions remain unavailable while armed.

Music tests run with vanilla Music at zero, change it during playback, change the mod gain during playback, verify independent mute and 200% gain, and restore vanilla music according to its current option. Native Mods persistence/grouping tests pass. Local B42 bytecode inspection confirms file-clip effective volume uses GameSound user volume, while the emitter applies the mod fade/gain; it does not multiply the vanilla music option. Music definitions are normalized to user volume 1 so the mod gain is applied once. Overall native master/device output remains normal.

Encounter tests render both entrance and post-landing frames, check alpha/crop bounds, normal blending, mouse-transparent viewports, lifecycle, counts/thresholds, pause, budgets, custom providers and style isolation. The new movement is bounded intro-graphics shake, not world-camera movement. Timing is recreated in Lua, not asserted frame-perfect to reference videos.

## Approved supplied assets and native import

Both new impact PNGs match the original supplied Yakuza 6 DDS RGBA bytes and dimensions exactly: a 1024x1024 8x8 explosion atlas and a 256x256 radial shock. Source/output/raw-pixel hashes and approval are in encounter-impact-assets.json. No resizing, AI, invented pixels or audio creation. Native B42 ImageData successfully decodes all four intro textures. Existing font reconstruction/glyph metrics and flare provenance still pass.

The repaired stance-entry clip imports through B42 and matches native hand offsets over all 51 frames / 102 hand-prop pairs (maximum matrix error 6.914139E-6). Its two prop channels are the only differing channel blocks: hierarchy, timing, body and finger bytes match the previous release. Native-grip/source/output hashes and explicit authorization are in style-entry-prop-repair.json and style-entry-motion.json.

Of 605 previous motion/image/audio files, only that approved entry prop repair differs; two approved original texture decodes are added. All 449 previous native XML files are unchanged. No separate voice-pack files are touched. Existing source contacts, charge timing, paired handoffs, 316 event-free observers, native weapon selection/props, original aura/HUD/blood pixels and addon checks pass.

## Install and remaining limits

The prior 1,295-file installation must match its 0.50.0 ZIP before replacement. The installer backs up only changed existing files, verifies every installed byte, and the release check compares source/install/ZIP bytes and the published asset digest. Extraction folders, previews, credentials and backups stay outside Git.

Restart matching clients/server to load the clip and textures. The 0.3-second Lua counter window starts when an attack is first observed; it cannot predict exact pre-contact time or eliminate MP latency. Entry may expire after two seconds of equipment/action unavailability and logs one diagnostic. The world camera stays fixed; live appearance and original-game similarity require assessment after restarting.
