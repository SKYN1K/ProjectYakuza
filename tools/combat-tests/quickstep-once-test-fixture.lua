require=function()end
local checks=0
local function check(v,message)checks=checks+1;assert(v,message)end
local clock=1000
getTimestampMs=function()return clock end
isGamePaused=function()return false end
isClient=function()return false end
instanceof=function()return true end
local function event()local e={callbacks={}};e.Add=function(fn)e.callbacks[#e.callbacks+1]=fn end;e.Remove=function()end;return e end
Events={OnPlayerUpdate=event(),OnWeaponSwing=event(),OnPlayerAttackFinished=event(),OnWeaponHitCharacter=event(),OnSave=event(),OnMainMenuEnter=event()}
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
do local _="ProjectYakuzaFixture:COMBO" end
do local _="ProjectYakuzaFixture:STYLE" end
do local _="ProjectYakuzaFixture:BINDINGS" end
local PY=ProjectYakuza
local swingEvents=0
PY.Heat={onSwing=function()swingEvents=swingEvents+1 end,endSwing=function()end}
do local _="ProjectYakuzaFixture:RUNTIME" end
do local _="ProjectYakuzaFixture:QUICKSTEPS" end
local Q=PY.Quicksteps
local token={getFullType=function()return PY.TOKEN end,getMaxHitCount=function()return 3 end,getWeaponSprite=function()return 'ProjectYakuza_EmptyHand' end}
local p={vars={},data={ProjectYakuzaStyle='dragon_of_dojima'},allowed=true,attacking=false,async=false,reject=false,submissions=0}
function p:getPlayerNum()return 0 end
function p:getModData()return self.data end
function p:isLocalPlayer()return true end
function p:isDead()return false end
function p:isAiming()return true end
function p:getPrimaryHandItem()return token end
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
 if not self.async then fire('OnWeaponSwing',self,token)end
 return false
end
local style=PY.getStyle('dragon_of_dojima')
local function handover(direction)
 clock=clock+1000
 local c={player=p,style=style,action=style.actions.quickstep.variants[direction]}
 local a=Q.Action:new(c);c.timedAction=a;a.attackHandover=true;a:perform()
 check(Q.pending[p] and Q.pending[p].direction==direction,'quickstep produces its directional handover')
 return a,Q.pending[p],c
end
local function finish()
 p.attacking=false;fire('OnPlayerAttackFinished',p,token);PY.Bindings.update(p)
end
for _,direction in ipairs({'forward','backward','left','right'})do
 local a,ticket=handover(direction);local nativeBefore=p.submissions;local before=swingEvents
 a:perform();check(Q.pending[p]==ticket,'duplicate native completion cannot mint a second handover')
 check(PY.requestAction(p,'quickstepAttack',direction,ticket),'first quickstep strike accepted')
 check(ticket.consumed and not Q.pending[p],'accepted native submission atomically consumes the ticket')
 check(not p.allowed and PY.blocksNativeAttacks(p),'native mouse attack permission locked during quickstep strike')
 Q.shoveAuth[p]={allowed=true};Q.restoreShove(p)
 check(not p.allowed,'releasing quickstep/shove key cannot lift the active strike lock')
 local attack=PY.stateFor(p).finisherMove;local stamp=PY.stateFor(p).multiHitToken
 for i=1,4 do
  mouse[0]=false;Q.pollAttack(p,a.context);mouse[0]=true;Q.pollAttack(p,a.context)
  check(not PY.attemptAttack(p),'rapid release/repress cannot submit another native attack')
 end
 fire('OnWeaponSwing',p,token)
 check(p.submissions==nativeBefore+1 and swingEvents==before+1 and PY.stateFor(p).multiHitToken==stamp,'duplicate native swing callback cannot restart/classify another strike')
 check(PY.stateFor(p).finisherMove==attack and PY.stateFor(p).queued==0,'rapid taps do not queue a light/double-finisher branch')
 finish()
 check(p.allowed and not PY.activeActions[p] and p:GetVariable('ProjectYakuzaMove')=='dd_light_01','completion restores native input and immediately resets animation selection')
 Q.pending[p]=ticket
 local ok,why=PY.requestAction(p,'quickstepAttack',direction,ticket)
 check(not ok and why=='quickstep_required','even retained/reinserted consumed ticket cannot replay')
 Q.pending[p]=nil;a:perform();check(not Q.pending[p],'late repeated completion cannot recreate consumed handover')
end

local a,ticket=handover('forward');p.reject=true
local ok,why=PY.requestAction(p,'quickstepAttack','forward',ticket)
check(not ok and why=='native_attack_rejected' and not ticket.consumed and Q.pending[p]==ticket,'failed native submission keeps its one valid retry entitlement')
p.reject=false;check(PY.requestAction(p,'quickstepAttack','forward',ticket),'valid native retry can use that entitlement once');finish()

a,ticket=handover('left');p.async=true;local before=swingEvents
check(PY.requestAction(p,'quickstepAttack','left',ticket),'asynchronous native submission accepted')
check(not p.allowed and PY.stateFor(p).pendingFinisher,'pending first swing remains classified despite immediate native input gate')
fire('OnWeaponSwing',p,token);fire('OnWeaponSwing',p,token)
check(swingEvents==before+1 and PY.stateFor(p).finisherMove.quickstepAttack,'only first asynchronous swing passes the lock');finish();p.async=false

a,ticket=handover('right');ok,why=PY.requestAction(p,'quickstepAttack','left',ticket)
check(not ok and why=='quickstep_required' and not ticket.consumed,'handover cannot request another direction');Q.pending[p]=nil
local c={player=p,style=style,action=style.actions.quickstep.variants.forward}
a=Q.Action:new(c);c.timedAction=a;a.attackHandover=true;a:cleanup(false,'cancelled');a:perform()
check(not Q.pending[p],'cancelled quickstep cannot dispatch a stale attack from late completion')
check(Q.limit==3 and Q.windowMs==15000,'existing quickstep quota is unchanged')
clock=clock+16000;p.data.ProjectYakuzaQuickstepTimes={};Q.nextAllowed[0]=nil
local available,recovery,gap=Q.recovery(p)
check(available==3 and recovery==0 and gap==0,'unused quicksteps have no recharge or action gap')
Q.spend(p);clock=clock+5000;Q.nextAllowed[0]=clock+180
available,recovery,gap=Q.recovery(p)
check(available==2 and recovery==10000 and gap==180,'HUD recharge exposes the real rolling charge timer and short action gap')
clock=clock+10000;available,recovery,gap=Q.recovery(p)
check(available==3 and recovery==0 and gap==0,'HUD returns to ready at the exact quota expiry')

local wall,paused,typing=false,false,false
local keyState={};isKeyDown=function(k)return keyState[k]==true end
local nativeBindings={FORWARD=17,BACKWARD=31,LEFT=30,RIGHT=32}
KeybindId={};for id in pairs(nativeBindings)do local name=id;KeybindId[id]={getId=function()return name end}end
getCore=function()return {isDoingTextEntry=function()return typing end,getKey=function(_,id)return nativeBindings[id]end}end
isGamePaused=function()return paused end
function p:getForwardDirection()return {getX=function()return 1 end,getY=function()return 0 end}end
function p:moveUnmodded(dx,dy)self.dashX=(self.dashX or 0)+dx;self.dashY=(self.dashY or 0)+dy end
function p:getX()return 0 end;function p:getY()return 0 end;function p:getZ()return 0 end
function p:getCurrentStateName()return self.nativeState or (self.attacking and 'SwipeStatePlayer' or 'IdleState')end
function p:getHitReaction()return self.hit or '' end
function p:isBlockMovement()return self.blocked==true end
for _,name in ipairs({'isOnFloor','isKnockedDown','isClimbing','isDraggingCorpse','isAsleep','hasTimedActions'})do p[name]=function()return false end end
function p:getVehicle()return nil end
function p:setPerformingAttackAnimation(v)self.performingOverride=v end
function p:isPerformingAttackAnimation()if self.performingOverride~=nil then return self.performingOverride end;return self.attacking end
function p:reportEvent(name)check(name=='ActiveAnimFinishing','cancel uses native recovery completion event');self.exitReports=(self.exitReports or 0)+1 end
getCell=function()return {getGridSquare=function()return {TreatAsSolidFloor=function()return true end,isSolid=function()return false end,isSolidTrans=function()return false end,testCollideAdjacent=function()return wall end}end}end
local function light(step)
 clock=clock+2000;Q.clearLightCancel(p);PY.resetPlayer(p,'test');p.attacking=false;p.performingOverride=nil;p.nativeState=nil;p.hit='';p.blocked=false
 p.data.ProjectYakuzaQuickstepTimes={};Q.nextAllowed[0]=0;Q.shoveDown[p]=nil;Q.shoveAuth[p]=nil;PY.Bindings.restore(p);p.allowed=true
 local state=PY.stateFor(p);state.active=true;state.step=step or 1;state.multiHitToken={};state.startedAt=clock;state.queued=0
 p.attacking=true;p.vars.ProjectYakuzaHitMarker='';p.vars.ProjectYakuzaQuickstepCancelReady=''
 return state,style.lightAttacks[state.step]
end
for i=1,4 do
 local state,move=light(i);state.queued=1;state.queuedFinisher=i
 p:setVariable('ProjectYakuzaHitMarker',move.nodeValue)
 p:setVariable('ProjectYakuzaQuickstepCancelReady',move.nodeValue)
 local before=p.exitReports or 0
 check(Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}),'each light accepts a recovery cancel '..i)
 check(Q.isCancelling(p) and p.exitReports==before+1 and state.recoveryReleased,'one native exit requested '..i)
 check(state.queued==0 and not state.queuedFinisher and not p.allowed,'handoff clears buffered attacks and gates native submissions '..i)
 Q.processLightCancel(p);check(not PY.activeActions[p] and Q.isCancelling(p),'dash never starts while native attack still owns hands '..i)
 p.attacking=false;p.nativeState='IdleState';fire('OnPlayerAttackFinished',p,token)
 check(Q.processLightCancel(p) and PY.activeActions[p].kind=='quickstep','native exit transfers to real quickstep handler '..i)
 check(PY.stateFor(p).step==0 and not Q.lightCancels[p] and #p.data.ProjectYakuzaQuickstepTimes==0,'old combo clears and quota waits for actual action start '..i)
 local ctx=PY.activeActions[p];ctx.timedAction.action={setOverrideHandModelsObject=function()end};ctx.timedAction.setActionAnim=function()end
 ctx.timedAction:start();check(#p.data.ProjectYakuzaQuickstepTimes==0,'queued dash does not spend quota before animation movement '..i)
 p.vars.ProjectYakuzaQuickstepStarted=ctx.action.nodeValue;p.vars.ProjectYakuzaQuickstepProgress='.25';ctx.timedAction:update()
 check(#p.data.ProjectYakuzaQuickstepTimes==1 and Q.quota(p)==2,'first native dash movement spends exactly one quota unit '..i)
 PY.cancelAction(p,'test_end')
end
local optState=light(1);style.quickstepCancelLights=false
check(not Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}),'unconfigured/opted-out styles keep their existing attack behavior');style.quickstepCancelLights=true
local state,move=light(1);local reports=p.exitReports
check(Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}) and not Q.isCancelling(p),'a short pre-window press is buffered without cutting windup')
p:setVariable('ProjectYakuzaQuickstepCancelReady',move.nodeValue);Q.processLightCancel(p)
check(p.exitReports==reports,'cancel marker alone cannot skip the collision marker')
clock=clock+100;p:setVariable('ProjectYakuzaHitMarker',move.nodeValue);Q.processLightCancel(p)
check(Q.isCancelling(p) and p.exitReports==reports+1,'buffer catches the opening window within 150ms')
Q.clearLightCancel(p)
state,move=light(1);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});clock=clock+151
p:setVariable('ProjectYakuzaQuickstepCancelReady',move.nodeValue);p:setVariable('ProjectYakuzaHitMarker',move.nodeValue);reports=p.exitReports
Q.processLightCancel(p);check(not Q.lightCancels[p] and p.exitReports==reports,'expired early input does not trigger a late dodge')
state,move=light(1);p.data.ProjectYakuzaQuickstepTimes={clock,clock,clock};reports=p.exitReports
check(not Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}) and p.exitReports==reports,'exhausted three-per-15s quota cannot truncate an attack')
state,move=light(1);Q.nextAllowed[0]=clock+500;check(not Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}),'cooldown is checked before cancelling')
state,move=light(1);wall=true;reports=p.exitReports;check(not Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}) and p.exitReports==reports,'blocked direction cannot cancel into a wall');wall=false
state,move=light(1);state.finisherMove=style.actions.finisher.variants.after_1;check(not Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}),'first finishers cannot quickstep cancel')
state.finisherMove=style.actions.chargedHeavy.variants.after_1;check(not Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true}),'charged attacks cannot quickstep cancel')
state,move=light(1);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});state.multiHitToken={};Q.processLightCancel(p);check(not Q.lightCancels[p],'input cannot transfer to a different light swing')
state,move=light(1);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});p.hit='Bite';Q.processLightCancel(p);check(not Q.lightCancels[p],'being hit cancels the pending request')
state,move=light(1);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});paused=true;Q.processLightCancel(p);paused=false;check(not Q.lightCancels[p],'paused game cannot retain a delayed dodge intent')
state,move=light(1);p:setVariable('ProjectYakuzaQuickstepCancelReady',move.nodeValue);p:setVariable('ProjectYakuzaHitMarker',move.nodeValue);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});clock=clock+401;Q.processLightCancel(p)
check(not Q.lightCancels[p] and p.allowed,'missing native exit times out and restores the input gate')
state,move=light(1);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});PY.resetPlayer(p,'external_reset');check(not Q.lightCancels[p],'external reset clears cancel ownership')
state,move=light(1);Q.requestLightCancel(p,'backward',{dx=-1,dy=0,shove=true});Q.restoreAllShoves();check(not Q.lightCancels[p],'save/menu cleanup removes queued cancel input')

