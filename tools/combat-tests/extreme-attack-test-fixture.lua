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
check(#style.extremeLightAttacks==4,'four verified boost lights')
check(not style.actions.finisher.variants.extreme_default,'directional heavy removed')
for i=1,4 do
 check(not style.actions.finisher.variants['extreme_after_'..i] and not style.actions.finisher.variants['extreme_double_after_'..i],'directional pair removed '..i)
 local m=style.extremeLightAttacks[i];check(m.extremeHeat and m.hitResponse==false,'mode-only source hit response '..i)
 check(PY.Weapons.findMove(style,m.nodeValue)==m,'server lookup indexes boost '..i)
end
p:AttemptAttack();check(state().activeLightMove==style.lightAttacks[1],'ordinary light retained');finish();reset();activate()
local view=PY.getPlayerStyle(p);check(view.extremeView and view.lightAttacks==style.extremeLightAttacks,'active mode switches light chain')
for i=1,4 do
 PY.Combo.press(state(),4,1);p:AttemptAttack()
 check(state().step==i and state().activeLightMove==style.extremeLightAttacks[i],'native boost light '..i)
 check(p.vars.ProjectYakuzaMove==style.extremeLightAttacks[i].nodeValue,'owner selector '..i)
 finish()
end
reset();activate();H.states[p].fuel=1;p:AttemptAttack()
check(not H.isExtreme(p) and state().activeLightMove==style.extremeLightAttacks[1],'final cost-depleted swing retains boost clip')
fire('OnPlayerUpdate',p);check(p.vars.ProjectYakuzaMove==style.extremeLightAttacks[1].nodeValue,'depletion cannot change playing boost pose')
finish();p:AttemptAttack();check(state().step==1 and state().activeLightMove==style.lightAttacks[1],'normal chain restarts after mode ends');finish();reset()
for _,profile in ipairs({'bat','knife','blade'})do
 local v=PY.Weapons.views[style.id][profile];check(not v.extremeLightAttacks and not v.barrageInput and not v.actions.barrage,'weapons isolate boost input '..profile)
end
local phase=0;local weight=1;local paused=false
isGamePaused=function()return paused end
PY.AttackEffects={findTrack=function()return phase,weight,{layer=0,slot=0}end}
PY.Defense={snapActor=function()end};PY.HitEffects={spawn=function()end};PY.HitResponses={apply=function()end}
function p:isDeferredMovementEnabled()return self.deferred~=false end
function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:getMovementLastFrame()return {set=function()end}end
function p:setMoving()end;function p:setRunning()end;function p:setSprinting()end
function base:setActionAnim(v)self.animation=v end
function base:forceComplete()self:perform()end
function base:forceStop()self:stop()end
InventoryItemFactory={CreateItem=function()return {getMinDamage=function()return .3 end,getMaxDamage=function()return .5 end}end}
do local _="ProjectYakuzaFixture:BARRAGE_RULES" end
do local _="ProjectYakuzaFixture:BARRAGES" end
local F=PY.Barrages;local R=PY.BarrageRules;local cfg=style.actions.barrage.variants
check(R.valid(cfg.punch)and R.valid(cfg.kick),'source barrage configuration valid')
check(#cfg.punch.contactFrames==13 and #cfg.kick.contactFrames==5,'source BEP contact counts')
check(math.abs(R.damage(cfg.punch,1,.4,true)-.168)<.000001,'first contact damage')
check(math.abs(R.damage(cfg.punch,13,.4,true)-.54)<.000001,'terminal contact damage')
for _,key in ipairs({'fps','speed','duration','damageMultiplier','finalMultiplier','range'})do
 local copy={};for k,v in pairs(cfg.punch)do copy[k]=v end;copy[key]=0/0;check(not R.valid(copy),'invalid numeric configuration rejected '..key)
end
reset();local ok=PY.requestAction(p,'barrage','kick');check(not ok,'mode required for direct barrage')
activate();state().step=4;state().finishedAt=clock;state().lastDown=false;mouse[0]=true
local consumed,started=F.input(p,state(),PY.getPlayerStyle(p),false)
check(consumed and started,'fifth click requests punch barrage')
local c=PY.activeActions[p];check(c and c.kind=='barrage'and c.variant=='punch','dedicated punch action context')
check(PY.blocksNativeAttacks(p),'native attacks blocked during barrage')
local a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start()
check(p.blocked and not p.deferred and a.animation==cfg.punch.animation,'barrage locks player and uses source animation')
local pulses={};a.pulse=function(_,i)pulses[#pulses+1]=i end
for _,frame in ipairs(cfg.punch.contactFrames)do phase=frame/30+.001;clock=clock+150;a:update()end
check(#pulses==13 and pulses[1]==1 and pulses[13]==13,'all thirteen source-timed contacts occur once')
a:update();check(#pulses==13,'update repeats cannot duplicate contact')
p.vars.ProjectYakuzaBarrage='done';a:update();check(a.cleaned and not PY.activeActions[p]and not p.blocked and p.deferred,'end marker restores controls')
mouse[0]=false;reset();activate()
consumed,started=F.input(p,state(),PY.getPlayerStyle(p),true);check(consumed and started and PY.activeActions[p].variant=='kick','heavy starts five-hit barrage')
c=PY.activeActions[p];a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};p.vars.ProjectYakuzaBarrage='';a:start();pulses={};a.pulse=function(_,i)pulses[#pulses+1]=i end
phase=cfg.kick.contactFrames[1]/30+.001;paused=true;a:update();check(#pulses==0,'paused barrage does not strike');paused=false;a:update();check(#pulses==1,'resume uses native source phase')
phase=cfg.kick.contactFrames[4]/30+.001;a:update();check(#pulses==2 and pulses[2]==4,'late frames skipped rather than burst replayed')
H.stop(p,'depleted');phase=cfg.kick.contactFrames[5]/30+.001;a:update();check(pulses[3]==5,'started source motion finishes after depletion')
PY.cancelAction(p,'test');check(a.cleaned and not p.blocked and p.deferred,'interruption restores movement')
reset();activate();state().step=4;state().active=true;state().lastDown=false;state().queued=1;mouse[0]=true
consumed,started=F.input(p,state(),PY.getPlayerStyle(p),false);check(consumed and not started and F.pending[p] and state().queued==0,'buffer avoids duplicate native light')
state().lastDown=true;clock=clock+400;F.input(p,state(),PY.getPlayerStyle(p),false);check(not F.pending[p],'short barrage buffer expires')
reset();activate();p.held=weapon('Base.BaseballBat');PY.Weapons.sync(p)
check(not F.input(p,state(),PY.getPlayerStyle(p),true),'weapons never consume barrage input')
reset();activate();consumed,started=F.input(p,state(),PY.getPlayerStyle(p),true)
c=PY.activeActions[p];a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start()
local victim={hits=0,total=0,dead=false}
function victim:isDead()return self.dead end;function victim:isOnFloor()return false end;function victim:isKnockedDown()return false end
function victim:getX()return .8 end;function victim:getY()return 0 end;function victim:getZ()return 0 end
function victim:Hit(item,attacker,damage)check(item==token and attacker==p,'native hit uses current item/player');self.hits=self.hits+1;self.total=self.total+damage end
function p:CanSee()return true end
local scans=0;local oldOrigin,oldTargets,oldPath=PY.MultiHit.origin,PY.MultiHit.targets,PY.MultiHit.clearPath
PY.MultiHit.origin=function()return {fx=1,fy=0}end
PY.MultiHit.clearPath=function()return true end
PY.MultiHit.targets=function(_,_,_,_,cap)scans=scans+1;check(cap==3,'bounded barrage scan');return victim.dead and {}or{{victim=victim}}end
local pulseEvents=0;PY.on('barragePulse',function()pulseEvents=pulseEvents+1 end)
a:pulse(1);a:pulse(2)
check(victim.hits==2 and math.abs(victim.total-.6)<.000001,'native SP damage uses source contact factor and mode once')
check(scans==1 and pulseEvents==2,'contacts reuse live targets and emit one feedback cue each')
victim.dead=true;a:pulse(3);check(scans==2 and victim.hits==2,'dead target triggers bounded reacquisition without damage')
PY.cancelAction(p,'test');PY.MultiHit.origin=oldOrigin;PY.MultiHit.targets=oldTargets;PY.MultiHit.clearPath=oldPath
return true,'PASS '..checks..' boost, barrage, depletion, input, pause, expiry, damage and weapon isolation checks'
