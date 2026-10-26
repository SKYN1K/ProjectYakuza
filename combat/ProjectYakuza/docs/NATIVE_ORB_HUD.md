# Original-asset connected orb HUD

The active HUD uses only original artwork from the game's e/texture/btl_hact.dds and e/texture/btl.dds. Both atlases are losslessly converted to PNG, with every RGBA pixel checked against the source. No repainting, texture enlargement, generated animation frames or new graphical artwork is used. The older bar implementation and its assets remain preserved for later reference and are not loaded by the active HUD.

The original heat_gauge.bin and e/texlist/btl_texlist.bin were decoded to obtain actual sprite rectangles, placement offsets and head scaling. The dragon body, head, six orb frames, serpentine connectors, tail and main-orb kanji now form one continuous composition. A common 0.75 display scale keeps the source artwork at or below its original resolution. Original glow pieces use native transparency rendering with state restored afterward; shared pixel boundaries avoid seams.

The reference's six small orbs visualize the existing heat capacity: two visual orb sections per banked stock, with the existing three-stock combat system unchanged. Completed and partial sections fill according to the existing heat value. Ready and Extreme Heat states use the original glow sprites. The earlier custom text label is no longer drawn. No red health gauge is added.

839 native Kahlua assertions pass, including correct atlas crop routing, original connector/tail/kanji selection, six visual orbs, glow state restoration, panel bounds, pause/cancel and existing combat/aura behavior. Packaging checks source-pixel identity, hashes, and the preserved bar implementation. The aura and other combat media remain byte-identical to v0.16.0. Live GPU appearance still needs an in-game check.

ARMP format notes used while reading the original layout: [Ret-HZ/reARMP](https://github.com/Ret-HZ/reARMP). The game binaries are read-only inputs; they are not modified.