state,move=light(1);p:setVariable('ProjectYakuzaQuickstepCancelReady',move.nodeValue);p:setVariable('ProjectYakuzaHitMarker',move.nodeValue)
keyState[57]=true;check(Q.pollShove(p) and Q.isCancelling(p),'actual quickstep binding triggers the light cancel')
reports=p.exitReports;Q.pollShove(p);check(p.exitReports==reports,'held quickstep input cannot request another cancel')
keyState[57]=false;Q.clearLightCancel(p);Q.restoreAllShoves();PY.resetPlayer(p,'test_done')
function p:isRunning()return self.running==true end
function p:isSprinting()return self.sprinting==true end
local previousRunningAim=p.isAiming;p.isAiming=function()return false end
for _,mode in ipairs({'running','sprinting'})do
 PY.resetPlayer(p,'running_space_test');Q.restoreAllShoves();keyState[57]=false;Q.pollShove(p);p[mode]=true
 local queued=0;local savedQueue=ISTimedActionQueue.add;ISTimedActionQueue.add=function()queued=queued+1;return {}end
 keyState[57]=true;check(not Q.pollShove(p)and queued==0 and not PY.activeActions[p]and not Q.aimPending[p],'running Space cannot queue a facing-lock action '..mode)
 check(not p.blocked and not p:GetVariable('IsPerformingAnAction'),'running Space never takes animation/movement ownership '..mode)
 ISTimedActionQueue.add=savedQueue;p[mode]=false;keyState[57]=false;Q.restoreAllShoves()
