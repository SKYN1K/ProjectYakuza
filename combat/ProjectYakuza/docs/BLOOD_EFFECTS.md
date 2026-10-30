# Original Yakuza 6 blood (0.48.0)

Dragon of Dojima now displays a small red blood burst on confirmed damaging zombie hits alongside the existing hit sparks. The normal-heavy/finisher and charged variants use slightly larger bursts. Grounded targets use a low contact anchor. Swings that miss do not create blood, and the existing per-swing victim guard prevents duplicate primary/supplementary callbacks from replaying it.

The source is the supplied Yakuza 6 e_j_0035_bfBloodSplash03.dds atlas. Sixteen 128x128 cells are decoded/cropped in row-major order with identical source RGBA pixels and transparency. The user explicitly approved conversion. No AI, generated artwork, upscaling, recolouring, matte conversion or interpolated animation frames. Source/output hashes and crop rectangles are in blood-effects-assets.json.

The effect plays all 16 source frames once over 400 ms, with a short opacity fade at the end. It uses detached native world sprites with normal alpha blending, not HUD drawing or additive glow. Its world centre follows the victim, without a facing-dependent arm offset. Native PZ wounds, blood on real equipment, blood decals, damage and hit timing remain unchanged.

Existing multiplayer confirmed-impact presentation calls the same spawn path for observers; no new damage event or packet protocol was added. This includes the existing strong-impact presentation for Tiger Drop. Maximums are four concurrent blood bursts per attacker and sixteen globally. The sixteen frame sprites are cached lazily; pooled instances are released on frame changes, completion, disable, death, save or exit. No tick/render hooks remain while idle. Pause freezes animation time; repeated renders at the same clock do not advance frames.

Inventory context menu > Combat styles > Toggle hit effects disables both existing sparks and blood. Other styles do not inherit blood automatically. Developers opt in with bloodEffects="yakuza6" and hitEffects="yakuza6" for the built-in confirmed-hit path. ProjectYakuza.BloodEffects.spawn(player,victim,strong,charged) and clear(player) are client presentation helpers. Custom callers must already have confirmed the hit and manage any additional deduplication.

Offline source-pixel, native decoder, Kahlua lifecycle and world-anchor tests pass. The game was not launched, so live size, appearance and MP latency still need user assessment after restarting matching installations.
