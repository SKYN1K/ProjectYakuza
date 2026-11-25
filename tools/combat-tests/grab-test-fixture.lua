function p:StopTimedActionAnim()end
function p:CanSee()return self.visible~=false end
function p:setIsAiming(value)self.aiming=value end
function p:isAiming()return self.aiming==true or mouse[1]==true end
function p:isAimControlActive()return mouse[1]==true or self.forceAim==true end
do
 local add,remove=Events.OnTick.Add,Events.OnTick.Remove;Events.OnTick.hooks={}
 Events.OnTick.Add=function(fn)Events.OnTick.hooks[fn]=true;add(fn)end
 Events.OnTick.Remove=function(fn)Events.OnTick.hooks[fn]=nil;remove(fn)end
end
ZombRand=function(max)return max-1 end
Events.OnZombieUpdate=event();Events.OnGameStart=event();Events.OnServerCommand=event()
CharacterStat={ENDURANCE=1}
mouse[1]=true
local paused=false;isGamePaused=function()return paused end
local stamina=.9;function p:getStats()return {get=function()return stamina end,remove=function(_,_,v)stamina=stamina-v end}end
function p:getX()return self.x or .5 end;function p:getY()return self.y or .2 end
function p:moveUnmodded(dx,dy)self.x=self:getX()+dx;self.y=self:getY()+dy end
function p:setX(v)self.x=v end;function p:setY(v)self.y=v end
function p:setNextX(v)self.nextX=v end;function p:setNextY(v)self.nextY=v end
function p:setLastX(v)self.lastX=v end;function p:setLastY(v)self.lastY=v end
function p:setCurrentSquareFromPosition()end;function p:setMovingSquareNow()end
function p:getIgnoreMovement()return self.ignore==true end;function p:setIgnoreMovement(v)self.ignore=v end
function p:isBlockMovement()return self.blocked==true end
function p:isDeferredMovementEnabled()return self.deferred~=false end;function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:setMoving(v)self.moving=v end;function p:setRunning(v)self.running=v end;function p:setSprinting(v)self.sprinting=v end
function p:getMovementLastFrame()return {set=function()end}end
local forward={getX=function()return 0 end,getY=function()return 1 end}
function p:getForwardDirection()return forward end;function p:getAnimForwardDirection()return forward end
function p:setTargetAndCurrentDirection()end;function p:isInvincible()return self.invincible==true end;function p:setInvincible(v)self.invincible=v end
function p:isGhostMode()return self.ghost==true end;function p:setGhostMode(v)self.ghost=v end
Vector2={new=function()return forward end}
function token:getMinDamage()return .3 end;function token:getMaxDamage()return .5 end
function token:getModData()return {}end
instanceItem=function()return token end
function base:setActionAnim(v)self.animation=v end
function base:forceStop()self:stop()end;function base:forceComplete()self:perform()end
local oldNew=base.new
base.new=function(class,player)local a=oldNew(class,player);a.action={setOverrideHandModelsObject=function()end};return a end
ZombieOnGroundState={instance=function()return 'ZombieOnGroundState'end}
local z={x=.5,y=.9,health=10,vars={},hits=0,deferred=true,target=p,state='idle'}
function z:getHealth()return self.health end;function z:setHealth(v)self.health=v end;function z:setAttackedBy(v)self.attacker=v end
function z:hitConsequences(_,_,skip,amount)check(skip and amount==0 and self:isDead(),'terminal paired death cannot apply damage twice')end
function z:changeState(v)self.state=v end
function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return 0 end
function z:setX(v)self.x=v end;function z:setY(v)self.y=v end
function z:setNextX(v)self.nx=v end;function z:setNextY(v)self.ny=v end
function z:setLastX(v)self.lx=v end;function z:setLastY(v)self.ly=v end
function z:setCurrentSquareFromPosition()end;function z:setMovingSquareNow()end
function z:getStateMachine()local z=self;return {isLocked=function()return z.locked==true end}end
function z:setStateMachineLocked(v)self.locked=v end;function z:getCurrentStateName()return self.state end
function z:isFallOnFront()return self.front==true end
function z:isDead()return self.health<=0 end;function z:isOnFloor()return self.floor==true end;function z:isKnockedDown()return false end
function z:isUseless()return self.useless==true end;function z:setUseless(v)self.useless=v end
function z:getIgnoreMovement()return self.ignore==true end;function z:setIgnoreMovement(v)self.ignore=v end
function z:isDeferredMovementEnabled()return self.deferred end;function z:setDeferredMovementEnabled(v)self.deferred=v end
function z:getTarget()return self.target end;function z:setTarget(v)self.target=v end
function z:getHitReaction()return self.reaction or ''end;function z:setHitReaction(v)self.reaction=v end
function z:setVariable(k,v)self.vars[k]=v end;function z:GetVariable(k)local v=self.vars[k];return type(v)=='boolean'and tostring(v)or v or''end
function z:clearVariable(k)self.vars[k]=nil end
function z:reportEvent(v)self.report=v;if not self.locked then self.state=v=="wasHit"and "ZombieHitReactionState"or "idle"end end;function z:setAttackOutcome(v)self.outcome=v end
function z:isAttacking()return false end;function z:setTargetAndCurrentDirection()end;function z:setForwardDirection()end
function z:moveUnmodded(x,y)self.x=self.x+x;self.y=self.y+y end
function z:setFallOnFront(v)self.front=v end
function z:setKnockedDown(v)self.knock=v end;function z:setOnFloor(v)self.floor=v end;function z:setStaggerBack(v)self.stagger=v end
function z:setHitForce(v)self.force=v end;function z:getOnlineID()return 9 end
function z:isIgnoreStaggerBack()return self.ignoreStagger==true end
function z:setIgnoreStaggerBack(v)self.ignoreStagger=v end
function z:setBumpType(v)self.bump=v end
function z:setBumpStaggered(v)self.bumpStagger=v end
function z:setBumpFall(v)self.bumpFall=v end
function z:setBumpDone(v)self.bumpDone=v end
function z:setMoving(v)self.moving=v end
function z:getMovementLastFrame()return {set=function(_,x,y)self.moveX=x;self.moveY=y end}end
function z:Hit(_,_,damage)self.hits=self.hits+1;self.health=self.health-damage;self.floor=true;self.knock=true;self.stagger=true end
instanceof=function(o,name)return o==z and name=='IsoZombie'or o==p and name=='IsoPlayer'end
PY.TigerDrop={tracked={}}
PY.MultiHit={origin=function(player,range)return {x=player:getX(),y=player:getY(),z=0,fx=0,fy=1,range=range}end,targets=function()return {{victim=z}}end,clearPath=function()return true end}
PY.Quicksteps={shoveAuth={},canMove=function()return true end}
local track=0;PY.AttackEffects={findTrack=function()return track,1 end}
PY.NetworkProtocol={path=function()return true end,integer=function(v,a,b)return type(v)=='number'and v==math.floor(v)and v>=a and v<=b end,number=function(v,a,b)return type(v)=='number'and v==v and v>=a and v<=b end}
local heard=0;PY.Feedback={sound=function(_,v)return v end,play=function()heard=heard+1 end}
PY.HitEffects={spawn=function()end}
local wall=true;local window=false;local door=false;local blocked=false
local squares={}
getCell=function()return {getGridSquare=function(_,x,y,level)
 if level~=0 then return end
 local key=x..':'..y
 if not squares[key]then squares[key]={isWallTo=function(_,other)return wall and other and y==1 and other.y==0 end,isWindowTo=function()return window end,isDoorTo=function()return door end,getMovingObjects=function()return {size=function()return 0 end}end,y=y}end
 return squares[key]
end}end
PY.NetworkProtocol.path=function()return not blocked end
getSpecificPlayer=function()return p end
PY.resetPlayer=function()end
PY.isBusy=function(player)return PY.activeActions[player]~=nil end
PY.stateFor=function()return {step=0,queued=0}end
PY.setVisual=function()end
PY.Network=nil

