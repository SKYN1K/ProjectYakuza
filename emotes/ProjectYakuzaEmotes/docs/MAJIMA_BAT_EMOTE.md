# Majima bat-point emote

Hold a usable baseball bat, stop moving and aiming, then open the normal emote wheel and choose Project Yakuza → Majima: Bat Point (hold a bat). Supported native items are BaseballBat, BaseballBat_Crafted, BaseballBat_Metal, BaseballBat_Nails, ShortBat and ShortBat_Nails in the Base module. The secondary hand may be empty or hold the same two-handed item. An unrelated off-hand item, broken or hidden bat, active combat action or pending timed action prevents playback.

The gesture is independent of equipped combat styles and has no Heat gain, cost, damage, threat, protection or voice playback. It uses the existing native held item and model. PZ controls emote completion and cancellation; this feature adds no polling, custom network packets or combat action lease.

The integration follows the native-emote approach of [Custom Voice Framework](https://github.com/DmitryFisk/custom-voice-framework/tree/e0f46546cbbddb864671d9a14887987b3900e2a5). The original framework and separate voice pack are unchanged. Project Yakuza adds its own category after the native menu rebuild and delegates all other selections to the previous handler. It works with either CVF loading order and also without CVF. From CVF's Yakuza 0 submenu, use Back to reach the native category list.

The supplied Kiwami archive is media/data/auth_w64_e/main08_s02.par. Its CMN16 tree binds c_at_majima_U1_S185 to the actor motion and a08_02a_bat_metal_5 to the independently animated bat. Cut 009 resolves these resources to main08_009_6.gmt and main08_009_18.gmt. The emote retains frames 170..321 inclusive at 30 fps, including the raise, pointed hold and lowering. A constant yaw makes the point face forward. PZ limb lengths, supplied native bat fingers, a calibrated palm/grip and per-frame root-Y sole correction adapt the original data without inventing motion samples.

The selector plays ProjectYakuza_MajimaBatPoint in the native emote animation group with full-body and prop weights, a 0.25-second blend and one EmoteFinishing event. Native PlayerEmoteState carries the emote name and playing flag for multiplayer; no combat observer clip is substituted. Every peer needs the same animation and selector. Offline checks verify native state parameters and asset selection; an actual multiplayer session was not run.

See majima-bat-emote-assets.json for source hashes, exact role/resource bindings, frame selection, source yaw, original bat orientations, native grip and grounding corrections. See VALIDATION_0.104.0.md for results. No textures, icons, models or audio were generated or replaced.

This gesture is supplied by the standalone Project Yakuza Emotes mod from version 0.1.0. Project Yakuza combat is optional.