end
p.isAiming=previousRunningAim
local previousEffects=PY.AttackEffects;local previousAim=p.isAiming;local trackPhase,trackWeight
PY.AttackEffects={findTrack=function()return trackPhase,trackWeight,{layer=0,slot=0}end};p.dbgGetAnimTrackName=function()return ''end
function p:StopTimedActionAnim()self.animationStops=(self.animationStops or 0)+1 end
function p:isAiming()return self.aimReady==true end
function base:setActionAnim(name)self.animationRequests=(self.animationRequests or 0)+1 end
function base:forceStop()self:stop()end;function base:forceComplete()self:perform()end
local function dash(direction)
 clock=clock+2000;Q.clearLightCancel(p);PY.resetPlayer(p,'startup_test');p.attacking=false;p.performingOverride=false;p.hit='';p.blocked=false;p.aimReady=false;mouse[1]=false
 p.data.ProjectYakuzaQuickstepTimes={};Q.nextAllowed[0]=nil;trackPhase=nil;trackWeight=1
 local c={player=p,style=style,action=style.actions.quickstep.variants[direction or 'forward'],shove=true,dx=1,dy=0}
 local a=Q.Action:new(c);c.timedAction=a;a.action={setOverrideHandModelsObject=function()end,setUseProgressBar=function(_,v)a.progressBar=v end};PY.activeActions[p]=c;a:start();return a
