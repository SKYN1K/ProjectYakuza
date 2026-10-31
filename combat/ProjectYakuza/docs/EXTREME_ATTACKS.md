# Extreme Heat rush combat (0.59.0)

Dragon of Dojima uses the four supplied Kiryu bct_ath_01 through bct_ath_04 clips for the first four Extreme Heat lights, then alternates the first two clips for an eight-input chain. Each fresh LMB press commits one native attack. Stopping input leaves that attack's original recovery intact. There is no automatic multi-contact attack.

Connect all eight lights, with no more than 1.2 seconds between confirmed hits, against eligible standing targets. If the eighth target survives, the chain flows into the paired three-hit finish. The current confirmed target is retained: this does not search for enemies, aim the player or enable soft targeting. MMB takes priority if pressed before the transition, retaining ordinary finishers. If targets die first, no heat action is performed on their corpses. This naturally makes the sequence more useful against durable zombies. A missed light breaks the confirmed-hit run.

Three short prompts ask for the configured finisher binding (MMB by default). Each needs a new press within its window; holding does not count. Successful prompts add the corresponding hit; failures add no damage. The full original motion continues, so failed inputs are not replaced with invented animations. QTE timing is adapted to PZ using source-motion contact estimates, not an imported Dragon Engine QTE state machine. The original 30 fps paired clip lasts 4.333 seconds. The contact frames used are 29, 40 and 65, with ten-frame input windows.

The player and target follow bounded original source vector tracks while movement is locked. Space and walls are checked before starting and throughout movement. Equipment/style changes, death, invalid animation playback or player hit reactions interrupt and release the locks. Other zombies can interrupt the sequence; it does not add player invincibility. The final successful prompt knocks a surviving target down after recovery. No cinematic camera override, new sound recording or generated graphical prompt is added.

## Source replacement

The removed automatic attacks used motion.par/gmt/P_KRU_BTL_SUD_bct_ath_sp.gmt and P_KRU_BTL_SUD_bct_ath_sp2.gmt. Their two converted animation files, two owners, eight observers, Lua modules, input configuration and network damage command are removed from the current payload. Historical releases retain their original contents.

The new pair comes from Yakuza 6/data/hact/h23590_3combo.par, entries 000.par/h23590_000_4.gmt (Kiryu) and 000.par/h23590_000_2.gmt (victim). Resource names identify m_kiryu/am_kiryu_1_c001 and ccm_com_suit_face_1_c001. The original 131 frames, scene-vector rotations and extracted movement paths are retained through approved non-AI retargeting, with native PZ hand/prop conventions. See heat-rush-assets.json for hashes and operations. No previous automatic attack is relabelled as this sequence.

## Multiplayer and authors

The server requires an eight-contact source-order proof, an active unarmed style, current equipment, a live frontal target and clear source paths. It reserves one actor/target lease, checks source-time QTE inputs, calculates canonical damage and consumes each hit once. Client-supplied damage is ignored. Replays, wrong serials, stale sessions, late poses and missing participants cannot reapply the result. Remote victim animation and path updates contain no observer damage events. Existing client-owned Heat state remains client-owned.

`extremeLightAttacks` now permits 1..16 moves independently of normal light-chain length. Reusing the same move table for repeated entries avoids duplicate-node definitions. `finisherBranches=4` maps longer light chains back to the four authored normal finisher/charge branches. Weapon profiles do not inherit this unarmed setup.

`heatRush={hits=8,windowMs=700}` is DoD's transition configuration, and its enabled heatAction contains the supplied pair and QTE definition. The paired handler is registered for DoD only. Other styles can provide their own action handler and use the shared [QTE API](QTE.md) with their own assets, target rules, UI and server authorization. The framework no longer registers a barrage action kind or packet.
