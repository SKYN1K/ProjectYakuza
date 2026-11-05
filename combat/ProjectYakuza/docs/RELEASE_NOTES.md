# Project Yakuza 0.85.0

- The configured Grab button now grabs and, on a fresh press while holding, throws the zombie. Default: hold RMB and press G, then press G again. Release RMB to let go without throwing.
- Removed the separate Throw binding and updated HUD/feedback prompts to show the current Grab binding. MMB remains the wall Heat Action input when eligible.
- DoD throws knock down up to four nearby standing zombies in the impact area using native reactions. Secondary knockdowns cause no extra damage and respect walls, floor height and active paired/grab protections.
- Added validated per-style crowd-impact settings, a one-shot bounded scan and server-selected/deduplicated MP reactions. Throw requests validate the active grab ID and original impact timing.

Code-only update. No animation, texture, audio or voice-pack files were changed. Validated offline without launching PZ; see [validation](VALIDATION_0.85.0.md). Restart with matching MP versions.
