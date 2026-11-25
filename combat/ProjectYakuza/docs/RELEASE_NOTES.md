# v1.1.4

The movement controller ends travel when the actual animation track reaches the second footstep, so a faster animation clock cannot leave a trailing push.

The grab push ends when the second foot plants: original source frame 25 at 30 fps, about 0.833 seconds into the attempt. Foot and toe height traces identify the first right-foot plant at frame 15 and the second left-foot plant at frame 25. Travel is reduced to 0.7 tiles, preserving the current 0.84-tile-per-second speed while stopping about 417 ms earlier than 1.1.3.

The original 1.6-second animation and contact window remain unchanged. No forward push is added during the remaining recovery. Existing target clearance, collision, pause and multiplayer ownership rules remain. Original animation, model, texture and audio files are unchanged.

Offline checks verify the source footstep traces, all movement updates through the stop point, no trailing recovery movement, grab lifecycle and multiplayer authority. Live appearance still needs confirmation after restarting PZ.

# v1.1.3

Dragon's grab slide travels 1.05 tiles over 1.25 seconds. Compared with the previous 1.1424-tile slide over 1.6 seconds, forward speed increases by about 18 percent and the push finishes 350 ms earlier. The original 1.6-second animation completes with no extra forward push during its remaining recovery. Contact timing, target clearance, collision checks and animation speed remain unchanged.

Style authors may configure attemptMoveDurationMs separately from attemptDurationMs, and attemptDistance separately from the original motion data. Movement duration must be positive and no longer than the animation; an explicit distance must be finite, positive and at most two tiles. Omitting these fields retains the original motion's distance and animation-length travel.

Offline checks cover all movement updates through slide completion and recovery, invalid movement settings, grab lifecycle and multiplayer authority. No original animation, model, texture or audio files change. Live appearance remains to be checked in-game after a restart.

# v1.1.2

Grab initiation uses steady forward travel over its original 1.6-second duration and total distance. The animation's planted-foot pauses and the one-frame prediction limit no longer stop movement between updates. Collision checks cover the full pending displacement; each update submits one complete native movement request. Target spacing, interruption, pause handling and late-ownership protection remain.

Grab-hit returns begin 300 ms before source playback ends and blend for 240 ms while the outgoing tail keeps playing. Native percentage events select the holding pose before the source track ends. Paired placement follows samples of the actual eased native mixer with the outgoing tail still moving. The original animation clips and playback speed are unchanged.

Paired grab damage applies the configured amount without calling the ordinary weapon-hit reaction. This prevents a second native flinch from interrupting the victim clip. Single-player and server paths share the same damage helper; lethal hits finalize death once, and repeated MP contacts remain rejected.

Native checks cover live fade weights, four mixed midpoint poses, 100 return samples across two base poses, unchanged holding grips and owner/victim/observer selection. Lifecycle checks cover steady queued movement, contact timing, health changes without native flinch calls and one-time death. Offline checks do not establish the final live appearance or network timing; restart the game and update every MP peer.

# v1.1.1

Grab strikes hand off to the holding node directly from their native end event. Actor, victim and multiplayer observer selectors freeze their outgoing hit pose during the existing 240 ms return fade. The Lua controller recognizes a completed native handoff even if the new hold-start marker has already replaced the strike-end marker. Repeated multiplayer victim-pose packets cannot re-enter the same finished strike phase.

Forward grab reach follows the original footsteps between repeated animation timestamps. Prediction is limited to one source frame and remains bounded by the original travel curve, target spacing and collision checks. Pausing preserves the sampling clock; delayed ownership never adds a catch-up jump. Original clips, animation speed, hit timing, damage and reach distance are unchanged.

Validated offline with grab lifecycle, multiplayer and native selector/handoff checks. No game session or new visual/audio assets were produced. Live single-player and multiplayer appearance still needs confirmation after restarting PZ.

# v1.1

Sandbox options display the Project Yakuza page, readable Dragon (DE) Tiger Drop controls, Heat Actions, Grabs and Extreme Heat, with their full tooltips. Translations now use the installed Build 42 JSON format. This also restores the existing readable mod-option and sound labels. IDs, enabled defaults, timing limits and cooldown defaults remain unchanged.

