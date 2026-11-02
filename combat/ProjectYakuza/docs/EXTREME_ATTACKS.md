# Extreme Heat rush combat (0.72.0)

Dragon of Dojima uses the four supplied Kiryu bct_ath_01 through bct_ath_04 clips for the first four Extreme Heat lights, then alternates the first two clips for an eight-input chain. Each fresh LMB press commits one native attack. Stopping input leaves that attack's original recovery intact. There is no automatic multi-contact attack.

Perform the eight-input light chain; the first seven attacks may miss or hit different targets. Only the eighth strike must connect. Its last character target is selected, including confirmed supplemental contacts; an invalid final target does not fall back to an earlier victim. The target must survive, remain standing, be within the existing frontal/range rules and have clear paired paths. Eligible PvP players are supported while normal PvP, safety, faction, zone and protected-player checks remain enforced. No target search or soft targeting is used. MMB takes priority before the transition, retaining ordinary finishers.

Boost lights retain their 0.525 damage multiplier and now stun zombies in place for 250 ms. Weapon push/knockdown is suppressed only for the swing, and the short AI/root-movement stun restores original flags after it expires. Repeated hits refresh the same lease.

The retail paired rush asks for **Light → Heavy → Grab → Light → Heavy → Grab**. Default inputs are LMB, MMB, G, LMB, MMB, G. Each label reads the current action binding; using the Grab binding here does not enable ordinary grabs. A fresh press is required inside each window. The original circular timing texture surrounds the current input; a shrinking ring approaches it and the full six-input sequence remains visible below.

| Contact | Original frame at 30 fps | Input window | Binding |
| --- | --- | --- | --- |
| Punch 1 | 56 | 400 ms | light |
| Punch 2 | 63 | 200 ms | finisher |
| Punch 3 | 77 | 400 ms | grab |
| Punch 4 | 85 | 233 ms | light |
| Punch 5 | 102 | 400 ms | finisher |
| Punch 6 | 110 | 233 ms | grab |
| Finishing kick | 143 | Automatic | None |

Successful prompts play existing punch feedback at their original contact. Earned damage is applied once at the final kick, preventing intermediate QTE punches from killing the victim and cutting off the pair. Each success contributes one sixth of the previous maximum payoff; missed inputs reduce that payoff. Six successes retain the previous total 3.75 coefficient and canonical Extreme Heat bonus. The original motion and recovery continue after the prompts, including failed prompts. Timing is adapted to PZ from the source motion and scene sound markers; it is not an imported Dragon Engine QTE state machine.

The player and victim follow bounded original source vectors while movement is locked. Paths are checked before and during playback. Equipment/style changes, invalid animation playback and interruption restore owned flags. Shared Heat Action protection grants invulnerability only during the action and targeting protection for another 500 ms. A surviving victim is knocked down at completion. The existing Extreme Heat aura and limb effects remain in use. PZ's normal camera is retained: the reference's cinematic close-ups are outside this Lua-only implementation.

## Verified retail source

The pair comes from `Yakuza 6/data/hact/h24010_100punchi.par`: `000.par/h24010_000_3.gmt` is Kiryu and `000.par/h24010_000_5.gmt` is the victim. Scene GUID bindings establish the roles, and the scene names three repeated-punch loops, kick and down sounds. Both original clips retain all 225 frames at 30 fps, lasting 7.4667 seconds. The former demo-era `h23590_3combo` conversion is replaced rather than retained as an alternate. Source hashes, heading normalization, vertical motion, hand conventions and bounded paired paths are documented in [motion provenance](heat-rush-assets.json).

The timing ring is the unchanged `btl_qte_gauge.dds` decode from the supplied Y6 UI archive. Runtime rotation of four textured quarters creates each full ring without generated graphics or upscaling. See [texture provenance](heat-rush-qte-assets.json). No artwork, audio recording or AI assets were created.

## Multiplayer and authors

The server requires an eight-input source-order proof and a validated final contact, an active unarmed style, current equipment, a live frontal target and clear source paths. It reserves one actor/target lease, checks source-time QTE inputs, calculates canonical damage and consumes each hit once. Client-supplied damage is ignored. Replays, wrong serials, stale sessions, late poses and missing participants cannot reapply the result. Remote victim animation and path updates contain no observer damage events. Typed target IDs keep players separate from zombies. Supplemental acknowledgements are matched to the source swing and bounded to 500 ms; the handoff waits for the final confirmed target and skips timed-out contacts. Existing client-owned Heat state remains client-owned.

`extremeLightAttacks` now permits 1..16 moves independently of normal light-chain length. Reusing the same move table for repeated entries avoids duplicate-node definitions. `finisherBranches=4` maps longer light chains back to the four authored normal finisher/charge branches. Weapon profiles do not inherit this unarmed setup.

`heatRush={hits=8,windowMs=700}` is DoD's transition configuration, and its enabled heatAction contains the supplied pair and QTE definition. The paired handler is registered for DoD only. Other styles can provide their own action handler and use the shared [QTE API](QTE.md) with their own assets, target rules, UI and server authorization. The framework no longer registers a barrage action kind or packet.