end
local dashAction=dash();check(not dashAction.started and Q.quota(p)==3 and dashAction.progressBar==false,'Space startup has no quota or progress-bar cost before a visible dash')
mouse[1]=true;clock=clock+30;dashAction:update();check(dashAction.animationRequests==2 and p:GetVariable('PerformingAction')==dashAction.context.action.animation,'RMB pressed after Space re-arms the actual native action selector')
clock=clock+700;dashAction:update();check(dashAction.cleaned and Q.quota(p)==3 and not Q.nextAllowed[0]and not p.blocked,'missing animation cancels without a spent charge, cooldown or movement lock')
dashAction=dash();mouse[1]=true;trackPhase=0;clock=clock+30;dashAction:update()
p.aimReady=true;clock=clock+30;dashAction:update();trackPhase=.1;clock=clock+30;dashAction:update()
check(dashAction.started and dashAction.moved>0 and Q.quota(p)==2,'Space then RMB executes when the real quickstep track advances')
trackPhase=.2;dashAction:update();check(Q.quota(p)==2,'one dash cannot spend twice after aim startup recovery')
trackPhase=dashAction.context.action.duration*dashAction.context.action.speed;dashAction:update()
check(dashAction.cleaned and math.abs(dashAction.moved-dashAction.context.action.distance)<.000001 and not p.blocked,'recovered dash reaches its original distance and restores movement')
for _,direction in ipairs({'forward','backward','left','right'})do
 dashAction=dash(direction)
 trackPhase=.1;dashAction:update();local requests=dashAction.animationRequests
 mouse[1]=true;p.aimReady=true;clock=clock+20;dashAction:update()
 check(dashAction.animationRequests==requests,'aim changes cannot restart a visible quickstep '..direction)
 local stops=p.animationStops or 0
 trackPhase=dashAction.context.action.duration*dashAction.context.action.speed;trackWeight=.08;dashAction:update()
 check(dashAction.cleaned and not p.blocked and p:GetVariable('PerformingAction')=='','fading native track completes without waiting for a timeout '..direction)
 check((p.animationStops or 0)==stops+1,'completion explicitly exits the native timed action once '..direction)
 dashAction:update();dashAction:perform();check(p.animationStops==stops+1,'late update and completion cannot repeat the exit '..direction)
