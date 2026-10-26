# Mad Dog addon 0.2.0

Adds the original Yakuza 0 Mad Dog Legend selector image, original title artwork, a separate six-stock heat HUD and a white/violet torso aura made from original common aura textures. Extreme Heat brightens the same four emitters; completed flourishes flash them, including at zero heat and for existing remote observers.

The presentation is owned by the addon and selected through exact style flags. Framework HUD/aura/selector rendering and other styles are unchanged. Cleanup covers switching styles, unequipping, aura-disable settings, vehicle entry, death, disconnect, save and main-menu exit. The framework dependency remains this PR's 0.30.1-based revision with its optional weaponSprite API.

All 68 PNGs preserve original decoded DDS crop pixels. No ImageGen, repainting, generated frames or native Yakuza MEP shader execution is used. The 0.1.1 motion rebuild is unchanged. Validation: 619 Kahlua checks, 39 compiled production Lua files, 113,820 exact original RGBA pixels, and unchanged validated motion hashes. Gameplay appearance and two-client latency still need confirmation; the game was not launched for validation.

This version remains in the existing draft PR. No release/tag is published and the PR is not merged.
