# Runtime asset cleanup

Version 0.101.0 removes 258 confirmed obsolete files, totaling about 20.94 MiB before ZIP compression: 56 unused motion clips, 30 selectors permanently gated by unproduced pose variables, 171 unused textures and one unused ChargeEnd audio file. Its unused sound declaration and duplicated legacy first-light numeric dataset are removed too. No retained motion, model, texture or audio bytes are modified.

The removed motions are superseded weapon carry/ready/idle/walk/run variants, old footwork slices, moving stance, old victim hold/walk clips and disabled ordinary walk conversions. Every surviving custom animation has a live selector or production Lua reference. Current quicksteps, grabs, ordinary attacks, Heat Actions, entry, RMB idle, unarmed run/sprint and native pose fallbacks remain.

Unused textures comprise old TauntAura copies, WorldHit flipbooks, animated Bar slices, older QTE/effect atlases, wisp-only crops and superseded StyleFX images. The active normal HeatWisp a/b/c sequences, ExtremeHeat flame/smoke sequences, blood frames, source glints, current HUD/selector/input atlases and item/model textures remain. Dynamic frame filenames and engine-resolved item/model textures are included in the reference audit.

asset-cleanup.json records every removed path, original size, SHA-256 and reason against v0.100.0. Historical conversion reports and their local source/archive references remain for reproducibility. Their removed-output records describe prior releases; they do not imply those files are still installed. Older pose-only/full-payload validators apply to those historical outputs. Current runtime checks use validate_asset_cleanup.py, native import/selector probes and the rebuilt combat suites.

validate_asset_cleanup.py is the current release gate. It rejects retired files, dangling Lua requires, missing animation/texture/audio references, unreferenced clips/textures/audio and disabled pose selectors. Its baseline-audit option additionally verifies all retained media against the v0.100.0 ZIP. validate_effect_loader_paths.py verifies current native sequence naming and retained pixels.

Older source-conversion builders may emit their historical dormant outputs while reproducing a full source conversion. After such a rebuild, run validate_asset_cleanup.py with its prune option to remove only exact audited retired outputs, then run the normal checks. The prune option refuses changed or unaudited files. Publishing runs the read-only gate before creating a ZIP; it never prunes automatically.

The style-addon templates, public registry/API, current source provenance and separate voice-pack integration are retained. Extraction folders, previews, historical ZIPs, backups and the separate voice-pack project remain outside the combat package and Git scope.
