# Controls and settings

These defaults apply to Dragon of Dojima in v1.0.1. Other styles can register their own bindings and input callbacks. See the [reference-style control table](../README.md#default-controls).

## Settings

**Options > Mods > Project Yakuza options** contains the local mouse/keyboard bindings and separate Music volume, Hit volume and Voice volume sliders. A keyboard code of zero is unbound. Light Attack also controls running strikes and quickstep attacks. Heavy Attack / Finisher also controls the running dropkick. Tiger Drop also uses Heavy Attack / Finisher, taking priority only when its timing and target checks succeed. These contextual attacks have no separate bindings. Each action has a readable keybind type selector and keyboard bind. Heavy attack and finisher use one combined setting; Heat Action remains a separate binding. Native aim, movement, run and sprint keep their PZ bindings.

**Sandbox Options > Project Yakuza** contains the world/server switches for Heat Actions, grabs and Extreme Heat, plus Dragon Tiger Drop's toggle, timing window and cooldown. Defaults are enabled, 160 ms and 20 seconds respectively. Disabling a feature prevents its requests; it does not remove a style definition.

**Options > Mods > Project Yakuza options > Presentation > Zombie Encounter Intro** enables or disables the local animated encounter title and its intro sound. It defaults to enabled, saves per client, and can be changed during play. Disabling it closes the active intro and cancels queued counting.

## Heavy input and Heat Action priority

While aiming, a valid frontal Tiger Drop is checked on the initial heavy press. Otherwise, tap-release submits the neutral heavy or a combo finisher. Holding charges the neutral heavy or the first-finisher branch after one to four lights. Charged attacks release automatically at the 1,200 ms limit; a lower-power early release is possible after the minimum source wind-up. Second finishers do not charge.

Heat Action defaults to MMB as well, but has its own setting. It requires physical RMB, a valid target, enough resource and no active combo/follow-up window. Combo MMB input retains finisher behavior. One complete Heat stock qualifies; supported weapon actions can use active Extreme Heat fuel.

## Movement and grabs

RMB + Space quicksteps when eligible. Direction chooses the step; stationary input goes backward. A step can grant one quickstep attack. There are three accepted quicksteps per rolling fifteen seconds. Startup waits briefly for native aim readiness, and a rejected startup does not spend the quota. Running Space without aim keeps native movement rather than starting a combat step.

RMB + G grabs a standing zombie. A fresh G press throws; Light attacks during the hold. Releasing RMB does not release the grab. Hold RMB and press Heat Action for the eligible wall/open-space grab scene. See [Grabs](GRABS.md).

## Styles and audio

Hold Z and release over an assigned slot to equip it. Top unequips; bottom opens assignments/settings. Assignment alone does not equip the style. Empty slots preserve the current selection. The wheel does not pause the world and targets the first local keyboard/mouse player.

Music, Sounds and Voices each have a 0Ã¢â‚¬â€œ200% slider. Music controls the style playlist independently of vanilla Music volume. Sounds controls framework effects and UI sounds; menu playback is local. Voices applies to optional combat voice integration. A missing voice pack remains silent. Add-on bindings appear in the same settings page through `Bindings.register`.

## Extreme Heat prompts

The paired rush follows the eighth confirmed unarmed light-chain contact against a surviving eligible target with enough space. Follow Light, Heavy, Grab, Light, Heavy, Grab using the current bindings. Each prompt needs a fresh press; holding a button does not satisfy the next prompt. The six authored nineteen-frame sections retain 633 ms windows at 1x animation speed. Failure enters the original ending kick. Weapon Heat Actions remain available during Extreme Heat when their own requirements are met.

Music volume defaults to 45 percent for new or reset preferences. Existing saved values are preserved. Volume sliders has separate Music volume, Hit volume and Voice volume controls.

Vanilla shove/stomp input is disabled while a fighting style is equipped, including after quickstep is rebound. Unequipping restores its prior permission. The custom ground attacks remain part of the fighting style.

The default heat HUD shows quickstep charges and the next recovery countdown below the gauge, followed by Tiger Drop cooldown when supported and enabled. Filled segments are available quicksteps; the partial segment shows the next returning charge.

The HUD scales down to fit its viewport and reserves space below the full glow for its cooldown rows. Quickstep charges appear beside QUICKSTEP; the recharge time or READY stays at the right edge. The extra numeric Heat label is removed.

HUD scale is available under Options > Mods > Project Yakuza, from 50 to 200 percent. The complete health/heat display, text and cooldown geometry scale together and fit within the current viewport. The health frame retains fixed-size original silver end caps and a gray left backing.
