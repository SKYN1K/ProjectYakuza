# Project Yakuza 0.51.0

- Restored style-selection stance entry while holding supported weapons. Equipment/model readiness now gets a bounded retry instead of silently losing the entry request. Entry still locks movement and attacks, remains vulnerable, and uses the original Kiwami 2 body motion.
- Repaired only the entry clip's two prop tracks using native hand offsets so held weapons follow the hands; 51 source frames and all body/finger channels are preserved.
- Heavy input (MMB by default) now prioritizes Tiger Drop during the first 0.3 seconds of an observed frontal zombie attack, before damage. The one-minute cooldown remains. Guard keeps its original native timing. This Lua window is measured from observing the windup, not predicted bite contact.
- Combat music gain now uses only Project Yakuza's Music slider, independently of PZ's Music option. Vanilla music still ducks/restores according to its own option; overall device/master mixing still applies.
- Polished DoD's encounter title with a cool screen filter, flight into the centre, a brief shake of the intro graphics, and original Yakuza 6 explosion/shock textures behind the landing text. The world camera stays fixed. Existing crowd thresholds and style-exclusive/custom-provider behavior remain.
- All texture conversion and prop repair use explicitly approved existing assets. No AI, upscaling, invented artwork or new audio. Grabs remain disabled; the separate voice pack is untouched.

Offline checks and asset provenance are documented in VALIDATION_0.51.0.md. PZ was not launched. Install matching client/server versions and restart fully to load the repaired clip and textures.