end
dashAction=dash();trackPhase=.1;dashAction:update();trackPhase=nil;p:setVariable('ProjectYakuzaQuickstepDone',dashAction.context.action.nodeValue)
dashAction:update();check(dashAction.cleaned and not p.blocked,'native end event completes after its track has disappeared')
dashAction=dash();trackPhase=.1;dashAction:update();trackPhase=nil;clock=clock+150;dashAction:update()
check(not dashAction.cleaned and dashAction.animationRequests==1,'temporary track loss never re-arms an already visible dash')
clock=clock+math.ceil(dashAction.context.action.duration*1000)+100;dashAction:update()
check(dashAction.cleaned and not p.blocked,'lost terminal track has a bounded completion fallback')
do
 local queued
 function p:getCharacterActions()return {size=function()return queued and 1 or 0 end,contains=function(_,v)return queued==v end}end
 local priorBusy=p.hasTimedActions
 function p:hasTimedActions()return queued~=nil or self.vars.IsPerformingAnAction==true end
 dashAction=dash();queued=dashAction.action;p:setVariable('PerformingAction','')
 check(p:hasTimedActions(),'blank selector still leaves the native busy flag active')
 dashAction:perform();queued=nil
 check(not p:hasTimedActions() and not PY.activeActions[p] and not p.blocked,'dash completion clears its stale busy flag after native selector reset')
 dashAction=dash();p:setVariable('PerformingAction','');queued={};dashAction:perform()
 check(p:hasTimedActions(),'cleanup preserves a real replacement native action')
 queued=nil;p:setVariable('IsPerformingAnAction',false)
 dashAction=dash();p:setVariable('PerformingAction','AnotherNativeAction');dashAction:perform()
 check(p.vars.IsPerformingAnAction==true and p:GetVariable('PerformingAction')=='AnotherNativeAction','dash cannot erase a foreign animation or busy flag')
 p:setVariable('PerformingAction','');p:setVariable('IsPerformingAnAction',false)
 dashAction=dash();local replacement={};PY.activeActions[p]=replacement;dashAction:cleanup(false)
 check(PY.activeActions[p]==replacement and p.vars.IsPerformingAnAction==true,'late dash cleanup preserves replacement context animation ownership')
 PY.activeActions[p]=nil;p:setVariable('PerformingAction','');p:setVariable('IsPerformingAnAction',false);p.hasTimedActions=priorBusy
