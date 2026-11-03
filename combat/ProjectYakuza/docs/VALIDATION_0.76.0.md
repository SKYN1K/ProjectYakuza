# Validation: 0.76.0

Project Zomboid is kept closed. The release runs the 73-step offline validation set, including 27 Kahlua suites, compilation of all 63 production Lua files, zero comments across 811 scanned source files and lexical-preservation tests. Bounded 192 MB JVMs load native B42 classes/importers without game/GPU startup.

## Original weapon motion

Ready, relaxed idle, walking and slow-walking retain their original WPA/WPC/WPD source clips. Sixteen composites now use source shoulder/elbow/wrist directions relative to the source chest, fitted to PZ bone lengths and chest orientation. Wrist articulation transfers relative to the forearm; finger grips and hand-prop offsets remain native-coordinate attachments. These do not replace the animations with native holds.

Independent checks measure source segment directions rather than comparing only against the old quaternion retarget. Maximum angular error is 0.0339 degrees; the old v0.75.0 katana hold fails the negative regression at 16.08 degrees. Native walking torso/head/legs/helper channels remain unchanged. Source wrist/finger samples, original GMT hashes, geometry-helper hash and unchanged attack/guard outputs are checked. Eighteen motion files change: sixteen fitted poses and the katana run/sprint prop tracks needed to retain the same grip through transitions. The original attack and running arm motion remains unchanged.

Checks cover 60,596 other source/native samples, 3,314 native hand-prop pose pairs, native loading of all converted clips and 147 selector/isolation contracts. Katana mesh-edge clearance from neck/head is at least 0.0707 native units across poses and 0.0675 across the sampled crossfades, above the 0.045 contract. Live clothing/custom skeleton clearance and appearance still require in-game assessment after restart.

## Heat Action audio

The CVF suite executes the actual feedback resolver and the actual compatible provider registry/playback with controlled native emitter interfaces. Its 90 checks include every configured katana/bottle contact resolving an existing impact cue and attack voice, no entrance voice consuming the contact channel, a busy-provider retry playing once, and cancellation/replacement/expiry preventing stale speech. Missing recordings, voice settings, provider exclusivity and native MP voice transmission remain respected. The separate installed voice pack is only inspected for compatibility, never edited.

The paired-action suite passes 254 checks, including 250 ms delayed automatic/QTE contact processing, one source-time presentation per contact, immediate local MP audio/FX without predicted damage, deduplication of the first-session echo and repeated confirmations, and no replay after cleanup or from stale sessions. Input acceptance windows remain 400 ms for DoD QTEs; only successful-contact catch-up uses the same 650 ms tolerance as server hit processing.

Server damage ownership, inventory validation, native voice transport and ordinary SFX replication retain their existing tests. All 406 event-free observer selectors, deterministic 72-clip/83-window trail catalogue, original texture pixels, source models, prior locomotion references, heat/QTE/volume/exertion/UI and lifecycle regressions remain included.

## Original input icons

The original PC input atlas supplies four pixel-exact 84x84 crops. Validation reopens the source ui.par entry, decompresses its stored DDS and compares every output RGBA pixel and source hash. Native B42 ImageData decodes all four PNGs and the font measurement APIs exist. No artwork, recoloring, resizing or upscaling is introduced.

The input suite passes 138 checks across mouse left/right/middle, dynamically rebound keyboard names, source-frame regions that exclude the baked legend, long names, unbound/faded states, addon bindings and descriptor/texture caches. The paired UI tests exercise the same renderer for QTEs and Heat Action eligibility, preserving ring animation, original flame, current bindings, fades and mouse passthrough.

## Installation

No game launch, new visual/audio artwork, AI, upscale, Java bridge or voice-pack change is used. Installation compares v0.75.0 against its ZIP, backs up only replaced files and verifies every installed byte. The v0.76.0 release ZIP and uploaded digest must match source/install bytes. Matching versions are required on MP server and clients. Offline checks establish routing, geometry and importer contracts; live rendering and audibility remain in-game verification items.
