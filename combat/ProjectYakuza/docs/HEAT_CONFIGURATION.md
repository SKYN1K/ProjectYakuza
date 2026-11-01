# Per-style Heat configuration (0.64.0)

Styles opt into the existing Heat system with `heat=true`. Optional `heatConfig` tunes gain, drain and stock capacity without changing other styles. Heat and Extreme fuel remain normalized from 0 to 100; capacity changes the number of stocks inside that gauge, not the saved resource format. Switching styles preserves the existing shared Heat percentage. Dragon of Dojima and its weapon profiles omit this configuration and retain their previous six-stock rules.

```lua
heat=true,
heatConfig={
    maxStocks=4,
    gainPerDamage=2.5,
    lossPerDamage=.5,
    idleGraceMs=3000,
    idleLossPerSecond=3,
    knockdownLoss=8,
    secondsPerStock=5,
    attackFuelCost=1,
    retainStocks=false,
},
```

| Setting | Default | Allowed values and meaning |
| --- | --- | --- |
| maxStocks | 6 | Integer 1..32; one orb/bar stock is 100 divided by capacity |
| gainPerDamage | 1.25 | 0..100 normalized Heat per confirmed damage point; existing per-victim deduplication and two-point damage cap apply |
| lossPerDamage | .5 | 0..100 Heat loss per eligible incoming damage point; existing passive illness/bleeding exclusions remain |
| idleGraceMs | 3000 | 0..600000 ms since the last combat/taunt activity before idle drain |
| idleLossPerSecond | 4 | 0..100 normalized Heat points per second after grace |
| knockdownLoss | 8 | 0..100 loss on the first update of a knockdown |
| secondsPerStock | 3.75 | .1..600 seconds of Extreme Heat per stock, before attack/damage fuel costs |
| attackFuelCost | 1.5 | 0..100 normalized Extreme fuel spent per committed attack |
| retainStocks | true | Boolean; protect completed normal stocks from loss, or allow continuous drain through them |

Omitted settings inherit the unchanged defaults. `heatConfig=false` resets to defaults; it does not disable Heat. Unknown keys, invalid types, nonfinite values and out-of-range values fail style registration. Keep registered definitions immutable while playing; re-register changes or restart with the updated addon. The shared resolver caches merged configurations and invalidates on official style registration. The returned rule tables are read-only by convention.

Normal retained-stock mode drains only the unfinished part above the last completed stock. Set `retainStocks=false` for normal loss that can empty the entire gauge. Extreme Heat always consumes fuel and still blocks Heat gain while active. `secondsPerStock` and capacity determine the time drain as `100 / maxStocks / secondsPerStock` Heat per second; `attackFuelCost` adds to that drain. Existing activation animation, forced-stop restrictions, damage/speed bonuses and input handling remain separate settings/systems. Heat-based attack speed remains an independent opt-in feature.

Weapon profiles inherit the owning style's configuration. A profile `heatConfig` table overrides only the specified fields, merging other authored base-style fields. A profile `heatConfig=false` uses framework defaults. These settings remain style-owned and do not affect ordinary weapons outside that style.

`ProjectYakuza.Heat.rules(player)` returns the effective equipment-view rules. `Heat.stockSize(player)` and `Heat.stocks(player)` use that capacity. A no-player stockSize call returns the default stock size. `ProjectYakuza.HeatRules.forStyle(styleView)` and `HeatRules.stockSize(styleView)` expose the same resolver in shared/server code. `HeatRules.valid(config)` checks authoring bounds. Do not modify `Heat.config` to configure an individual style; it remains the shared defaults object.

Stock-priced actions (`heatStocks`) and completed taunt rewards now use the acting player's stock size. Raw `heatCost` stays in normalized Heat points. The server uses the registered equipment view's stock size when authorizing activation protection. Heat/fuel packets remain bounded 0..100 and require matching style definitions on all peers; no per-packet configuration is accepted from a client.

Style UI callbacks receive the effective `context.maxStocks`, stock count and normalized Heat. Custom bar/orb renderers can use those values for their own layouts. The existing Y6 orb renderer repeats only its unchanged supplied ring/connector textures for the configured capacity, extending its panel width as needed; six stocks keep their original coordinates. Very wide gauges may need an addon layout suited to the player's viewport. No new artwork, audio, texture conversion or animation asset is involved.
