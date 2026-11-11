require=function()end
local checks=0
local function check(v,s)checks=checks+1;assert(v,s)end
local function near(a,b)return math.abs(a-b)<.000001 end
local clock,paused,text=1000,false,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
local function event()return {Add=function()end,Remove=function()end}end
Events={OnPlayerUpdate=event(),OnTick=event(),OnGameStart=event(),OnSave=event(),OnMainMenuEnter=event(),OnKeyStartPressed=event(),OnKeyKeepPressed=event(),OnKeyPressed=event(),OnPostRender=event()}
local keys={}
isKeyDown=function(k)return keys[k]==true end
local mouse={}
isMouseButtonDown=function(n)return mouse[n]==true end
KeybindId={SHOUT='Shout'}
getCore=function()return {isDoingTextEntry=function()return text end,isKey=function(self,id,key)return id=='Shout' and key==16 end}end
local base={}
function base:derive()local c={};c.__index=c;setmetatable(c,{__index=self});return c end
function base.new(class,p)return setmetatable({character=p},class)end
function base:setActionAnim(anim)self.character:setVariable('PerformingAction',anim)end
function base:forceStop()self.stopped=true;self:stop()end
function base:forceComplete()self.completed=true;self:perform()end
function base.perform()end
function base.stop()end
ISBaseTimedAction=base
local queueFail=false
ISTimedActionQueue={add=function(a)if queueFail then return nil end;return {current=a}end}
do local _="ProjectYakuzaFixture:BINDINGS" end
do local _="ProjectYakuzaFixture:REGISTRY" end
local ProjectYakuza=ProjectYakuza
do local _="ProjectYakuzaFixture:STYLE" end
local p={vars={},data={ProjectYakuzaStyle='dragon_of_dojima',ProjectYakuzaHeat=0},block=false,ignore=false,deferred=true,aim=true,x=10,y=12,localPlayer=true}
function p:getModData()return self.data end
function p:GetVariable(k)return self.vars[k]end
function p:setVariable(k,v)self.vars[k]=v end
function p:isDead()return self.dead or false end
function p:isOnFloor()return false end
function p:isKnockedDown()return false end
function p:isClimbing()return false end
function p:isAsleep()return false end
function p:isDraggingCorpse()return false end
function p:getHitReaction()return self.hit or '' end
function p:getVehicle()return self.vehicle end
function p:isAiming()return self.aim end
function p:isBlockMovement()return self.block end
function p:setBlockMovement(v)self.block=v end
function p:getIgnoreMovement()return self.ignore end
function p:setIgnoreMovement(v)self.ignore=v end
function p:isDeferredMovementEnabled()return self.deferred end
function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:getX()return self.x end
function p:getY()return self.y end
function p:getZ()return 0 end
function p:getMovementLastFrame()return {set=function()end}end
function p:setMoving(v)self.moving=v end
function p:setRunning(v)self.running=v end
function p:setSprinting(v)self.sprinting=v end
local entryItem={}
function p:getPrimaryHandItem()return entryItem end
function p:isLocalPlayer()return self.localPlayer end
function p:getOffsetX()return 0 end
function p:getOffsetY()return 0 end
local equipped,extreme=true,false
ProjectYakuza.isEquipped=function()return equipped end
ProjectYakuza.isBusy=function(p)return ProjectYakuza.activeActions[p]~=nil end
ProjectYakuza.resetPlayer=function()end
ProjectYakuza.setVisual=function(player,active)player:setVariable("ProjectYakuzaActive",active)end
ProjectYakuza.Defense={ready=function(p)return p.aim and equipped and not paused and not ProjectYakuza.isBusy(p) and not p.vehicle and not p.dead end,
 snapActor=function(p,x,y)p.x=x;p.y=y end}
ProjectYakuza.Heat={stockSize=function()return 100/6 end,isExtreme=function()return extreme end,enabled=function()return true end,
 stocks=function(p)return math.floor(ProjectYakuza.getHeat(p)/(100/6))end,display=function(p)return extreme and 80 or ProjectYakuza.getHeat(p)end}
getSpecificPlayer=function()return p end
local vanilla={0,0,0}
ISEmoteRadialMenu={onKeyPressed=function()vanilla[1]=vanilla[1]+1 end,onKeyRepeat=function()vanilla[2]=vanilla[2]+1 end,onKeyReleased=function()vanilla[3]=vanilla[3]+1 end}

function p:hasTimedActions()return self.nativeAction~=nil end
function p:isWeaponReady()return self.ready~=false end
function p:isAttackStarted()return false end
function p:isPerformingAttackAnimation()return false end
function p:isRunning()return self.running==true end
function p:isSprinting()return self.sprinting==true end
function p:isAuthorizeMeleeAction()return self.authorize~=false end
function p:setAuthorizeMeleeAction(v)self.authorize=v end
function p:getCharacterActions()
 return {size=function()return self.nativeAction and 1 or 0 end,contains=function(_,a)return self.nativeAction==a end}