Multiplayer grab and Heat Action requests carry their current validated combat snapshot. The server can approve an intent when its separate state update has not arrived, and uses the supplied unit aim direction rather than a delayed character-facing update. Equipment ownership, sandbox switches, heat costs, combo state, target range, collision paths, event ordering and victim leases still apply. Update the host/server and every client to 1.1, then restart them.

Version metadata, player ZIP and Workshop upload folder use 1.1. Player packages retain vanilla bat, katana and knife Heat Actions; custom objects and development instructions remain excluded. No animation, model, texture or audio assets change.

Offline validation includes the native translator and sandbox parser, production client-to-server request tests, Kahlua compilation, Heat Action lifecycle checks, runtime filtering and package privacy checks. A live multiplayer session was not launched; verify real host/client triggering after updating all peers.

# v1.0.14

Holding and walking grips fit the original native palm to an upper-collar mesh surface instead of aligning the wrist to the neck bone. The holding torso uses stable native parent transforms; original torso and right-arm motion remain, while a two-bone fit keeps the left palm at the contact. The victim chest retains its original grip pose during standing and native walking. Seven existing clips retain their original identifiers, source frame counts and 30 fps timing. No artwork, textures or audio changed.

Grab strikes keep their original animation clips, speed, damage frames and single-hit policy. Source skin contact points determine their paired placement. The return to hold now uses a matched 240 ms fade for both bodies, with contact curves sampled from the native AnimationPlayer blend. Walking stays locked until the outgoing full-body strike has faded. One fresh strike or Heat Action input during this return is queued and consumed after recovery, preventing a new hit from cutting off the fade. Pause preserves the remaining return time.

Offline checks cover 210 native standing/walking palm placements, 100 native return frames across two base poses, source frame preservation, grip constraints, recovery movement locks, queued input, pause and multiplayer authority. The measured native grip discrepancy is below 0.000004 tiles for these reference bodies and poses. An approved offline preview uses supplied PZ male/female bodies. Live clothing, different character models and network latency still need gameplay verification; PZ was not launched.

# v1.0.13

Grab strikes follow the dominant visible animation track, preventing a faint restarted or fading track from moving their clock backward. Ordinary attack effects retain their existing track policy. Grab strikes use separate strike1..strike4 completion markers. The controller handles a matching end marker before reading an animation track, so a restarted or fading non-looping track cannot keep the completed strike active. A near-end track rollback also returns to hold, while strike placement never rewinds. Delayed markers from a different strike are ignored. Damage remains limited to one original source contact per accepted strike; frames and animation speed are unchanged.

Holding now uses the character's normal world aim direction instead of the animation-facing direction. Both characters share that axis, and each strike retains the axis captured at its start. Control polling and authoritative grab poses reassert the paired facing; native damage immediately restores victim placement. Paired actor/victim nodes disable additional native torso twisting, preserving the original full-body strike masks and source clips.

Offline regressions cover repeated/fading tracks, stale completion markers, all four strikes, distinct aim/animation directions in eight headings, authoritative timing, native selector isolation, source placement and original media hashes. PZ was not launched; visible blending and cursor alignment require gameplay verification.

# v1.0.12

The four grab strikes restore their established full-body animation nodes for the owner and multiplayer observers. Source clip frames, speed and collision timing remain unchanged. Instead of changing the actor skeleton, the held zombie follows a per-frame hand/collar placement curve derived from each original paired clip. The 120 ms handoff blend remains. The incompatible grab-strike hand-trail parent overrides are removed with the masks they belonged to.

Stationary and walking holds restore the centered 0.48-tile forward / 0.019354-tile lateral placement. The large side offsets from 1.0.10 are removed. The open-space Heat Action placement fix and native forced-aim ownership remain.

Grab reach uses the original in-place clip's planted-foot timing rather than a fixed 0.28-tile ease-out. A clear miss travels about 1.1424 tiles across the original 1.6-second attempt/recovery. Movement uses collision-checked steps of at most 0.04 tiles, preserves nearby-target clearance, stops at attachment or obstruction and skips late samples instead of catching up. Contact still resolves only in original source frames 10-12.

