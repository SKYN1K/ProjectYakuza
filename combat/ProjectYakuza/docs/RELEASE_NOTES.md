# Project Yakuza 0.59.0

- Removed the two automatic barrage animations, their native owners/observers, Lua action modules, input routing, action kind and network damage command.
- Extreme Heat now uses eight individually pressed native light attacks, followed by a paired three-hit finish when all eight connect and the last target survives. Three fresh finisher-button prompts determine the extra hits. Holding or missing inputs adds no bonus hit. The original recovery continues.
- Converted the approved original Kiryu/victim pair from Yakuza 6 h23590_3combo.par. Source vector movement, native animation phase, bounded space checks, interruption cleanup and multiplayer target leases keep the paired action scoped to DoD. No cinematic camera override is included.
- Added original rear-turn first and second finishers for all four light branches, using the verified AttackRevFin/AttackRevFinW source mappings. Side turns keep ordinary finishers because no distinct source side-finisher mapping was verified. No auto targeting is added.
- Added the reusable ProjectYakuza.QTE API: per-action prompt definitions, configurable existing/addon bindings, fresh-press tracking, result and cancellation events, deterministic sequence progression and authoring documentation. Other styles retain their own handlers and presentation.
- Added source/native importer, prop, MP observer, QTE/SP lifecycle, replay/session and authoritative MP damage checks. Original images, audio recordings and voice-pack files are unchanged.

Only the explicitly approved non-AI motion conversions create assets. PZ was not launched or operated. Live animation fit, UI appearance and multiplayer latency require an in-game check after restart. Install matching 0.59.0 versions on server and clients. See VALIDATION_0.59.0.md.
