token.min=.3;token.max=.5;token.data={}
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
token.push=1.2;token.knockdown=2.4;token.knockback=true;token.always=false
function token:getPushBackMod()return self.push end;function token:setPushBackMod(v)self.push=v end
function token:getKnockdownMod()return self.knockdown end;function token:setKnockdownMod(v)self.knockdown=v end
function token:isKnockBackOnNoDeath()return self.knockback end;function token:setKnockBackOnNoDeath(v)self.knockback=v end
function token:isAlwaysKnockdown()return self.always end;function token:setAlwaysKnockdown(v)self.always=v end
local H=PY.Heat;local style=PY.getStyle('dragon_of_dojima')
local function state()return PY.stateFor(p)end
local function finish()p.attacking=false;fire('OnPlayerAttackFinished',p,p:getPrimaryHandItem());PY.Bindings.update(p);clock=clock+30 end
local function reset()p.attacking=false;p.held=nil;mouse[0]=false;mouse[2]=false;H.stop(p,'test');PY.resetPlayer(p,'test');PY.Weapons.sync(p);PY.Bindings.update(p);clock=clock+100 end
local function activate()PY.setHeat(p,100);check(H.start(p),'mode starts');check(H.isExtreme(p),'mode is active')end
reset()
check(#style.extremeLightAttacks==8,'eight-input boost chain using four supplied clips')
for _,m in ipairs(style.extremeLightAttacks)do check(math.abs(m.damageMultiplier-.75*.7)<.000001,'boost light damage is reduced thirty percent')end
for _,m in ipairs(style.lightAttacks)do check(m.damageMultiplier==.75,'normal light damage remains unchanged')end
check(not style.actions.finisher.variants.extreme_default,'directional heavy removed')
for i=1,4 do
 check(not style.actions.finisher.variants['extreme_after_'..i] and not style.actions.finisher.variants['extreme_double_after_'..i],'directional pair removed '..i)
 local m=style.extremeLightAttacks[i];check(m.extremeHeat and m.hitResponse=='boostStun'and m.noKnockback==true,'mode-only source hit response '..i)
 check(PY.Weapons.findMove(style,m.nodeValue)==m,'server lookup indexes boost '..i)
end
p:AttemptAttack();check(state().activeLightMove==style.lightAttacks[1],'ordinary light retained');finish();reset();activate()
local view=PY.getPlayerStyle(p);check(view.extremeView and view.lightAttacks==style.extremeLightAttacks,'active mode switches light chain')
for i=1,8 do
 PY.Combo.press(state(),8,1);p:AttemptAttack()
 check(token.push==0 and token.knockdown==0 and not token.knockback and not token.always,'boost swing suppresses native push and knockdown '..i)
 check(state().step==i and state().activeLightMove==style.extremeLightAttacks[i],'native boost light '..i)
 check(p.vars.ProjectYakuzaMove==style.extremeLightAttacks[i].nodeValue,'owner selector '..i)
 check(math.abs(token:getMinDamage()-.3*1.5*.525)<.000001 and math.abs(token:getMaxDamage()-.5*1.5*.525)<.000001,'native boost weapon damage has one thirty-percent reduction '..i)
 finish();check(token.push==1.2 and token.knockdown==2.4 and token.knockback and not token.always,"native weapon force settings restore after boost light")
end
reset();activate();H.states[p].fuel=1;p:AttemptAttack()
check(not H.isExtreme(p) and state().activeLightMove==style.extremeLightAttacks[1],'final cost-depleted swing retains boost clip')
fire('OnPlayerUpdate',p);check(p.vars.ProjectYakuzaMove==style.extremeLightAttacks[1].nodeValue,'depletion cannot change playing boost pose')
finish();p:AttemptAttack();check(state().step==1 and state().activeLightMove==style.lightAttacks[1],'normal chain restarts after mode ends');finish();reset()
for last=5,8 do
 reset();activate()
 for i=1,last do PY.Combo.press(state(),8,1);p:AttemptAttack();finish()end
 H.stop(p,'depleted')
 fire('OnPlayerUpdate',p)
 check(p.vars.ProjectYakuzaMove==style.lightAttacks[1].nodeValue,'depleted extended chain restores ready pose '..last)
 p:AttemptAttack();check(state().step==1 and state().activeLightMove==style.lightAttacks[1],'depleted extended chain restarts normal attack '..last);finish()
end
reset()
for _,profile in ipairs({'bat','knife','blade'})do
 local v=PY.Weapons.views[style.id][profile];check(not v.extremeLightAttacks and not v.heatRush and not v.directionalFinishers,'weapons isolate boost input '..profile)
end
local victim={Hit=function()check(token.push==0 and token.knockdown==0 and not token.knockback and not token.always,'server native hit applies temporary zero-force settings');error('injected native Hit failure')end}
local ok=PY.HitResponses.nativeHit(p,victim,token,.1,{noKnockback=true})
check(not ok and token.push==1.2 and token.knockdown==2.4 and token.knockback and not token.always,'failed native Hit still restores original weapon settings')
check(not PY.HitResponses.valid('stun',1),'in-place stun cannot request push force')
local valid=PY.validateStyle({id='invalid_knockback',name='Invalid',lightAttacks={{animation='a',nodeValue='a',duration=1,noKnockback='bad'}},actions={}})
check(not valid,'framework rejects nonboolean knockback overrides')
return true,'PASS '..checks..' boost inputs, eight-link chain, depletion, normal combat and weapon isolation checks'
