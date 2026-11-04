require "ProjectYakuza/Registry"
require "ProjectYakuza/WallHeatPaths"
require "ProjectYakuza/GroundHeatPaths"
ProjectYakuza.GrabMoves={
    {animation="ProjectYakuza_DD_GrabStrike01",targetAnimation="ProjectYakuza_DD_GrabStrikeVictim01",duration=1.0,contactMs=233.33333333333334,damageMultiplier=.65},
    {animation="ProjectYakuza_DD_GrabStrike02",targetAnimation="ProjectYakuza_DD_GrabStrikeVictim02",duration=1.3,contactMs=566.6666666666666,damageMultiplier=.65},
    {animation="ProjectYakuza_DD_GrabStrike03",targetAnimation="ProjectYakuza_DD_GrabStrikeVictim03",duration=1.3,contactMs=566.6666666666666,damageMultiplier=.65},
    {animation="ProjectYakuza_DD_GrabStrike04",targetAnimation="ProjectYakuza_DD_GrabStrikeVictim04",duration=1.3,contactMs=566.6666666666666,damageMultiplier=.65},
}
ProjectYakuza.WallHeatMove={enabled=true,grabHeat=true,requiresTarget=true,animation="ProjectYakuza_DD_WallHeat",targetAnimation="ProjectYakuza_DD_WallHeatVictim",nodeValue="dd_wall_heat",motionId="dod_wall",duration=140/30,heatStocks=1,useExtremeFuel=true,noKnockback=true,hitResponse=false,deferFinalDamage=true,contacts={{atMs=1/30*1000,damageMultiplier=0,cue="throwImpact",voice="CombatLightAttack",strong=false},{atMs=28/30*1000,damageMultiplier=0,cue="heavyImpact",voice="CombatHeavyAttack",strong=true},{atMs=73/30*1000,damageMultiplier=5,cue="throwImpact",voice="CombatHeavyAttack",strong=true}}}

ProjectYakuza.GroundHeatMove={enabled=true,groundHeat=true,requiresTarget=true,animation="ProjectYakuza_DD_GroundHeat",targetAnimation="ProjectYakuza_DD_GroundHeatVictim",nodeValue="dd_ground_heat",motionId="dod_ground",duration=110/30,heatStocks=1,useExtremeFuel=true,noCombo=true,noKnockback=true,hitResponse=false,deferFinalDamage=true,contacts={{atMs=30/30*1000,damageMultiplier=5,cue="heavyImpact",voice="CombatHeavyAttack",strong=true}}}
