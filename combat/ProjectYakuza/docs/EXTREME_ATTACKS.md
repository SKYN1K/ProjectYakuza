# Extreme Heat boost combat (0.55.0)

Dragon of Dojima uses four supplied Kiryu `P_KRU_BTL_SUD_bct_ath_01` through `04` clips for its unarmed light chain during Extreme Heat. Press LMB after the fourth light to request the punch barrage; press MMB while aiming for the kick barrage. A fresh press is required, and the input buffer lasts 350 ms. Tiger Drop takes priority over the heavy input. Charged/ordinary finisher input remains available outside Extreme Heat. Weapons retain their separate movesets.

The punch barrage uses the complete `bct_ath_sp` clip and its 13 kind-68 BEP contact starts: 5, 10, 15, 20, 25, 30, 34, 40, 45, 50, 55, 59 and 64. The kick barrage uses `bct_ath_sp2`, with contacts 5, 14, 24, 32 and 40. Both sources are 30 fps and play at 1.15 speed; durations are about 2.55 and 1.74 seconds. These inputs adapt the source attacks to PZ; they are not a claim of identical Dragon Engine input/state logic.

## Contact and lifecycle rules

PZ's native SwipeStatePlayer records ATTACKED after its first AttackCollisionCheck. Repeating that event does not reliably produce a barrage. These two attacks therefore use a full-body timed action, reading the actual native animation track phase for source contacts. No Java bridge or game JAR edit is required. Ordinary boost lights continue through the existing native collision path.

Movement is locked for the barrage. Hit reactions, death, falling, climbing, entering a vehicle, changing held equipment/style, missing/restarted clips or a start timeout cancel it and restore previous movement flags. Releasing aim after starting does not truncate the source motion. Pausing suspends contact processing. Contacts more than 0.1 source seconds late are skipped to avoid a catch-up damage burst. The existing native hand-to-prop offsets are retained.

Each contact can hit up to three living, standing, frontal targets at the same level within 1.25 tiles. Live targets are reused; empty/invalid caches trigger a bounded local search. Source-frame contact indices are consumed once, including misses. Nonterminal hits use 0.28 (punch) or 0.5 (kick) of base token damage; terminal hits use 0.9 or 1.0 and knock down. Existing Extreme Heat damage is applied once while active. Fuel is charged once for the whole barrage. No heat is earned from barrage contacts after depletion.

An already-playing boost light retains its selected move if Heat ends. The next normal light restarts its normal chain. Barrages finish their original motion after depletion, losing the active-mode damage bonus; another barrage cannot start. The former reversing DoD variants and their asset/nodes have been removed. The generic optional extreme finisher-variant API remains available to other styles.

## Framework authors

`extremeLightAttacks` is an optional array matching the normal light-chain length. Give each move a globally unique nodeValue and a supplied animation/native owner node; `extremeHeat=true` enables the server mode-start gate. Weapon views do not inherit this array or barrageInput. Ordinary native collision, chain and quickstep-cancel markers remain required. DoD's boost lights use the existing moving-leg upper-body layering; barrages use the full source body.

`actions.barrage={enabled=true,variants={...}}` registers source-contact actions. Each variant requires animation, nodeValue, fps, speed, duration (wall-clock seconds), increasing integer contactFrames, range, damageMultiplier and finalMultiplier. `ProjectYakuza.BarrageRules.valid`, `time` and `damage` expose the shared validation/time/damage contracts. Mark mode-only variants `extremeHeat=true`; these built-in actions are unarmed and require aiming on start.

`barrageInput={afterLights=4,lightVariant="punch",heavyVariant="kick",bufferMs=350}` opts a style into the built-in input routing. Missing fields are not inherited from DoD. `barrageStarted(player,style,move)`, `barragePulse(player,move,index,context)` and `barrageFinished(player,move,completed)` provide lifecycle hooks. Remote pulse context is absent. Existing style sound keys provide impact/terminal feedback; no new audio is synthesized.

Register each clip in the network catalogue and generate event-free observer nodes for both repeat cycles. Barrage owner nodes select on PerformingAction and emit ProjectYakuzaBarrage=started/done. Use a fixed speed matching move.speed and no native AttackCollisionCheck events. Four native boost owners and two timed-action owners have 24 matching observers.

The server authorizes a bounded lease per action serial and validates source contact order/time, held item, style, target cap, range, facing, floor and path. Damage is calculated from shared definitions, never a client damage field. Depletion permits only the already-leased action. Cosmetic broadcasts are deduplicated per contact for sound and per target/result for hit effects. The framework's pre-existing client-owned Heat state remains client-owned. All participants need matching versions.

See boost-attack-assets.json for source GMT/BEP/rig/output hashes and all retained frames. No invented motion, image or audio assets are used. Offline checks cannot establish live animation quality or latency behavior; PZ remained closed.
