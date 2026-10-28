# Project Yakuza 0.37.0

- Lowered DoD's punch VFX by 2.5 sprite-pixel units (about five pixels at normal tile scale), enlarged the existing particles and strengthened the white-blue core glow. Limb particles now render at native limb-height world depth, with compensated screen positioning and a small surface bias, rather than using the player's foot depth.
- Removed the taunt's additive brightness pulse completely. Its completion flare/sparks remain in normal transparency with a cooler blue tint; the base aura is drawn only once.
- A held charge is now a valid recovery follow-up after the light attack's existing hit and chain markers. No held intent still allows full playback; buffered light attacks keep priority. The charge queue preserves the custom stance, and entry blending is .14 seconds; held/release timing is unchanged.
- Strengthened and enlarged limb charge VFX. Effect startup receives the action context directly, covering synchronous timed-action starts before registry publication. Missing debug-track lookups use a bounded presentation-only pose clock and retry throttle; fixed held poses need no lookup. Small cores glow; source flame layers keep normal alpha.
- Charge limits, partial/full damage, smoke behavior/tint, voices, controls and second-finisher rules remain unchanged. No visual/audio/motion asset was generated or modified. Grabs remain disabled.

## Validation

3,931 offline Kahlua assertions pass and all 40 production Lua files compile. Native checks cover world/model projection, limb sample data, charge owner/observer nodes and unchanged asset pixels/hashes. Tests cover marker-gated combo handoff, preserved stance, startup before registration, missing-track rendering, lowered centres, actual limb-height anchors, scoped glow and removal of taunt brightening. See [validation](VALIDATION_0.37.0.md).

PZ was not launched. Live visibility, final blended-pose alignment and animation feel still need a gameplay check after a full restart. Server/clients need the same version.
