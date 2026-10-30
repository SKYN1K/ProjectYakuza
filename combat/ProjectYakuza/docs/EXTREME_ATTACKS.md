# Extreme Heat attack variations (0.49.0)

Dragon of Dojima now has nine unarmed attack variations during Extreme Heat: the neutral MMB heavy, the first finisher after each of the four lights, and their four matching double finishers. Use the existing inputs: aim and tap-release MMB for a heavy/finisher; another MMB input requests the second finisher. No extra key or activation setting.

The supplied Yakuza 6 fighter command file labels the motions Heavy_Rev, AttackRevFin1–4 and AttackRevFinW1–4. Those map to ath_BKL_lf_md and the four B_fin_md/B_finW_md pairs. Original command strings, GMT/BEP hashes, source ranges, rig inputs, output hashes and pose-link measurements are in extreme-attack-assets.json. This update uses those source motions within PZ's existing combat lifecycle; it does not replicate the full Dragon Engine combat state machine.

The four light attacks, charged attacks, movement attacks, weapons and ordinary non-Extreme finishers retain their existing motions. A real weapon uses its own profile, with no unarmed variation leakage. The existing x1.25 heavy/finisher damage and Extreme Heat damage/speed bonuses remain; no extra variation multiplier is added. Existing sounds, voices, blood, sparks and aura presentation apply.

## Source-based paired flow

First finishers retain all source frames and play fully unless the player requests a second. Queued doubles release recovery only inside native markers selected from the closest existing source poses after contact. Matching points are first-clip frames 27, 23, 26 and 29; the windows last three source frames. The second-finisher entry uses source frame 0 except branch 2, which omits one leading frame. No bridge poses, interpolated animation frames or invented motion are baked into the assets. Native blending is 0.10 seconds on doubles.

Measured local bone-rotation RMS gaps are about 0.061, 4.399, 1.031 and 0.780 degrees. The largest local root-position gap is below 0.001 PZ model units. These are offline source-pose measurements, not a guarantee about live blends on every character model.

A first finisher remembers its mode so its second uses the matching source pair even if Heat depletes between them. Existing follow-up time limits still apply. An attack already playing finishes naturally when mode ends; subsequent new attacks use normal variations. A final valid attack that depletes Heat through its own swing cost is preserved. Damage loses its Extreme bonus when the existing Heat system ends it.

## Framework and multiplayer

Developers can define enabled actions.finisher.variants.extreme_default, extreme_after_1–4 and extreme_double_after_1–4. The variants need their own nodeValue, native animation/owner metadata and extremeHeat=true. afterLight/double/neutralHeavy flags follow the ordinary contracts. Missing variants fall back to ordinary moves. The current standalone weapon-heavy route remains profile-owned. Other styles receive no DoD motions automatically.

Native owner nodes are isolated to DoD and the empty weapon profile. They select by the latched move ID; a live Heat condition is deliberately omitted so depletion cannot remove a playing clip. Lua gates new Extreme requests, preserves paired mode and clears it on reset, aim release, cancellation or expiry.

Nine matching network catalogue entries and 36 event-free observer nodes provide both remote repeat cycles in actions/melee. The server verifies move/profile membership and the mode flag, retains the current swing after depletion, and grants a bounded paired continuation lease. A recent active-mode snapshot permits one final cost-depleted first/neutral swing; after accepting it, the inactive snapshot cannot authorize further new Extreme attacks. The existing client-owned Heat model and native primary-hit authority are unchanged. Server and clients must install the same version.

PZ was not launched. See VALIDATION_0.49.0.md for native import, source contacts/poses, Kahlua and MP protocol checks; live appearance and latency need user testing after a full restart.