Heat Action tint increases from 20 to 36 percent maximum opacity and shake from 7 to 12 zoom-scaled pixels. Shake now updates both current and previous camera position samples and remains applied through the tint draw until render completion, with guarded restoration and existing map/pause/ownership cleanup. These changes address weak or smoothed-out camera motion; live appearance still needs gameplay verification.

Offline validation covers all source placement frames in eight headings, authoritative/client timing, source footsteps and collision/pause handling, restored native owner/observer selectors, original animation hashes, native camera APIs, screen-effect cleanup and hand-trail parent selection. No model, motion, image or audio assets changed. PZ was not launched.

# v1.0.11

Grab-strike hand trails now use the same native parent frame as their corrected animation masks. Existing numeric source curves remain unchanged. Native layered-pose checks now include all four grab strikes alongside standing/walking and mixed-pose light attacks. This release includes the early reach, stable grip/strike staging and open-space placement fixes described below.

# v1.0.10

Grab reach movement starts on the first visible source frames and eases forward over 240 ms, before contact at frames 10-12. It no longer waits until the miss is known. The 0.28-tile cap, small collision-checked increments, pause handling and no late-frame catch-up remain. A nearby target limits approach clearance without being acquired or frozen before source contact.

Stationary and walking grip offsets now use the actual masked native pose. Their transition is shared by client and server. Grab strikes retain the native root, pelvis and lower spine while playing the original upper-body and leg joints, keeping their original speed and contacts. Twelve owner/observer nodes share these masks. Dragon strike phases retain the held victim root instead of moving it between unrelated source offsets. Native no-knockback damage temporarily suppresses default staggering and restores its previous permission even on failure.

The open-space Yakuza 5 sacrifice throw now derives its scene axis from the original initial actor/victim separation and the held pair. This keeps the actor in position and the victim on the held side instead of reversing their placement. Wall placement remains unchanged. Held-target validation retains ownership, range and path checks without applying the ordinary unheld frontal cone to an already acquired victim.

Offline validation covers early reach motion, four-heading movement, obstacles, pause, eight-heading open-scene placement, stable strike roots, transient hit-reaction suppression, MP leases, 804 native parent-transform checks and original clip hashes. Source animation frames, speeds, damage/contact timings and Heat costs are unchanged. PZ was not launched; live animation blending and networking still require gameplay verification.

# v1.0.9

Running attacks use a 160 ms moving run-up and a 180 ms early-input buffer. An 80 ms sampling grace tolerates a duplicate update with no displacement without granting idle run-up. Accepted actions can submit their native swing in the same update; transient native readiness can retry only inside the original input deadline. Releasing aim, losing eligibility, changing floor or teleporting discards the buffer. Holding an attack cannot repeat it. Light running recovery accepts aim input at the existing source recovery marker; the dropkick retains its committed landing recovery.

Dragon's three light running strikes deal 1.25 times native damage with a 0.55 backward stagger. The dropkick deals 1.75 times damage with a 0.85 knockdown. Original native Strength/exhaustion calculations, stamina costs, animation speeds, travel curves and collision windows remain in use. Confirmed contacts use existing punch/heavy or kick impact pools once per swing, including crowds. No hit awards feedback on a miss.

Failed grabs take a wall-checked forward step of up to 0.28 tiles, from the end of the source contact window through 800 ms. Successful attachments and pending MP approvals do not receive this movement; late denials cannot cause a delayed lunge. Holding a Dragon grab now owns native forced aim and temporarily disables run/sprint, keeping combat movement after RMB release. Cleanup restores the prior forced-aim and movement permissions, including restrictions owned by other features.

Heat Action tint increases from 12 to 20 percent maximum opacity and shake from 5 to 7 zoom-scaled pixels. The impact tail lasts about 0.49 to 0.62 seconds, with the existing 120 ms anticipation. Camera/blend restoration, local ownership, pause/map/menu suppression and the no-spark policy remain intact.