end
function p:StopAllActionQueue()self.nativeStops=(self.nativeStops or 0)+1;self.nativeAction=nil end
function p:setGhostMode()error('entry must not grant ghost mode')end
function p:setInvincible()error('entry must remain vulnerable')end
function base.perform(a)a.character.nativeAction=nil end
function base.stop(a)a.character.nativeAction=nil end
do local _="ProjectYakuzaFixture:ENTRY" end
local E=ProjectYakuza.StyleEntry
local starts,stops=0,0
ProjectYakuza.on('styleEntryStarted',function()starts=starts+1 end)
ProjectYakuza.on('styleEntryStopped',function()stops=stops+1 end)
local function begin()
 p.aim=false;p.nativeAction=nil;p.hit='';p.dead=false;p.authorize=true
 check(E.request(p,'dragon_of_dojima'),'selection request accepted without aiming')
 local c=ProjectYakuza.activeActions[p];local a=c.timedAction
 a.action={setOverrideHandModelsObject=function()a.handOverride=true end}
 p.nativeAction=a.action;a:start();return a,c
end
local a,c=begin();local heat=ProjectYakuza.getHeat(p)
check(p:GetVariable('ProjectYakuzaActive')==true and p:GetVariable('ProjectYakuzaStyle')=='dragon_of_dojima','idle style variables are ready beneath entry for a native blended handoff')
check(p.block and p.ignore and not p.deferred and a.handOverride,'entry locks movement, root travel and native weapon attacks')
ProjectYakuza.Bindings.update(p);check(not p.authorize,'native attack authorization is gated while entry is active')
check(not a.stopOnWalk and not a.stopOnRun and not a.stopOnAim,'movement and aim input cannot cancel entry')
check(c.action.duration==45/30 and starts==1,'original Kiwami 1 Dragon entry timing and one start event')
p.x=p.x+.5;p.y=p.y+.5;p.running=true;E.holdPositions()
check(p.x==a.anchorX and p.y==a.anchorY and not p.running,'entry anchor prevents sliding')
p.aim=true;mouse[0]=true;check(E.watch(p,c) and not a.cleaned,'attack input cannot interrupt entry')
local ok,reason=ProjectYakuza.requestAction(p,'finisher','after_1');check(not ok and reason=='busy','framework attack request is blocked during entry');mouse[0]=false
p:setVariable('ProjectYakuzaStyleEntry','started');a:update();p:setVariable('ProjectYakuzaStyleEntry','done');a:update();ProjectYakuza.Bindings.update(p)
check(a.completed and not p.block and not p.ignore and p.deferred and p.authorize,'completion restores all movement and attack permissions')
check(not ProjectYakuza.activeActions[p] and stops==1 and ProjectYakuza.getHeat(p)==heat,'entry has no heat or persistent action effects')
a,c=begin();p:setVariable('ProjectYakuzaStyleEntry','started');a:update();p.hit='Bite';a:update();ProjectYakuza.Bindings.update(p)
check(a.stopped and not p.block and not p.ignore and p.deferred and p.authorize,'zombie hit interrupts entry and restores controls')
p.hit='';a,c=begin();clock=clock+601;a:update();check(a.stopped and not p.block,'missing clip fails closed')
a,c=begin();p:setVariable('ProjectYakuzaStyleEntry','started');a:update();local start=a.startedAt
paused=true;clock=clock+10000;a:update();paused=false;check(a.startedAt==start+10000 and not a.stopped,'pause freezes timeout')
E.clear();ProjectYakuza.Bindings.update(p);check(a.cleaned and not p.block and not p.ignore and p.authorize,'world exit clears only the entry lock')
a,c=begin();equipped=false;a:update();equipped=true;check(a.stopped and not p.block,'unequipping cancels safely')
queueFail=true;p.nativeAction=nil;check(not E.request(p,'dragon_of_dojima') and not ProjectYakuza.activeActions[p],'rejected queue has no lock or start cue');queueFail=false
check(not E.request(p,'different_style'),'stale selected style cannot start entry')
p.nativeAction=nil;p.hit='';p.ready=false
check(E.request(p,'dragon_of_dojima') and E.pending[p] and not ProjectYakuza.activeActions[p],'entry waits for unsettled weapon model instead of being lost')
check(ProjectYakuza.blocksNativeAttacks(p),'pending style selection discards attack input')
clock=clock+60;E.retry();check(E.pending[p]~=nil,'model readiness is retried with a bounded deadline')
p.ready=true;clock=clock+60;E.retry()
check(not E.pending[p] and ProjectYakuza.activeActions[p] and not E.pendingHook,'ready equipment starts queued entry once and unhooks retry')
E.clear()
p.ready=false;E.request(p,'dragon_of_dojima');p.hit='Bite';clock=clock+60;E.retry()
check(not E.pending[p],'getting hit cancels pending entry')
p.hit='';E.request(p,'dragon_of_dojima');clock=clock+2001;E.retry()
check(not E.pending[p] and not E.pendingHook,'failed equipment readiness cannot leave an input lock')
p.ready=true
local ending,endingContext=begin();p:setVariable('ProjectYakuzaStyleEntry','started');ending:update();clock=clock+math.ceil(endingContext.action.duration*1000)+1;ending:update()
check(ending.completed and p:GetVariable('PerformingAction')==''and not p.block and not p.ignore,'native early blending cannot leave the source-duration action locked when its final marker is absent')
local nextAction,nextContext=begin();p:setVariable('ProjectYakuzaStyleEntry','started');nextAction:update();p:setVariable('PerformingAction','AnotherNativeAction');nextAction:cleanup(false);check(p:GetVariable('PerformingAction')=='AnotherNativeAction','entry cleanup cannot erase another native action')
return 'PASS '..checks..' locked style entry, vulnerability, completion and cleanup checks'
