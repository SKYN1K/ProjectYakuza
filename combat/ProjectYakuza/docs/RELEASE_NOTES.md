# Project Yakuza 0.97.0

- Added the supplied Yakuza 5 bicycle model and original h11010_jitensha Heat Action. Equip ProjectYakuza.Bicycle with Dragon of Dojima, hold physical RMB and press the Heat Action binding (default MMB) near an eligible standing target outside a combo. One stock or equivalent Extreme Heat fuel is paid only after confirmed playback.
- Retained original strike/recovery frames 125..308 at 30 fps, including both victim hits, source object-root motion, original sound/voice starts and blood attachments. The long riding approach is excluded for nearby-target gameplay. This is an inventory weapon; individual wheel/pedal animation and physics fragments are not recreated.
- Used the original low-detail bicycle mesh (397 vertices, 250 triangles), with original UVs/normals and its supplied 256x256 diffuse reduced to 128x128 using nearest source texels. No generated art, upscaling or audio.
- Halved the beer crate's linear model size and corrected its world-model reference. Replaced its three ordinary combo attacks, heavy and ground strike with supplied Yakuza 5 large-object motions. The ground strike reuses the original overhead heavy; the existing Yakuza 5 H3270 Heat Action and guard are retained.
- Corrected the katana's hilt pivot and native right-wrist fit through the original grip change. Preserved source airborne motion, release/catch, sharp-end thrust and all original hit times. Adjusted paired victim staging against native anatomy for slash, punch and thrust, with a shared thrust offset to avoid following the moving blade.
- All 30 Kahlua suites pass, including bicycle confirmed-playback payment, canonical contacts, interruption/lethal recovery and authoritative MP replay checks. Native source/importer, exact reduced pixels, PCM decode, selector and comment checks pass offline. Project Zomboid was not launched.

See [bicycle controls and source contract](BICYCLE.md), [crate](BEER_CRATE.md) and [validation](VALIDATION_0.97.0.md).