The playlist display title Receive You Ver. 7 is now Rolling Eyes Fall Down the Dragon Wall. Its sound ID and recording are unchanged, preserving saved favorites. Offline checks cover input/lifecycle, damage restoration, authoritative reaction profiles, feedback deduplication, native control APIs, grab source playback and bounded screen effects. PZ was not launched; final feel and multiplayer movement need gameplay verification.

# v1.0.8

Music adds saved shuffle, Repeat Off/All/One and song favorites. Defaults preserve ordered manual listening and shuffled combat playback until Shuffle is explicitly changed. Shuffled playback visits every song before refilling and avoids an immediate repeat; Previous follows the actual playback history. Repeat One affects natural completion, while an explicit Next still changes songs. Repeat Off ends at the playlist or shuffle-bag boundary. Original audio bytes, gains and combat fade timing are unchanged.

Grabs confirm attachment once, with the existing supplied grip cue and a brief GRAB CONNECTED notice. Failed reaches show MISSED GRAB without an impact sound; multiplayer waits for ownership approval before reporting an outcome. Held prompts show the current strike and throw bindings. Notices remain visible briefly after releasing aim and hide behind the map or menu.

Near-simultaneous standing flinches share a 90 ms restart gate, including different source clips. A short stable-exit grace preserves reaction continuity across native hit-state handoffs. Stuns, native knockback, floor states, juggling and paired scenes keep priority. Damage, hit force, original motion, contact timing and grab spacing are unchanged.

Offline Kahlua checks cover shuffled exhaustion/refill, actual history, repeat modes, saved preferences, failed-channel replacement, grab outcomes/cleanup, aim-independent notices, reaction continuity and MP authority. Runtime package/privacy and source-comment checks are required before publication. PZ was not launched; live feel and networking still need gameplay verification.

# v1.0.7

Music exposes local playback controls and a read-only current-track snapshot for interfaces and style add-ons. The included playlist now carries the original artist, album and complete recording duration for all twenty supplied songs. The corrupted Kiwami title is replaced with a readable title. Audio bytes, gains and normal combat fade timing remain unchanged.

Manual playback runs the equipped style playlist outside combat, advances in playlist order and supports previous/next selection. Stop suspends automatic restart until Play, Auto or a style change. Auto returns to the existing combat lifecycle. Replacement playback stops the previous owned channel only after the new channel starts successfully. Elapsed progress is estimated from the playback clock and excludes observed game pauses; arbitrary timestamp seeking is not exposed by the Lua interface.

Grab holding and walking now mask only the upper spine and props. The native root, pelvis, lower spine and legs retain their native transforms, addressing the reported whole-body sideways tilt. Hold distance increases from 0.291238 to 0.48 tiles to reduce body overlap. Existing source animation bytes, grab contact windows, strikes and throw timing are unchanged. Final visual grip placement still requires live verification.

Validation covers playback selection, wrapping, channel replacement, manual/automatic ownership, pause, natural completion and cleanup; original source music metadata; native holding-root and leg preservation; grab and multiplayer regressions. PZ was not launched.

# v1.0.6

Grab attempts use the complete original Yakuza 6 failed-reach and recovery motion. The original BEP frames 10–12 determine when a target can connect; success branches to the paired entry, while misses play the full 1.6-second recovery. The holding mask now owns the complete arm parent chain without replacing native walking legs. Hand/neck spacing removes the extra gap. Holding maintains the combat stance after RMB release and restores native aim input on cleanup, including MP grant/cancel paths.

Heat Action tint and shake begin up to 120 ms before contact and last roughly 0.4–0.52 seconds afterward. Repeated hits preserve the preceding tail during anticipation. Cancelling an unconfirmed contact clears its effect. Damage, source animation speeds, audio contacts and the existing Extreme Heat blood effect are unchanged.

The health bar uses the existing silver frame with fixed end caps and a gray left backing. HUD scale is configurable from 50 to 200 percent under Presentation. Health, heat, cooldowns and their text scale together, fitting both viewport dimensions; quickstep charges stay beside the label and its READY/countdown remains right-aligned.

