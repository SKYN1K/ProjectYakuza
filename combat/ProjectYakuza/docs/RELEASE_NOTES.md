# Project Yakuza 0.99.0

- Menu/interface WAVs now explicitly set both distance limits to zero as well as is3D=false. This selects the native non-positional playback path and fixes sounds remaining at the player's earlier menu position. Original Kiwami/Y6 PCM bytes are unchanged.
- Replaced the combat-entry animation with Kiwami 1's original Dragon P_KRL_style_st: all 46 samples, 1.5 seconds at original speed. It releases into the game-selected vanilla idle/aim with a 0.3-second fade. The old custom unarmed idle overrides are removed, and cleanup clears only its own action variable.
- Fixed one-orb Heat Action eligibility/payment: client, server and payment checks now share the orb counter's tiny floating-point tolerance. A native-rounded full stock can start and pay once; genuinely underfilled stocks are rejected. Extreme fuel stock-boundary updates are sent before dependent MP commands.
- Seated the reduced beer crate on the native victim's head throughout its Heat Action and failure recovery. Only right-prop translation changes; source body poses, crate rotation, timings, QTEs and damage remain.
- Replaced the bicycle Heat Action with Yakuza 6's original h23701_buki_f big/heavy-object scene and independent object track, all 145 samples at original speed. Its original frame-58 hit, three sound cues, actor voice role and four blood starts replace the Y5 action events. The existing bicycle model, reduced texture and ordinary attacks remain.
- Heat aura, transient aura bursts and owned outline now hide while the full map is visible. Their clocks keep the existing pause behavior and rendering resumes after closing the map.
- All 30 Kahlua suites, 82 production Lua compilations, native source/grip/contact/idle/audio checks, 450 MP observer selectors and zero-comment checks pass offline. Project Zomboid was not launched.

See [validation](VALIDATION_0.99.0.md), [combat entry](COMBAT_ENTRY.md), [interface audio](INTERFACE_AUDIO.md), [bicycle](BICYCLE.md) and [crate](BEER_CRATE.md).
