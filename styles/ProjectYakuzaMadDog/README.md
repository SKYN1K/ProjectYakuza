# Mad Dog of Shimano — addon 0.1.1

Adds Majima's Yakuza 0 legend style to Project Yakuza. The 26 playable clips are retargeted from the supplied local game's original `BattlePlayerMajimaL.par` motions. This addon contains its own registration, animation nodes and multiplayer catalogue; it does not bundle another copy of the framework.

## Install for testing this PR

Use the **ProjectYakuza framework from this PR**, based on 0.30.1, plus `styles/ProjectYakuzaMadDog`. Put the `ProjectYakuza` and `ProjectYakuzaMadDog` folders side by side in `Zomboid/mods`, then enable both. The released 0.30.1 framework by itself lacks the optional `weaponSprite` API added here. This branch is not a published framework release. Install matching framework/addon revisions on server and clients.

Right-click your inventory → **Combat styles → Mad Dog of Shimano**, or assign it to a slot through the framework's existing Z selector. Selecting the style plays Majima's original one-second `P_btlst_MJA_to_MJK` entry at source speed, without invulnerability.

Default inputs (the framework's rebinding settings still apply):

| Input | Mad Dog action |
| --- | --- |
| Aim + LMB | Four successive original knife attacks; one buffered light at a time |
| Aim + MMB after a light | The corresponding original finisher, one per combo branch |
| Aim + X | Majima's guard entry, loop, hit and exit |
| Space + movement | Original forward/back/left/right quickstep; no direction steps back |
| LMB during an aimed quickstep | Directional evasive knife slash |
| Run + LMB or MMB | Running knife slash, after the framework's 250 ms run-up |
| Native ground attack/stomp input | Downward knife slash with native floor targeting |
| Aim + Q | Original style-action flourish through the shared taunt handler |
| Aim + N | Shared Extreme Heat using the original style-action entry motion |

Light attacks keep the original full-body turns, crouches and leg motions. A style-scoped movement lease restores the previous movement flag on completion, damage, death, unequip, save, timeout and world exit. Finishers, dodges and other actions use the framework's existing handlers. The style can be switched back to Dragon of Dojima when idle.

The held knife and swing/impact sounds use Zomboid's existing `HuntingKnife` resources. No new model, texture, music or voice recordings are bundled. Character voices are disabled for this style to avoid using the separate Kiryu pack. The shared heat HUD and impact glint are explicitly enabled; Kiryu's aura, Tiger Drop, paired grabs and enemy reaction mappings are not enabled.

## Fidelity and testing limits

This is a Zomboid adaptation. Horizontal root travel is removed; bounded native collision-aware movement handles dodges and the running slash. Contact frames and damage are approximate and use one native collision per move. Native PZ proportions and knife/finger grip replace Yakuza's skeleton/weapon attachment. Version 0.1.1 uses the true Human inverse-skin bind and a Z-axis handedness conversion, preserving left/right and the original motion direction; no pose generation or floor solver is used. Light attacks play at 1.8×; quicksteps at 1.35×; entry, guard and flourish at source speed.

The shared heat/Extreme Heat system is not Yakuza 0's exact heat model. Both running triggers use the running slash. Continuous spinning double finishers, charged attacks, cinematic heat actions and synchronized counters are not implemented. Guard/idle retain native walking legs; attacking clips use the complete original body motion.

All 28,824 original-source direction comparisons and 463 Lua assertions pass; Project Zomboid was not launched. Foot contact, blade alignment, blending, female-body proportions, controller feel and live two-client replication still need gameplay testing before merging. See [validation](docs/VALIDATION.md) and [motion provenance](docs/motion-provenance.json).
