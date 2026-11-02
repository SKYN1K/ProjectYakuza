# Project Yakuza 0.73.0

- Kept DoD's six QTE success windows unchanged. Prompts now use rotating/contracting original Y6 rings, animated supplied atlas regions and a short accepted-input flash. No extra ready cue or preparatory text is shown.
- Preserved the eighth punch's full follow-through and softened the paired entry blend. The handoff blocks an accidental ninth native attack.
- Fixed native damage interrupting the zombie's paired reaction: visible contacts keep their source timing, while the earned final health hit settles once after the victim clip finishes.
- DoD now branches on a missed QTE into an original short Kiryu recovery, releasing the victim and forfeiting the final payoff. The framework supports custom per-prompt windows/bindings, consecutive or total miss limits, configurable failure recovery and success/miss/failure sound cues using supplied assets.
- Added the original Yakuza 6 beer crate as a separately spawnable Short Blunt weapon: ProjectYakuza.BeerCrate. It uses original mesh/texture data, native durability and the DoD Short Blunt profile.
- Fixed quicksteps tapped during the native RMB transition with a bounded 350 ms retry, cancelled by RMB release, interruption or expiry.
- Added SP/MP regressions, original-pixel/source-motion checks and native model/item/animation imports. Grabs remain disabled and the separate voice pack is unchanged.

Project Zomboid was not launched. See [validation](VALIDATION_0.73.0.md). Restart after updating and install matching files on server and clients. No AI, invented artwork/audio or upscaling is used.
