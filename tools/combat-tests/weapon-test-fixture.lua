require=function()end
local checks=0
local function check(v,message)checks=checks+1;assert(v,message)end
local clock=1000
getTimestampMs=function()return clock end
isGamePaused=function()return false end
isClient=function()return false end
instanceof=function()return true end
local function event()local e={callbacks={}};e.Add=function(fn)e.callbacks[#e.callbacks+1]=fn end;e.Remove=function()end;return e end
Events={OnTick=event(),OnPlayerGetDamage=event(),OnPlayerUpdate=event(),OnWeaponSwing=event(),OnPlayerAttackFinished=event(),OnWeaponHitCharacter=event(),OnSave=event(),OnMainMenuEnter=event()}
local function fire(name,...)for _,fn in ipairs(Events[name].callbacks)do fn(...)end end
local mouse={};isMouseButtonDown=function(i)return mouse[i]==true end
isKeyDown=function()return false end
getCore=function()return {isDoingTextEntry=function()return false end}end
local base={}
function base:derive()local c={};c.__index=c;setmetatable(c,{__index=self});return c end
function base.new(class,p)return setmetatable({character=p},class)end
local completions=0
function base.perform()completions=completions+1 end
function base.stop()end
ISBaseTimedAction=base
ISTimedActionQueue={add=function()return {}end}
do local _="ProjectYakuzaFixture:REGISTRY" end
do local _="ProjectYakuzaFixture:WEAPONS" end
do local _="ProjectYakuzaFixture:COMBO" end
do local _="ProjectYakuzaFixture:STYLE" end
do local _="ProjectYakuzaFixture:BINDINGS" end
local PY=ProjectYakuza
PY.StyleEntry={request=function()return true end}
local swingEvents=0
do local _="ProjectYakuzaFixture:HEAT" end
do local _="ProjectYakuzaFixture:RUNTIME" end
do local _="ProjectYakuzaFixture:QUICKSTEPS" end
do local _="ProjectYakuzaFixture:MULTIHIT" end
do local _="ProjectYakuzaFixture:MENU_EQUIP" end
local Q=PY.Quicksteps
local token={getFullType=function()return PY.TOKEN end,getMaxHitCount=function()return 3 end,getWeaponSprite=function()return 'ProjectYakuza_EmptyHand' end}
local p={vars={},data={ProjectYakuzaStyle='dragon_of_dojima'},allowed=true,attacking=false,async=false,reject=false,submissions=0}
function p:getPlayerNum()return 0 end
function p:getModData()return self.data end
function p:isLocalPlayer()return true end
function p:isDead()return false end
function p:isAiming()return true end
function p:getPrimaryHandItem()return self.held or token end
function p:setVariable(k,v)self.vars[k]=v end
function p:GetVariable(k)return self.vars[k]end
function p:isWeaponReady()return true end
function p:isAttackStarted()return self.attacking end
function p:isPerformingAttackAnimation()return self.attacking end
function p:isAuthorizeMeleeAction()return self.allowed end
function p:setAuthorizeMeleeAction(v)self.allowed=v end
function p:setMeleeDelay()end
function p:setBlockMovement(v)self.blocked=v end
function p:getIgnoreMovement()return false end
function p:setIgnoreMovement()end
function p:AttemptAttack()
 if not self.allowed or self.reject then return false end
 self.submissions=self.submissions+1;self.attacking=true
 if not self.async then fire('OnWeaponSwing',self,self:getPrimaryHandItem())end
 return false
end

function p:isOnFloor()return false end;function p:isKnockedDown()return false end
function p:isClimbing()return false end;function p:getVehicle()return nil end
function p:hasTimedActions()return false end;function p:isBlockMovement()return false end
function p:getHitReaction()return '' end;function p:getCurrentStateName()return self.attacking and 'SwipeStatePlayer' or 'IdleState' end
function p:isAimAtFloor()return false end;function p:isPerformingStompAnimation()return false end
function p:setPerformingAttackAnimation(v)self.performing=v end
function p:reportEvent(name)self.report=name end
function p:setIgnoreStaggerBack(v)self.stagger=v end;function p:isIgnoreStaggerBack()return self.stagger==true end
function p:getX()return 0 end;function p:getY()return 0 end;function p:getZ()return 0 end
function p:getForwardDirection()return {getX=function()return 1 end,getY=function()return 0 end}end
function p:isDraggingCorpse()return false end;function p:isAsleep()return false end
local function weapon(id)
 local w={id=id,min=.8,max=1.2,data={},condition=10}
 function w:getMaxRange()return self.range or 1.25 end
 function w:getFullType()return self.id end;function w:getCondition()return self.condition end
 function w:getMinDamage()return self.min end;function w:getMaxDamage()return self.max end
 function w:setMinDamage(v)self.min=v end;function w:setMaxDamage(v)self.max=v end
 function w:getModData()return self.data end
 return w
end
local W=PY.Weapons;local bat=weapon('Base.BaseballBat');local pipe=weapon('Base.MetalPipe');local knife=weapon('Base.WoodAxe')
local original=PY.getStyle('dragon_of_dojima')
local armed=W.views.dragon_of_dojima.bat
check(armed~=original and armed.id==original.id,'equipment view preserves style identity without mutating base')
check(#armed.lightAttacks==3 and #original.lightAttacks==4,'three weapon attacks and four original unarmed attacks')
check(not armed.actions.heavyCharge and not armed.actions.runningAttack and not armed.tigerDrop,'unarmed special moves do not leak into weapons')
check(armed.actions.quickstep==original.actions.quickstep,'same quota-controlled quickstep retained')
check(armed.actions.styleEntry==original.actions.styleEntry,'armed profiles retain style selection entry')
check(armed.actions.block.animation=='ProjectYakuza_DD_BatGuard','weapon-specific moving guard')
for _,id in ipairs(W.profiles.dragon_of_dojima.bat.items)do check(W.profile(original.id,weapon(id))=='bat','explicit supplied blunt weapon '..id)end
check(not W.profile(original.id,knife),'heavy axe retains vanilla combat')
p.held=bat;p.data.ProjectYakuzaStyle=nil
check(not PY.isEquipped(p),'weapons require explicit style selection')
p.data.ProjectYakuzaStyle='dragon_of_dojima';W.sync(p)
check(PY.isEquipped(p) and PY.getPlayerStyle(p)==armed,'selected DoD and real weapon work simultaneously')
check(PY.isCombatWeapon(p,bat) and not PY.isCombatWeapon(p,pipe),'hit callback must use actual held item')
local function finish()
 p.attacking=false;fire('OnPlayerAttackFinished',p,p:getPrimaryHandItem());clock=clock+40
end
for i=1,3 do
 mouse[0]=false;fire('OnPlayerUpdate',p);mouse[0]=true;fire('OnPlayerUpdate',p)
 if not p.attacking then p:AttemptAttack() end
 local state=PY.stateFor(p)
 check(state.active and state.step==i and p.vars.ProjectYakuzaMove==armed.lightAttacks[i].nodeValue,'native swing routed to weapon combo '..i)
 check(bat.min==.8 and bat.max==1.2,'lights retain native weapon damage')
 if i==1 then
  PY.setHeat(p,0);local victim={};fire('OnWeaponHitCharacter',p,victim,bat,.4)
  check(math.abs(PY.getHeat(p)-.5)<.00001,'real weapon native hit earns current reduced heat')
  fire('OnWeaponHitCharacter',p,victim,bat,.4)
  check(math.abs(PY.getHeat(p)-.5)<.00001,'same victim cannot duplicate heat within a swing')
 end
 finish()
end
check(PY.queueFinisher(p),'weapon heavy available after combo')
check(PY.stateFor(p).finisherMove.nodeValue=='dd_bat_heavy','MMB uses weapon heavy instead of unarmed finisher')
check(math.abs(bat.min-1)<.00001 and math.abs(bat.max-1.5)<.00001,'heavy uses native weapon damage times 1.25')
check(not PY.queueFinisher(p),'heavy cannot queue itself or a double finisher')
finish();check(bat.min==.8 and bat.max==1.2,'heavy restores native damage')
PY.resetPlayer(p,'test');clock=clock+600
check(PY.queueFinisher(p),'weapon heavy also works without prior light')
finish();PY.resetPlayer(p,'test')
p:AttemptAttack();check(PY.queueFinisher(p) and PY.stateFor(p).queuedWeaponHeavy,'heavy queues behind a running light')
check(not PY.stateFor(p).queuedFinisher,'weapon heavy does not consume an unarmed branch')
finish();fire('OnPlayerUpdate',p)
check(PY.stateFor(p).finisherMove and PY.stateFor(p).finisherMove.nodeValue=='dd_bat_heavy','queued heavy starts after native light exits')
finish();PY.resetPlayer(p,'test')
PY.Heat.applyMoveDamage(p,{damageMultiplier=1.25});check(bat.min==1,'real weapon gets scoped multiplier')
p.held=pipe;W.sync(p)
check(bat.min==.8 and bat.max==1.2 and not bat.data.ProjectYakuzaMoveOriginalMin,'swapping restores the old item')
check(not PY.stateFor(p).active and PY.groundNext[0]==1,'same-profile weapon swap resets combo and ground variant')
PY.stateFor(p).active=true;PY.stateFor(p).step=3
pipe.condition=0;W.sync(p)
check(not PY.isEquipped(p) and not PY.stateFor(p).active,'breakage safely exits custom combat')
pipe.condition=10;p.held=knife;W.sync(p)
check(not PY.isEquipped(p) and PY.getPlayerStyle(p)==original,'unsupported weapon remains native')
p.held=nil;W.sync(p);check(PY.getPlayerStyle(p)==original and PY.isEquipped(p),'equipping token restores original unarmed style')

local addon={};for k,v in pairs(original)do addon[k]=v end;addon.id='tests.other';PY.registerStyle(addon)
p.data.ProjectYakuzaStyle=addon.id;p.held=bat
check(not PY.isEquipped(p) and PY.getPlayerStyle(p)==addon,'another style never inherits DoD weapon animations')
local before=W.byItem[original.id]['Tests.UnmappedBlade']
check(not pcall(W.register,original.id,{id='bad',items={'Tests.UnmappedBlade','Base.BaseballBat'},lightAttacks=armed.lightAttacks}),'duplicate mapping rejected')
check(W.byItem[original.id]['Tests.UnmappedBlade']==before and not W.profiles[original.id].bad,'failed registration does not partially publish')
check(not pcall(W.register,original.id,{id='bad',items={'Tests.UnmappedBlade'},lightAttacks={}}),'invalid move definitions rejected')
check(not W.byItem[original.id]['Tests.UnmappedBlade'],'invalid style view cannot publish item mapping')
check(not pcall(W.register,original.id,{id='bad',items={'Tests.UnmappedBlade'},lightAttacks={{animation=original.lightAttacks[1].animation,nodeValue=original.lightAttacks[1].nodeValue,duration=1}}}),'distinct profiles cannot shadow base collision node IDs')
check(not pcall(W.register,original.id,{id='bad',items={'Tests.UnmappedBlade'},lightAttacks=armed.lightAttacks,standaloneHeavy=true}),'standalone heavy requires an actual heavy definition')
PY.resetPlayer(p,'test');p.attacking=false;p.held=bat
PY.equipStyle(p,original.id)
check(p.held==bat and PY.getPlayerStyle(p)==armed,'actual style menu retains supported real weapon')
check(p.data.ProjectYakuzaStyle==original.id,'style identity remains selected while holding weapon')

p.data.ProjectYakuzaStyle=original.id;p.held=bat;W.sync(p);PY.resetPlayer(p,'test');p.attacking=false
p:AttemptAttack();local state=PY.stateFor(p);local move=armed.lightAttacks[1]
Q.canMove=function()return true end
p.vars.ProjectYakuzaHitMarker=move.nodeValue;p.vars.ProjectYakuzaQuickstepCancelReady=move.nodeValue
check(Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}) and Q.isCancelling(p),'armed light accepts native quickstep cancel')
check(state.recoveryReleased and p.report=='ActiveAnimFinishing','cancel releases real native attack without a second collision')
check(bat.condition==10 and pipe.condition==10,'framework never repairs or manually consumes weapon condition')

