local S=PY.Sandbox;local style=PY.getStyle('dragon_of_dojima');local other={id='addon.counter',actions={}}
SandboxVars=nil
check(S.enabled('ExtremeHeat')and S.enabled('Grabs')and S.enabled('HeatActions')and S.tigerDrop(style),'missing sandbox vars preserve gameplay defaults')
check(S.tigerWindowMs(style)==160 and S.tigerCooldownMs(style)==20000,'defaults match published Tiger Drop timings')
for mask=0,15 do
 local vars={};local names={'DragonTigerDrop','HeatActions','Grabs','ExtremeHeat'}
 for i,key in ipairs(names)do vars[key]=math.floor(mask/2^(i-1))%2==1 end
 SandboxVars={ProjectYakuza=vars}
 check(S.actionAllowed(style,'parry')==vars.DragonTigerDrop,'Tiger Drop toggle '..mask)
 check(S.actionAllowed(style,'heatActivation')==vars.ExtremeHeat,'Extreme Heat toggle '..mask)
 check(S.actionAllowed(style,'grab')==vars.Grabs,'grab toggle '..mask)
 check(S.actionAllowed(style,'groundHeat')==vars.HeatActions,'ground Heat toggle '..mask)
 check(S.actionAllowed(style,'grabHeat')==(vars.HeatActions and vars.Grabs),'grab Heat needs both switches '..mask)
 check(S.actionAllowed(style,'heatAction')==(vars.HeatActions and vars.ExtremeHeat),'Extreme Heat QTE needs both switches '..mask)
 check(S.actionAllowed(style,'heatAction',{weaponHeat=true})==vars.HeatActions,'weapon Heat Actions are independent of the Extreme Heat toggle '..mask)
 check(S.actionAllowed(other,'parry')and S.actionAllowed(style,'block')and S.actionAllowed(style,'finisher'),'unrelated counters, guards and attacks stay available '..mask)
end
SandboxVars={ProjectYakuza={DragonTigerDropWindowMs=35,DragonTigerDropCooldownSeconds=2.5}}
check(S.tigerWindowMs(style)==35 and S.tigerCooldownMs(style)==2500,'configured timing and fractional seconds are read dynamically')
check(S.tigerWindowMs(other)==160 and S.tigerCooldownMs(other)==20000,'Dragon timing does not change addon counter timings')
for _,case in ipairs({{0,10},{9999,1000},{30.5,31},{0/0,160},{math.huge,160},{'160',160}})do SandboxVars.ProjectYakuza.DragonTigerDropWindowMs=case[1];check(S.tigerWindowMs(style)==case[2],'timing validates, clamps and rounds safely')end
for _,case in ipairs({{-1,0},{9999,600000},{0,0},{0/0,20000},{math.huge,20000},{'x',20000}})do SandboxVars.ProjectYakuza.DragonTigerDropCooldownSeconds=case[1];check(S.tigerCooldownMs(style)==case[2],'cooldown validates safely, including zero')end
SandboxVars={ProjectYakuza={DragonTigerDrop=false,HeatActions=false,Grabs=false,ExtremeHeat=false}}
PY.setHeat(p,100);local before=PY.getHeat(p)
for _,kind in ipairs({'parry','grab','grabHeat','heatAction','groundHeat','heatActivation'})do local ok,reason=PY.requestAction(p,kind,nil,{});check(not ok and reason=='sandbox_disabled'and not PY.activeActions[p]and PY.getHeat(p)==before,'disabled action has no stock or ownership side effects: '..kind)end
local ok,reason=PY.Heat.start(p);check(not ok and reason=='sandbox_disabled'and PY.getHeat(p)==before,'direct Extreme Heat startup cannot bypass sandbox')
SandboxVars={ProjectYakuza={Grabs='bad',ExtremeHeat=0,HeatActions={}}};check(S.enabled('Grabs')and S.enabled('ExtremeHeat')and S.enabled('HeatActions'),'invalid bool values keep defaults')
SandboxVars=nil
return true,'PASS '..checks..' sandbox defaults, switch combinations, safe timing limits, style scope and no-payment action gates'
