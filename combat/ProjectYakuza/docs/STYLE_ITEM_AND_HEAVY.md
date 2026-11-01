# Style equipment and ordinary heavy (0.47.0)

Dragon of Dojima still uses its style item for unarmed combat. Selecting the style equips a temporary clean item; it stays favourited and normal drop/external-transfer actions are blocked. Blood is removed after a native hit, with a throttled cleanliness refresh. Real weapons and their dirt, blood and favourites are unaffected.

Manually unequipping the item disables the style and deletes the item. It is not forced back into the hand. The selector top circle now says Unequip style and performs the same disable/removal; a real weapon stays equipped. Left/right assignments and bottom setup are unchanged.

Native timed weapon equips settle before the lifecycle reacts. A supported weapon keeps the style and removes unused style items. Removing that real weapon restores the temporary unarmed item without entry replay. Unsupported equipment disables the style. The multiplayer server owns token deletion and acknowledges equipment; clients do not delete inventory items locally.

While aiming with the unarmed style item, tap-release MMB with no active combo performs the supplied Kiryu normal heavy. Source P_KRU_BTL_SUD_ath_hvy_md.gmt supplies all 51 frames; the original BEP contact begins at frame 9. Playback uses 1.6 speed and x1.25 base damage. Holding MMB still charges; lights retain their branch finishers and doubles. The neutral heavy opens no double branch. Tiger Drop retains initial-press priority.

Only approved source-motion conversions/prop corrections are included. No image, audio, model or invented body-motion asset was generated. See the provenance JSON files and VALIDATION_0.64.0.md. No game was launched; assess live grip/blend and MP presentation after restarting matching installations.
