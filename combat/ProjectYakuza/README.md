# Project Yakuza 0.28.0

## Clean rename and temporary grab disable

All active namespaces and asset references use ProjectYakuza. Enable **Project Yakuza** and equip its new fighting-style item; old identifiers are not recognized and settings start in the new entry. Grabs are temporarily disabled on clients and servers. The separate voice pack is unchanged and needs its own namespace update before its combat recordings are usable here. See [release notes](docs/RELEASE_NOTES.md).


## Multiplayer repairs 0.27.1

Multiplayer style items now originate in the server inventory; combat waits for native item delivery and a matching ID acknowledgement. This repairs the null-weapon native attack/zombie-hit packets seen in the co-op log and also migrates already-equipped client-only tokens after reconnecting. Re-select the style once after installing if necessary.

Quicksteps send bounded position/facing samples every 50 ms, including an unthrottled final sample. Observers interpolate these while native movement continues to synchronize. Server distance/path checks and the three-per-15-seconds quota also apply to this stream. Same-tick state transitions are retained, and alternating event-free observer nodes restart repeated animations correctly. Zombie reactions now enter the native hit state, cover its repeat-hit group, and briefly queue updates that precede zombie streaming.

Install 0.27.1 on the server and every client, then restart them. Protocol v2 and the new observer conditions require matching versions. Validation is offline; real two-client latency and appearance still require a playtest.

Project Zomboid Build 42.21. Dragon of Dojima uses Kiryu's four light attacks, four finishers and four double-finisher follow-ups from Yakuza 6. Common-enemy animations supply standing zombie hit reactions during this style's combat.

## Controls, effects and audio 0.27.0

Options > Mods > Project Yakuza now contains Music, Sounds and combat-only Voices sliders, plus bindings for all thirteen combat actions. Choose a mouse button, or select Keyboard and set its key. Native PZ aim, movement and run bindings remain in PZ settings. Space is the default quickstep key; Shift no longer quicksteps. Quicksteps are limited to three starts in a rolling 15-second window.

Taunt completion uses short-lived Kiwami 2 particle wisps and sparks rather than a large glow. Extreme Heat activation supports the existing CVF activation voice entry and can briefly retry a busy provider. The style selector uses a larger original Kiwami crop at native pixel resolution. See [release details and validation](docs/RELEASE_NOTES.md).

## Kiwami 2 taunt and brief aura pulse 0.26.4

RMB + Q now plays the supplied Kiwami 2 `P_KRU_BTL_SUD_rct_pvk.gmt` at its original speed (55/30 seconds, approximately 1.83 s), replacing the Kiwami 1 taunt. Movement stays locked until the actual animation end marker and then restores the prior movement flags. Interrupted playback gives no heat or flash; a completed taunt still gives one stock, except during Extreme Heat.

The completion effect now uses the ordinary four aura sprites, with the same size, anchors and animation frames. A single shallow brightness pulse peaks at 12% additive opacity and lasts only 180 ms. It creates no taunt-only sprites and never advances their animation twice in a frame. The previous fast taunt wisps are removed; Extreme Heat keeps its separate existing layers. Pause and MP completion synchronization remain supported. All textures and audio assets are reused unchanged.

## Relaxed combat idle 0.26.3

Combat idle now takes Kiryu's upper-body motion from the supplied `P_KRU_BTL_SUD_stdB_lp.gmt` instead of the high-guard `stdA_lp` stance. Standing and moving retain the same 12-second upper-body loop, existing 0.28-second blends and native Zomboid leg movement. The separate X/block stance, attack animations, damage, sound balance and effects remain unchanged. This retargets a supplied animation; no graphical or audio assets were generated.

## Sound balance and softer taunt glow 0.26.2

Hit sound clips (punches, kicks, heat impacts, throws, finishers and guard breaks) now use 75% of their previous scripted volume. Swing, heat-gain, activation and music levels remain unchanged; the existing hit-volume slider still applies.

Dragon of Dojima's combat voice mix increases from 1.5 to 2.25 (another 50% over 0.26.1). Quickstep voice cues remain disabled. The taunt-completion flash uses a lower additive strength (0.25 instead of 0.55) and a slower, shallow pulse to reduce harsh brightness. It still triggers only on successful completion. Normal and active Extreme Heat aura settings remain unchanged. All audio/visual assets are byte-identical; only code and sound-script mix values change.

## Attack fix, Kiwami taunt and completion glow 0.26.1

Fixes the native attack permission accidentally held off by shove-to-quickstep. The shove key blocks native shoving only while held. Light attacks, finishers, running attacks and quickstep attacks submit through a shared helper that temporarily lifts only this mod's shove gate and restores it even after an error. Other permission restrictions remain intact.

