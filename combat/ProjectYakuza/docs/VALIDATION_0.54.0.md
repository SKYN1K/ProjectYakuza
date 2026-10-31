# Validation: 0.54.0

PZ was not launched. Live text appearance, player visibility/facing, actual PvP events and MP latency remain untested.

5,798 Kahlua assertions across 21 actual-module fixtures pass. All 48 production Lua modules compile. The focused encounter fixture was rerun after final target caching/backoff/native player-hit additions: 1,045 checks pass. Existing broad framework, combat, MP, style/weapon, presentation, sound, heat, addon and source-asset checks retain their passes. Six lexical preservation tests pass and the comment audit reports zero comments across 596 source files.

The stock renderer's short text exceeds its former 0.72 scale, while the new helper caps source-font scale at 1, fits long titles within 88% of viewport width including the landing pulse, and bounds title height on small viewports. Glyph bounds, blend restoration, mouse isolation and source pixels retain their previous checks.

New actual-module checks cover explicit per-style triggers; visible-player detection; range, wall/LOS, facing and dead-target rejection; reversed seen-by-player detection; 16-candidate list cursors and cached target reuse; no zombie count or threat-counter reads for player-only/no-count intros; native player-hit opt-in; manual/custom trigger context; detector registration, polling, removal, missing fallback and error quarantine; exact minimum-count acceptance, insufficient-count rejection without encounter latching; and invalid config types/combinations. Default styles without explicit intro config/provider still do no detection, and default DoD remains zombie-only.

The custom StyleUI provider/lifecycle fixture remains active, including supplied sounds and cleanup on style/provider removal. Renderer context now carries the style config and optional target. New fields/functions/events and source-only custom effect examples are documented in ENCOUNTER_INTROS.md. Custom detector work is author-controlled and must be bounded; failures are quarantined per function/state instead of repeating each poll.

Native reflection confirms getOnlinePlayers/getSpecificPlayer, IsoGameCharacter.CanSee(IsoMovingObject), getForwardDirection, threat counters, grid lookup and moving-object APIs. Local native source inspection confirms CanSee is geometric line of sight, so the new framework adds its own range/floor/facing-cone checks. It is not a server-authoritative visibility, hostility, lighting or screen-pixel system. Loaded/replicated player positions and facing constrain MP accuracy. Client presentation adds no network messages or PvP damage logic.

All 1079 existing motion/image/audio/native-XML files are byte-identical to 0.53.0. No graphical/audio asset is created, cropped, upscaled or modified. The separate voice pack and disabled grabs are untouched. Default threat polling, zombie thresholds, nearby count budgets, explosion and combat settings remain unchanged.

The prior 1,330-file installation must match the published 0.53.0 ZIP before update. Back up only changed existing files, verify every installed/source/ZIP byte, and verify the published release digest. Fully restart matching installations for live assessment.