Q.clearLightCancel(p);PY.resetPlayer(p,'test');p.attacking=false;mouse[0]=false
local realKnife=weapon('Base.HuntingKnife');realKnife.range=.9
local blade=weapon('Base.Katana');blade.range=1.4;blade.min=8;blade.max=8
for _,case in ipairs({{id='knife',item=realKnife,prefix='Knife'},{id='blade',item=blade,prefix='Blade'}})do
 p.held=case.item;W.sync(p);PY.resetPlayer(p,'test');p.attacking=false;mouse[0]=false
 local view=PY.getPlayerStyle(p)
 check(view.weaponProfile==case.id and view.id==original.id,'sharp equipment keeps DoD identity '..case.id)
 check(#view.lightAttacks==3 and not view.actions.heavyCharge and not view.actions.runningAttack,'three sharp lights without unarmed action leakage '..case.id)
 check((view.actions.block~=nil)==(case.id=='blade'),'guard only when supplied source clips exist '..case.id)
 for _,id in ipairs(W.profiles[original.id][case.id].items)do check(W.profile(original.id,weapon(id))==case.id,'explicit sharp weapon mapping '..id)end
 for i=1,3 do
  mouse[0]=false;fire('OnPlayerUpdate',p);mouse[0]=true;fire('OnPlayerUpdate',p)
  if not p.attacking then p:AttemptAttack() end
  check(PY.stateFor(p).step==i and p.vars.ProjectYakuzaMove==view.lightAttacks[i].nodeValue,'source sharp combo routing '..case.id..i)
  finish()
 end
 local min,max=case.item.min,case.item.max
 check(PY.queueFinisher(p),'sharp heavy available '..case.id)
 check(PY.stateFor(p).finisherMove.animation=='ProjectYakuza_DD_'..case.prefix..'Heavy','sharp heavy uses distinct source clip '..case.id)
 check(math.abs(case.item.min-min*1.25)<.00001 and math.abs(case.item.max-max*1.25)<.00001,'sharp heavy uses real native damage '..case.id)
 finish();check(case.item.min==min and case.item.max==max,'sharp heavy restores real item '..case.id)
 PY.resetPlayer(p,'test');p:AttemptAttack()
 local state=PY.stateFor(p);local move=view.lightAttacks[1]
 p.vars.ProjectYakuzaHitMarker=move.nodeValue;p.vars.ProjectYakuzaQuickstepCancelReady=move.nodeValue
 check(Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}) and Q.isCancelling(p),'sharp light can quickstep cancel '..case.id)
 Q.clearLightCancel(p);PY.resetPlayer(p,'test');p.attacking=false;mouse[0]=false
