token.min=.3;token.max=.5;token.data={}
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
local H=PY.Heat
local style=PY.getStyle('dragon_of_dojima')
local function state()return PY.stateFor(p)end
local function finish()
 p.attacking=false;fire('OnPlayerAttackFinished',p,p:getPrimaryHandItem());PY.Bindings.update(p);clock=clock+30
end
local function reset()
 p.attacking=false;p.held=nil;H.stop(p,'test');PY.resetPlayer(p,'test');PY.Weapons.sync(p);PY.Bindings.update(p);clock=clock+100
end
local function activate()
 PY.setHeat(p,100);check(H.start(p),'real Extreme Heat activates with stored heat')
 check(H.isExtreme(p) and math.abs(token.max-.75)<.00001,'existing Extreme Heat multiplier applied once')
end
local function queue(branch)
 state().step=branch;state().finishedAt=clock
 check(PY.queueFinisher(p),'MMB queues branch '..branch)
 fire('OnPlayerUpdate',p)
 return state().finisherMove
end
reset()
local ok,reason=PY.requestAction(p,'finisher','extreme_default')
check(not ok and reason=='extreme_heat_required','direct Extreme heavy cannot bypass mode gate')
check(PY.queueFinisher(p) and state().finisherMove.nodeValue=='dd_heavy','normal neutral heavy retained')
finish();reset();activate()
check(PY.queueFinisher(p) and state().finisherMove.nodeValue=='dd_extreme_default','Extreme neutral heavy uses Heavy_Rev source')
check(math.abs(token.max-.9375)<.00001,'mode variation retains x1.25 heavy and existing x1.5 Extreme bonus')
check(not PY.queueFinisher(p),'Extreme neutral heavy has no double')
finish();check(not state().finisherBranch and not state().finisherExtreme,'neutral cleanup opens no mode branch')
reset();activate();H.states[p].fuel=1
check(PY.queueFinisher(p) and state().finisherMove.extremeHeat and not H.isExtreme(p),'last valid Extreme attack survives fuel depletion from its own swing cost')
finish()
for branch=1,4 do
 reset()
 local ordinary=queue(branch)
 check(ordinary==style.actions.finisher.variants['after_'..branch],'ordinary branch remains unchanged '..branch)
 finish();reset();activate()
 local first=queue(branch)
 check(first==style.actions.finisher.variants['extreme_after_'..branch] and first.afterLight==branch,'Extreme first variant '..branch)
 check(first.damageMultiplier==1.25 and not first.chargedHeavy,'mode variation does not stack extra damage or charging '..branch)
 local report=p.report;p.vars.ProjectYakuzaHitMarker='';p.vars.ProjectYakuzaDoubleReady=''
 check(PY.queueFinisher(p) and not state().recoveryReleased and p.report==report,'double input waits for source pose window '..branch)
 p.vars.ProjectYakuzaHitMarker=first.nodeValue;p.vars.ProjectYakuzaDoubleReady=first.nodeValue
 check(PY.tryRecoveryCancel(p,style,state()) and state().recoveryReleased,'source markers release queued recovery '..branch)
 check(PY.finisherHandoffs[p]~=nil,'handoff holds movement between clips '..branch)
 finish();fire('OnPlayerUpdate',p)
 local second=state().finisherMove
 check(second==style.actions.finisher.variants['extreme_double_after_'..branch] and second.double,'matching Extreme double starts '..branch)
 check(not PY.queueFinisher(p),'third finisher refused '..branch)
 finish();check(not state().finisherBranch and not PY.finisherHandoffs[p],'double completion clears latch and movement handoff '..branch)
end
reset();activate();local first=queue(2)
clock=clock+100;fire('OnPlayerUpdate',p)
check(state().active and not state().recoveryReleased and state().finisherMove==first,'without second input first continues its full animation')
H.stop(p,'depleted')
check(state().finisherMove==first and state().active,'depletion does not replace an in-progress clip')
finish()
check(state().finisherExtreme==true and not H.isExtreme(p),'first finisher remembers mode after depletion')
state().step=2;state().finishedAt=state().finisherFinishedAt
local accepted,why=PY.requestAction(p,'finisher','double_after_2')
check(not accepted and why=='finisher_mode_mismatch','mismatched normal double cannot follow Extreme first')
check(PY.queueFinisher(p),'depleted first can still request its matching double')
fire('OnPlayerUpdate',p)
check(state().finisherMove==style.actions.finisher.variants.extreme_double_after_2,'matching source double retained after depletion')
check(math.abs(token.max-.625)<.00001,'depleted double loses Extreme damage bonus without changing heavy balance')
finish();clock=clock+style.comboResetMs+1
check(PY.queueFinisher(p) and state().finisherMove.nodeValue=='dd_heavy','future neutral attacks return to ordinary mode')
finish();reset();activate();queue(1);finish();clock=clock+style.comboResetMs+1
state().step=1;state().finishedAt=state().finisherFinishedAt
accepted,why=PY.requestAction(p,'finisher','extreme_double_after_1')
check(not accepted and why=='combo_window_closed','source mode latch does not bypass normal follow-up expiry')
reset();local normal=queue(3);finish();activate()
check(PY.queueFinisher(p),'normal first can request its original double after mode activation')
fire('OnPlayerUpdate',p)
check(state().finisherMove==style.actions.finisher.variants.double_after_3,'first mode determines paired double even if Heat changes')
finish();reset();activate()
local bat=weapon('Base.BaseballBat');p.held=bat;PY.Weapons.sync(p)
check(PY.queueFinisher(p) and state().finisherMove.nodeValue=='dd_bat_heavy','real weapon uses its own heavy, without unarmed mode leak')
finish();p.held=nil
for _,profile in ipairs({'bat','knife','blade'}) do
 local view=PY.Weapons.views[style.id][profile]
 check(not view.actions.finisher.variants.extreme_default and not view.actions.finisher.variants.extreme_after_1,'weapon profile isolated '..profile)
end
reset();activate();p:AttemptAttack()
check(state().step==1 and not state().finisherMove and p.vars.ProjectYakuzaMove==style.lightAttacks[1].nodeValue,'Extreme mode retains original LMB chain')
finish();reset()
local other={id='tests.mode_isolation',name='Mode isolation',lightAttacks=style.lightAttacks,actions={finisher={enabled=true,variants={default=style.actions.finisher.variants.default}}}}
PY.registerStyle(other);p.data.ProjectYakuzaStyle=other.id;PY.Weapons.sync(p)
check(PY.queueFinisher(p) and state().finisherMove.nodeValue=='dd_heavy','another style needs explicit variation definitions')
finish()
return true,'PASS '..checks..' actual Extreme Heat finisher, paired handoff, depletion, damage, weapon and style isolation checks'