RMB + Q (the current shout binding) now plays Kiryu's original Kiwami `P_KRL_provoke.gmt` from `media/data/motion/BattlePlayerKiryu.par`: 1.6 seconds, original speed, full movement lock. Successful completion awards one heat orb, capped at six; interrupted or failed playback awards nothing. Extreme Heat cannot gain heat. Releasing aim cannot leak a shout. Native shouting remains available outside aimed style use.

Only successful taunt completion triggers the extra glow/flash (about 0.7 seconds); it is absent during the taunt animation. The regular heat aura and brighter Extreme Heat aura retain their existing conditions. A bounded completion serial synchronizes the flash without repeating it on MP heartbeats or flashing for cancelled taunts. All effect textures are reused.

Dragon of Dojima combat voices use a 1.5 native handle volume multiplier (50% louder); plain quicksteps have no CombatSpecialMove voice. Quickstep attacks still use attack voices. No recordings are altered, replayed twice or newly generated.

## Optional character combat voices 0.25.0

Custom Voice Framework 1.1+ can now supply the selected character's light, heavy, special, taunt, Extreme Heat activation, stance entry, getting-hit and stun voices through eight reserved Combat-prefixed entries under ProjectYakuza. Hooks run only for the owning player; CVF handles playback, policy, cooldowns and native MP transmission. Missing recordings stay silent. No voice/audio assets were added, and CVF remains optional. Dragon of Dojima now calls CombatTaunt once when its taunt animation starts; missing audio never prevents the taunt. See [integration and pack-author guide](docs/CVF_COMBAT_VOICES.md) and [the exact manifest entries](templates/CVFCombatLines/lines.json).

## Extreme Heat controls and shove quicksteps 0.24.0

N now activates Extreme Heat without manually cancelling an active mode. Hits and framework heat additions cannot bank/refill heat during Extreme Heat. The shove key (Space by default, respects rebinding) triggers a quickstep while the style is equipped, including without RMB: movement chooses direction, no movement steps backward. Shift + RMB + direction remains available. LMB ground attacks keep their native authorization. The style item's inventory icon is a byte-identical copy of the existing Kiwami Dragon selector icon. Existing activation/end SFX remain; no voice cues were added. The pending Mods-label formatting and common-folder fixes are included; no memory configuration was changed. See [controls and sound notes](docs/EXTREME_HEAT_AND_SHOVE.md).

## Multiplayer synchronization and Mods audio controls 0.23.0

Adds nearby-player style/heat snapshots, observer animation nodes without collision events, remote world auras and impact/reaction effects. Native primary damage stays on PZ's hit protocol; supplemental victims, throws and Tiger Drop use checked server requests. Grabs reserve one zombie on the server and restore its AI on release, timeout or disconnect. Temporary Extreme Heat protection has a bounded server lease. Options ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Mods ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Project Yakuza now contains grouped combat music and hit-volume sliders, using the native ModOptions persistence and GameSound user levels.

Install the same version on the server and every client. This release passed offline protocol, native animation-parser and single-player regressions. It has not been validated in a live two-client session; paired movement, death ownership and latency-sensitive counters require that integration check. See [multiplayer notes](docs/MULTIPLAYER.md).

## Four-way style selector 0.22.0

Hold Z on foot, move the mouse toward a slot (or use arrow keys), and release Z. Left is Style 1 (Dragon of Dojima by default); right is Style 2 (empty by default). Top is empty; bottom opens the slot assignment menu. The assignment menu lists every registered framework style and saves both slots per character. Empty slots do nothing. Combat, chat entry, pause and vehicles prevent opening/switching. Existing Kiwami circular-frame and Dragon textures are converted losslessly, with no generated artwork. See [selector controls and authoring](docs/STYLE_SELECTOR.md).

## Combat sound balance 0.21.1

Punch-impact playback is 15% quieter. Orb-gain and final-orb/full cues are 30% louder. Changes use playback volume only; original audio files are unchanged. Sound toggles are replaced by PZ's native Options ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Audio ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Advanced sliders under Project Yakuza - Effects and Dragon of Dojima - Music. Separate Extreme Heat activation effects (`battle_common/hactmode_on`, two layers) are already wired. The local voice bank also contains `gv_fighter_kiryu/boost_on`, a candidate activation voice; it has not been added.

## Style API and expanded playlist 0.21.0