Validation: Kahlua lifecycle, MP authority, HUD/option/layout and impact-envelope checks; native animation/XML selection and camera APIs; 49 original grab-attempt frames and 1,666 retarget body transforms; twenty mixed hold/walk hand transforms. Original texture/audio bytes remain unchanged. PZ was not launched; live appearance and performance still need gameplay testing.

# v1.0.5

Grab entry blends the victim from its actual position into the full forward/lateral grip offset over 180 ms, shared by the client and server. This removes the fixed distance-per-tick approach and final side snap. Delayed grants recheck range, facing, visibility and walls. Pausing preserves entry/approval clocks, and a finished miss releases controls promptly even if its animation track disappears.

Grab reaches use a soft supplied arm whoosh at contact, including misses. Fully charged strikes use a distinct supplied Heat impact; partial charges retain the heavy impact. Tiger Drop layers the existing guard-break transient with a heavy confirmation. Simultaneous guard contacts share a short audio gate to avoid crowd clipping. Existing volume controls and source audio remain unchanged.

Standing hit reactions now choose among existing source clips by contact family: punches, kicks, blades and blunt weapons. Selection varies by swing and victim; the server sends the selected registered clip to owners and observers. Native knockback, knockdowns, Extreme Heat stuns, grabs and paired cinematics retain priority. Blocked/no-damage SP hits cannot force a flinch. Damage and hit-force tuning are unchanged.

Validation includes grab cadence/placement, pause and obstruction recovery, MP grants and reaction replication, reaction-family/clip whitelists, confirmed-hit gating, feedback selection and duplicate suppression. Native importers verify all reused reaction/grab clips and original sound definitions. No animation, texture or audio bytes were generated or changed. PZ was not launched; live feel still needs gameplay testing.

# v1.0.4

Heat Action impacts now briefly tint the full viewport and shake the local camera. Camera offsets apply on the simulation tick before world rendering and restore before UI drawing, with an after-render fallback. Strength and decay scale with the contact. Map/menu screens, pause, death, disabled hit effects, remote actors and split-screen suppress the treatment. Chromatic aberration is omitted. The unwanted Extreme Heat contact spark stays removed; existing blood and limb trails remain.

Dragon grab attempts play the existing half-second reach animation on hits and misses. A victim is searched and acquired at 200 ms of source animation instead of being immobilized on keypress. Misses and interruptions restore movement without touching victims. Multiplayer grants continue the same reach; denials, timeouts and late grants cannot start a surprise grab. Existing held movement, strikes, throws and Heat Actions are preserved.

Validation covers native camera access, rectangle rendering, blend restoration, viewport sizes, cleanup, grab contact timing, misses, interruptions, server grants, duplicate/late replies and existing grab/MP behavior. No visual/audio assets were generated or changed, and PZ was not launched. Live appearance remains to be tested in game.

# v1.0.3

Removed the cinematic screen tint, camera shake and contact-local RGB spark together. Genuine full-screen chromatic aberration requires graphics controls not exposed to this Lua mod. Extreme Heat and its QTE sequence now use the existing blood impact effect without an added energy/contact spark, including multiplayer observers and contacts after fuel depletion. Ordinary non-Extreme hit effects and limb trails retain their existing behavior.

Validation: production blood and impact tests cover owner/observer blood-only routing, original victim anchors, no replacement spark allocation, normal-hit preservation and cleanup. The player package excludes the retired screen-effects module. No assets were generated or modified, and no game was launched.

# v1.0.2

Default music volume is now 45 percent. Saved volume choices remain unchanged. Mods settings show Project Yakuza options, Volume sliders, Music volume, Hit volume and Voice volume even before translations are available.

Extreme Heat activation uses reliable native emitter playback and lets the original windy whoosh play through its swell instead of fading it out at the flare. Charging heavy attacks now have supplied start, full-charge and release sounds. Existing source waveforms are unchanged.

Vanilla shoves are disabled while any style is equipped, independently of the quickstep binding. Unequipping restores the previous native permission. The HUD now stacks styled Quickstep and Tiger Drop recovery counters below the heat display, with quickstep charges, countdowns and progress bars. Low-health flashing has stronger fill contrast and a clearer red frame glow.

