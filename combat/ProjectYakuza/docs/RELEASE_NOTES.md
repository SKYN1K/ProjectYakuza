# Project Yakuza 0.103.0

- Inventory wheel input reaches the item list again. Passive combat overlays keep their visible layout while using zero native mouse-input bounds, preventing world zoom from taking the wheel.
- Multiplayer Heat Action and activation protection no longer enables native ghost mode, which hides actors from ordinary observers. Invulnerability, zombie attack suppression and restoration of pre-existing protection remain active.
- Observer Heat Action effects use the synchronized action clock and server-confirmed QTE contacts. Out-of-order poses cannot rewind presentation; duplicate contacts remain ignored and delayed effects have a bounded 350 ms grace.
- Bicycle uses Yakuza 6 h23750_buki_h: a held-object overhead crash with original weapon release, both original damage contacts, full recovery and matching original sound events. The existing bicycle model and pixels remain unchanged.
- Beer crate main and failure scenes turn the opening down and seat the victim's head inside the crate against its inner roof. Body, finger and victim animations remain unchanged.
- Offline Kahlua, native imports/selectors, source motion/CMN/PCM, texture pixels, runtime references and comment checks pass. Project Zomboid was not launched. This release was not installed locally, as requested. Live MP and visual playback still need an in-game check.