Dragon of Dojima now owns a 19-song playlist made from the supplied recordings. If a song finishes during ongoing combat, another song starts without immediately repeating it. Other styles have independent music, sounds and optional heat/effect profiles. API 1 provides validation, style action/input hooks and registration events. See [style authoring](docs/STYLE_AUTHORING.md), the inactive [submod starter](templates/StyleSubmod/README.md) and [release details](docs/PLAYLIST_AND_STYLE_API.md). No new visual or audio content was generated.

## Original Yakuza audio and movement fixes 0.20.0

Combat now uses original Kiryu impact, swing, grab, guard-break and heat sounds extracted from the supplied Yakuza 6 banks. Heat gain/full and Heat Mode on/off have their own cues; Heat Mode preserves the original second-layer delay. Held zombies now commit current/next/render positions together after collision checks and follow the player's rendered facing, including after zombie updates. Extreme Heat activation disables deferred movement, clears momentum and holds its entry position; the previous movement setting is restored afterward. X guard now leaves native Zomboid leg movement available in every phase. See docs/YAKUZA_AUDIO_AND_MOVEMENT.md.

## Walking grabs, impact polish and animated Extreme Heat 0.19.0

Once a grab is established, movement keys walk with the held zombie. Kiryu's original paired grab-walk clips supply the upper-body motion; player legs use native PZ locomotion, and the victim's idle/four-direction walking legs use native PZ clips. MMB aligns the paired roots and current facing before locking the throw. Impacts are now small animated bursts of the existing centred glint texture, with fixed anchors during scaling and no corner-origin fan. N randomly chooses one of four Kiryu Extreme Heat activation clips; movement is locked and temporary native protection prevents zombie attacks during that clip. Protection is restored afterward or on cancellation; heat is committed only on successful animation completion. Extra existing-game impact/rustle cues and brief action feedback are included, with a sound toggle in the combat-style menu. No graphical assets were generated or changed. See docs/WALKING_GRABS_AND_HEAT_ACTIVATION.md.

## Dashes, multi-hit and playlist 0.17.1

Quicksteps move 1.5x farther with 25% faster animation playback. Every current attack can hit up to three eligible nearby targets, including stomps and Tiger Drop, without changing global sandbox options. Existing world-rendered hit sparks are 10% more opaque. Bring It On and Receive You Ver. 7 join Funk Goes On in the random combat-entry playlist; the chosen song stays throughout that encounter. See docs/DASH_MULTIHIT_AND_PLAYLIST.md.

## Guard, grab/throw and original-particle polish 0.18.0

Aim with RMB; hold X to guard, tap G to grab/release, and tap MMB while holding a zombie to throw. N now toggles Extreme Heat. Guard consumes stamina, covers frontal standing bites, and breaks on exhaustion. One short single-player grab uses Kiryu's paired player/victim entry, hold and throw clips; release aim, take damage or exceed the hold limit to escape. No launcher or Java changes. G's vanilla safety callback is suppressed only while aiming with this style equipped. The original spark/glint textures replace the old generated hit-frame sequence in the active world renderer, with a larger finisher flash and existing PZ impact audio. A small original-atlas Tiger Drop ready/cooldown indicator sits under the heat HUD. See docs/DEFENSE_AND_PARTICLE_POLISH.md.

## Tiger Drop 0.17.0

RMB + a fresh MMB press counters a standing zombie in front of you during the final 0.2 seconds before its bite hit. A successful counter instantly kills that attacker, plays Kiryu's original Tiger Drop animation and applies strong outward Lua knockback. Cooldown: 60 seconds; missed timing does not consume it. Existing MMB finishers remain available outside the counter window. Normal game launcher retained; this is an approximation of a launch, without direct ragdoll impulse control. See docs/TIGER_DROP.md for timing, limits and validation.

## HUD polish and six heat stocks 0.16.5

Each of the six orbs now holds one real heat stock. Confirmed-hit heat gain is 75% slower, and full-meter Extreme Heat lasts 22.5 seconds before attack/damage costs (25% longer). The same original atlas pixels now use eased source crops, continuous glow timing and a smoother activation flash. The character aura remains unchanged. See docs/HUD_POLISH_AND_SIX_STOCKS.md.

## Aura fade-in 0.16.4

The character aura now eases in over 0.35 seconds whenever it appears. Pausing holds the fade and ordinary heat updates do not restart it. Size, textures, color, anchors, animation timing and the HUD are unchanged. See docs/AURA_FADE_IN.md.

## Character aura top edge 0.16.3

The character aura now has transparent headroom and a soft top fade. Its current enlarged size, body anchors, colors and animation timing are preserved. Native projection, lower-image byte comparisons and the full combat checks pass; live GPU appearance still needs confirmation. See docs/AURA_TOP_EDGE_FIX.md.

