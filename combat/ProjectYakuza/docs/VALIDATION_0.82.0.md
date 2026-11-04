# Validation: Project Yakuza 0.82.0

Validation is offline; Project Zomboid was not launched.

The compact health bar is 270 pixels wide at the existing 0.75 scale, 12 pixels lower than before. The HUD suite preserves overall-health mapping, including 25% and empty health, original atlas selection, native input passthrough and addon isolation. All 68 production Lua files compile, the full combat regression suite passes, and source-comment/lexical-preservation checks pass.

The ground correction uses vertices from the supplied native MaleBody.x/FemaleBody.x head skin groups and animated right-foot sole vertices at source impact frame 30. A constant victim translation is applied through the shared paired-point calculation, including server placement, clearance and observers. Tests cover all eight headings; the averaged head/sole centres coincide within numerical tolerance. Source mesh hashes and calibration values are retained in ground-contact-alignment.json. All animation clips remain byte-identical to v0.81.0; original frame timing/body motion is preserved.

Style-entry lifecycle tests cover preloaded idle variables, full-duration movement/attack locks, hit vulnerability, completion, interrupted/missing playback cleanup, paused timers and completion when native blending omits the last marker. Native AnimNode parsing confirms earlyTransitionOut=true and a 0.24-second blend-out in the owner and both observer definitions. Only these three existing XML definitions change. The other 724 previously protected motion/combat XML files remain unchanged, and all 30 disabled weapon/walk overrides retain their native fallback gates.

Four original Kiwami 2 textures preserve every decoded DDS pixel and native dimensions, and decode through B42 ImageData. Original hashes and paths are recorded in style-transition-effects.json. World-effect tests verify distinct entry/taunt assets, restrained opacity, brief lifetimes, pause behavior, one-shot cleanup and stable allocation. MP tests verify one effect trigger per distinct entry action. All 418 observer selectors remain event-free and pass native selection.

Installation backs up only changed existing files and verifies the complete installed copy. The release ZIP is compared with source and installation. GPU appearance, exact in-game blending and live multiplayer latency remain for user testing after restart. No separate voice-pack edits or game JAR changes were made.
