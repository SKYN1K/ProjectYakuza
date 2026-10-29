# Heat and Extreme Heat

heat=true opts into a shared player meter, modData.ProjectYakuzaHeat, 0-100, divided into six stocks. Styles without heat neither gain nor activate it. Switching styles ends Extreme Heat/restores modifiers; stored ordinary heat belongs to the player.

| Rule | Current tuning |
| --- | --- |
| Confirmed-hit gain | min(damage,2) * 1.25 per eligible zombie/strike |
| Idle grace/partial decay | 3 seconds / 4 raw points per second |
| Acute damage loss/new knockdown | damage * 0.5 / 8 points |
| Completed stocks | Banked; ordinary losses remove unfinished charge only |
| Completed taunt | +1 stock, capped; interrupted/mode-active gives none |
| Extreme duration | 3.75 seconds per stock before attack/damage costs |
| Swing fuel cost | 1.5 raw points |
| Extreme damage/speed | x1.5 / additional x1.2 |

This is PZ-tuned Yakuza-style behavior, not an exact Dragon Engine simulation. Heat.config is global; changing it affects every heat-enabled style.

Activation chooses enabled clips without immediate repetition when alternatives exist. It locks position and temporarily protects; real End playback starts fuel. Missing/interrupted clips restore flags without starting mode. Input cannot manually end mode. Hits/taunts/positive setHeat do not gain heat during mode. Fuel depletes naturally or ends through lifecycle cleanup. Style entry/taunt remain vulnerable. The taunt reward/brief aura flash is at completion.

Require ProjectYakuza/Heat. getHeat/setHeat use ordinary raw points. Heat.stockSize(), stocks(player), display(player), isExtreme(player) provide UI/status. Heat.toggle requests activation; start/stop are lower-level lifecycle helpers, not input shortcuts. Heat.lose removes partial charge/active fuel. Configured action costs debit only on accepted start and are not automatically refunded on cancel. Put costs on variants themselves. Ordinary heat transfers on activation: custom moves spending Extreme Heat fuel need explicit validated fuel behavior instead of ordinary heatStocks costs. Native strike hooks already apply damage/gain once.

Version 0.42.0 halves confirmed-hit heat gain relative to 0.41.0 (2.5 to 1.25 raw points per damage). The taunt reward remains one stock; losses, Extreme Heat duration/fuel and its no-gain rule are unchanged.
