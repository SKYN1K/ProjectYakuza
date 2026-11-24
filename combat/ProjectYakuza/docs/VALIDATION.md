# Validation coverage

GitHub release **v1.0.8** packages version **1.0.8**. The player profile contains 1,200 runtime files and 88 Lua modules; the full development source contains additional custom-object work excluded from this profile.

The [release-profile report](release-profile-1.0.8.json) records the retained profiles, transformed source files and 262 excluded custom files. Validation covers compilation of the filtered Lua modules, require/animation closure, retained bat/katana/knife profiles and actions, rejection of removed multiplayer moves/observer clips, and resolution of limb tracks. Native inventory checks confirm that a missing item record is skipped without consuming the next saved record.

Package checks enforce the runtime allowlist, inspect private paths/credential formats and compare archive bytes. The native B42 Workshop validator checks content layout, file types and preview. Installation verifies both the normal mod copy and the loadable Workshop payload against the player ZIP. Development source and retained media are recorded separately; retained animation, model, texture and audio bytes are unchanged by release filtering.

[Hit-trail validation](hit-trail-validation-0.135.0.json) and the underlying [catalogue](attack-trail-catalog.json) describe source-pose and projection checks for the full development catalogue. The player filter removes the custom-object entries. These results verify configuration and coordinate math rather than the final blended skeleton or GPU output.

Offline checks do not establish live animation appearance, frame pacing, networking latency or gameplay balance. Test the framework and each add-on in PZ, including a real host/client session, before claiming those properties. See [Testing](TESTING.md) for an add-on checklist. Historical version-named validation documents are available in Git history.

The [1.0.6 validation report](update-validation-1.0.6.json) covers the original grab-attempt conversion, source contact window, native importer, blended hand transforms, combat stance ownership, MP leases, longer impact envelopes and HUD scaling. The unchanged original health textures supply the silver frame and left backing. Tests check 50/100/200 percent scales and small through ultrawide viewports; PZ was not launched.

The 1.0.7 update tests manual/automatic playback ownership, playlist order/wrapping, elapsed estimates, pause and source metadata. Hold/walk tests preserve native root, pelvis, lower spine and both legs; spacing includes explicit body clearance after live feedback. These tests supersede the earlier root-mask assumption in 1.0.6.

The [1.0.8 validation report](update-validation-1.0.8.json) covers saved shuffle/repeat/favorites, complete shuffle cycles, actual history, failed playback preservation, one-time grab outcomes, visible local feedback and reaction continuity. Near-simultaneous alternate flinches coalesce without replacing native knockback or stun. No audio, model, animation or texture bytes change in this update.
