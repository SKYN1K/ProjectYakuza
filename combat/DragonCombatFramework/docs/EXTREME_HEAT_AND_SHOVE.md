# Extreme Heat and shove quicksteps 0.24.0

N is activation-only while the mode is active: pressing or holding it cannot cancel Extreme Heat. Existing fuel drain, attack costs and cleanup on death/unequip/style change remain. Hit gain was already blocked; the shared setHeat entry point now also rejects increases during Extreme Heat so other framework callers cannot bank extra heat. Fuel itself is not replenished. Normal gain resumes after the mode ends.

The native MELEE/shove binding (default Space) starts a single quickstep on press for an equipped style with quicksteps enabled. It works on foot without RMB. Held movement chooses the world direction relative to character facing; with no movement input it steps backward. Holding the key does not repeat. The native manual hand-to-hand button is disabled only for that style state and its previous permission is restored on unequip, unsupported styles, vehicles, typing, incapacitation, save and menu cleanup. The separate LMB shove/stomp authorization remains unchanged, preserving ground attacks. Shift + RMB + direction continues to work. Busy actions, collision checks and existing quickstep cooldowns still apply; unavailable dashes do not fall back to a shove. Special quickstep LMB attacks still require aiming.

## Sound and icon assets

Original battle_common/hactmode_on provides the two Extreme Heat activation layers; hactmode_off provides its ending effect. act_kiryu/charge_st is the current activation wind-up. Those cues were already extracted and wired. gv_fighter_kiryu/boost_on exists as a candidate voice, but no voice cue or new audio is added in this update.

The style item references Item_DCF_Dragon.png, an exact byte copy of media/textures/DCF/StyleSelector/KiwamiDragon.png. This is the same supplied Kiwami Dragon icon, with no resizing, recoloring, upscaling or generated imagery.

## Included pending fixes

Mods slider labels now use registered UI_DCF translation keys with plain percent text instead of passing a raw percent format string to Translator.getText. This removes the observed UnknownFormatConversionException from addModOptionsPanel. Empty common/media/AnimSets and common/media/actiongroups directories are retained to prevent missing-folder scan errors. Windows virtual-memory settings and the hosted server's memory allocation were not changed. The previously reported fatal native allocation failure is outside this code fix.
