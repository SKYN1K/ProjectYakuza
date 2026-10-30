local total=0
local function check(ok,msg)total=total+1;if not ok then error(msg)end end
require=function()end
local clock=1000;getTimestampMs=function()return clock end
local paused,typing=false,false
isGamePaused=function()return paused end
local function event()local e={};e.Add=function(fn)e[fn]=true end;e.Remove=function(fn)e[fn]=nil end;return e end
Events={OnPlayerUpdate=event(),OnPlayerGetDamage=event(),OnSave=event(),OnMainMenuEnter=event()}
ISBaseTimedAction={derive=function(_,name)local t={};t.__index=t;return t end}
ISTimedActionQueue={add=function()return true end}
local keys={};local bindings={MELEE=57,FORWARD=17,BACKWARD=31,LEFT=30,RIGHT=32}
KeybindId={};for name in pairs(bindings)do local id=name;KeybindId[id]={getId=function()return id end}end
Keyboard={KEY_LSHIFT=42,KEY_RSHIFT=54,KEY_N=49}
isKeyDown=function(key)return keys[key]==true end
local rmb=false;isMouseButtonDown=function(button)return button==1 and rmb end
getCore=function()return {isDoingTextEntry=function()return typing end,getKey=function(_,id)return bindings[id]end}end
local p={data={},aim=false,vars={},authorize=true,equipped=true}
function p:getModData()return self.data end;function p:isLocalPlayer()return true end
function p:isAiming()return self.aim end;function p:isDead()return self.dead==true end
function p:getVehicle()return self.vehicle end
function p:getPrimaryHandItem()return self.equipped and {getFullType=function()return 'ProjectYakuza.StyleToken' end} or nil end
function p:GetVariable(name)return self.vars[name]or ''end
function p:setVariable(name,value)self.vars[name]=value end
function p:getForwardDirection()return {getX=function()return 1 end,getY=function()return 0 end}end
function p:isAuthorizeMeleeAction()return self.authorize end
function p:setAuthorizeMeleeAction(value)self.authorize=value end
function p:getPlayerNum()return 0 end
function p:getHitReaction()return ''end
for _,name in ipairs({'isOnFloor','isKnockedDown','isClimbing','isDraggingCorpse','isAsleep','hasTimedActions','isAttackStarted','isPerformingAttackAnimation','isBlockMovement','getIgnoreMovement'})do p[name]=function()return false end end
instanceof=function(obj,kind)return kind=='IsoPlayer' and obj==p or kind=='IsoZombie' and obj.zombie==true end
do local _="ProjectYakuzaFixture:MODULES" end
local ProjectYakuza=ProjectYakuza;local H=ProjectYakuza.Heat;local Q=ProjectYakuza.Quicksteps
ProjectYakuza.stateFor=function()return {active=false} end
local z={zombie=true}
p.data.ProjectYakuzaStyle='dragon_of_dojima';p.data.ProjectYakuzaHeat=0
H.states[p]={extreme=true,fuel=45}
for i=1,4 do local ok,reason=H.toggle(p);check(ok==false and reason=='already_active' and H.isExtreme(p),'N cannot cancel active Extreme Heat')end
H.onHit(p,z,2,{active=true});check(ProjectYakuza.getHeat(p)==0 and H.display(p)==45,'hits add neither banked heat nor fuel during Extreme Heat')
check(ProjectYakuza.setHeat(p,50)==false and ProjectYakuza.getHeat(p)==0,'shared framework heat gain also blocked')
H.states[p].extreme=false;ProjectYakuza.setHeat(p,30);check(ProjectYakuza.getHeat(p)==30,'normal heat gain restored outside Extreme Heat')
ProjectYakuza.setHeat(p,0)
local rateCombo={active=true}
H.onHit(p,z,.4,rateCombo);check(ProjectYakuza.getHeat(p)==.5,'hit heat is exactly half the previous .4-damage reward')
H.onHit(p,z,.8,rateCombo);check(ProjectYakuza.getHeat(p)==.5,'same-strike victim deduplication remains intact')
H.onHit(p,{zombie=true},10,{active=true});check(ProjectYakuza.getHeat(p)==3,'two-damage heat cap uses the halved coefficient')
check(H.config.gainPerDamage==1.25 and H.config.secondsPerStock==3.75 and H.stockSize()==100/6,'only gain coefficient changed; mode duration and orb size preserved')
ProjectYakuza.setHeat(p,30)
local calls={}
ProjectYakuza.requestAction=function(player,kind,variant,target)calls[#calls+1]={kind=kind,variant=variant,target=target};return true end
Q.update(p);check(p.authorize,'released shove key preserves native attack authorization')
keys[57]=true;Q.update(p)
check(not p.authorize,'held shove key gates native shove')
check(#calls==1 and calls[1].kind=='quickstep' and calls[1].variant=='backward' and calls[1].target.shove,'idle shove key triggers backstep without RMB')
Q.update(p);Q.update(p);check(#calls==1,'holding shove does not repeat')
keys[57]=false;Q.update(p);keys[17]=true;keys[57]=true;Q.update(p)
check(#calls==2 and calls[2].target.dx<0 and calls[2].target.dy<0,'movement plus shove uses current movement vector')
keys[57]=false;keys[17]=false;Q.update(p);bindings.MELEE=46;ProjectYakuza.Bindings.options={getOption=function(_,id)if id=="key_quickstep" then return {getValue=function()return 46 end} end end}
keys[57]=true;Q.update(p);check(#calls==2,'old key no longer triggers after rebinding')
keys[46]=true;Q.update(p);check(#calls==3,'rebound vanilla shove key triggers quickstep')
keys[46]=false;keys[57]=false;Q.update(p);typing=true;Q.update(p)
check(p.authorize,'typing restores native input authorization')
keys[46]=true;Q.update(p);check(#calls==3,'typing cannot trigger a dash')
typing=false;keys[46]=false;Q.update(p);p.equipped=false;Q.update(p)
check(p.authorize,'unequip restores prior shove behavior')
p.authorize=false;p.equipped=true;Q.update(p);p.equipped=false;Q.update(p)
check(p.authorize==false,'pre-existing blocked shove permission is preserved')
p.authorize=true;p.equipped=true;Q.update(p);Q.restoreAllShoves();check(p.authorize,'save/menu cleanup restores permission')
local handler=ProjectYakuza.actionHandlers.quickstep
local c={player=p,target={shove=true}};local ok=handler.canStart(c)
check(ok and c.shove,'native quickstep handler permits un-aimed replacement')
local aimed={player=p,target={}};local allowed=handler.canStart(aimed)
check(not allowed,'ordinary direct quickstep still requires aiming')
local action=setmetatable({character=p,context={shove=true}},Q.Action)
check(action:isValid(),'replacement action remains valid without RMB')
keys[46]=false;p.aim=true;rmb=true;keys[42]=true;keys[17]=true;Q.update(p)
check(#calls==3,'Shift plus RMB direction shortcut is removed')
Q.restoreAllShoves()
return 'PASS '..total..' Extreme Heat and native shove-to-quickstep checks'
