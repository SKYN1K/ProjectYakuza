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
return 'PASS '..checks..' one-strike quickstep ownership, native gate, rapid taps, retries and asynchronous handoff checks'
