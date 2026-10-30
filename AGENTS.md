# Project Yakuza workflow

User requirements:
- Keep project source, templates and generated code free of comments. Put explanations in the documentation and run tools/combat-tests/check_source_comments.py.
- Never generate visual/audio assets, including AI upscaling. Use only supplied game assets. Ask before generating anything or if a required asset is missing.
- Do not launch Project Zomboid unless the user explicitly authorizes it. Validate offline, then install the requested update locally.
- After each actual combat-mod update, commit/push it with GitHub CLI and publish a separate versioned release with the install ZIP. This was explicitly requested by the user. Preview-only requests do not change or release the mod.
- GitHub destination: private SKYN1K/ProjectYakuza. Keep extraction folders, previews, backups, tokens and the separate CVF voice-pack project out of Git.

Source is combat/ProjectYakuza. Update 42/mod.info and shared/ProjectYakuza/Registry.lua consistently. Keep docs/RELEASE_NOTES.md current and document meaningful validation. Run appropriate tools/combat-tests Kahlua checks when available; source motion/texture changes also need provenance and native importer/pixel checks. Back up only files being changed during local installation and verify installed bytes.

Publish using tools/Publish-CombatRelease.ps1 with a configured/authenticated gh CLI. Never reuse/overwrite a published version tag. Do not upload unrelated local files or credentials. Later explicit user instructions override this workflow.

Naming: use ProjectYakuza for internal identifiers and Project Yakuza for display text. Do not retain old aliases or compatibility loaders. Do not modify the separate voice pack; it is maintained in another chat. Grabs are temporarily disabled.
