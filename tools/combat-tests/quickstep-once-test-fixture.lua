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
-- REGISTRY
-- COMBO
-- STYLE
-- BINDINGS
local PY=ProjectYakuza
local swingEvents=0
PY.Heat={onSwing=function()swingEvents=swingEvents+1 end,endSwing=function()end}
-- RUNTIME
-- QUICKSTEPS
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
 return false -- B42 may return false after accepting the native submission.
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
-- A rejected native attempt is not a completed attack and may retry inside its window.
local a,ticket=handover('forward');p.reject=true
local ok,why=PY.requestAction(p,'quickstepAttack','forward',ticket)
check(not ok and why=='native_attack_rejected' and not ticket.consumed and Q.pending[p]==ticket,'failed native submission keeps its one valid retry entitlement')
p.reject=false;check(PY.requestAction(p,'quickstepAttack','forward',ticket),'valid native retry can use that entitlement once');finish()
-- The first native swing may arrive after requestAction has published its gate.
a,ticket=handover('left');p.async=true;local before=swingEvents
check(PY.requestAction(p,'quickstepAttack','left',ticket),'asynchronous native submission accepted')
check(not p.allowed and PY.stateFor(p).pendingFinisher,'pending first swing remains classified despite immediate native input gate')
fire('OnWeaponSwing',p,token);fire('OnWeaponSwing',p,token)
check(swingEvents==before+1 and PY.stateFor(p).finisherMove.quickstepAttack,'only first asynchronous swing passes the lock');finish();p.async=false
-- Variant must correspond to the actual dodge, and cancelled completions stay inert.
a,ticket=handover('right');ok,why=PY.requestAction(p,'quickstepAttack','left',ticket)
check(not ok and why=='quickstep_required' and not ticket.consumed,'handover cannot request another direction');Q.pending[p]=nil
local c={player=p,style=style,action=style.actions.quickstep.variants.forward}
a=Q.Action:new(c);c.timedAction=a;a.attackHandover=true;a:cleanup(false,'cancelled');a:perform()
check(not Q.pending[p],'cancelled quickstep cannot dispatch a stale attack from late completion')
check(Q.limit==3 and Q.windowMs==15000,'existing quickstep quota is unchanged')

-- Real light recovery -> native exit -> timed quickstep handoff.
local wall,paused,typing=false,false,false
local keyState={};isKeyDown=function(k)return keyState[k]==true end
local nativeBindings={FORWARD=17,BACKWARD=31,LEFT=30,RIGHT=32}
KeybindId={};for id in pairs(nativeBindings)do local name=id;KeybindId[id]={getId=function()return name end}end
getCore=function()return {isDoingTextEntry=function()return typing end,getKey=function(_,id)return nativeBindings[id]end}end
isGamePaused=function()return paused end
function p:getForwardDirection()return {getX=function()return 1 end,getY=function()return 0 end}end
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
 ctx.timedAction:start();check(#p.data.ProjectYakuzaQuickstepTimes==1 and Q.quota(p)==2,'successful native dash start spends exactly one quota unit '..i)
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
-- The bound quickstep key reaches the same path, and held keys do not repeat.
state,move=light(1);p:setVariable('ProjectYakuzaQuickstepCancelReady',move.nodeValue);p:setVariable('ProjectYakuzaHitMarker',move.nodeValue)
keyState[57]=true;check(Q.pollShove(p) and Q.isCancelling(p),'actual quickstep binding triggers the light cancel')
reports=p.exitReports;Q.pollShove(p);check(p.exitReports==reports,'held quickstep input cannot request another cancel')
keyState[57]=false;Q.clearLightCancel(p);Q.restoreAllShoves();PY.resetPlayer(p,'test_done')
return 'PASS '..checks..' one-strike quickstep ownership, native gate, rapid taps, retries and asynchronous handoff checks'