## HUD glow correction 0.16.2

Original glow textures now use transparency blending with reduced opacity, restoring their feathered edges and avoiding the cyan flood. The character aura remains unchanged. See docs/HUD_GLOW_FIX.md.

## Native connected orb HUD 0.16.1

The HUD now uses the original game layout and atlas rectangles for the white dragon, continuous serpent connectors, tail, six visual orbs and main-orb kanji. Both active texture atlases are pixel-identical to their original game sources. Six visual sections represent the existing three-stock heat capacity. The aura and combat media remain unchanged. See docs/NATIVE_ORB_HUD.md.

## Connected orb HUD 0.16.0

Three connected small heat orbs now extend from the main orb inside the dragon, one per stock. The dragon/head now fit inside the panel. The original atlas supplies its glow. The corrected bar version is saved in docs/reference/HeatUI-Bar-preserved.lua. The aura is exactly 15% larger than v0.15.4, with no other changes to its code or textures. See docs/ORB_HUD.md.

## HUD crop fix and aura size 0.15.4

The dragon atlas now uses explicit UI source rectangles to prevent the complete sprite sheet from appearing. The aura is exactly 20% larger; its textures, colors, animation and anchor positions are unchanged. See docs/HUD_CROP_FIX.md.

## Heat visuals update 0.15.3

The dragon and orb now draw directly from the original Yakuza 6 atlas with no altered artwork, added ring or baked dragon animation. The original white dragon stays neutral below full heat, glows at 100 heat and uses full glow in Extreme Heat. The heat bar is continuous, with internal stock markers. The native world aura uses the original aura texture with upward flow and doubled texture density.

## Heat visuals update 0.15.2

The dragon now draws over a separate animated orb layer. Activating Extreme Heat plays a one-shot 800 ms energy surge. The world aura now uses an original high-resolution rising-flame sequence in place of the barely moving oval. See docs/HEAT_VISUALS.md for source and validation details.

## Animated heat HUD

The heat HUD now uses original Yakuza 6 sprites extracted from ui.par: the dragon frame, glass orb, blue glow and flame sheet. The orb and cyan bar animate at 20 fps using cached textures. The three stock sections and Extreme Heat display retain their existing behavior. Health is not displayed. The panel passes mouse input through and samples heat state at 10 Hz. This recreates layer composition and motion for PZ; the Dragon Engine UI scene itself is not executed.

## Combat music

Funk Goes On starts on the first confirmed zombie hit with Dragon of Dojima. It fades out after 12 seconds without a hit. Use Combat styles -> Toggle combat music to disable it; the Music volume slider controls its level. Restart the game after updating so the new sound definition loads. See docs/COMBAT_MUSIC.md for details and validation.

## Combat stance and footwork

Hold RMB with Dragon of Dojima equipped. Standing and moving now share an animated Kiryu stdA_lp upper-body loop with a 0.28-second blend, replacing the frozen moving pose. Stationary hips/legs use the native Bob_IdleAim1Hand track; walking legs use the native directional strafe clips. The moving stance controls only Spine1 descendants and held-item props, leaving the native root, hips, Spine and both leg chains untouched. This preserves one consistent stance in all directions without tying the upper body to the footstep cycle.

The loop seam blends over twelve source frames. Native-data checks verify 12,274 lower-body rotation/position keys, loop closure and animated upper-body motion. Native state selection and the existing 593 combat checks pass. Restart after updating; live gameplay blending still needs confirmation.

## Hit sparks

Confirmed hits now produce a small, brief warm spark burst using two original Yakuza 6 particle textures. Finishers have a slightly larger burst. The effect uses native animated world sprite attachments on the hit zombie, with camera and zoom handled by the world renderer. The blue heat aura appears at one full stock and during Extreme Heat. Combat styles -> Toggle hit sparks enables/disables the effect for your character. The effect is visual only; damage and collision behavior are unchanged.

## Controls

While actually running with RMB released, a fresh LMB randomly selects a left side kick, right side kick or jumping knee. A fresh MMB dropkicks in any running direction. About 0.25 seconds of actual run-up is required.

Aim + N: toggle Extreme Heat when at least one full heat stock is available.

Select Combat styles -> Dragon of Dojima from an inventory context menu. Hold RMB to aim. Tap LMB for up to four light attacks. Press middle mouse (MMB) for a finisher; press MMB a second time for its matching follow-up.

- One LMB, MMB: light 1 -> finisher 1.

- Two LMB taps, MMB, MMB: lights 1ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ2 -> finisher 2 -> double finisher 2.

- Three/four LMB taps select the equivalent branch 3/4.

