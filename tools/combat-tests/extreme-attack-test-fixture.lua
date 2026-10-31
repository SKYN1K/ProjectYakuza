token.min=.3;token.max=.5;token.data={}
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
local H=PY.Heat;local style=PY.getStyle('dragon_of_dojima')
local function state()return PY.stateFor(p)end
local function finish()p.attacking=false;fire('OnPlayerAttackFinished',p,p:getPrimaryHandItem());PY.Bindings.update(p);clock=clock+30 end
local function reset()p.attacking=false;p.held=nil;mouse[0]=false;mouse[2]=false;H.stop(p,'test');PY.resetPlayer(p,'test');PY.Weapons.sync(p);PY.Bindings.update(p);clock=clock+100 end
local function activate()PY.setHeat(p,100);check(H.start(p),'mode starts');check(H.isExtreme(p),'mode is active')end
reset()
check(#style.extremeLightAttacks==8,'eight-input boost chain using four supplied clips')
check(not style.actions.finisher.variants.extreme_default,'directional heavy removed')
for i=1,4 do
 check(not style.actions.finisher.variants['extreme_after_'..i] and not style.actions.finisher.variants['extreme_double_after_'..i],'directional pair removed '..i)
 local m=style.extremeLightAttacks[i];check(m.extremeHeat and m.hitResponse==false,'mode-only source hit response '..i)
 check(PY.Weapons.findMove(style,m.nodeValue)==m,'server lookup indexes boost '..i)
end
p:AttemptAttack();check(state().activeLightMove==style.lightAttacks[1],'ordinary light retained');finish();reset();activate()
local view=PY.getPlayerStyle(p);check(view.extremeView and view.lightAttacks==style.extremeLightAttacks,'active mode switches light chain')
for i=1,8 do
 PY.Combo.press(state(),8,1);p:AttemptAttack()
 check(state().step==i and state().activeLightMove==style.extremeLightAttacks[i],'native boost light '..i)
 check(p.vars.ProjectYakuzaMove==style.extremeLightAttacks[i].nodeValue,'owner selector '..i)
 finish()
end
reset();activate();H.states[p].fuel=1;p:AttemptAttack()
check(not H.isExtreme(p) and state().activeLightMove==style.extremeLightAttacks[1],'final cost-depleted swing retains boost clip')
fire('OnPlayerUpdate',p);check(p.vars.ProjectYakuzaMove==style.extremeLightAttacks[1].nodeValue,'depletion cannot change playing boost pose')
finish();p:AttemptAttack();check(state().step==1 and state().activeLightMove==style.lightAttacks[1],'normal chain restarts after mode ends');finish();reset()
for _,profile in ipairs({'bat','knife','blade'})do
 local v=PY.Weapons.views[style.id][profile];check(not v.extremeLightAttacks and not v.heatRush and not v.directionalFinishers,'weapons isolate boost input '..profile)
end
return true,'PASS '..checks..' boost inputs, eight-link chain, depletion, normal combat and weapon isolation checks'
