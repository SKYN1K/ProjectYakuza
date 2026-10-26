> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Defense and particle polish — 0.18.0

Controls while the Dragon of Dojima style item is equipped:

- RMB + hold X: raise Kiryu's guard. Release X to lower it.
- RMB + G: grab one nearby standing zombie in front. G again releases it.
- RMB + MMB while holding: throw the held zombie.
- RMB + N: toggle Extreme Heat. H returns to its ordinary health-panel use.
- Existing LMB combos, MMB finishers/Tiger Drop and Shift quicksteps remain available outside defense actions.

Guard uses the original Kiryu enter, loop, hit and exit GMT clips. A confirmed guard stance cancels frontal standing bites during the existing native pre-collision marker window, spends 0.08 endurance per blocked bite plus 0.008 per second held, and plays the native defended-zombie reaction. Raising guard must precede contact. Rear attacks remain dangerous. Exhaustion lowers guard and requires release plus a 1.2-second recovery before raising it again. Damage is never healed retroactively and infection is never removed.

The initial grab is single-player only. It selects an unobstructed standing, non-attacking target within 1.05 tiles. Both player and zombie must confirm the original paired entry animations before a throw becomes available. Position adjustment uses short collision-checked native movement steps. The hold expires after 3.5 seconds from entry and costs endurance; throwing costs 0.06 endurance. Release aim, change equipment, fall, get hit, lose the target, encounter an obstructed adjustment or miss an animation marker and the action releases both participants. A throw applies one ordinary native weapon hit at the paired impact markers and knocks the target down. It does not apply a Java ragdoll impulse. Multiplayer grabs fail closed until there is an authoritative synchronized handler.

G also controls vanilla safety. The mod wraps the original key callback at game start and suppresses G only while aiming with the style equipped outside a vehicle. Other keys and ordinary G use delegate to the original callback. User keybinding settings are not rewritten. N remains the vehicle-engine key in vehicles, where Extreme Heat is unavailable. X's native firearm rack action has no firearm to act upon while the style token is equipped.

The active hit-effect code now loads only the existing original HitSparks.png and HitGlint.png exports. It transfers native sprite instances to one fixed-facing world renderer and animates scale, position and opacity over 240 ms (280 ms for finishers). It does not load the older generated 64×64 WorldHit frame pages. All visual texture files are byte-identical to 0.17.1; there are no new PNG, DDS, generated frames, upscaled graphics or AI assets. Existing original GMT animations were retargeted to PZ's skeleton. The character aura, idle stance, existing attack animations and music are unchanged.

The heat HUD uses the same original atlas for a small Tiger Drop status icon and displays its remaining cooldown. Finishers use a larger original-texture flash and the existing PZ BodyHitGround sound. Native normal attack impact audio remains intact.

Validation: native PZ importer accepts all ten added clips with 35 channels each; 13 native phase selections choose the correct player/victim nodes and leave unrelated characters/actions alone. Kahlua regression coverage includes blocking before collision, rear exposure, stamina/guard break, input scoping, paired animation gating, single throw damage, timeouts, interruption cleanup, collision failure and the original-world-particle lifecycle. Live visual observations are recorded separately when available.