The light buffer holds only one pending attack. Extra early LMB taps are discarded; press again as the next attack begins to continue through all four steps. Buffered LMB and MMB inputs retain their order. Both MMB taps can be queued while lights are playing. The second MMB can also be pressed during the first finisher or within 400 ms of its completion. Holding MMB does not count as another press. A third finisher is refused. Later LMB taps cannot overtake a queued finisher. A finisher without its follow-up ends the light chain, retaining only a short double-finisher window. A new light attack clears that window.

Releasing aim clears queued attacks and queued finishers; an already playing move completes normally. The HUD shows queued finishers and the active single/double phase.

## Damage balance

Light attacks 1-4 deal 0.75x their previous damage. First and double finishers deal 1.25x. Running attacks, quickstep attacks and ground stomps retain their previous damage. These multipliers combine with the existing Extreme Heat multiplier. Native strength, armor and hit calculations still apply. Per-move weapon values restore on completion, interruption and save reload, so modifiers do not accumulate.

## Conditional recovery

Without a second MMB press, the first finisher plays its full original animation. A queued second press may link at a short pose-matched window unique to each branch. The follow-up uses an entry aligned to that pose, with a short correction blending back into the source animation before contact. If the press comes after the window, the first finisher completes and the original follow-up clip starts. Light attack continuation still begins after its 58% recovery marker; double finishers retain full recovery.

ProjectYakuzaChainReady gates light chaining. ProjectYakuzaDoubleReady opens and closes a branch-specific finisher handoff window; both it and the current hit marker must match before a queued follow-up can interrupt the first. Native cleanup still separates the two collision calculations. A brief movement hold and overlapping blends prevent a locomotion pose between linked attacks.

## Animation sources and footwork

All player finishers use Kiryu sources:

- First finishers: P_KRU_BTL_SUD_ath_01_fin_md.gmt through 04_fin_md.gmt.

- Double follow-ups: P_KRU_BTL_SUD_ath_01_finW_md.gmt through 04_finW_md.gmt.

Finishers preserve the full body, including kicks, jumps and turns. Native BlockMovement events plant the character during playback. Completion and cancellation release movement. Light attacks retain native upper-body masking so the legs can walk while punching. Normal playback remains 1.6x (1.92x during Extreme Heat) with 0.08-second blend-out for most moves and 0.04-second first-finisher blend-out. Horizontal source travel is omitted. Contact timings are approximate and selected from rendered poses.

## Update 0.14.6

Aura rendering is now identical in every facing: all four effects draw directly in the world camera pass using the same native render direction as the previous up-right fix. They are removed from automatic character rendering to prevent duplicate/pixelated copies. The world callback explicitly advances each native looping animation. Travelling brightness bands animate the smooth source rims upward; the old pixelated atlas remains removed. Size, upper-body placement and the stance/blend rollback are unchanged.

## Update 0.14.5

Aura is approximately 15% wider and 30% taller. Removed the older low-resolution animated atlas layer; only the smooth original Yakuza flame rims remain, with gentle looping motion. Frames now use 64x96 pixels for cleaner scaling. Patches remain on the upper body, and the missing-facing world-render workaround is retained. Stance and attack blends remain rolled back.

## Update 0.14.4

Reverted the recent idle-guard arm/turn modifications and attack-to-idle blend changes. The guard clip and standing/moving blends are restored from v0.14.0; attack animation XML is restored from v0.14.2. Native turning is restored by removing the four custom turn nodes.

Heat aura patches are approximately 50% larger and brighter. Their centres are raised to keep the visible effect above the legs. A native world-render fallback draws the aura in the facing skipped by B42's generic attached-sprite renderer; it is registered only while the aura is active and does not create UI elements. Other facings retain the ordinary native attachment path.

## Update 0.14.3

Smoothed the visual return from attacks into the adjusted guard: light/quickstep-attack recovery fades use 0.20 seconds; finishers, running attacks and ground attacks use 0.24 seconds. Explicit transitions retain the original shorter fades for light chains and first-to-second finishers. Attack clips, speeds, hit events, input buffers and recovery-release markers are unchanged.

## Update 0.14.2

Heat aura now uses four compact, overlapping patches on the middle/upper torso, arms and head. Original Yakuza 6 flame-rim DDS textures are combined with the original animated wisp sheet. Orbiting movement and lower/leg emitters are removed. Effects remain close to the character centre, with all visible pixels above the configured upper-body cutoff. Heat thresholds, combat, guard pose and toggles are unchanged.

## Update 0.14.1