end
PY.AttackEffects=previousEffects;p.isAiming=previousAim;p.dbgGetAnimTrackName=nil;mouse[1]=false
do local _="ProjectYakuzaFixture:RUNNING" end
local B=PY.Bindings
local values={input_light=4,key_light=33,input_finisher=4,key_finisher=35,input_runningLight=1,input_dropkick=1,input_quickstepAttack=1,input_counter=1}
B.options={getOption=function(_,name)if values[name]then return {getValue=function()return values[name]end}end end}
mouse[0]=true;mouse[2]=true;keyState[33]=false;keyState[35]=false
local context={timedAction={},lastAttackDown=false}
Q.pollAttack(p,context);check(not context.timedAction.attackRequested,'old mouse quickstep assignment is ignored after remapping Light')
keyState[33]=true;Q.pollAttack(p,context);check(context.timedAction.attackRequested,'remapped Light requests the quickstep strike')
context.timedAction.attackRequested=false;Q.pollAttack(p,context);check(not context.timedAction.attackRequested,'held Light cannot repeat quickstep strikes')
keyState[33]=false;Q.pollAttack(p,context);keyState[33]=true;Q.pollAttack(p,context);check(context.timedAction.attackRequested,'fresh Light remains available after release')
keyState[33]=false;mouse[0]=false;mouse[2]=false;mouse[1]=false
local oldBusy,oldEquipped,oldStyle,oldRequest=PY.isBusy,PY.isEquipped,PY.getPlayerStyle,PY.requestAction
PY.isBusy=function()return false end;PY.isEquipped=function()return true end;PY.getPlayerStyle=function()return style end
local requested
PY.requestAction=function(_,kind,variant)requested={kind=kind,variant=variant};return true end
ZombRand=function()return 0 end
local runner={x=0}
for _,name in ipairs({'isAiming','isDead','isOnFloor','isKnockedDown','isClimbing','isDraggingCorpse','isAsleep','hasTimedActions','isBlockMovement','getIgnoreMovement'})do runner[name]=function()return false end end
runner.isRunning=function()return true end;runner.isSprinting=function()return false end;runner.getVehicle=function()return nil end;runner.getHitReaction=function()return ''end
runner.getX=function(self)return self.x end;runner.getY=function()return 0 end;runner.getZ=function()return 0 end
local R=PY.RunningAttacks
local function runup()
 R.players[runner]=nil;requested=nil;R.update(runner)
 for i=1,5 do clock=clock+100;runner.x=runner.x+.1;R.update(runner)end
end
runup();mouse[0]=true;clock=clock+100;runner.x=runner.x+.1;R.update(runner)
check(not requested,'stale mouse Running Light setting cannot override Light binding')
keyState[33]=true;clock=clock+100;runner.x=runner.x+.1;R.update(runner)
check(requested and requested.kind=='runningAttack' and requested.variant=='left','remapped Light dispatches a running strike after runup')
keyState[33]=false;mouse[0]=false;runup();keyState[35]=true;clock=clock+100;runner.x=runner.x+.1;R.update(runner)
check(requested and requested.variant=='dropkick','remapped Heavy dispatches the running dropkick')
R.pause(runner);check(R.players[runner].heavy and not R.players[runner].light,'pause snapshots the shared physical inputs')
local attempts=0
local function freshRun()
 keyState[33]=false;keyState[35]=false;mouse[0]=false;mouse[1]=false;R.players[runner]=nil;requested=nil;runner.x=0;R.update(runner)
