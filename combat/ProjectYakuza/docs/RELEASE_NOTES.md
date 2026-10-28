# Project Yakuza 0.38.0

- Removed additive brightness from every punch particle layer and enlarged every punch sprite by exactly 25%.
- Punch facing now includes the game's live shoulder-turn value, converted from degrees, as well as its body angle. This addresses aim-turn lag instead of applying different screen offsets for each direction. The final blended limb pose still needs a live check.
- Replaced the taunt's flame/spark burst with the standard heat aura animation, enlarged by up to 20%, for 0.75 unpaused seconds after successful completion. Smooth 0.10-second fade-in and 0.15-second fade-out. The echo replaces the normal aura pass instead of doubling it, and uses normal transparency throughout.
- Existing blue aura texture pixels are unchanged. The requested 25% whitening needs a colour-only asset copy because the blue is baked into those frames; approval is pending under the user's no-new-assets rule.
- Extreme Heat, charge effects/timing, combat damage and controls are unchanged. No visual/audio/motion asset was created or modified. Grabs remain disabled.

## Validation

3,966 offline Kahlua assertions pass and all 40 production Lua files compile. Tests cover normal transparency on every punch draw, exact sprite scale increases, sixteen continuous facings with shoulder turn, the normal-aura taunt replacement, envelope duration, pause, cleanup and remote completion. Native source/texture checks also pass. See [validation](VALIDATION_0.38.0.md).

PZ was not launched. Live visual alignment and appearance remain unverified. Fully restart the game; server and clients need the same version.