RMB guard: hands moved forward/outward with a two-bone arm solve, preserving bone lengths and wrist orientation. Native aim-turn leg clips remain; style-scoped 90/180-degree turns have gentler blends, a consistent torso twist limit and no extra Spine-pose contribution over the guard. Standing/moving guard blends use 0.32 seconds. Native leg animation is preserved.

Heat aura: replaced the full-body image with six small animated Yakuza wisps distributed around the shoulders, arms and waist. Separate phases/speeds and width/brightness changes suggest depth. These are native world sprite attachments, not volumetric 3D particles; no UI or broad background plane is used. Threshold and toggles are unchanged.

## Update 0.14.0

Corrected the native character bottom-centre anchor: sparks are centred on the zombie torso (or near the floor for ground attacks). Sparks now have 16-frame flash/scatter animation, 240ms normal and 280ms finisher lifetime at normal time. A looping blue heat aura uses original Yakuza 6 aura textures and appears at one completed stock or during Extreme Heat. Toggle it separately through Combat styles -> Toggle heat aura. Its native animation follows the character; status checks reuse the existing 100ms heat update. No UI layer or extra player-update event is created for either effect.

## Update 0.13.1

Removed the full-screen spark UI element that interfered with the mouse. Sparks now render as native animated attachments on the target zombie. The cleanup callback runs only while sparks exist and removes only this mod's own instances. Fully restart the game to unload the old panel.

## Update 0.13.0

Four Kiryu running attacks use randomized LMB selection and all-direction MMB dropkick. They submit native melee attacks through a brief native locomotion exit, with bounded collision-aware travel. RMB + Shift quicksteps and LMB quickstep attacks retain their controls.

Queued double finishers now use per-branch pose matches rather than a fixed post-contact delay. The first finisher is never cut without the second input. Late inputs keep the complete first animation and use the original follow-up. See docs/FINISHER_LINKS.md for timing and source-preservation details.

Normal attacks against downed targets now use two full-body Kiryu stomp variants. Native floor targeting chooses them automatically; no new key is needed. The native stomp route also uses these clips. See the ground-attacks section below.

The heat UI uses the original Yakuza 6 dragon/orb sprites and animated energy textures. It includes three stock sections and no red health bar. The panel passes mouse clicks through and samples state at 10 Hz.

Heat now builds from confirmed native damage, banks completed stocks, loses unfinished charge after inactivity/acute damage/knockdown, and supports Extreme Heat. Aim and press N with at least one complete stock to activate; press N while aiming again to end it. Extreme Heat consumes current heat into a fuel meter, drains over time and on attacks, increases native token damage by 50%, plays ProjectYakuza strikes 20% faster and temporarily enables native stagger-back resistance. Completion/cancellation/unequip/death restore modifiers; saved boosted tokens carry cleanup metadata.

The installed Yakuza 6 tables confirm a base capacity of three stocks and separate gain/loss/drain coefficients. Their engine units and all runtime behavior were not recovered. Rates and defensive behavior are Zomboid-specific approximations; see docs/HEAT.md and docs/y6-heat-parameter-check.json. No cinematic heat actions or object interactions are implemented.

The existing input order, native targeting and quickstep-attack behavior are retained. Queued double finishers release at a post-contact marker 0.08 seconds after the first move's collision at base speed, with 0.04-second follow-up blend-in and first-finisher blend-out. Single finishers still play fully. Prior idle optimizations are retained; no global per-zombie callback or repeated idle combo reset is added.

## Quicksteps

Quicksteps now require physical RMB, an equipped style and either Shift key plus a movement direction. Shift without RMB retains normal Zomboid run behavior; no game keybinding is changed. The old Left Alt quickstep chord is removed.

With Dragon of Dojima equipped, hold RMB to aim, then press either Shift key together with a movement direction. Movement uses your rebound Forward/Backward/Left/Right keys (WASD by default). The requested world direction is retained; the nearest forward/backward/left/right clip is selected relative to facing. Release Shift or the direction, then press again for another step. Holding the same chord does not repeat. Changing direction creates a new chord, subject to cooldown.

Press LMB during the quickstep to request one directional special attack. A click after quickstep entry counts; an already held LMB does not. The opening step must reach 25% of travel progress before the action hands off. Native timed-action cleanup must release the hand override before the strike is submitted. Aim release, hit interruption, unequip or a 500 ms handover timeout discards the request. The strike uses normal native melee targeting and one collision event, retains full-body footwork and adds no invulnerability or coordinate teleport. A third-party timed action can block the handover.

Special sources: P_KRU_BTL_SUD_ath_swy_f.gmt, ath_swy_b.gmt, ath_swy_l.gmt and ath_swy_r.gmt. They play at 1.6x with approximate contact frames chosen from previews. Their in-place clips omit horizontal source travel; the preceding quickstep supplies movement. These attacks end their own chain and do not open a finisher window.