end
local function stepRun(ms,distance,light,heavy)
 clock=clock+ms;runner.x=runner.x+distance;keyState[33]=light==true;keyState[35]=heavy==true;R.update(runner)
end
freshRun();stepRun(80,.08,true);check(not requested,'early running press waits for actual runup');stepRun(80,.08,false)
check(requested and requested.variant=='left','early released Light press survives until runup completes')
requested=nil;for i=1,5 do stepRun(50,.05,false)end;stepRun(20,.02,true)
check(requested~=nil,'a new fresh press can arm another running strike');requested=nil
for i=1,8 do stepRun(50,.05,true)end;check(not requested,'holding Light cannot repeat running strikes')
freshRun();stepRun(80,.08,false,true);stepRun(80,.08,false,false)
check(requested and requested.variant=='dropkick','buffered Heavy uses shared heavy binding even after release')
freshRun();stepRun(80,.08,true,true);stepRun(80,.08,false,false)
check(requested and requested.variant=='dropkick','simultaneous Light and Heavy resolve to one dropkick')
local runup=style.actions.runningAttack.runupMs;style.actions.runningAttack.runupMs=400
freshRun();stepRun(80,.08,true);for i=1,4 do stepRun(100,.1,false)end
check(not requested,'expired early input cannot launch a delayed attack');stepRun(20,.02,true)
check(requested,'fresh input still works after the expired buffer');style.actions.runningAttack.runupMs=runup
freshRun();stepRun(80,.08);stepRun(80,.08);stepRun(20,0,true)
check(requested,'duplicate zero-displacement update retains recent running direction')
freshRun();stepRun(80,.08);stepRun(80,.08);local earned=R.players[runner].runMs;stepRun(20,0)
check(R.players[runner].runMs==earned,'stationary duplicate samples do not manufacture runup');stepRun(100,0,true)
check(not requested and R.players[runner].runMs==0,'standing still clears momentum after its short sampling grace')
freshRun();stepRun(80,.08,true);mouse[1]=true;stepRun(80,.08,false);mouse[1]=false;stepRun(100,.1,false)
check(not requested and not R.players[runner].pending,'aiming cancels an early running input')
freshRun();stepRun(80,.08,true);stepRun(80,2,false)
check(not requested and not R.players[runner].pending,'teleport movement cannot satisfy a running buffer')
freshRun();stepRun(80,.08,true);runner.getZ=function()return 1 end;stepRun(80,.08,false);runner.getZ=function()return 0 end
check(not requested and not R.players[runner].pending,'floor changes discard buffered attacks')
local failures=0;PY.requestAction=function(_,kind,variant)failures=failures+1;if failures==1 then return false,'native_attack_busy'end;requested={kind=kind,variant=variant};return true end
freshRun();stepRun(80,.08,true);stepRun(80,.08,false);check(failures==1 and R.players[runner].pending and not R.active[runner],'transient native readiness retains input without locking movement');stepRun(20,0,false)
check(failures==2 and requested,'buffer retries transient native readiness only inside its deadline')
PY.requestAction=oldRequest;runner.vars={};runner.data={ProjectYakuzaStyle=style.id};runner.attacking=false;runner.submissions=0;setmetatable(runner,{__index=p})
function runner:setRunning(value)self.running=value end;function runner:setSprinting(value)self.sprinting=value end;function runner:setMoving(value)self.moving=value end
function runner:setIgnoreMovement(value)self.ignore=value end;function runner:getIgnoreMovement()return self.ignore==true end
function runner:setForwardDirection(x,y)self.facing={getX=function()return x end,getY=function()return y end}end
function runner:getForwardDirection()return self.facing end;function runner:DirectionFromVector()end
function runner:getCurrentActionContextStateName()return 'movement'end
function runner:reportEvent(name)self.lastReport=name end
freshRun();stepRun(80,.08,true);stepRun(80,.08,false)
check(runner.submissions==1 and PY.stateFor(runner).finisherMove==style.actions.runningAttack.variants.left and R.active[runner],'accepted running attack submits its native swing in the same update')
local move=PY.stateFor(runner).finisherMove;runner.vars.ProjectYakuzaRunRecover=move.nodeValue;runner.vars.ProjectYakuzaHitMarker=move.nodeValue;mouse[1]=true;R.advance(runner);mouse[1]=false
check(not R.active[runner]and not runner.ignore and runner.lastReport=='ActiveAnimFinishing','aim input exits light running recovery only at source recovery and hit markers')
runner.attacking=false;fire('OnPlayerAttackFinished',runner,token);PY.resetPlayer(runner,'running_test')
local drop=style.actions.runningAttack.variants.dropkick;R.active[runner]={move=drop,moved=0,dx=1,dy=0,oldIgnore=false,oldBlock=false};runner.ignore=true
runner.vars.ProjectYakuzaRunRecover=drop.nodeValue;runner.vars.ProjectYakuzaHitMarker=drop.nodeValue;mouse[1]=true;R.advance(runner);mouse[1]=false
check(R.active[runner]and runner.ignore,'dropkick keeps its committed landing recovery instead of gaining an aim cancel');R.finish(runner)
local invalid={id='tests.bad_running',name='Invalid',lightAttacks=style.lightAttacks,actions={runningAttack={enabled=true,runupMs=-1,variants={}}}}
check(not PY.validateStyle(invalid),'negative running runup is rejected');invalid.actions.runningAttack.runupMs=160;invalid.actions.runningAttack.inputBufferMs=501
check(not PY.validateStyle(invalid),'unbounded running input buffer is rejected')
PY.isBusy,PY.isEquipped,PY.getPlayerStyle,PY.requestAction=oldBusy,oldEquipped,oldStyle,oldRequest
B.options=nil;keyState[35]=false
function p:isAuthorizeShoveStomp()return self.nativeShove~=false end
function p:setAuthorizeShoveStomp(value)self.nativeShove=value end
local equippedForShove=true;local wasEquipped=PY.isEquipped
PY.isEquipped=function()return equippedForShove end
B.options={getOption=function(_,id)return {getValue=function()return id=='input_quickstep'and 4 or id=='key_quickstep'and 33 or id=='input_light'and 1 or 0 end}end}
p.nativeShove=true;p.allowed=true;B.update(p)
check(not p.nativeShove and p.allowed,'equipped style blocks native shove independently of ordinary melee permission')
keyState[57]=true;B.update(p)
check(not p.nativeShove and not B.down('quickstep'),'Space cannot shove after quickstep is rebound to another key')
keyState[57]=false;keyState[33]=true;B.update(p)
check(not p.nativeShove and B.down('quickstep'),'rebound quickstep remains available with native shove disabled')
equippedForShove=false;B.update(p)
check(p.nativeShove and not B.shoveGates[p],'unequipping restores the original native shove permission')
p.nativeShove=false;equippedForShove=true;B.update(p);B.clear()
check(not p.nativeShove,'cleanup preserves a pre-existing shove restriction')
p.nativeShove=true;B.update(p);B.clear()
check(p.nativeShove and not B.shoveGates[p],'save/menu cleanup restores a previously allowed shove')
PY.isEquipped=wasEquipped;B.options=nil;keyState[33]=false
for i=1,4 do
 local state,move=light(i);local before=p.exitReports or 0
 p:setVariable('ProjectYakuzaHitMarker',move.nodeValue);p:setVariable('ProjectYakuzaChainReady',move.nodeValue)
 check(not PY.tryRecoveryCancel(p,style,state)and p.exitReports==before,'unbuffered light retains its full recovery '..i)
 state.queued=1;p:setVariable('ProjectYakuzaHitMarker','')
 check(not PY.tryRecoveryCancel(p,style,state),'earlier rush chain cannot bypass its collision '..i)
 p:setVariable('ProjectYakuzaHitMarker',move.nodeValue)
 check(PY.tryRecoveryCancel(p,style,state)and p.exitReports==before+1,'buffered light exits on the earlier native marker '..i)
 check(not PY.tryRecoveryCancel(p,style,state)and p.exitReports==before+1,'earlier rush recovery exits exactly once '..i)
 check(move.chainAt>move.impact and move.chainAt<.58 and move.speed==1.6,'each rush link is earlier without changing animation playback '..i)
end
return 'PASS '..checks..' one-strike quickstep ownership, native gate, rapid taps, retries and asynchronous handoff checks'