end
check(W.hitRange(realKnife)==.9 and W.hitRange(blade)==1.4,'supplementary reach comes from the real blade')
realKnife.range=math.huge;check(W.hitRange(realKnife)==1.25,'nonfinite reach falls back safely');realKnife.range=.9
blade.range=10;check(W.hitRange(blade)==1.65,'supplementary range retains framework world-check budget');blade.range=1.4
check(W.extraDamage(realKnife,100)==realKnife.max,'native knife close-kill damage cannot spread to extra victims')
check(W.extraDamage(blade,8)==8,'high native sword damage is not reduced to unarmed damage')
check(W.extraDamage(realKnife,0/0)==0,'invalid supplementary damage fails closed')
local M=PY.MultiHit;M.clear();p.held=realKnife;W.sync(p);p.attacking=false;PY.resetPlayer(p,'test');p:AttemptAttack()
local first={};M.onHit(p,first,realKnife,100)
check(M.pending[p].origin.range==.9 and M.pending[p].damage==realKnife.max,'actual extra-hit queue captures knife reach and bounded damage')
local extra={isDead=function()return false end,Hit=function(self,w,actor,damage)self.damage=damage;self.weapon=w end}
M.targets=function()return {{victim=extra}}end
M.tick();check(extra.damage==realKnife.max and extra.weapon==realKnife,'native SP supplement uses held knife without copying jaw-kill damage')
M.clear();p.held=blade;W.sync(p);p.attacking=false;PY.resetPlayer(p,'test');p:AttemptAttack();M.onHit(p,{},blade,8)
p.held=realKnife;extra.damage=nil;M.tick()
check(extra.damage==nil,'SP pending extra hit cannot survive an equipment swap before next player update')
W.sync(p);PY.resetPlayer(p,'test');p.attacking=false;p:AttemptAttack()
local current=PY.stateFor(p);current.groundMove=PY.getPlayerStyle(p).groundAttacks[1]
M.onHit(p,{},weapon('Base.BareHands'),.4);p.held=blade;extra.damage=nil;M.tick()
check(extra.damage==nil,'native BareHands ground collision also retains the real held-item owner')
W.sync(p);PY.resetPlayer(p,'test');p.attacking=false
p.data.ProjectYakuzaStyle=addon.id
check(not PY.isEquipped(p),'sharp profile remains unavailable in unrelated styles')

