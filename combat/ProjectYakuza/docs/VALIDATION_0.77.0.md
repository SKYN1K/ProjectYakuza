# Validation: Project Yakuza 0.77.0

This update changes the client style selector/settings presentation and removes its inventory-context registration. Combat motion, damage, network protocol and the separate voice pack are unchanged. Project Zomboid was not launched; live GPU appearance and real multiplayer sessions remain untested.

The Kahlua selector suite passes 181 checks, including delayed opening/focus animation, original-atlas bounds, mouse passthrough, slot policy, release-to-select, assigning add-on styles, per-character persistence, native preference defaults, Cancel/Save behavior, effect-cleanup helper routing, repeated saves, optional developer icons, and Escape cleanup. The builder verifies the old inventory event registration is absent.

All 27 gameplay/framework Kahlua suites pass, covering the existing MP authority, ownership, QTE, style-item, weapon, heat, feedback and provider-isolation contracts. All 63 production Lua files compile. The native passive-UI probe verifies right-button passthrough for the wheel and the other passive overlays.

The original Kiwami pause_c.par texture is decoded again directly from its archive metadata. All 524,288 output RGBA pixels match the original DDS at 1024x512, with the output and RGBA hashes checked against style-settings-background.json. The PNG also decodes through B42 ImageData without launching the game. Runtime center cropping, fading and motion leave the source asset unchanged; its menu display is smaller than native resolution.

The source-comment policy check and lexical-preservation tests pass. Installation backs up only changed existing files and verifies every installed file against source. The versioned release ZIP is checked against the installed/source file set after publication.
