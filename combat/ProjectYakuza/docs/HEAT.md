# Heat and Extreme Heat

heat=true opts into a shared player meter, modData.ProjectYakuzaHeat, 0-100, divided into six stocks. Styles without heat neither gain nor activate it. Switching styles ends Extreme Heat/restores modifiers; stored ordinary heat belongs to the player.

| Rule | Current tuning |
| --- | --- |
| Confirmed-hit gain | min(damage,2) * 1.25 for the first eligible target per swing; 25% for additional targets |
| Idle grace/partial decay | 3 seconds / 4 raw points per second |
| Acute damage loss/new knockdown | damage * 0.5 / 8 points |
| Completed stocks | Banked; ordinary losses remove unfinished charge only |
| Completed taunt | +1 stock, capped; requires a pursuing threat within 5 tiles at request, start and completion; interrupted/mode-active gives none |
| Extreme duration | 3.75 seconds per stock before attack/damage costs |
| Swing fuel cost | 1.5 raw points |
| Extreme damage/speed | x1.5 / additional x1.2 |

The first eligible unique target in each swing receives full gain; every further unique target receives a quarter. Repeated callbacks for the same victim give no additional Heat. A new swing resets this order. This applies to Dragon of Dojima and its weapon views; addon styles keep the default multiplier of 1 unless they opt in.

This is PZ-tuned Yakuza-style behavior, not an exact Dragon Engine simulation. Heat.config is global; changing it affects every heat-enabled style.

For the default Dragon of Dojima rules, one stock is 100/6, about 16.67 points. After three seconds without a swing, eligible hit or taunt activity, ordinary Heat loses four points per second, stopping at the last completed stock. For example, 40 points decay to 33.33 and stay there. Eligible incoming damage removes half its damage value in Heat, and a new knockdown removes eight points, with the same completed-stock floor. Bleeding, hunger, thirst, sickness and poison do not cause damage-based Heat loss. Ordinary idle decay requires the style to remain equipped.

Extreme Heat moves all stored points into a separate fuel meter. Its continuous drain is about 4.44 points per second, so a full meter lasts 22.5 seconds before other costs. Every committed swing costs another 1.5 points; eligible damage and new knockdowns also consume fuel, without a retained-stock floor. Normal hits and taunts cannot refill active fuel. The activation animation defers drain until activation completes; paired Heat Actions still consume time while the mode is active. Accepted stock-priced Heat Actions spend their configured stock cost separately from passive loss, including completed stocks. Actions authored with useExtremeFuel can pay from active fuel. These rules were documented in 0.93.0 without changing their tuning.

Activation chooses enabled clips without immediate repetition when alternatives exist. It locks position and temporarily protects; real End playback starts fuel. Missing/interrupted clips restore flags without starting mode. Input cannot manually end mode. Hits/taunts/positive setHeat do not gain heat during mode. Fuel depletes naturally or ends through lifecycle cleanup. Style entry/taunt remain vulnerable. The taunt reward/brief aura flash is at completion.

Require ProjectYakuza/Heat. getHeat/setHeat use ordinary raw points. Heat.stockSize(), stocks(player), display(player), isExtreme(player) provide UI/status. Heat.toggle requests activation; start/stop are lower-level lifecycle helpers, not input shortcuts. Heat.lose removes partial charge/active fuel. Ordinary framework action costs debit on accepted start. Built-in paired Heat Actions defer the debit until native playback is confirmed; missing playback or cancellation before that point costs nothing. Cancellation after payment does not refund it. Put costs on variants themselves. Ordinary heat transfers on activation: custom moves spending Extreme Heat fuel need explicit validated fuel behavior instead of ordinary heatStocks costs. Native strike hooks already apply damage/gain once.

Version 0.42.0 halves confirmed-hit heat gain relative to 0.41.0 (2.5 to 1.25 raw points per damage). The taunt reward remains one stock; losses, Extreme Heat duration/fuel and its no-gain rule are unchanged.

## Optional Heat attack speed (0.61.0)

Addon styles can opt in with heatAttackSpeed={max=1.25,power=1,useExtremeFuel=false}, with per-weapon overrides. The curve is sampled per committed attack, applies to the existing native speed variables and is bounded/replicated in MP snapshots. Fixed-speed timed clips are not automatically retimed. Dragon of Dojima does not enable this feature. See [Heat-based attack speed](HEAT_ATTACK_SPEED.md) for validation, timing and authoring contracts.

## Per-style Heat rules (0.64.0)

Optional `heatConfig` sets per-style gain, normal/Extreme drain and 1..32 stock capacity. Weapon profiles inherit and merge field overrides. Taunt rewards, stock-priced actions, the built-in orb row, custom UI context and server activation protection use the effective capacity. Omitted configuration uses the framework defaults; DoD explicitly sets secondaryTargetGain=.25. See [Heat configuration](HEAT_CONFIGURATION.md) for bounds, defaults, APIs, stock retention and network requirements.