check(PY.getStyle('dragon_of_dojima').impactFeedback=='unarmed','DoD unarmed keeps original feedback')
for id,family in pairs({bat='blunt',knife='blade',blade='blade'})do
 local view=W.views.dragon_of_dojima[id]
 check(view.impactFeedback==family,'weapon family is style-owned '..id)
 check(view.sounds.heavyImpact and view.sounds.groundImpact,'weapon heavy/ground cues are configured '..id)
end
local impactBase=PY.getStyle('dragon_of_dojima');local oldImpact=impactBase.impactFeedback
for _,bad in ipairs({'metal',true,1,{}})do impactBase.impactFeedback=bad;local valid=PY.validateStyle(impactBase);check(not valid,'unknown impact presets rejected')end
impactBase.impactFeedback=oldImpact
local customProfile={id='test.impact',items={'Tests.ImpactWeapon'},lightAttacks=impactBase.lightAttacks,actions={},impactFeedback=false}
local customView=W.register(impactBase.id,customProfile)
check(customView.impactFeedback==false,'profile can disable inherited impact preset')
customProfile={id='test.inheritedimpact',items={'Tests.InheritedImpactWeapon'},lightAttacks=impactBase.lightAttacks,actions={}}
customView=W.register(impactBase.id,customProfile)
check(customView.impactFeedback=='unarmed','omitted family inherits base style feedback')


