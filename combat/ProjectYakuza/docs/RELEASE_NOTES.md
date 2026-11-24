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
