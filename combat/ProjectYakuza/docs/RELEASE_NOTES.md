# Project Yakuza 0.52.0

- Added Kiryu's supplied Yakuza 6 running loop while Dragon of Dojima is selected, for unarmed, bat/club, knife and longer-blade profiles.
- Added supplied unlocked weapon-hold loops outside aiming, including walking variants with Zomboid's native leg motion. Held weapon props follow the native hand/grip offsets.
- Added 0.25-second animation blends and transitions between running, relaxed carrying and combat stances. Native walking speed/deferred travel tracks are preserved; the run cadence is matched to the existing healthy native run.
- Scope is ordinary non-aimed running and relaxed armed idle/walking. Sprinting, crouching, turning, injuries, trees and overburdened movement keep existing native behavior. Other styles and unsupported weapons are unaffected.
- Uses 13 approved source-derived motion files and 10 style/profile selectors. No extra per-frame Lua checks, zombie scans, timers or network packets. No visual artwork, audio, AI or upscaling.

5,489 Kahlua regression assertions pass, plus native clip/selector, movement-track, source-sample and hand-prop checks. See VALIDATION_0.52.0.md and LOCOMOTION.md. PZ was not launched; assess blending/foot contact after a full restart. Install matching server/client versions. Grabs remain disabled and the separate voice pack is untouched.