for _,case in ipairs({{id='bottle',item='ProjectYakuza.IntactBeerBottle',prefix='Bottle'},{id='crate',item='ProjectYakuza.BeerCrate',prefix='Crate'}})do
 PY.resetPlayer(p,'profile_test');clock=clock+2000;p.attacking=false;p.held=weapon(case.item);p.data.ProjectYakuzaStyle=original.id;W.sync(p)
 local view=PY.getPlayerStyle(p)
 check(view.weaponProfile==case.id and W.profile(original.id,p.held)==case.id,'separate supplied object profile '..case.id)
 check(#view.lightAttacks==3 and view.lightAttacks[1].animation=='ProjectYakuza_DD_'..case.prefix..'Light01','object-specific original light animation '..case.id)
 p:AttemptAttack();check(PY.stateFor(p).active and PY.stateFor(p).step==1 and p.vars.ProjectYakuzaMove=='dd_'..case.id..'_light_01','object-specific native light route '..case.id)
 finish();PY.resetPlayer(p,'heavy_test');p.attacking=false;clock=clock+1000
 check(PY.queueFinisher(p) and PY.stateFor(p).finisherMove.nodeValue=='dd_'..case.id..'_heavy','object heavy uses its own source motion '..case.id)
 finish();PY.resetPlayer(p,'profile_test')
 check(view.actions.block.animation=='ProjectYakuza_DD_'..case.prefix..'Guard','object-specific walking guard '..case.id)
 check((view.actions.heatAction~=nil)==(case.id=='bottle'or case.id=='crate'),'bottle and crate use separate original weapon Heat Actions')
 check(view.actions.styleEntry==original.actions.styleEntry and view.actions.quickstep==original.actions.quickstep,'shared style systems retained '..case.id)
end

return true,'PASS '..checks..' real-weapon style, sharp/blunt combo, heavy, reach, damage and isolation checks'