Sources are P_KRU_BTL_SUD_swy_f.gmt, swy_b.gmt, swy_l.gmt and swy_r.gmt. Each full-body clip plays at 1.35x for about 0.54 seconds. Native timed actions select the animations; clip events gate movement and completion. The HUD shows QUICKSTEP and its direction.

A quickstep requests up to 0.8 tile of travel in increments capped at 0.08 tile per update, followed by a 180 ms cooldown. Target terrain must exist, support a floor and be non-solid. Crossing a tile edge checks native adjacent collision, and displacement is queued with moveUnmodded for native moving-object collision resolution. The mod does not set player coordinates directly. Obstruction or lower frame rates may shorten travel.

Quicksteps require an idle combat state and cannot start during attacks, other timed actions, corpse dragging, climbing, vehicle use, death or knockdown. Ordinary movement/turning is temporarily locked and the native timed-action hand override blocks melee submission during playback. Hits, aim release, unequip, interruption and missing-animation timeout restore controls. No invulnerability, damage or heat cost is added. Native collisions, wounds and enemy attacks remain effective.

## Running attacks

Equip the style, run or sprint in any direction with RMB released, then click LMB for a random left side kick, right side kick or jumping knee. MMB selects the dropkick in any direction, including backward and diagonals. The chosen move faces sampled travel direction; movement-key names no longer choose the attack. A fresh click and about 250 ms of actual displacement are required. Holding Run against a wall or holding an early click does not buffer a running strike. Simultaneous fresh LMB/MMB chooses MMB.

Only the jumping knee is slower: 1.2x playback instead of 1.6x, making its full animation about 33% longer. The side kicks and dropkick retain 1.6x playback. Extreme Heat applies its existing 1.2 multiplier to each move's own speed.

For the side kicks, movement input can end recovery after 78% of the animation; the knee permits this after 80%. The current move's hit marker must already have passed. Held movement keys count, so continuing to run releases the late ending automatically. Without movement input the entire animation plays. The dropkick always retains its full landing/get-up recovery and ignores movement cancellation.

Attacks have one native MeleeSwing collision, native targeting/damage and bounded collision-aware travel: up to 0.9 tile for side kicks, 1.0 for the knee and 1.2 for dropkick, capped at 0.08 per update. Startup briefly releases native run/sprint, then submits through native idle/movement-to-melee transitions without RMB or forced aim. Terrain, hit interruption, death, unequip and timeouts clean up movement locks. Running attacks do not open a finisher branch or grant invulnerability.

Sources and contact frames are unchanged. Automated input, animation selection and native state checks pass; live visual and input confirmation remains pending after restart.

## Ground attacks

With Dragon of Dojima equipped, use the normal attack input against a downed target. Zomboid decides whether the attack targets the floor; the mod then selects Kiryu's P_KRU_BTL_SUD_ath_dwn_stmp.gmt or P_KRU_BTL_SUD_ath_dwn_stmp_nr.gmt, alternating after completed ground attacks. Native force-ground/stomp controls retain their native targeting and also select the converted clips. Standing shoves and attacks retain their existing routes.

Normal floor melee uses one MeleeToFloor collision event. The native stomp state uses one Stomp event and StompAnim lifecycle events. The mod does not force targets to fall, scan for nearby downed zombies, set coordinates or subtract health itself. Floor reactions remain native. Full-body movement is locked during the stomp and released on completion/interruption. Stomps end their own chain and cannot open finishers or fill the standing light buffer. Actual contacts can build heat. ProjectYakuzaCombatSpeed supports 1.6 normal and 1.92 Extreme playback.

The game writes its floor animation state after OnWeaponSwing. Runtime adopts the grounded lifecycle from the native isAimAtFloor getter after state entry, rather than attempting to access Java AttackVars fields. Contact is approximate, at source frame 14/54; live foot alignment and hit feel need verification.

## Zombie hit reactions

Four common-enemy sources are converted:

- C_COM_BTL_SUD_dmg_hed_lv1_l.gmt

- C_COM_BTL_SUD_dmg_hed_lv1_r.gmt

- C_COM_BTL_SUD_dmg_bdy_lv1_f.gmt

- C_COM_BTL_SUD_dmg_hed_lv2_u.gmt

An actual OnWeaponHitCharacter event from the equipped style tags a living, standing zombie with the move's reaction clip. High-priority nodes in zombie/hitreaction select that clip during an ordinary frontal HeadLeft reaction. The native reaction enum is preserved; arbitrary names are not supplied to the game's enum parser. Tags clear after leaving the reaction, another weapon hit, death, falling/knockdown, or a bounded cleanup timeout.

