# Extreme Heat replacement aura - 0.30.1

Extreme Heat replaces the regular heat aura for its full duration. Both use four upper-body patches at identical offsets and scales; no extra leg/waist layers or size changes are introduced. The replacement reorders the already supplied a/b/c HeatWisp sequences and runs them about 20% faster for a distinct flowing pattern.

Base tint is RGB (0.90, 0.98, 1.00), with a restrained additive tint (0.72, 0.93, 1.00) at 16% opacity, gently varying by 6%. Both passes use the same replacement instance/frame; animation advances only once per render. No normal-profile sprite is drawn while extreme is selected. Mode changes preserve completed fade opacity, release old instances and reuse cached sprites; they do not reload textures or allocate emitters on every update.

Taunt completion still flashes the currently selected profile briefly. Normal glow resumes only when Extreme Heat ends and normal heat is eligible; zero-stock exhaustion clears it. Existing toggle/death/unequip/save/MP state behavior remains in place.

Assets: the existing 96 HeatWisp PNG frames, traced in heat-aura-assets.json to supplied raw_event/e_j_0073_spdAura02.dds. No texture/audio/motion was generated, converted or modified for this change. All 310 shipped media files match v0.30.0 byte-for-byte.

Validation: 121 taunt/aura lifecycle/render checks and 2,629 broader combat/aura/music checks pass (2,750 total); 33 production Lua files compile. Tests check exclusive replacement, equal geometry, different supplied sequences, one frame advance across both passes, bounded brightness, renderer-state restoration, cached return and stable allocation. No game was launched; final appearance still needs the user's in-game viewing.