All four normal Dragon rush links now use each original Yakuza 6 BEP follow-up opening instead of a uniform 58 percent recovery marker. The latest authored opening is selected conservatively; collision checks, animation speed and source clips are unchanged.

The style item is now Dragon (DE) - Project Yakuza, with internal ID ProjectYakuza.Dragon_DE_Style. Its existing icon fills more of the equipped-hand circle without changing inventory icons or image bytes. The redundant text Heat counter is removed. The HUD is 20 percent larger, the health bar is 25 percent longer, and cooldown rows adapt to viewport size and font height. Quickstep charges sit beside the ability name; countdown/READY remains right-aligned.

Extreme Heat passive stock lifetime is 10 percent longer: 4.125 seconds per orb, or 24.75 seconds for six full orbs before attack and damage costs. Combat music now waits 22 quiet seconds before fading. The Heat Action screen-effect hook uses the registered OnRenderTick event instead of nonexistent OnPreRender.

Validation: focused combat, audio, HUD, settings, item lifecycle and multiplayer checks; 27 viewport/font combinations; 88 player Lua files compile; 126 release-profile checks; native rush timing and audio checks. Package privacy and installed bytes are verified offline. No game launch.

# v1.0.1

Added a local Zombie Encounter Intro toggle under Options > Mods > Project Yakuza > Presentation. It defaults to enabled; disabling it closes the current title, cancels pending counting and suppresses future intro titles and cues. The preference persists between sessions.

The running dropkick now coats and trails both legs using separate native foot paths, including multiplayer observers. Both effects share the animation clock and retain independent history and cleanup.

Running light attacks and quickstep attacks now use the Light Attack binding. The running dropkick and Tiger Drop use Heavy Attack / Finisher. Tiger Drop takes priority on a correctly timed heavy press; otherwise heavy/finisher input keeps its normal behavior. Their four separate binding settings have been removed.

Control settings now display readable names such as Light Attack keybind type and Light Attack keyboard bind, including a fallback when translations are unavailable. Existing Light Attack and Heavy Attack / Finisher assignments are preserved.

Validation: native ModOptions persistence and 1,068 encounter-toggle/lifecycle checks; input checks; fresh native 257-pose dropkick import; 23,424 native projection cases; 48,804 effect tracking/lifecycle/observer checks; player-package compilation and privacy checks. Existing texture hashes are unchanged. The full Gaiden archive pixel recheck is unavailable because its source archive is no longer installed. No game launch.

# v1

Project Yakuza is a Lua combat framework for independent fighting-style add-ons for Project Zomboid Build 42. This release is version 1.0.0, Lua API 3 and multiplayer protocol 2.

## For style creators

Install the B42 runtime ZIP, then use the repository's starter add-on and style-authoring guide. Register shared style definitions, provide matching native animation nodes, and keep your add-on under its own mod ID with require=ProjectYakuza. Observer registration supplies multiplayer presentation; new gameplay mechanics still need server validation.

- [Style authoring](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/STYLE_AUTHORING.md)
- [Lua API reference](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/API_REFERENCE.md)
- [Starter add-on](https://github.com/SKYN1K/ProjectYakuza/tree/main/combat/ProjectYakuza/templates/StyleSubmod)
- [Testing and packaging](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/TESTING.md)

## Reference implementation

Dragon of Dojima demonstrates combo/finisher routing, charged attacks, quicksteps, guard, counters, grabs, paired Heat Actions, Heat, effects and style-owned audio. The player build retains vanilla bat/club, blade and knife profiles and supported bat, katana and knife Heat Actions. Experimental custom-object content and voice packs are excluded.

## Downloads

Use the named B42 ZIP for local installation or the Workshop ZIP for upload preparation. The mod metadata and package filenames use version 1.0.0 (v1). GitHub's automatic Source code archives contain developer material and are not player packages. Server and clients need matching framework and add-on versions.

[Workshop guide](https://github.com/SKYN1K/ProjectYakuza/blob/main/docs/WORKSHOP.md) ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· [Controls](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/CONTROLS.md) ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· [Validation coverage](https://github.com/SKYN1K/ProjectYakuza/blob/main/combat/ProjectYakuza/docs/VALIDATION.md)