do local _="ProjectYakuzaFixture:GRAB_RULES" end
do local _="ProjectYakuzaFixture:RUSH_RULES" end
do local _="ProjectYakuzaFixture:HEAT_ACTIONS" end
do local _="ProjectYakuzaFixture:DEFENSE" end
do local _="ProjectYakuzaFixture:RUSH" end
do local _="ProjectYakuzaFixture:GRAB_COMBAT" end
local D=PY.Defense;local G=PY.GrabCombat;local R=PY.GrabRules;local style=PY.getStyle('dragon_of_dojima')
check(style.actions.grab.enabled and #style.actions.grab.strikes==4,'DoD enables four original grab strikes')
local function startGrab()
 p.ignore=false;p.blocked=false;p.deferred=true;p.attacking=false;z.reaction='';z.useless=false;z.ignore=false;z.deferred=true;z.locked=false;z.state="idle";z.health=10;stamina=.9
 z.x=p:getX();z.y=p:getY()+.7
 local ok,reason=PY.requestAction(p,'grab',nil,z);check(ok,'grab handler starts '..tostring(reason))
 local a=PY.activeActions[p].timedAction;a:start()
 check(not z.useless and not z.ignore and z.reaction=='' and not a.context.target,'grab starts as an unpaired attempt without immobilizing a victim')
 track=style.actions.grab.attemptContactMs/1000;clock=clock+200;a:update();track=0
 check(a.context.target==z and z.useless and z.ignore,'source reach contact acquires the nearby target after the wind-up')
 p.vars.ProjectYakuzaDefenseMarker='enter_ready';z.vars.ProjectYakuzaGrabMarker='enter_ready';clock=clock+500;a:update()
 check(a.phaseName=='hold'and a.paired,'paired source markers reach hold')
 return a
end
local a=startGrab()
check(z.locked and z.useless and z.ignore and not z.deferred,'native reaction is latched while held')
check(not p.blocked and not p.ignore and p.deferred,'walking remains available with native movement during hold')
clock=clock+12000;a:update();check(not a.cleaned and a.phaseName=='hold','hold survives the obsolete 3.5-second timeout')
p.x=.6;p.y=.3;clock=clock+50;a:update();check(math.abs(z.x-(.6+R.offset(style.actions.grab,'hold').right))<.001 and math.abs(z.y-(.3+R.offset(style.actions.grab,'hold').forward))<.001,'held victim follows actor translation')
p.x=.5;p.y=.2;z.y=.9
for i=1,4 do
 check(G.input(p,a,true,false),'LMB starts grab strike '..i)
 local m=a.strikeMove;check(a.phaseName=='strike'..i and p.blocked and p.ignore and not p.deferred,'strike locks movement and selects correct paired phase')
 local before=z.hits;local beforeHealth=z.health;track=math.max(0,m.contactMs/1000-.02);clock=clock+10;a:update();check(z.hits==before,'strike cannot hit before source contact')
 track=m.contactMs/1000+.001;clock=clock+20;a:update();a:update();check(z.hits==before and math.abs(z.health-(beforeHealth-R.damage(p,m)))<.000001,'one source contact applies configured damage without a second native flinch')
 check(z.locked and not z.floor and not z.knock and not z.stagger and z:getHitReaction()=='ProjectYakuzaGrabbed'and z.force==0,'strike does not eject or knock back held victim')
 track=m.duration;clock=clock+30;a:update();check(a.phaseName=='hold'and p.blocked and not p.deferred,'full source strike keeps movement locked while blending to its grip');track=0;clock=clock+style.actions.grab.recoveryMs;a:update();check(not p.blocked and p.deferred,'walking resumes after the complete pose blend')
end
PY.cancelAction(p,'released');check(not z.locked and not z.useless and not z.ignore and z.deferred and not p.blocked and p.deferred,'release restores every owned native flag')
local saved=R.capture(z);z.locked=true;R.keep(z);R.restore(z,saved);check(z.locked,'cleanup preserves a pre-existing state-machine lock');z.locked=false
local pose=R.wall(p,z,style.actions.grabHeat.variants.default);check(pose and pose.fx==0 and pose.fy==1,'wall action faces its solid wall along the original forward motion')
do
 local originalCell=getCell;local oldX,oldY,oldZX,oldZY=p.x,p.y,z.x,z.y
 for _,v in ipairs({{0,1,.5,.2,.5,.9},{0,-1,.5,1.8,.5,1.1},{1,0,.2,.5,.9,.5},{-1,0,1.8,.5,1.1,.5}})do
  local nx,ny=v[1],v[2];p.x,p.y,z.x,z.y=v[3],v[4],v[5],v[6]
  getCell=function()return {getGridSquare=function(_,x,y)return {x=x,y=y,isWallTo=function(a,b)return nx==0 and a.y==1 and b.y==0 or ny==0 and a.x==1 and b.x==0 end,isWindowTo=function()return false end,isDoorTo=function()return false end}end}end
  local aligned=R.wall(p,z,style.actions.grabHeat.variants.default)
  check(aligned and aligned.fx==nx and aligned.fy==ny,'wall facing follows the selected wall normal in every direction')
  local motion=PY.PairedMotions.dod_wall
  for _,path in ipairs({motion.actor,motion.victim})do
   for _,point in ipairs(path)do
    local x=aligned.x+aligned.fx*point[1]+aligned.fy*point[2];local y=aligned.y+aligned.fy*point[1]-aligned.fx*point[2]
    check((nx==0 and (1-y)*ny or (1-x)*nx)>=.149999,'paired path remains on the interior side of its wall')
   end
  end
 end
 getCell=originalCell;p.x,p.y,z.x,z.y=oldX,oldY,oldZX,oldZY
end
window=true;check(not R.wall(p,z,style.actions.grabHeat.variants.default),'windows never count as solid heat-action walls');window=false
door=true;check(not R.wall(p,z,style.actions.grabHeat.variants.default),'doors never count as solid heat-action walls');door=false
blocked=true;check(not R.wall(p,z,style.actions.grabHeat.variants.default),'blocked source pair paths reject the heat action');blocked=false
wall=false;check(not R.wall(p,z,style.actions.grabHeat.variants.default),'no wall means no wall-specific heat action');wall=true
p.data.ProjectYakuzaHeat=100;a=startGrab();local target,move=G.candidate(p,true);check(target==z and move==style.actions.grabHeat.variants.default,'eligible held target exposes the heat-action prompt')
check(G.input(p,a,false,true),'heat-action input takes priority near a wall')
check(G.updatePending(p),'wall action consumes the held-target ticket')
local c=PY.activeActions[p];check(c and c.kind=='grabHeat'and c.target.fromGrab,'grab transfers into the paired heat-action framework')
check(a.cleaned and not z.locked,'handoff releases the old grab lock before the new victim lock')
local action=c.timedAction;action:start();check(p.invincible and p.ghost and p.blocked,'wall action uses full-duration protection and movement lock')
z.bump='stumble';z.bumpStagger=true;z.bumpFall=true;z.stagger=true;z.force=1;z.moveX=1;z.moveY=1
PY.HeatActions.zombie(z)
check(z:GetVariable('ProjectYakuzaPairedVictimClip')=='ProjectYakuza_DD_WallHeatVictim'and z.bump==''and not z.bumpStagger and not z.bumpFall and z.bumpDone and z.ignoreStagger and not z.stagger and z.force==0 and z.moveX==0 and z.moveY==0,'wall victim update suppresses collision stumble flags and residual movement without replacing its paired clip')

action:cleanup(false);check(not p.invincible and p.ghost and not z.ignoreStagger,'ending restores invulnerability and original stagger permission while target grace remains')
clock=clock+600;PY.HeatActions.tick();check(not p.ghost and not z.locked,'target grace and victim lock clean up')

do
 wall=false;window=false;door=false;blocked=false;stamina=1;p.x=.5;p.y=.2;z.x=.5;z.y=.9;z.floor=false;z.knock=false;z.useless=false;z.reaction='';z.health=1
 local cost=PY.Heat.stockSize(p);p.data.ProjectYakuzaHeat=cost;local held=startGrab();local target,move,pose,variant=G.candidate(p,true)
 check(target==z and variant=='open'and move==style.actions.grabHeat.variants.open and pose.motion==PY.PairedMotions.dod_grab_open,'open space selects the single held target and original shoulder throw')
 p.data.ProjectYakuzaHeat=cost-.01;check(not G.candidate(p,true),'open grab Heat Action rejects less than one full stock');p.data.ProjectYakuzaHeat=cost
 blocked=true;check(not G.candidate(p,true),'blocked paths never expose an open grab action');blocked=false
 check(G.input(p,held,false,true),'Heat Action input selects open-space variant')
 local pending=G.pending[p];check(G.input(p,held,true,true)and G.pending[p]==pending and held.phaseName=='hold','pending handoff cannot be replaced by repeated Heat input or a grab strike')
 blocked=true;check(not G.updatePending(p)and PY.activeActions[p].timedAction==held and not held.cleaned and p.data.ProjectYakuzaHeat==cost,'new obstruction preserves the old grab and Heat before handoff');blocked=false
 check(G.input(p,held,false,true),'clear-space retry uses the same held victim')
 local request=G.pending[p].request;check(G.receive('heatRushGranted',p,{request=request,grabHeat=true,grabVariant='default',action=23}),'mismatched server variant is rejected');check(not G.pending[p]and not held.cleaned and p.data.ProjectYakuzaHeat==cost,'mismatched grant cannot consume Heat or release the grab')
 check(G.input(p,held,false,true)and G.updatePending(p),'one full stock accepts open-space handoff')
 local context=PY.activeActions[p];local heat=context.timedAction;check(context.kind=='grabHeat'and context.variant=='open'and context.target.z==z and held.cleaned,'native variant handoff retains the exact grabbed target')
 z.health=1;heat:start();track=.01;clock=clock+10;heat:update();check(context.heatPaid and p.data.ProjectYakuzaHeat==0,'confirmed open-space playback spends exactly one stock');heat:update();check(p.data.ProjectYakuzaHeat==0,'repeated native update cannot spend twice')
 for i in ipairs(context.action.contacts)do heat.success[i]=true;heat:contact(i);heat:contact(i)end
 check(not z:isDead()and heat.pendingDamage and heat.pendingDamage>0,'lethal throw damage waits for the complete paired animation')
 heat:cleanup(true);check(z:isDead()and not z.locked and not z.useless and not p.invincible,'completion settles lethal damage once and restores owned state')
 clock=clock+600;PY.HeatActions.tick();check(not p.ghost,'open action protection grace expires');z.health=10;z.floor=false;z.knock=false;z.reaction='';wall=true;p.data.ProjectYakuzaHeat=100
end

a=startGrab();stamina=.01;clock=clock+20;a:update();check(a.cleaned and not z.locked,'exhaustion releases the hold and AI lock')
a=startGrab();z.floor=true;clock=clock+20;a:update();check(a.cleaned and not z.locked,'invalid victim state releases the hold');z.floor=false
local originalMoves=style.actions.grab.strikes
style.actions.grab.strikes={originalMoves[1],originalMoves[2],originalMoves[3],originalMoves[4],originalMoves[1]}
check(not PY.validateStyle(style),'more than four phase-backed grab strikes rejected')
style.actions.grab.strikes={{animation='provided.actor',targetAnimation='provided.victim',duration=1,contactMs=1000}}
check(not PY.validateStyle(style),'contact beyond the source strike duration rejected')
style.actions.grab.strikes={{animation='provided.actor',duration=1,contactMs=200}}
check(not PY.validateStyle(style),'missing paired victim clip rejected')
style.actions.grab.strikes=originalMoves
do
 wall=false;window=false;door=false;p.x=.5;p.y=.2;z.x=.5;z.y=.9;z.floor=true;z.knock=true;z.health=10;z.useless=false;z.reaction='';p.data.ProjectYakuzaHeat=100
 local state=PY.stateFor(p);state.active=false;state.starting=false;state.step=0;state.finisherBranch=nil;state.queued=0
 local move=style.actions.groundHeat
 check(PY.HeatRushRules.validFor(p,z,move)and not PY.HeatRushRules.validFor(p,z,style.actions.heatAction),'ground heat requires a live downed zombie and normal rush still rejects it')
 z.front=true;check(not PY.HeatRushRules.validFor(p,z,move),'face stomp rejects a face-down zombie');z.front=false
 z.floor=false;check(not PY.HeatRushRules.validFor(p,z,move),'knockdown flag alone cannot qualify before landing');z.floor=true
 z.state='ZombieGetUpState';check(not PY.HeatRushRules.validFor(p,z,move),'face stomp rejects a zombie already getting up');z.state='idle'
 local pose=PY.HeatRushRules.placement(p,z,move);check(pose~=nil,'ground pair has a bounded safe placement')
 local ticket={z=z,pose=pose,ground=true,pressed=true,expires=clock+600}
 check(PY.requestAction(p,'groundHeat',nil,ticket),'ground heat is registered in the shared paired framework')
 local action=PY.activeActions[p].timedAction;action:start();check(p.invincible and not z.floor and not z.knock,'ground action protects actor and suspends native downed overrides')
 local before=z.hits;local health=z.health;track=1;clock=clock+1000;action:update();check(z.hits==before and z.health<health,'nonlethal ground damage preserves the original victim clip without native Hit')
 action:cleanup(false);check(not p.invincible and z.floor and z.knock,'ground interruption restores downed victim and protection')
 wall=true;z.floor=false;z.knock=false
end
do
 local oldX,oldY,oldZX,oldZY=p.x,p.y,z.x,z.y;local oldCell=getCell
 p.x=.5;p.y=.8;z.x=.5;z.y=.9;z.floor=false;z.knock=false;wall=true
 local move={motionId='clearance_test',duration=1/30};PY.PairedMotions.clearance_test={actor={{0,0},{.1,0}},victim={{.3,0},{.3,0}}}
 local pose=PY.HeatRushRules.placement(p,z,move)
 check(pose and pose.y<p.y and PY.HeatRushRules.clearance(p,pose),'ordinary pair shifts together away from the nearby wall')
 getCell=function()return {getGridSquare=function()return {isWallTo=function()return true end,isWindowTo=function()return false end,isDoorTo=function()return false end}end}end
 check(not PY.HeatRushRules.placement(p,z,move),'no fitting clear space refuses the action rather than clipping')
 getCell=oldCell;p.x,p.y,z.x,z.y=oldX,oldY,oldZX,oldZY;PY.PairedMotions.clearance_test=nil
end
do
 wall=false;z.floor=false;z.knock=false;z.useless=false;z.reaction='';p.data.ProjectYakuzaHeat=100
 local oldCell=getCell;local scans=0
 getCell=function()return {getGridSquare=function()scans=scans+1;return {getMovingObjects=function()return {size=function()return 0 end}end}end}end
 PY.HeatRush.groundPreviews[p]=nil;local state=PY.stateFor(p);state.active=false;state.step=0;state.finisherBranch=nil
 PY.HeatRush.weaponCandidate(p,state,style,false);local count=scans;PY.HeatRush.weaponCandidate(p,state,style,false)
 check(count==25 and scans==count,'empty ground searches retain their cache when no weapon action is available')
 getCell=oldCell;wall=true
end
do
 local rules=PY.HeatRushRules;local motion=PY.PairedMotions.dod_ground;local offset=motion.contactOffset;check(offset~=nil,'ground sequence includes native head/sole calibration')
 local forward,right=rules.sample(motion.victim,1)
 for _,v in ipairs({{1,0},{0,1},{-1,0},{0,-1},{.70710678,.70710678},{-.70710678,.70710678},{.70710678,-.70710678},{-.70710678,-.70710678}})do
  local job={x=5,y=7,fx=v[1],fy=v[2],motion=motion};local x,y=rules.point(job,motion.victim,1)
  check(math.abs(x-(5+v[1]*(forward+offset.forward)+v[2]*(right+offset.right)))<.000001 and math.abs(y-(7+v[2]*(forward+offset.forward)-v[1]*(right+offset.right)))<.000001,'victim calibration rotates with the pair in all eight headings')
 end
end

do
 local slot=style.actions.grab
 check(R.spacing(nil)==.7,'other styles retain legacy default grab distance')
 for _,phase in ipairs({'hold','throw','strike1','strike2','strike3','strike4'})do
  local offset=R.offset(slot,phase)
  for i=0,7 do
   local angle=i*math.pi/4;local fx,fy=math.cos(angle),math.sin(angle)
   local x,y=fx*offset.forward+fy*offset.right,fy*offset.forward-fx*offset.right
   check(math.abs(x*fx+y*fy-offset.forward)<.000001 and math.abs(x*fy-y*fx-offset.right)<.000001,'paired offsets preserve contact in every facing')
  end
 end
 local state={};local hold=R.alignment(slot,'hold',state,0)
 local first=R.alignment(slot,'strike1',state,100);check(first.forward==hold.forward and first.right==hold.right,'strike handoff preserves previous root position')
 local final=R.alignment(slot,'strike1',state,220);local target=R.offset(slot,'strike1')
 check(math.abs(final.forward-R.offset(slot,'strike1',false,.12).forward)<.000001 and math.abs(final.right-R.offset(slot,'strike1',false,.12).right)<.000001,'strike reaches calibrated contact offset after its short blend')
 local returning=R.alignment(slot,'hold',state,230);check(returning.forward==final.forward and returning.right==final.right,'return to hold begins at previous paired offset')
 local restore=R.alignment(slot,'hold',state,470);check(math.abs(restore.forward-R.offset(slot,'hold').forward)<.00002,'returning hold restores walking grab spacing')
 local original=slot.throwOffset;slot.throwOffset={forward=0/0,right=0};check(not PY.validateStyle(style),'invalid paired offsets cannot enter registered styles');slot.throwOffset=original
end
do
 p.x=.5;p.y=.2;z.floor=false;z.knock=false;z.front=false
 local thrown=startGrab();check(thrown:throw(),'paired hold starts throw')
 local hits=z.hits
 p.vars.ProjectYakuzaDefenseMarker='throw_impact';z.vars.ProjectYakuzaGrabMarker='throw_impact';clock=clock+1500;thrown:update()
 check(thrown.cleaned and z.hits==hits+1,'completed throw deals one hit and releases paired action')
 check(z.floor and not z.front and not z.stagger and z.force==0 and z:getHitReaction()=='','throw cleanup leaves victim face-up on the floor without a stumble reaction')
 check(not z.ignore and not z.useless and z.deferred and not z.locked,'prone landing restores normal AI and owned movement locks')
 z.floor=false;z.knock=false
end
do
 local originalCell,originalPath,originalInstance=getCell,PY.NetworkProtocol.path,instanceof
 local candidates={};local function victim(x,y)
  local v=setmetatable({x=x,y=y,health=10,vars={},hits=0,deferred=true,floor=false,knock=false,locked=false,useless=false,state='idle',crowdZombie=true},{__index=z})
  function v:isKnockedDown()return self.knock==true end
  function v:getHitDir()return {set=function(_,dx,dy)v.dx=dx;v.dy=dy end}end
  function v:setAttackedBy(actor)self.attacker=actor end
  return v
 end
 p.x=0;p.y=0;z.x=0;z.y=.5;z.floor=true
 for i=1,6 do candidates[i]=victim(i*.04,1+i*.04)end
 local blockedVictim=victim(.12,1);local dead=victim(0,1);dead.health=0
 local prone=victim(0,1);prone.floor=true
 local protected=victim(0,1);protected.vars.ProjectYakuzaHeatRushVictim=true
 local held=victim(0,1);held.vars.ProjectYakuzaGrabbed=true
 local upper=victim(0,1);function upper:getZ()return 1 end
 local behind=victim(0,.25);local distant=victim(0,4)
 local list={z,p,blockedVictim,dead,prone,protected,held,upper,behind,distant}
 for _,v in ipairs(candidates)do list[#list+1]=v end
 instanceof=function(v,kind)return kind=='IsoZombie'and v.crowdZombie==true or originalInstance(v,kind)end
 local scans=0;getCell=function()return {getGridSquare=function()scans=scans+1;return {getMovingObjects=function()return {size=function()return #list end,get=function(_,i)return list[i+1]end}end}end}end
 PY.NetworkProtocol.path=function(_,x,y)return x~=blockedVictim.x or y~=blockedVictim.y end
 local found=R.crowd(p,z,style.actions.grab,0,1)
 check(#found==4 and scans==25,'crowd throw scans bounded nearby cells once and caps secondary victims')
 for i,v in ipairs(found)do
  check(v==candidates[i],'nearest unprotected standing targets are selected once despite repeated square objects')
  check(R.collide(p,v,style.actions.grab.throwCrowd)and v.knock and v.force==.65 and v.attacker==p and v.dy>0,'secondary target receives native outward knockdown')
  check(v.health==10 and v.hits==0,'crowd collision causes no additional native damage')
 end
 check(not dead.knock and not prone.knock and not protected.knock and not held.knock and not upper.knock and not behind.knock and not distant.knock and not blockedVictim.knock,'dead/downed/held/paired/upper-floor/behind/distant/walled targets remain unaffected')
 check(#R.crowd(p,z,{})==0 and #R.crowd(p,z,{throwCrowd=false})==0,'other styles opt into crowd throws explicitly')
 local cfg=style.actions.grab.throwCrowd
 for _,bad in ipairs({{radius=0/0,forward=.4,maxTargets=4,force=.6},{radius=1,forward=.4,maxTargets=9,force=.6},{radius=1,forward=2,maxTargets=4,force=.6},{radius=1,forward=.4,maxTargets=4,force=2}})do
  style.actions.grab.throwCrowd=bad;check(not PY.validateStyle(style),'invalid crowd throw configuration rejected')
 end
 style.actions.grab.throwCrowd=cfg;getCell=originalCell;PY.NetworkProtocol.path=originalPath;instanceof=originalInstance;z.floor=false
end
do
 wall=false;local oldKey,oldOptions=isKeyDown,PY.Bindings.options;local grabDown=false
 PY.Bindings.options={getOption=function(_,id)if id=='input_grab'then return {getValue=function()return 4 end}elseif id=='key_grab'then return {getValue=function()return 37 end}end end}
 isKeyDown=function(key)return key==37 and grabDown end
 local held=startGrab();D.input[p]={};mouse[2]=true;D.update(p);check(held.phaseName=='hold','heavy input no longer throws when no wall Heat Action is available')
 mouse[2]=false;D.update(p)
 local originalAim,originalReaction=p.isAiming,p.getHitReaction;p.isAiming=function()return false end;p.getHitReaction=function()return p.reaction or ''end;mouse[1]=false
 D.update(p);held:update();D.followZombie(z)
 check(held:isValid()and not held.cleaned and held.phaseName=='hold','releasing RMB cannot manually end a committed DoD grab')
 check(not D.safe(p)and not D.ready(p),'starting a new grab or guard still requires aiming')
 local keep=style.actions.grab.releaseOnAimLoss;style.actions.grab.releaseOnAimLoss=nil;check(not held:isValid(),'other style grabs retain their authored default aim-loss behavior');style.actions.grab.releaseOnAimLoss=keep
 p.x=p:getX()+.1;p.y=p:getY()+.1;clock=clock+50;held:update();check(not held.cleaned and not p.blocked,'walking held grab survives aim release')
 grabDown=true;D.update(p)
 check(held.phaseName=='throw'and not held.cleaned,'fresh remapped grab press throws instead of releasing')
 local started=held.phaseAt;clock=clock+20;D.update(p);check(held.phaseAt==started,'holding the grab button cannot restart the throw')
 p.reaction='HitReaction';held:update();check(held.cleaned and not z.locked and not z.useless,'external hit still interrupts the committed grab/throw safely');p.reaction='';p.isAiming=originalAim;p.getHitReaction=originalReaction;mouse[1]=true
 isKeyDown=oldKey;PY.Bindings.options=oldOptions;D.input[p]=nil;wall=true
 check(PY.Bindings.byId.throw==nil,'obsolete separate throw binding is removed')
end

do
 local R=PY.GrabRules;local rolls=0;local timer={};local cfg=style.actions.grab
 local function low(max)rolls=rolls+1;check(max==10000,'escape roll has bounded precision');return 0 end
 check(not R.escapeDue(timer,cfg,1000,low)and rolls==0,'first escape check waits a full second')
 check(not R.escapeDue(timer,cfg,1999,low)and rolls==0,'no per-frame escape rolls')
 check(R.escapeDue(timer,cfg,2000,low)and rolls==1,'all held zombies can escape after a successful small roll')
 check(not R.escapeDue(timer,cfg,2001,low)and rolls==1,'one roll per second maximum')
 check(R.escapeDue(timer,cfg,99999,low)and rolls==2,'long stalls do not perform a burst of catch-up rolls')
 timer={};R.escapeDue(timer,cfg,0,low)
 check(not R.escapeDue(timer,cfg,1000,function()return 500 end),'five-percent boundary is excluded')
 timer={};R.escapeDue(timer,cfg,0,low)
 check(R.escapeDue(timer,cfg,1000,function()return 499 end),'last valid five-percent roll is included')
 check(not R.escapeDue({}, {},1000,low),'other styles must explicitly configure break-outs')
 wall=false;local action=startGrab();local oldRandom=ZombRand;ZombRand=function()return 0 end
 clock=clock+1;action:update();local due=action.escapeNext
 clock=due-1;action:update();check(action.phaseName=='hold','held actor stays paired before escape deadline')
 clock=due;action:update();check(action.phaseName=='escape'and z.locked,'successful escape starts original paired separation without releasing victim early')
 check(not action:escape()and not action:throw(),'escape cannot restart or turn into a throw')
 local oldTrack=PY.AttackEffects.findTrack;PY.AttackEffects.findTrack=function()return cfg.breakout.duration,1,0 end
 action:update();check(action.cleaned and not z.locked and not z.useless and not p.blocked,'source separation completion restores both actors')
 PY.AttackEffects.findTrack=oldTrack;ZombRand=oldRandom;wall=true
end

do
 local originalTargets=PY.MultiHit.targets;local candidates={}
 for i=1,8 do candidates[i]={victim={isAttacking=function()return true end,isUseless=function()return false end,getHitReaction=function()return ''end,getCurrentStateName=function()return 'idle'end}} end
 candidates[9]={victim=z};z.state='idle';z.reaction='';z.useless=false;z.locked=false
 PY.MultiHit.targets=function(_,_,_,_,limit)local selected={};for i=1,math.min(limit,#candidates)do selected[i]=candidates[i]end;return selected end
 check(D.target(p)==z,'eight closer busy horde targets cannot hide the ninth eligible grab target')
 PY.MultiHit.targets=originalTargets
end
do
 local nativeCalls=0;local keyHook;local oldEquipped=ISEquippedItem;local oldGetPlayer=getPlayer;local oldEvent=Events.OnKeyPressed
 ISEquippedItem={onKeyPressed=function()nativeCalls=nativeCalls+1 end};getPlayer=function()return p end;Events.OnKeyPressed={Remove=function()end,Add=function(fn)keyHook=fn end};D.safetyWrapped=false;D.bindSafetyInput()
 local saved=SandboxVars;SandboxVars={ProjectYakuza={Grabs=false}};keyHook(PY.Bindings.key('grab'));check(nativeCalls==1,'disabled grabs restore the original native key handler');SandboxVars=saved
 ISEquippedItem=oldEquipped;getPlayer=oldGetPlayer;Events.OnKeyPressed=oldEvent
end
do
 D.clear();local targets=PY.MultiHit.targets;local bindings=PY.Bindings.down;local client=isClient;local network=PY.Network
 local requests,releases=0,0
 local function attempt()
  p.ignore=false;p.blocked=false;p.deferred=true;p.attacking=false;p.data.ProjectYakuzaEquipped=true;stamina=.9
  z.reaction='';z.useless=false;z.ignore=false;z.deferred=true;z.locked=false;z.state='idle';z.health=10;z.floor=false;z.x=p:getX();z.y=p:getY()+.7
  check(PY.requestAction(p,'grab'),'grab attempts do not require a preselected target')
  local action=PY.activeActions[p].timedAction;action:start();return action
 end
 PY.MultiHit.targets=function()return {}end
 PY.Bindings.down=function(id)return id=='grab'end;D.input[p]=nil
 check(D.update(p),'pressing Grab on empty space starts the reach animation')
 local miss=PY.activeActions[p].timedAction;miss:start();track=(style.actions.grab.attemptContactMs-10)/1000;clock=clock+190;miss:update()
 check(not miss.cleaned and not miss.context.target and not z.useless,'an empty early reach keeps playing without acquiring or freezing a zombie')
 track=style.actions.grab.attemptDurationMs/1000;clock=clock+300;miss:update();check(miss.cleaned and not PY.activeActions[p]and not p.blocked and not p.ignore and p.deferred,'a missed reach completes and restores movement')
 PY.MultiHit.targets=targets;PY.Bindings.down=bindings
 local hit=attempt();track=(style.actions.grab.attemptContactMs-10)/1000;clock=clock+190;hit:update();check(not hit.context.target and not z.useless,'nearby zombies remain free before the authored contact')
 track=style.actions.grab.attemptContactMs/1000;clock=clock+10;hit:update();check(hit.context.target==z and hit.victimState,'a hit attaches once at the reach contact');hit:cancel()
 local interrupted=attempt();interrupted:cancel();check(not z.useless and not z.ignore and not PY.activeActions[p],'interruption before contact never changes victim state')
 isClient=function()return true end
 PY.Network={pending={},leases={},grabStates={},requestGrab=function(player,target)requests=requests+1;PY.Network.pending[player]={z=target};return false end,releaseGrab=function(player)releases=releases+1;PY.Network.pending[player]=nil;PY.Network.leases[player]=nil end}
 local waiting=attempt();track=style.actions.grab.attemptContactMs/1000;clock=clock+200;waiting:update()
 check(requests==1 and waiting.awaitingGrab and not waiting.context.target and not z.useless,'MP requests authority at contact while the victim remains unpaired')
 clock=clock+100;waiting:update();check(requests==1,'waiting for authority does not send repeated grab requests')
 PY.Network.grabStates[p]={grabId=901,useless=false,ignore=false,deferred=true,locked=false};PY.Network.leases[p]=z:getOnlineID();PY.Network.pending[p]=nil
 check(waiting:acceptGrab(z)and waiting.grabId==901 and waiting.context.target==z,'a server grant continues the existing animation and saves its lease')
 waiting:cancel();check(releases==1 and not z.useless and not z.ignore,'cancellation restores the victim and releases server ownership')
 local denied=attempt();track=style.actions.grab.attemptContactMs/1000;clock=clock+200;denied:update();PY.Network.pending[p]=nil;track=style.actions.grab.attemptDurationMs/1000;clock=clock+300;denied:update()
 check(denied.cleaned and not denied.victimState and not z.useless,'a denied MP reach completes as a miss')
 check(not denied:acceptGrab(z),'a late grant cannot attach to an already completed attempt')
 PY.Network=network;isClient=client;track=0;D.input[p]=nil
 local slot=style.actions.grab;local duration=slot.attemptDurationMs;slot.attemptDurationMs=slot.attemptContactMs
 check(not PY.validateStyle(style),'grab attempt configuration rejects contact after the end of its animation');slot.attemptDurationMs=duration
end
do
 D.clear();local slot=style.actions.grab;local ox,oy=z.x,z.y
 z.x=p:getX()+.6;z.y=p:getY()+.9
 for _,direction in ipairs({{0,1},{1,0},{0,-1},{-1,0}})do
  local fx,fy=direction[1],direction[2];local state={entryAt=0,entryX=z.x,entryY=z.y}
  local x,y=R.entryPosition(p,z,slot,state,0,fx,fy);check(x==z.x and y==z.y,'grab entry begins at the actual victim position')
  local o=R.offset(slot,'enter');local tx,ty=p:getX()+fx*o.forward+fy*o.right,p:getY()+fy*o.forward-fx*o.right
  x,y=R.entryPosition(p,z,slot,state,90,fx,fy);check(math.abs(x-(z.x+tx)/2)<.000001 and math.abs(y-(z.y+ty)/2)<.000001,'entry blends both forward and lateral placement without a hold-phase snap')
  for _,step in ipairs({10,30,45})do
   for t=0,180,step do x,y=R.entryPosition(p,z,slot,state,t,fx,fy)end
   check(math.abs(x-tx)<.000001 and math.abs(y-ty)<.000001,'entry settles identically at different update cadences')
  end
 end
 z.x,z.y=ox,oy
 local held=startGrab();held:cancel()
 local function reaching()
  p.blocked=false;p.ignore=false;p.deferred=true;z.reaction='';z.useless=false;z.ignore=false;z.locked=false;z.state='idle';z.floor=false;z.health=10;z.x=p:getX();z.y=p:getY()+.7;stamina=.9
  check(PY.requestAction(p,'grab'),'polished grab attempt starts');local a=PY.activeActions[p].timedAction;a:start();track=style.actions.grab.attemptContactMs/1000;clock=clock+200;a:update();return a
 end
 local a=reaching();paused=true;clock=clock+5000;a:update();paused=false
 p.vars.ProjectYakuzaDefenseMarker='enter_ready';z.vars.ProjectYakuzaGrabMarker='enter_ready';clock=clock+180;a:update()
 check(not a.cleaned and a.phaseName=='hold','pausing during entry preserves its alignment and timeout clocks');a:cancel()
 local path=PY.MultiHit.clearPath;z.x=p:getX();z.y=p:getY()+.7
 check(D.reachable(p,z),'visible nearby victim remains reachable at confirmation')
 p.visible=false;check(not D.reachable(p,z),'a grant cannot grab through newly blocked visibility');p.visible=true
 PY.MultiHit.clearPath=function()return false end;check(not D.reachable(p,z),'a grant rechecks walls between the player and victim');PY.MultiHit.clearPath=path
 z.y=p:getY()-.7;check(not D.reachable(p,z),'a delayed grant cannot catch a zombie behind the player')
 a=reaching();PY.MultiHit.clearPath=function()return false end;clock=clock+50;a:update();PY.MultiHit.clearPath=path
 check(a.cleaned and not z.useless and not z.ignore and not p.blocked,'a newly obstructed entry releases both actors safely')
 local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end
 a=reaching();track=nil;clock=clock+style.actions.grab.attemptDurationMs;a:update()
 check(a.cleaned and not p.blocked and not p.ignore,'a disappearing animation track cannot leave a missed grab blocked for an extra second')
 PY.MultiHit.targets=targets;track=0
end
do
 mouse[1]=true;p.aiming=false;local held=startGrab();mouse[1]=false;p:setIsAiming(false)
 check(Events.OnTick.hooks[D.holdStance],'a held victim owns the combat stance tick hook')
 D.holdStance();check(p:isAiming()and held:isValid(),'holding preserves combat aim after native RMB input clears it')
 held:cancel();check(not p:isAiming()and not Events.OnTick.hooks[D.holdStance],'release restores native aim input and removes the stance hook')
 mouse[1]=true;held=startGrab();held:cancel();check(p:isAiming(),'release preserves a currently held native aim button')
 local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end
 p.blocked=false;p.ignore=false;p.deferred=true;stamina=.9
 check(PY.requestAction(p,'grab'),'source recovery regression starts a missed reach')
 local miss=PY.activeActions[p].timedAction;miss:start();check(miss.phaseName=='attempt','miss begins in the dedicated source attempt phase')
 track=(style.actions.grab.attemptContactEndMs+20)/1000;clock=clock+500;miss:update()
 PY.MultiHit.targets=targets;track=1.2;clock=clock+700;miss:update()
 check(not miss.cleaned and not miss.context.target,'a target entering after the source contact window cannot attach during recovery')
 track=1.6;clock=clock+400;miss:update();check(miss.cleaned,'the original missed-grab recovery completes at its original 1.6-second duration');track=0
end
do
 local signals={};local function signal(kind,actor,target,context)signals[context]=signals[context]or {};signals[context][kind]=(signals[context][kind]or 0)+1 end
 PY.on('grabConnected',function(...)signal('connected',...)end);PY.on('grabMissed',function(...)signal('missed',...)end);PY.on('grabEnded',function(...)signal('ended',...)end)
 mouse[1]=true;local held=startGrab();check(signals[held].connected==1 and not signals[held].missed,'successful source contact confirms the grab exactly once')
 held:cancel();held:cancel();check(signals[held].ended==1,'duplicate cancellation cannot repeat grab cleanup feedback')
 local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end
 p.blocked=false;p.ignore=false;p.deferred=true;stamina=.9
 check(PY.requestAction(p,'grab'),'miss feedback regression starts')
 local attempt=PY.activeActions[p].timedAction;attempt:start();track=style.actions.grab.attemptContactMs/1000;clock=clock+350;attempt:update();attempt:update()
 check(signals[attempt].missed==1 and not signals[attempt].connected,'a missed source reach reports once without pretending to connect')
 track=1.6;clock=clock+1300;attempt:update();check(signals[attempt].ended==1,'failed recovery ends its own feedback session')
 p.blocked=false;p.ignore=false;p.deferred=true;check(PY.requestAction(p,'grab'),'interrupted reach regression starts');attempt=PY.activeActions[p].timedAction;attempt:start();attempt:cancel()
 check(signals[attempt].ended==1 and not signals[attempt].missed,'interruption before contact is not mislabeled a miss')
 PY.MultiHit.targets=targets;track=0
end
do
 D.clear();local targets=PY.MultiHit.targets;local canMove=PY.Quicksteps.canMove;local oldX,oldY=p.x,p.y
 PY.MultiHit.targets=function()return {}end;PY.Quicksteps.canMove=function()return true end
 local function reach()
  p.blocked=false;p.ignore=false;p.deferred=true;p.attacking=false;stamina=.9;mouse[1]=true;track=0
  check(PY.requestAction(p,'grab'),'miss movement regression starts');local a=PY.activeActions[p].timedAction;a:start();return a
 end
 for _,direction in ipairs({{1,0},{0,1},{-1,0},{0,-1}})do
  local a=reach();a.context.fx,a.context.fy=direction[1],direction[2];local x,y=p:getX(),p:getY()
  for frame=1,95 do track=frame/60;clock=clock+1000/60;a:update();if frame==4 then check((a.reachMoved or 0)>0 and a.reachMoved<=.06 and not a.missEmitted,'first source footstep starts bounded movement before contact resolves')end end
  check(math.abs(p:getX()-x-style.actions.grab.attemptDistance*direction[1])<.003 and math.abs(p:getY()-y-style.actions.grab.attemptDistance*direction[2])<.003,'failed reach travels the tuned distance along its initial facing')
  track=1.6;clock=clock+1000/60;a:update();check(math.abs((a.reachMoved or 0)-style.actions.grab.attemptDistance)<.00001,'animation recovery adds no movement after the shorter slide finishes');a:cancel()
 end
 local blocked=reach();local x,y=p:getX(),p:getY();PY.Quicksteps.canMove=function()return false end;track=.08;clock=clock+80;blocked:update()
 PY.Quicksteps.canMove=function()return true end;track=.12;clock=clock+40;blocked:update();check(p:getX()==x and p:getY()==y and blocked.reachBlocked,'obstruction cancels further miss motion without a delayed catch-up');blocked:cancel()
 local late=reach();track=1.2;clock=clock+1200;late:update();check(not late.reachMoved,'late ownership rejection cannot teleport the player after the movement window');late:cancel()
 local pause=reach();track=.016;clock=clock+16;pause:update();x,y=p:getX(),p:getY();paused=true;track=.1;clock=clock+84;pause:update();paused=false;check(p:getX()==x and p:getY()==y,'paused reach does not advance movement');pause:cancel()
 PY.MultiHit.targets=targets;PY.Quicksteps.canMove=canMove;p.x,p.y=oldX,oldY;track=0
 mouse[1]=true;p.forceAim=false;p.allowRun=true;p.allowSprint=true
 local held=startGrab();mouse[1]=false;p.aiming=false;D.holdStance()
 check(p.forceAim and p.aiming and not p.allowRun and not p.allowSprint,'held grab forces native aim and disables run/sprint after RMB release')
 held:cancel();check(not p.forceAim and not p.aiming and p.allowRun and p.allowSprint,'grab cleanup restores native aim and original movement permissions')
 mouse[1]=true;p.forceAim=true;p.allowRun=false;p.allowSprint=false;held=startGrab();held:cancel()
 check(p.forceAim and not p.allowRun and not p.allowSprint,'cleanup preserves restrictions and forced aim owned by another feature');p.forceAim=false;p.allowRun=true;p.allowSprint=true
end
do
 local rules=PY.HeatRushRules;local move=style.actions.grabHeat.variants.open;local clear,space,path=rules.clearance,rules.space,PY.NetworkProtocol.path
 rules.clearance=function()return true end;rules.space=function()return true end;PY.NetworkProtocol.path=function()return true end
 local x,y,zx,zy=p.x,p.y,z.x,z.y
 for i=0,7 do local angle=i*math.pi/4;local dx,dy=math.cos(angle)*.41,math.sin(angle)*.41;p.x,p.y=5,7;z.x,z.y=5+dx,7+dy
  local pose=rules.placement(p,z,move);local ax,ay=rules.point(pose,pose.motion.actor,0);local bx,by=rules.point(pose,pose.motion.victim,0)
  check(math.abs(ax-p.x)<.000001 and math.abs(ay-p.y)<.000001,'open grab scene keeps actor position at handoff in every heading')
  check((bx-ax)*dx+(by-ay)*dy>0 and math.abs((bx-ax)*dy-(by-ay)*dx)<.000001,'open grab victim stays on the held side instead of flipping 180 degrees')
 end
 p.x,p.y,z.x,z.y=x,y,zx,zy;rules.clearance,rules.space,PY.NetworkProtocol.path=clear,space,path
 local state={};local first=R.alignment(style.actions.grab,'hold',state,100);local next=R.alignment(style.actions.grab,'strike3',state,120)
 check(first.forward==next.forward and first.right==next.right,'restored strike placement begins at the held position before its blend')
 state.grabMoving=true;R.alignment(style.actions.grab,'hold',state,300);local walk=R.alignment(style.actions.grab,'hold',state,540)
 check(math.abs(walk.forward-.42)<.00002 and math.abs(walk.right-.019354)<.00002,'holding and walking keep the victim in front instead of far to the side')
end
do
 local hit=z.Hit;local oldGet,oldSet=z.isIgnoreStaggerBack,z.setIgnoreStaggerBack;local ignore=false
 z.isIgnoreStaggerBack=function()return ignore end;z.setIgnoreStaggerBack=function(_,v)ignore=v end
 z.Hit=function()check(ignore,'native paired hit suppresses the default stagger during damage');error('injected paired hit failure')end
 local ok=PY.HitResponses.nativeHit(p,z,token,.2,{noKnockback=true});check(not ok and not ignore,'failed native damage restores original stagger policy')
 z.Hit,z.isIgnoreStaggerBack,z.setIgnoreStaggerBack=hit,oldGet,oldSet
end
do
 for index,move in ipairs(style.actions.grab.strikes)do
  for frame,sample in ipairs(move.pairMotion.frames)do
   local time=(frame-1)/30;local offset=R.offset(style.actions.grab,'strike'..index,false,time)
   check(math.abs(offset.forward-sample[1])<.000001 and math.abs(offset.right-sample[2])<.000001,'strike placement samples the complete authored hand/collar curve')
   for heading=0,7 do
    local angle=heading*math.pi/4;local fx,fy=math.cos(angle),math.sin(angle)
    local x,y=fx*offset.forward+fy*offset.right,fy*offset.forward-fx*offset.right
    check(math.abs(x*fx+y*fy-sample[1])<.000001 and math.abs(x*fy-y*fx-sample[2])<.000001,'dynamic victim placement keeps the source contact in every heading')
   end
   if time>=.12 then
    local client={pairPhase='strike'..index,pairMoving=false,pairAt=0,pairFrom=R.offset(style.actions.grab,'hold'),strikeTime=time}
    local server={pairPhase='strike'..index,pairMoving=false,pairAt=0,pairFrom=client.pairFrom,strike={at=0}}
    local a=R.alignment(style.actions.grab,'strike'..index,client,time*1000);local b=R.alignment(style.actions.grab,'strike'..index,server,time*1000)
    check(math.abs(a.forward-b.forward)<.000001 and math.abs(a.right-b.right)<.000001,'client animation time and authoritative strike time select the same position')
   end
  end
 end
 local motion=style.actions.grab.attemptMotion;local original=motion.frames[2];motion.frames[2]=-1
 check(not PY.validateStyle(style),'invalid backwards reach curves are rejected');motion.frames[2]=original
 check(PY.validateStyle(style),'restored paired source curves and source-length reach are valid')
end
do
 G.clear();local held=startGrab();local previousMarker
 for index=1,4 do
  check(G.input(p,held,true,false),'completion regression starts each source strike')
  local move=held.strikeMove;local phase=held.phaseName
  if previousMarker then
   p:setVariable('ProjectYakuzaDefenseMarker',previousMarker);track=.1;clock=clock+100;held:update()
   check(held.phaseName==phase,'a fading previous strike cannot finish the current strike')
  end
  track=move.contactMs/1000+.01;clock=clock+600;held:update();local hits=z.hits
  p:setVariable('ProjectYakuzaDefenseMarker',phase..'_done');track=0;clock=clock+500;held:update()
  check(held.phaseName=='hold'and not held.strikeMove,'matching end marker wins over a restarted or fading animation track')
  held:update();check(z.hits==hits,'completion cannot replay its source damage')
  clock=clock+style.actions.grab.recoveryMs;held:update();previousMarker=phase..'_done'
 end
 held:cancel();held=startGrab();G.input(p,held,true,false);local move=held.strikeMove
 track=move.duration-.05;clock=clock+1000;held:update();local hits=z.hits
 track=.01;clock=clock+40;held:update()
 check(held.phaseName=='hold'and z.hits==hits,'near-end animation rollback returns to hold instead of playing the strike twice')
 held:cancel()
 local getAim,getAnimated,setActor,setVictim=p.getForwardDirection,p.getAnimForwardDirection,p.setTargetAndCurrentDirection,z.setTargetAndCurrentDirection
 local ax,ay,zx,zy,aimX,aimY
 p.getForwardDirection=function()return {getX=function()return aimX end,getY=function()return aimY end}end
 p.getAnimForwardDirection=function()return {getX=function()return -aimY end,getY=function()return aimX end}end
 p.setTargetAndCurrentDirection=function(_,x,y)ax,ay=x,y end;z.setTargetAndCurrentDirection=function(_,x,y)zx,zy=x,y end
 aimX,aimY=0,1;held=startGrab()
 for i=0,7 do
  aimX,aimY=math.cos(i*math.pi/4),math.sin(i*math.pi/4);held:alignPair(true)
  check(math.abs(ax-aimX)<.000001 and math.abs(ay-aimY)<.000001 and math.abs(zx+aimX)<.000001 and math.abs(zy+aimY)<.000001,'holding follows normal aim rather than a rotated animation facing')
  check(math.abs(held.context.fx-aimX)<.000001 and math.abs(held.context.fy-aimY)<.000001,'the held pair captures the same aim axis')
 end
 G.input(p,held,true,false);local lockedX,lockedY=held.context.fx,held.context.fy;aimX,aimY=-lockedY,lockedX;held:alignPair(true);held:holdControls()
 check(math.abs(ax-lockedX)<.000001 and math.abs(ay-lockedY)<.000001 and math.abs(zx+lockedX)<.000001 and math.abs(zy+lockedY)<.000001,'a strike keeps one captured axis for both characters')
 held:cancel();p.getForwardDirection,p.getAnimForwardDirection,p.setTargetAndCurrentDirection,z.setTargetAndCurrentDirection=getAim,getAnimated,setActor,setVictim;track=0
end
do
 G.clear();local held=startGrab();G.input(p,held,true,false);local move=held.strikeMove;track=move.duration;clock=clock+1400;held:update()
 check(held.recoveryUntil and p.blocked and p.ignore and not p.deferred,'return blend keeps native movement locked')
 local serial=held.grabStrikeCount;G.input(p,held,true,false);G.input(p,held,true,false)
 check(held.grabStrikeCount==serial and held.recoveryInput.light,'fresh input during recovery queues one strike instead of interrupting the fade')
 paused=true;local deadline=held.recoveryUntil;clock=clock+700;held:update();paused=false
 check(held.recoveryUntil==deadline+700,'pause preserves the remaining blend time')
 track=0;clock=clock+style.actions.grab.recoveryMs;held:update()
 check(held.strikeMove and held.grabStrikeCount==serial+1 and not held.recoveryInput,'one queued press starts after recovery completes')
 held:cancel()
 for index,move in ipairs(style.actions.grab.strikes)do
  local last=R.offset(style.actions.grab,'strike'..index,false,move.returnAtMs/1000)
  local state={pairPhase='strike'..index,pairMoving=false,pairOffset=last,pairFrom=last,pairAt=0}
  local first=R.alignment(style.actions.grab,'hold',state,1000)
  check(math.abs(first.forward-last.forward)<.000001 and math.abs(first.right-last.right)<.000001,'return starts at the actual last paired position')
  for frame=1,24 do
   local actual=R.alignment(style.actions.grab,'hold',state,1000+frame*10);local sample=R.sample(move.returnMotion,frame/100)
   check(math.abs(actual.forward-sample.forward)<.00002 and math.abs(actual.right-sample.right)<.00002,'return follows native quaternion-blended palm/collar placement')
  end
  local final=R.alignment(style.actions.grab,'hold',state,1360)
  check(math.abs(final.forward-.42)<.00002 and math.abs(final.right-.019354)<.00002,'completed return settles into the fitted collar grip')
 end
end
do
 G.clear();local held=startGrab();G.input(p,held,true,false);local move=held.strikeMove
 track=move.contactMs/1000+.01;clock=clock+600;held:update();local hits=z.hits
 p:setVariable('ProjectYakuzaDefensePhase','hold');p:setVariable('ProjectYakuzaDefenseMarker','hold_started');track=0;clock=clock+17;held:update()
 check(held.phaseName=='hold'and not held.strikeMove and held.recoveryUntil,'native strike-to-hold handoff survives the hold start marker replacing the strike end marker')
 check(z.hits==hits,'native return cannot replay a strike contact')
 held:cancel();track=0
 local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end;p.blocked=false;p.ignore=false;p.deferred=true;mouse[1]=true;stamina=.9
 check(PY.requestAction(p,'grab'),'smooth reach regression starts');local a=PY.activeActions[p].timedAction;a:start()
 track=.1;clock=clock+100;a:update();local first=a.reachMoved or 0
 clock=clock+8;a:update();local second=a.reachMoved or 0
 clock=clock+8;a:update();local third=a.reachMoved or 0
 check(second>first and third>second,'grab reach continues smoothly between repeated native animation timestamps')
 clock=clock+64;a:update();check((a.reachMoved or 0)>third,'source-clock reach does not stop after one predicted frame when a native timestamp repeats')
 a:cancel();PY.MultiHit.targets=targets;track=0
end
do
 G.clear();local held=startGrab();local hit=z.Hit;local state=z.state;local reaction=z.reaction
 z.Hit=function()error('ordinary hit reaction must not interrupt a paired grab strike')end
 G.input(p,held,true,false);local move=held.strikeMove;local health=z.health
 track=move.contactMs/1000+.001;clock=clock+250;held:update();held:update()
 check(math.abs(z.health-(health-R.damage(p,move)))<.000001 and z.state==state and z.reaction==reaction,'paired strike damages once while preserving the victim animation state')
 track=move.returnAtMs/1000;clock=clock+500;held:update();check(held.phaseName=='hold'and held.recoveryUntil,'return blend starts while the source hit track is still playing')
 z.Hit=hit;held:cancel();track=0
 local terminal=z.hitConsequences;local deaths=0;z.hitConsequences=function(...)deaths=deaths+1;return terminal(...)end;z.health=.1
 check(R.strike(p,z,token,.5)and z.health==0 and deaths==1,'lethal paired strike finalizes one death without a native flinch')
 check(not R.strike(p,z,token,.5)and deaths==1,'dead victim cannot receive another paired strike')
 z.hitConsequences=terminal;z.health=10
end
do
 G.clear();local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end
 p.blocked=false;p.ignore=false;p.deferred=true;mouse[1]=true;stamina=.9;track=0
 check(PY.requestAction(p,'grab'),'queued native movement regression starts');local a=PY.activeActions[p].timedAction;a:start()
 local original=p.moveUnmodded;local calls,lastRequest=0,0
 p.moveUnmodded=function(self,dx,dy)calls=calls+1;lastRequest=math.sqrt(dx*dx+dy*dy)end
 for i=0,3 do
  local before=a.reachMoved or 0;local count=calls;track=i/10;clock=clock+100;a:update();local moved=(a.reachMoved or 0)-before
  check(calls-count<2,'one timed-action update submits at most one native movement request')
  if moved>0 then check(math.abs(lastRequest-moved)<.000001,'native requested movement contains the whole frame displacement instead of only its last collision substep')end
 end
 p.moveUnmodded=original;a:cancel();PY.MultiHit.targets=targets;track=0
end
do
 G.clear();local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end
 p.blocked=false;p.ignore=false;p.deferred=true;mouse[1]=true;stamina=.9;track=0
 check(PY.requestAction(p,'grab'),'shorter slide regression starts');local a=PY.activeActions[p].timedAction;a:start();a:update()
 local previous=0
 for frame=1,50 do
  track=frame/60;clock=clock+1000/60;a:update();local moved=a.reachMoved or 0
  check(math.abs(moved-.7*frame/50)<.00001 and moved>previous,'slide maintains steady speed until the second foot plants at source frame 25')
  previous=moved
 end
 check(not a.cleaned and math.abs((a.reachMoved or 0)-.7)<.00001,'push finishes before the original grab recovery animation')
 for frame=51,96 do track=frame/60;clock=clock+1000/60;a:update();check(math.abs((a.reachMoved or 0)-.7)<.00001,'recovery never adds a trailing push')end
 check(a.cleaned,'original 1.6-second animation still completes normally');a:cancel();PY.MultiHit.targets=targets;track=0
 local slot=style.actions.grab;local duration,distance=slot.attemptMoveDurationMs,slot.attemptDistance
 for _,value in ipairs({0,-1,slot.attemptDurationMs+1,math.huge})do slot.attemptMoveDurationMs=value;check(not PY.validateStyle(style),'movement duration must be positive and fit inside the animation')end
 slot.attemptMoveDurationMs=duration
 for _,value in ipairs({0,-1,2.01,math.huge})do slot.attemptDistance=value;check(not PY.validateStyle(style),'movement distance stays within finite positive limits')end
 slot.attemptDistance=distance;check(PY.validateStyle(style),'restored shorter movement configuration validates')
end
do
 G.clear();local targets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {}end
 p.blocked=false;p.ignore=false;p.deferred=true;mouse[1]=true;stamina=.9;track=0
 check(PY.requestAction(p,'grab'),'native footstep cutoff regression starts');local a=PY.activeActions[p].timedAction;a:start();a:update()
 for frame=1,25 do track=frame/30;clock=clock+20;a:update()end
 local moved=a.reachMoved or 0;check(a.reachEnded and moved>0 and moved<.7,'actual second-foot source phase ends the push even if wall time has not reached its duration')
 clock=clock+100;track=26/30;a:update();check(math.abs((a.reachMoved or 0)-moved)<.000001,'no push is added after the animated second foot has planted')
 a:cancel();PY.MultiHit.targets=targets;track=0
end
return 'PASS '..checks..' reliable grab lifecycle, four source-timed strikes, following, cleanup, wall geometry, handoff and action protection checks'
