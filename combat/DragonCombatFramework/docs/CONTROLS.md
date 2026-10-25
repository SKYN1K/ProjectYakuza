## Default controls

Aim/movement/run use native PZ controls. While aiming: LMB light attack, MMB finisher or Tiger Drop; X block, G grab/release, MMB throw while grabbing, Q taunt, N Extreme Heat. Space quickstep; LMB during quickstep attacks. Running LMB attack, running MMB dropkick. Hold Z to select styles. Each action has its own binding in Mods settings; Shift remains native run input.


Controls are persisted through PZ's native ModOptions API. Keyboard code 0 disables a keyboard-mode action. Mouse/keyboard overrides are scoped to the combat token; native attack permission is restored on unequip and world exit. Selector navigation retains mouse/arrow UI controls. Quickstep quota is saved as DCFQuickstepTimes in character mod data and checked only when requesting/starting a step, without per-frame zombie scans.
