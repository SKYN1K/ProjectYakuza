# Project Yakuza Phone development build

This is an optional source project. It is not included in the framework v1 player release. Its style presentation fields apply only with this add-on enabled.

Requires Project Yakuza 0.131.0 or newer. Enable both mods, open the style wheel and choose Settings. Disabling the add-on restores the original mod menu after restarting PZ. Combat behavior and effects come from the shared dependency.

The original Yakuza 6 Xperia hardware, UVs and diffuse are rendered by PZ's native UI3DScene with the established angle and opening motion. Casing lighting uses original geometry and material-map samples, with cached projections and at most 224 visible lighting polygons. This adapts the material response without porting the Dragon Engine shader; native UI3DScene remains orthographic. The original phone_open and phone_cancel01 cues play locally through native UI audio.

Handset labels use projected glyphs from the installed PZ font to remain attached to the phone screen. Flat application menus use native text measurement/rendering. The projection is specific to this add-on and does not replace fonts in other PZ menus.

The Items app previews actual Project Zomboid skill levels and XP. Pressing it opens categorized main-inventory items. Existing native inventory actions and combat settings are reused. The phone battery shows overall health with a percentage and proportional red-to-green fill. Filled Heat stocks use the original filled core.

Styles opens registered style names, descriptions and previews. Only Assign to 1st slot and Assign to 2nd slot appear below the preview. Assignments stay in the menu and do not equip a style. Descriptions wrap and scroll within their own area. Preview images preserve their aspect ratio, and text stays inside the viewport layout. Dragon of Dojima uses light blue and the supplied 512x288 image, with no preview tabs.

Creators may define phoneMenu.theme and phoneMenu.previews on their registered style. Multiple previews add labelled buttons above the image; single previews have no tabs. Images and variable-delay animated frame sequences are supported. An included GIF import tool converts creator-supplied GIFs into native PNG frames and a timing descriptor; raw GIF playback is not supported by the game texture loader. See STYLE_PRESENTATION.md for the schema, controls, limits and import command.

Mouse wheel is consumed by visible lists. Arrows navigate; Enter selects; Escape returns or closes. In Styles, up/down selects a style, left/right chooses the slot, Tab cycles preview tabs, and wheel over the description scrolls its text. Controllers use directions and A/B/Y. Death, vehicles, map opening, chat input, viewport changes, saving and leaving release the phone and its input focus. Opaque submenus stop hidden model/lighting rendering.

Validation is offline: native font API and geometry/UV/pixel checks, Kahlua input/layout/theme/animation/lifecycle checks, source-comment auditing and runtime package/privacy checks. PZ was not launched, so live appearance and performance still need confirmation. The add-on has 34 runtime files; docs, source extractions, tools, previews, private paths and credentials are excluded from its ZIP. GIF import tools are distributed through the source repository, not bundled into the game runtime.
