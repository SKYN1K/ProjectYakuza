# Manual directional attacks and taunt attention (0.57.0)

## Dragon of Dojima controls

While aiming, start an unarmed light combo with LMB. Make a substantial manual turn before the next light: turns of 65–145 degrees select the corresponding side strike, and turns of at least 145 degrees select the rear kick. Smaller changes retain the normal chain. The reference heading is the previous light's starting heading; expired combos start normally. Both ordinary and Extreme Heat unarmed lights support this routing. A turn input takes priority over the fifth-click barrage; MMB retains its existing behavior outside a directional ender.

A directional strike ends that light chain. It retains x0.75 light damage and the existing active Extreme Heat bonus, uses one native collision and the existing three-target hit cap, and plays its full supplied recovery. A new combo starts after it finishes. Heavy/charged follow-ups are blocked during the directional ender. The ordinary quickstep quota/cooldown and post-contact cancel marker apply; cancelling or interruption releases its movement lock. Real weapon profiles keep their own movesets.

Player input continues to control facing and the native PZ hit cone. Selection reads two headings; it does not search for enemies or steer the player. Ground attacks and existing committed actions keep priority. Full-body source motion is used for these three turning strikes; normal lights retain their existing leg layering.

The source command file explicitly maps AttackRevL to ath_BBL_lf_md, AttackRevR to ath_BBR_lf_md and Heavy_Rev to ath_BKL_lf_md. All supplied source frames and root rotations are retained by the approved retargeter, with native fist/prop conventions. Contact starts are source frames 10, 10 and 11 at 30 fps. Source hashes, ranges and native inputs are in directional-attack-assets.json. These are PZ adaptations of the original motions, not an imported Dragon Engine combat state machine. No bridge poses or artwork/audio are generated.

## Taunt reactions

Complete the existing RMB + Q taunt to draw nearby zombies' attention. Existing one-orb reward and taunt aura timing remain unchanged; Extreme Heat still prevents heat gain. No attention burst happens at taunt start or after interruption.

DoD affects up to eight standing, living, non-attacking, non-useless zombies within five tiles on the same level, with a clear native collision path. It adds native aggro and targets the taunter. Native AI controls subsequent turning, movement and retargeting. Attacks already underway, downed zombies and blocked targets are skipped. This does not deal damage, stun, force a hit animation or play newly created sounds.

The scan runs once on completion. It visits at most 121 nearby squares for DoD, inspects at most 256 distinct moving objects, and path-checks at most the 32 nearest eligible candidates until its eight-target limit is reached. There is no persistent zombie-scanning loop for taunt reactions. The existing native animations provide zombie movement.

## Framework configuration

Styles opt in explicitly with `directionalAttacks={minimumDegrees=65,rearDegrees=145,moves={left=move,right=move,rear=move}}`. Each move uses a unique nodeValue, supplied animation, duration, speed, impact, `directional=true`, `fullBody=true`, damageMultiplier and native collision/cancel markers. Add `hitResponse="light"` for the style's light response and `kick=true` for kick feedback. Missing sectors have no replacement. Register native owners and event-free observers/catalog entries. Weapon views do not inherit the unarmed directional map.

`ProjectYakuza.DirectionalAttacks.direction` classifies two facing vectors. `select(player,state,style)` chooses an opt-in move, and `record(player,state,move)` stores the committed light heading. Runtime owns routing, latched playback and cleanup. No extra keybind is added.

`tauntReactions={radius=5,maxTargets=8}` opts a style with an enabled timed taunt into attention. Supported radius is 1–6 tiles and target cap is 1–8. Its taunt action needs a finite duration between 0.05 and 10 seconds. `ProjectYakuza.TauntReactions.config`, `valid`, `targets`, `apply` and `react` expose the bounded native-AI logic. Call native AI mutations only on SP/server or the zombie-owning client. Styles without this configuration receive no taunt attention behavior.

## Multiplayer

Three owner nodes have twelve event-free observer copies, supporting both repeat cycles and actions/melee groups. Directional lights use the existing native primary hit plus server-validated supplemental damage; observers never replay Hit. Server move lookup validates the unarmed style/profile membership.

The server observes a timed taunt action before accepting a new completion counter, checks its source duration with a 250 ms timing allowance, binds the lease to style and held item, and consumes completion once. It selects targets itself. Clients cannot send their own victim list or directly request a taunt effect. Server result packets carry the current player session and authorized zombie IDs; zombie-owning clients apply native AI once. Missing streamed targets have a 750 ms retry window and per-target deduplication. Other observers rely on native AI replication. Retained grabs remain disabled.

PZ was not launched. Offline input, source/native import, budgets, ownership, completion authorization and duplicate tests pass. Live pose blending, collision alignment, ownership migration and network latency still need an in-game check after a full matching client/server restart.
