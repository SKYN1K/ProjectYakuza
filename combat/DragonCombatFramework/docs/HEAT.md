# Heat behavior in 0.16.5

This is a Yakuza 6-style adaptation, not an exact engine port.

## Local evidence and references

The installed game at F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life was read without changing it. data/db/c/player_var.bin contains heat_stock_base=3. battle_param.bin contains heat_up_damage_ratio=0.0002, heat_down_damage_ratio=0.0001, heat_time_down_ratio=0.1, heat_up_guard_success=0.1 and heat_up_asset_break=0.1, plus several drain variants. See y6-heat-parameter-check.json for decoded values. These names and coefficients do not establish engine units, frame timing or every rule; the mod does not pass them directly into Zomboid damage calculations.

Reference: https://gamefaqs.gamespot.com/ps4/181153-yakuza-6-the-song-of-life/faqs/75786/basic-combat
Yakuza 6 starts with three heat stocks and spends stored heat to enter Extreme Heat. Its original UI uses orbs; the current mod uses six connected stock orbs with original atlas assets.

## Charge and loss

- Internal meter remains 0–100 for API/save compatibility, split into six equal stocks.
- A confirmed DCF hit on a zombie adds nativeDamage*2.5 points, with damage capped at 2 per victim per swing. Example: 0.4 damage adds 1 point. Misses add nothing. Duplicate callbacks for one victim/swing add nothing; separate targets can contribute.
- Completed stocks are banked. Only the unfinished stock decays or is reduced by damage/knockdown.
- Idle grace: 3 seconds after a DCF swing/hit. Partial heat then decays 4 points/second.
- Acute damage: loses damage*0.5 partial points. Chronic BLEEDING/HUNGRY/THIRST/SICKNESS/POISON events are excluded. This is a Zomboid-specific mapping, not a claim about Y6 coefficients.
- Falling/knockdown loses 8 partial points once per entry; staying down cannot repeatedly remove heat. Death clears the meter.
- Stored heat persists across saves and unequip. No XP progression or consumable conversion is included. Guard and environmental-break heat hooks require the corresponding combat features, which remain unfinished.

## Extreme Heat

Aim and press H with at least one completed stock. All current heat transfers into a separate fuel meter. Press H while aiming again to end it; cancellation does not refund fuel.

Fuel duration is tuned to 3.75 seconds per stock before attack costs (up to 22.5 seconds for six stocks, 25% longer than the previous full-meter duration). Accepted native swings spend 1.5 fuel points; acute damage also spends fuel. Confirmed hits do not refill the ordinary meter while Extreme Heat is active.

Only the style-token instance receives 1.5x native min/max damage. DCF attack XML reads DCFCombatSpeed: 1.6 normally and 1.92 in Extreme Heat, a 20% increase. Quickstep travel speed is unchanged. Native ignore-stagger-back is temporarily enabled and its original value is retained. Depletion, cancellation, unequip, style change, vehicle entry and death restore modifiers. Token original damage and the player's original stagger flag are tagged for cleanup after a save/load during Extreme Heat. Fuel is transient and is not restored on reload.

This does not provide Y6's full defensive model: zombie wounds, infection, grabs, falling and native damage still apply. No health restoration, damage-subtraction loop or invincibility is added. Cinematic heat actions, an eight-hit Extreme combo, object auto-pickup are not implemented. This release reuses the existing combat animations.

## UI and update cost

The upper-left HUD uses six connected stock orbs and the original dragon/glow atlas regions. Source and destination fill crops ease over 160 active milliseconds, preserving the original image proportions. Glow and activation timing pause with the game. The HUD passes mouse clicks through and samples heat at 10 Hz. All six stocks are real banks, and Extreme Heat shows remaining fuel using the same orbs.

No new artwork is generated. The old bar implementation is retained in docs/reference/HeatUI-Bar-preserved.lua. Rates remain exposed in DragonCombat.Heat.config. An action can specify heatStocks=1 to spend one of six stocks only after its handler starts successfully. See HUD_POLISH_AND_SIX_STOCKS.md for this release's scope and validation.
