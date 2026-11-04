# Kiwami-style selector

Hold Z while on foot. Move the pointer from the wheel centre toward a circle, or hold an arrow key, then release Z. Escape cancels. Nothing switches until release. Top unequips the style and deletes its temporary style item; a real weapon stays equipped. Left is Style 1; right is Style 2; bottom opens Project Yakuza settings. An empty side does not disable the current style.

Style 1 defaults to Dragon of Dojima. Style 2 starts empty. In settings, First Style and Second Style list all registered styles and preview their optional selector icons. Hit effects, heat aura and diagnostics follow them. Save applies changes; Cancel or Escape discards edits. The old inventory submenu is removed. The menu does not equip a style; selecting that slot later does. Assignments persist in character modData.ProjectYakuzaStyleSlots; missing add-ons retain their saved IDs but appear empty until installed again. No fake second style is registered.

The selector refuses mid-attack/action changes and ignores Z while typing, paused, dead or seated in a vehicle. Vehicle seat Z retains its normal behavior inside vehicles. It does not freeze or slow the game, capture the mouse globally, or scan zombies. Only the open wheel installs a tick callback. This input UI targets the first local keyboard/mouse player; it does not add split-screen/gamepad selectors or network synchronization.

## Add-on authors

Register styles using the framework API. They appear in the assignment menu automatically, including styles registered later. Optional `selectorIcon="media/textures/MyMod/MyExistingIcon.png"` displays a supplied texture. Other styles have a plain numbered slot if no icon is supplied. Dragon of Dojima uses the original Kiwami Dragon icon. No Kiryu assets are inherited by other styles.

`ProjectYakuza.StyleSlots.get(player)` returns persisted assignments. `id(player,"left"/"right")` resolves only available styles. `assign(player,side,id)` validates IDs; nil clears a slot. `styleSlotChanged(player,side,id)` fires after assignment. The top/bottom slots cannot be assigned. Top invokes `ProjectYakuza.unequipStyle(player)`; bottom opens setup.

## Original assets

Frame atlas: Yakuza Kiwami/media/data/2dpar/ui_c.par → surfboard/pjcm_life.par → pjcm_life.dds. Dragon icon: 2dpar/sprite_c.par → 2d_yk_style_icon_k03_e.dds. PNGs preserve the source RGBA pixels exactly; the original ring/highlight atlas regions are selected at runtime. No textures, audio or animations were synthesized. See style-selector-assets.json for hashes.


Selecting or reselecting a style with actions.styleEntry requests its native entry animation. The DoD entry blocks movement/attacks but leaves the player vulnerable. Empty/setup slots do not play entry. Explicit MP selection waits for equipment delivery/acknowledgement; reconnect repairs stay silent. Other styles can opt in with their own clip/markers.

The settings panel uses the selected original Kiwami dark texture with a 300 ms eased opening fade. The compact wheel uses the existing Kiwami circle art, staggered entry and smooth selection focus over visible gameplay. Custom style UI providers retain their rendering hooks. See style-settings-background.json for unchanged source pixels and archive provenance.

In 0.79.0 the decorative centre copies of the slot ring are removed. The original ring artwork is reserved for the four selectable slots and their highlights; no replacement centre graphic is generated.
