# Extreme Heat rush combat (0.74.0)

Dragon of Dojima uses the four supplied Kiryu bct_ath_01 through bct_ath_04 clips for the first four Extreme Heat lights, then alternates the first two clips for an eight-input chain. Each fresh LMB press commits one native attack. Stopping input leaves that attack's original recovery intact. There is no automatic multi-contact attack.

Perform the eight-input light chain; the first seven attacks may miss or hit different targets. Only the eighth strike must connect. Its last character target is selected, including confirmed supplemental contacts; an invalid final target does not fall back to an earlier victim. The target must survive, remain standing, be within the existing frontal/range rules and have clear paired paths. Eligible PvP players are supported while normal PvP, safety, faction, zone and protected-player checks remain enforced. No target search or soft targeting is used. MMB takes priority before the transition, retaining ordinary finishers.

Boost lights retain their 0.525 damage multiplier and now stun zombies in place for 250 ms. Weapon push/knockdown is suppressed only for the swing, and the short AI/root-movement stun restores original flags after it expires. Repeated hits refresh the same lease.

The retail paired rush asks for **Light → Heavy → Grab → Light → Heavy → Grab**. Default inputs are LMB, MMB, G, LMB, MMB, G. Each label reads the current action binding; using the Grab binding here does not enable ordinary grabs. A fresh press of the correct binding is required inside each consistent 400 ms window. Original Y6 ring textures rotate, contract, animate through their supplied atlas regions and flash briefly on acceptance. Only the current bound input appears; there is no extra ready message or input sequence overlay. The previous recovery-cancel handoff is restored, and both actors blend in over 80 ms. The next input appears immediately after the preceding valid press, while contacts retain their original source times.

| Contact | Original frame at 30 fps | Input window | Binding |
| --- | --- | --- | --- |
| Punch 1 | 56 | 400 ms | light |
| Punch 2 | 63 | 400 ms | finisher |
| Punch 3 | 77 | 400 ms | grab |
| Punch 4 | 85 | 400 ms | light |
| Punch 5 | 102 | 400 ms | finisher |
| Punch 6 | 110 | 400 ms | grab |
| Finishing kick | 143 | Automatic | None |

Successful prompts play punch feedback at their source contacts and a quiet confirmation sound. DoD aborts on the first missed prompt, plays the complete 21-frame Kiryu `bct_std_en` exit/recovery and releases the victim. This is an original recovery motion used as an abort, rather than a claim that it is Dragon Engine's original QTE-failure branch. Wrong inputs and held buttons do not count; missed prompts no longer silently play the successful ending.

The six punches and finishing kick retain their visible paired motion. The final native health hit is committed once after the victim clip completes, because a native Hit during the pair can replace/restart the zombie's hit-reaction animation. The previous maximum 3.75 coefficient and canonical Extreme Heat bonus are unchanged. Failure forfeits that final payoff; the preceding eight normal attacks keep their normal damage. Other styles can tolerate misses and retain a partial payoff with the framework's configurable failure policy. Timing is adapted to PZ from source motion and scene markers, rather than importing Dragon Engine's QTE state machine.

The player and victim follow bounded original source vectors while movement is locked. Paths are checked before and during playback. Equipment/style changes, invalid animation playback and interruption restore owned flags. Shared Heat Action protection grants invulnerability only during the action and targeting protection for another 500 ms. A surviving victim is knocked down at completion. The existing Extreme Heat aura and limb effects remain in use. PZ's normal camera is retained: the reference's cinematic close-ups are outside this Lua-only implementation.

## Verified retail source

The pair comes from `Yakuza 6/data/hact/h24010_100punchi.par`: `000.par/h24010_000_3.gmt` is Kiryu and `000.par/h24010_000_5.gmt` is the victim. Scene GUID bindings establish the roles, and the scene names three repeated-punch loops, kick and down sounds. Both original clips retain all 225 frames at 30 fps, lasting 7.4667 seconds. The former demo-era `h23590_3combo` conversion is replaced rather than retained as an alternate. Source hashes, heading normalization, vertical motion, hand conventions and bounded paired paths are documented in [motion provenance](heat-rush-assets.json).

The timing ring is the unchanged `btl_qte_gauge.dds` decode from the supplied Y6 UI archive. Runtime rotation of four textured quarters creates each full ring without generated graphics or upscaling. See [texture provenance](heat-rush-qte-assets.json). No artwork, audio recording or AI assets were created.

## Multiplayer and authors

The server requires an eight-input source-order proof and a validated final contact, an active unarmed style, current equipment, a live frontal target and clear source paths. It reserves one actor/target lease, checks source-time QTE inputs, calculates canonical damage and consumes each hit once. Client-supplied damage is ignored. Replays, wrong serials, stale sessions, late poses and missing participants cannot reapply the result. Remote victim animation and path updates contain no observer damage events. Typed target IDs keep players separate from zombies. Supplemental acknowledgements are matched to the source swing and bounded to 500 ms; the handoff waits for the final confirmed target and skips timed-out contacts. Existing client-owned Heat state remains client-owned.

`extremeLightAttacks` now permits 1..16 moves independently of normal light-chain length. Reusing the same move table for repeated entries avoids duplicate-node definitions. `finisherBranches=4` maps longer light chains back to the four authored normal finisher/charge branches. Weapon profiles do not inherit this unarmed setup.

`heatRush={hits=8,windowMs=700}` is DoD's transition configuration, and its enabled heatAction contains the supplied pair and QTE definition. The paired handler is registered for DoD only. Other styles can provide their own action handler and use the shared [QTE API](QTE.md) with their own assets, target rules, UI and server authorization. The framework no longer registers a barrage action kind or packet.

## Failure policy and feedback

DoD configures `failureLimit=1`, `failureMode="consecutive"` and a `qteFailure` recovery. Authors can set another limit or count total misses. Successful inputs reset consecutive misses. Individual `windowMs` and `binding` values remain configurable without altering the source motion. Feedback maps success, a tolerated miss and terminal failure to existing style sound cues at a configurable gain. See [QTE API](QTE.md), [failure motion](heat-rush-failure-assets.json) and [original animated prompt atlas](qte-effects-assets.json).

## Timed impact feedback and stable ending (0.74.0)

All six input windows are 400 ms. The explicit overlapping-window policy accepts the next sequential control before the previous punch's contact, and the UI advances on the accepted press. Holding a button or pressing a later role out of order cannot skip prompts. Impacts remain at source frames 56, 63, 77, 85, 102, 110 and 143.

Contacts alternate existing punch/heat impact sounds and stronger original spark presets; the final kick layers existing kick, heavy and heat impact sounds. Punches 1/3/5 request CombatLightAttack recordings and the finishing kick requests CombatHeavyAttack through the existing CVF adapter. The generic entry voice is skipped for this rush. The selected voice pack, Voices volume, provider cooldowns and busy-voice policy still apply; no pack or recording is modified.

The end clears the owned action clip and places surviving zombies directly into their native on-ground state, preserving the original victim facing opposite Kiryu. Deferred health settlement suppresses native push and delayed replicated hit reactions, avoiding another standing-hit/fall animation. Near-end track blend-out is treated as normal completion rather than an interruption. Extreme Heat lights suppress native stagger animation as well as force during their existing short in-place stun, preserving the original ignore-stagger flag on release.
