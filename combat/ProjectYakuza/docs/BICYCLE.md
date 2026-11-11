# Bicycle weapon and Heat Action

Version 0.97.0 adds ProjectYakuza.Bicycle, displayed as Bicycle (Yakuza 5). Obtain it through the native debug/admin item spawner or another addon that supplies the item. It weighs 7, is two-handed and uses native weapon condition/damage. No loot distribution, rideable vehicle or automatic world-object pickup is added.

Equip Dragon of Dojima and the bicycle. Hold physical RMB and press the Heat Action binding, MMB by default, near an eligible standing target outside a combo. It uses one Heat stock or equivalent Extreme Heat fuel, paid after confirmed playback. Shared protection, target clearance, interruption cleanup, lethal recovery and server authority apply. Other weapons cannot borrow this action.

The source is the user's installed Yakuza 5 h11010_jitensha.par. The original 125..308 strike/recovery section retains 184 samples per participant at 30 fps and lasts 6.1 seconds. The cinematic riding approach is excluded because its distant stage placement does not suit nearby targeting. Victim damage at source frames 131/158 maps to action frames 6/33, each dealing 0.75 times canonical held-weapon damage. A separate source prop-damage event at 174 is excluded from victim damage. Four original non-voice cues, two actor voice roles using existing Combat entries and three source blood-family attachments follow their independent original starts.

The model is the supplied wemap0006_bicycle_low.gmd, with 397 original vertices, 250 triangles, normals and UVs. It is rebased to the source hand attachment and driven by the original object-root track. The supplied blue diffuse is reduced from 256x256 to 128x128 by nearest-neighbour sampling, retaining original texels and alpha. Individual wheel/pedal animation and physics fragments are not recreated. The item uses the existing PZ tire icon. No visual or audio content is invented.

Ordinary attacks use the original Yakuza 5 P_WPC_CMB_01/02/03 and P_WPC_ATK_heavy large-object motions. The original overhead heavy is reused for floor targets. All source frames are retained before existing 1.4x combat playback. Native contact markers are calibrated from maximum two-hand sweep speed in the attack section; these are not CMN damage markers.

Source archive entries, original hashes, selected frames, native prop contracts and deterministic output hashes are recorded in bicycle-model-assets.json, bicycle-texture.json, bicycle-heat-assets.json and y5-object-attacks.json. See [validation](VALIDATION_0.97.0.md). Live blends and appearance require gameplay verification after restarting.