These are visual overrides for this style's ordinary standing hits. Rear hits, floor hits, death reactions, knockdowns and physics/ragdoll states retain native routing. They are not a global replacement for gunshots or other weapons. The mod does not force damage, resurrection, stun immunity or a guaranteed kill.

## Install and diagnostics

Fully exit the game and load the updated mod after restarting. For manual installation, extract ProjectYakuza-B42-v0.27.1.zip into C:/Users/Nik/Zomboid/mods. The required path is mods/ProjectYakuza/42/mod.info. Enable ProjectYakuza for the save and disable Y6LightAttackPrototype. Existing style items retain the valid invisible hand model introduced in 0.3.1.

Combat styles -> Toggle combat diagnostics shows move, queue, readiness and hit markers. With diagnostics enabled, logs include early recovery exit, queued double finisher, accepted swings and confirmed native hits. Warnings remain available without diagnostics. Clip/collision markers alone do not prove target contact.

## Heat gauge and Extreme Heat

The upper-left cyan bar represents three equal heat stocks on the existing 0ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ100 scale. Confirmed zombie hits add native damage times 10, capped at 20 points per victim/strike. Duplicate callbacks are ignored; different targets may add heat. Completed stocks remain banked. Unfinished charge decays at 4 points/second after a 3-second grace period; acute damage removes damage times 0.5, and a new knockdown removes 8 points, each limited to unfinished charge. These rates are tuned for Zomboid rather than copied verbatim from Dragon Engine units.

Aim + N activates Extreme Heat with at least one completed stock. Current heat becomes fuel lasting about 6 seconds per stock before action costs. Swings spend 1.5 fuel points; damage also drains fuel. Attacks cannot refill ordinary heat during Extreme Heat. Native min/max token damage is multiplied by 1.5; ProjectYakuza attack clips use 1.92x playback instead of 1.6x. Normal quickstep speed is retained. Native stagger-back resistance is temporary; wounds, infection, grabs and falls still apply. No invulnerability, health restoration or full Y6 defensive model is provided. Modifiers are restored on cancellation, depletion, unequip/style change, vehicle entry and death. Heat survives saving; active fuel does not.

The [heat behavior notes](docs/HEAT.md) document exact tuning and limitations. Grabs, guard, parry, XP upgrades and consumable heat are not implemented.

## Heat-action asset check

The extracted Yakuza 6 motion archive contains heat-mode transition clips, but no complete attacker/victim heat-action pair has been identified yet. Heat actions remain disabled. A simple action without environment alignment is the next suggested milestone once a suitable pair is located.

## Other actions and extension

Grabs, parries, blocks and heat actions remain disabled extension slots. Quicksteps are implemented. See docs/EXTENDING.md. Each strike uses native melee targeting, armor, line of sight and damage handling.

## Verification and limits

All eight new double-finisher/reaction clips pass the installed game's jassimp importer and ProcessedAiScene processing with 35 channels each. Native selection checks cover 20 standing player attacks, four quickstep action nodes and four zombie nodes, single collision events, body masks, movement lock events and native fallbacks. An isolated native ActionTransition test verifies the real recovery-exit condition, using native event storage to avoid full network initialization.

The game's Kahlua interpreter passes 794 checks with mocked player/input/zombie/timed-action interfaces, including the four running inputs, run-up/held-click rejection, native lunge bounds/wall stops/interruption cleanup, post-hit finisher exits, deferred native floor routing, alternating stomp lifecycle/cleanup, directional quickstep attack handover, held-input rejection, heat gain/capping, mouse pass-through gauge rendering, full single-attack recovery, marker-gated chaining, all four double-finisher branches, buffered input order, late follow-ups, action failure/timeout, movement cleanup and reaction scope.

Version 0.14.6 timing and optimizations have not been verified live. Terrain guards and movement bounds are checked headlessly; live wall/vehicle contact, input feel and playback still need confirmation. These checks do not prove live transition smoothness, reaction timing or target contact. Earlier light-attack versions were confirmed working by the user. Multiplayer, controller input, split-screen HUD and female-body differences remain untested. Retargeting and finger poses are approximate.

Native selection checks also verify ProjectYakuzaCombatSpeed resolves to 1.6 normally and 1.92 during Extreme Heat across all 20 standing attack nodes. The bar preview is rendered from captured production Lua drawing commands. These are headless checks, not live gameplay verification.

The archive includes source Lua/XML, 30 converted clips, source reports and validation logs. Editable Blender files are supplied alongside it.

