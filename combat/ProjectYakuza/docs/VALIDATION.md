# Validation coverage

GitHub release **v1** packages internal build **0.136.0**. The player profile contains 1,195 runtime files and 88 Lua modules; the full development source contains additional custom-object work excluded from this profile.

The [release-profile report](release-profile-0.136.0.json) records the retained profiles, transformed source files and 262 excluded custom files. Validation covers compilation of the filtered Lua modules, require/animation closure, retained bat/katana/knife profiles and actions, rejection of removed multiplayer moves/observer clips, and resolution of limb tracks. Native inventory checks confirm that a missing item record is skipped without consuming the next saved record.

Package checks enforce the runtime allowlist, inspect private paths/credential formats and compare archive bytes. The native B42 Workshop validator checks content layout, file types and preview. Installation verifies both the normal mod copy and the loadable Workshop payload against the player ZIP. Development source and retained media are recorded separately; retained animation, model, texture and audio bytes are unchanged by release filtering.

[Hit-trail validation](hit-trail-validation-0.135.0.json) and the underlying [catalogue](attack-trail-catalog.json) describe source-pose and projection checks for the full development catalogue. The player filter removes the custom-object entries. These results verify configuration and coordinate math rather than the final blended skeleton or GPU output.

Offline checks do not establish live animation appearance, frame pacing, networking latency or gameplay balance. Test the framework and each add-on in PZ, including a real host/client session, before claiming those properties. See [Testing](TESTING.md) for an add-on checklist. Historical version-named validation documents are available in Git history.
