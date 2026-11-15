# Publishing Project Yakuza to Steam Workshop

The prepared upload folder is `%UserProfile%/Zomboid/Workshop/ProjectYakuza-v0.113.0`. Its `Contents/mods/ProjectYakuza` folder contains only the versioned Build 42 mod and an empty common folder. The normal install ZIP uses the same game files. The separate Workshop ZIP adds only the uploader metadata and an unchanged preview supplied with Project Zomboid.

The payload excludes development notes, provenance JSON, templates, extraction/build tools, backups, previews, repository metadata and AGENTS.md. The package builder checks allowed file locations and extensions, scans runtime text and binary metadata for personal paths, email addresses and credential formats, and verifies packaged bytes against the source. The native B42 Workshop validator also checks the actual staged folder, versioned mod structure, allowed files and preview. The source workspace and private Git repository retain their development material separately.

1. Start Project Zomboid through Steam while signed into the Steam account that should own the item. From the main menu, open Workshop and choose Create and Update Items.
2. Select ProjectYakuza-v0.113.0 from the staged-folder list, then continue. The folder is already in the location the uploader scans. If using the downloadable Workshop ZIP on another computer, extract its top-level folder into that computer's Zomboid/Workshop directory.
3. Review the title, description, tags and preview. The included preview is Project Zomboid's default template image. You can replace preview.png with your own thumbnail before uploading. The prepared item starts with Private visibility; choose the visibility you want when ready.
4. Continue through the new-item pages, accept the Steam Workshop agreement if Steam requests it, and submit the upload. Wait for the uploader's completion result, then open the item page to review it. Steam's documentation confirms that content, preview and visibility are separate upload fields and that agreement acceptance is required for public visibility. [Steam Workshop documentation](https://partner.steamgames.com/doc/features/workshop/implementation)
5. Keep the folder and workshop.txt after the first upload. Zomboid records the published item ID there. For later updates, replace Contents with the new runtime payload while preserving that workshop.txt and its ID, then select the existing Workshop item. This updates the same item instead of creating another entry.

The mod ID is ProjectYakuza. Project Yakuza Emotes and the optional voice pack are separate mods and are not bundled. Use the same combat version on the server and clients. Sandbox settings appear under Project Yakuza in the world's Sandbox Options; local audio and key bindings appear under Options, Mods, Project Yakuza.

Only the prepared Contents folder, selected metadata and preview should be submitted. The entire development workspace is not an upload folder. No Workshop upload is performed by the build or validation tools, and no Steam password is stored in the package. Project Zomboid was not launched during preparation.

The standalone emote upload is prepared separately as `%UserProfile%/Zomboid/Workshop/ProjectYakuzaEmotes-v0.2.5`, with mod ID ProjectYakuzaEmotes. Use the same steps to publish it as its own item. Its animations are unchanged from 0.2.4; this update removes development material from the distribution.

On GitHub Releases, use the named install or Workshop ZIP. GitHub's automatically generated Source code archives contain the development workspace and are not Workshop packages.
