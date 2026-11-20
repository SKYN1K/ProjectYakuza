# Style entry and idle transitions

`actions.styleEntry` opts a style into entry playback after explicit selection. Supply an existing animation, duration and native start/end markers. Entry locks movement and attacks while retaining player vulnerability. Cleanup restores the flags owned by that action. Reconnect/model repairs do not replay the entry.

The optional `switchDuration` supplies an earlier handoff when a style was already equipped. It changes the controller's handoff duration rather than the animation speed. Capture the prior-equipped state before selection; multiplayer equipment acknowledgement can occur later.

Dragon of Dojima uses the Lost Judgment blue Dragon source entry, retaining 151 samples at 60 fps. First equip plays the full 2.5-second motion; switching or reselecting an equipped style uses the original control handoff at 31/30 seconds. The native conversion preserves source rotations and proportions while correcting support-foot height.

Relaxed unarmed idle uses Bob_Idle. Aiming with the DoD style token selects its combat idle through the native aim/strafe nodes; supported vanilla weapons retain native aim selection. Other styles provide their own entry/idle nodes and do not inherit DoD's clip.

[Entry provenance](combat-entry-assets.json) and [switch timing](style-switch-timing.json) record source hashes, native pose checks and the retained handoff. Earlier Kiwami conversion records describe superseded work. Native validation establishes clip/selector contracts; live blends require gameplay testing.
