# Attack limb coating and trails

Dragon of Dojima uses the supplied Y6 flame, glint and spark textures as overlapping world sprites on the attacking arm or leg. The full development catalogue covers 95 clips and 121 contact windows; the v1 player profile retains 76 clips and 93 windows after removing custom-object attacks. The catalogue includes lights, normal/linked/reverse/double/charged finishers, directional/running/quickstep/ground attacks, Tiger Drop, grab strikes and paired Heat Actions/endings, including weapon profiles. Other styles opt in with their own configuration. No visual, audio, motion, model or texture asset is generated or modified.

## Current animation and limb selection

The committed move identifies an allowed animation family. The renderer inspects the native tracks actually playing and chooses the matching clip with the greatest blend weight; equal weights prefer the incoming lower phase. Linked double finishers and paired failure clips belong to their original action's family. An unrelated attack or idle cannot replace the committed move. Cached locations are reused; full family scans are limited to once per 100 ms while stable, with immediate re-resolution if the cached clip disappears.

Each contact uses the current native animation phase to interpolate PZ skeleton joint positions. The offline numeric catalogue is produced by `build_attack_trails.py` and `LimbImpactProbe` from the unchanged supplied PZ clips. Native collision events or authored paired contacts supply exact source contact times; Tiger Drop retains its documented visual-phase fallback. Ordinary attacks use contact-local endpoint and relative motion, with verified pose exceptions. Every paired Heat Action instead declares its original striking limb per contact, independent of the equipped weapon: the knife changes from the weapon arm to its right kick; the katana changes to the left arm for its punch; the crate follows its right/left/right/left kicks between weapon-arm contacts. Other weapon scenes retain their wielding arm. Owner and observer playback use the same catalogue and contact mask. A normal finisher no longer inherits its charge-up limb. See `attack-trail-catalog.json` for source hashes, family assignments, contact phases and limb scores.

Arms use upper-arm, forearm, hand and knuckle samples. Legs use thigh, calf, foot and toe samples. Eleven overlapping flame centres coat the selected limb and three inner cores provide restrained white-blue light. The hand/foot endpoint remains 35% toward its knuckle/toe sample. Small deterministic offsets affect the middle of the coating, while both endpoints stay centred. No gameplay RNG is consumed. Windows start 120 ms before contact and end 200 ms after, bounded by the clip and neighboring contacts.

Recovering arms can move faster than a striking foot. Verified contact-pose mappings keep the first light on its original left hand and the high-kick finisher on its raised right foot, even when raw velocity favors a recovering arm. These decisions are recorded separately from inferred limb scores in the provenance.

The continuous rendered body angle and native-verified model projection place current samples in world space. This Lua-only method follows the actual clip and frame; it approximates the final blended skeleton. Walking blend, IK, clothing and model proportions can still differ. No live bone-transform adapter, Java bridge or launcher change is installed. Damage, timing, charge glow and body aura are unchanged.

## Lingering world-space history

A fixed 24-row ring stores the selected limb's three joint positions in absolute world coordinates, recording at most once per eight milliseconds. Twelve historical flame samples cover the outer half of earlier limb poses at staggered delays, and four small endpoint sparks reuse those positions. Turning or walking does not reproject the old history through the new facing.

Completed attacks retire their live coating but keep a fading wake for at most 200 ms. Starting the next attack preserves that wake within its global cap. Only the twelve trail instances survive retirement. Fade follows age and recorded blend weight; source animation frames advance once per changing effect clock. Pausing freezes history, animation and expiry. Changing to another contact limb resets the live history to avoid connecting different limbs. A root jump over one tile or a significant floor change discards the affected history.

Hits, cancellation, style changes, death and world exit clean up their owned sprites. Draw failures restore incoming renderer state and release all effect instances. Ordinary alpha blending avoids a bright additive coating.

## Addon contract

```lua
attackEffects={
    track="myaddon.leftPunch",
    from=2/30,
    to=14/30,
    swingFrame=3,
},
```

Register the matching numeric track in `ProjectYakuza.AttackTracks` first. Its `animation` matches the supplied clip, `fps` supplies its sample rate, `limb` is leftArm/rightArm/leftLeg/rightLeg, and each `frames` row has three XYZ triplets for the intermediate joint, hand/foot and knuckle/toe. Optional `upperFrames` provides the corresponding shoulder/hip XYZ samples. Explicit move `attackEffects` takes priority for the primary clip.

For alternate native clips, register an entry under `ProjectYakuza.AttackEffectCatalog[styleId][clipName]`, with `animation`, `actionAnimation` identifying the committed primary animation, `track`, `from`, `to`, optional `duration` and `windows`. Each window supplies its own `track`, `from` and `to`. The referenced track must exist and match the actually playing clip. Missing or unrelated tracks cannot drive an effect. `configuration`, `playing` and `window` expose the current selection to code.

`AttackEffects.registerLimbProvider(id,fn)` optionally supplies intermediate-joint and hand/foot world positions, plus optional shoulder/hip values. The provider receives player, actual clip name, native time and limb name. Six values retain their exact endpoint and use the sampled shoulder/hip offset; nine values provide all three joints. Invalid results fall back with a one-second retry throttle. `removeLimbProvider(id,fn)` unregisters an adapter. No adapter is bundled.

## Limits and multiplayer

There are at most eight active actors and eight retired wakes. Each active actor has 30 detached sprites; each retired wake retains twelve, for a worst-case total of 336. Rings and sprite instances are allocated at activation, rather than per particle draw. Idle actors install no effect polling. Observers resolve their local native clip/frame and retain local history; no particle packets or extra server checks are added. A repeated action/swing/clip snapshot cannot restart the same visual state. Remote/world cleanup releases the same bounded state.

Offline tests cover native source samples, continuous facings, limb endpoints, linked kick selection, turning history, lingering completion/next-attack trails, pause, teleport/interruption cleanup, provider contracts, budgets and duplicate MP snapshots. Native FK is checked against current unchanged clips. Live GPU appearance and a real multiplayer session remain untested; restart after updating matching client/server files.


## Hit impact variation

As of 0.100.0, confirmed-hit glints and sparks vary their initial direction, spread, scale, curvature, downward motion and fade from hit to hit. A small contact-centred offset prevents identical screen patterns. A separate local visual noise sequence leaves gameplay RNG untouched. Source textures, family tints, damage/contact timing, collision anchors and blood frames remain unchanged.

Burst/particle caps and maximum lifetimes remain the same. Heat Action contacts retain their copied physical world anchor; ordinary hits and guard effects keep their existing target/defender attachment. Pause freezes each varied trajectory. Existing pooling, interruption, death, menu and render-failure cleanup still dispose every owned instance.


The 0.101.0 cleanup removes the duplicated legacy first-light numeric dataset. AttackTracks remains the public numeric-track registry, populated by AttackTrailCatalog. The built-in first light uses dd_trail_light01_1, verified against the same original 31 native FK frames. Old unused WorldHit flipbooks and HitSparks are removed; the active glints, spark, flame, blood and contact variation are unchanged.
