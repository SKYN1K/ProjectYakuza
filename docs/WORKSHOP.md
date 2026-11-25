# Publishing a Project Yakuza style add-on

Publish your style as its own mod with `require=ProjectYakuza` in `42/mod.info`. The mod ID is a string; it is different from the numeric Steam Workshop item ID. If distributing through Workshop, add the framework's published Workshop item as a required item separately.

## Prepare the upload

Create an item folder under your PZ user-data directory's `Zomboid/Workshop` folder. PZ's installation includes `Workshop/ModTemplate`, which supplies uploader metadata and a default preview. Use your own add-on's runtime files under Contents:

```text
MyStyleAddon/
  workshop.txt
  preview.png
  Contents/
    mods/
      MyStyleAddon/
        common/
        42/
          mod.info
          media/
```

Keep `common/` present and empty if your add-on has no common assets. Include only enabled Lua, native animation nodes, scripts and required game assets. Exclude README files, templates, inactive .example files, extraction tools, source-game archives, test logs, backups, credentials and local configuration. Do not bundle another copy of ProjectYakuza.

Check mod.info identifiers, dependency, animation names, collisions and observer catalogs before packaging. Shared/server code and required assets must be identical on server and clients. See [Testing](../combat/ProjectYakuza/docs/TESTING.md).

## Upload

1. Start PZ through Steam on the account that should own the item.
2. Open Workshop, then Create and Update Items. Choose your staged add-on folder.
3. Review the title, description, tags and preview. Start with Private visibility so the uploaded item can be checked before publication.
4. Continue through validation and submit. Accept the Steam Workshop agreement if prompted; unaccepted terms keep the item hidden. [Steam Workshop documentation](https://partner.steamgames.com/doc/features/workshop/implementation).
5. Open the resulting page. Verify dependency/required-item settings, supported Build 42 version, controls and mod ID. Change visibility to Public when ready.
6. Retain workshop.txt, including the published item ID. Future uploads should update that existing item rather than create a duplicate.

PZ can load mods from local Workshop staging folders as well as Zomboid/mods. Keep one current staged copy of each mod while testing; obsolete copies can hide an update. Fully restart PZ after replacing runtime files.

## Framework v1.1.2 packages

The [v1.1.2 release](https://github.com/SKYN1K/ProjectYakuza/releases/tag/v1.1.2) contains version 1.1. Use ProjectYakuza-B42-v1.1.zip for local installation or ProjectYakuza-Workshop-v1.1.zip for core Workshop preparation. The latter extracts to ProjectYakuza-v1.1.2; place that folder under your own Zomboid/Workshop directory. GitHub's automatic Source code archives are development snapshots, not upload packages.

The core's player release includes vanilla bat/club, knife and blade profiles and their supported Heat Actions. Custom-object development profiles are excluded. The source package builder applies this filter; copying the full source mod folder includes development content.

For core maintenance, configure the local tool/dependency paths before using Build-GamePackage.py and the publication tools. Those tools build the framework, not arbitrary third-party add-ons. Their package allowlist/privacy checks and native Workshop validation complement gameplay testing; they do not upload to Steam.

## Update content without replacing the Workshop page

PZ's in-game uploader submits its local title, description, preview, tags and visibility again. The repository includes a content-only uploader for an existing Build 42 Workshop item. It calls Steam's StartItemUpdate, SetItemContent and SubmitItemUpdate APIs without submitting page-metadata setters. Only the content, update timestamp and an optional change note are updated. See [Steam's update API](https://partner.steamgames.com/doc/api/ISteamUGC#StartItemUpdate).

Keep Steam running and signed in as the item owner. The game can remain closed. Use 64-bit Python and the installed game's steam_api64.dll; no password or token file is required.

Run the PowerShell helper from the repository root, first without Upload to validate the prepared payload:

```powershell
.\tools\Upload-WorkshopContent.ps1 -WorkshopFolder 'D:\Workshop\MyStyleAddon' -GameFolder 'D:\SteamLibrary\steamapps\common\ProjectZomboid' -PythonPath 'python'
```

After reviewing the selected item ID, mod IDs and content size, repeat the command with -Upload. An optional -ChangeNote supplies a changelog entry. The helper reads the published ID from workshop.txt and never creates a new item. It uploads only Contents, verifies the runtime allowlist/privacy rules, and rejects an explicit ID that differs from workshop.txt. It does not rebuild the mod; prepare the player package before uploading.

For local defaults, create tools/WorkshopUpload.local.json with WorkshopFolder, GameFolder and PythonPath string fields. This file is ignored by Git. Do not include local configuration or uploader tools in your player mod. The helper then needs only -Upload; omitting that flag remains validation-only.
