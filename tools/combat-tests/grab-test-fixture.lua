Events.OnZombieUpdate=event();Events.OnGameStart=event();Events.OnServerCommand=event()
CharacterStat={ENDURANCE=1}
mouse[1]=true
local paused=false;isGamePaused=function()return paused end
local stamina=.9;function p:getStats()return {get=function()return stamina end,remove=function(_,_,v)stamina=stamina-v end}end
function p:getX()return self.x or .5 end;function p:getY()return self.y or .2 end
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
local z={x=.5,y=.9,health=10,vars={},hits=0,deferred=true,target=p,state='idle'}
function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return 0 end
function z:setX(v)self.x=v end;function z:setY(v)self.y=v end
function z:setNextX(v)self.nx=v end;function z:setNextY(v)self.ny=v end
function z:setLastX(v)self.lx=v end;function z:setLastY(v)self.ly=v end
function z:setCurrentSquareFromPosition()end;function z:setMovingSquareNow()end
function z:getStateMachine()local z=self;return {isLocked=function()return z.locked==true end}end
function z:setStateMachineLocked(v)self.locked=v end;function z:getCurrentStateName()return self.state end
function z:isDead()return self.health<=0 end;function z:isOnFloor()return self.floor==true end;function z:isKnockedDown()return false end
function z:isUseless()return self.useless==true end;function z:setUseless(v)self.useless=v end
function z:getIgnoreMovement()return self.ignore==true end;function z:setIgnoreMovement(v)self.ignore=v end
function z:isDeferredMovementEnabled()return self.deferred end;function z:setDeferredMovementEnabled(v)self.deferred=v end
function z:getTarget()return self.target end;function z:setTarget(v)self.target=v end
function z:getHitReaction()return self.reaction or ''end;function z:setHitReaction(v)self.reaction=v end
function z:setVariable(k,v)self.vars[k]=v end;function z:GetVariable(k)local v=self.vars[k];return type(v)=='boolean'and tostring(v)or v or''end
function z:reportEvent(v)self.report=v;if not self.locked then self.state=v=="wasHit"and "ZombieHitReactionState"or "idle"end end;function z:setAttackOutcome(v)self.outcome=v end
function z:isAttacking()return false end;function z:setTargetAndCurrentDirection()end;function z:setForwardDirection()end
function z:moveUnmodded(x,y)self.x=self.x+x;self.y=self.y+y end
function z:setFallOnFront(v)self.front=v end
function z:setKnockedDown(v)self.knock=v end;function z:setOnFloor(v)self.floor=v end;function z:setStaggerBack(v)self.stagger=v end
function z:setHitForce(v)self.force=v end;function z:getOnlineID()return 9 end
function z:Hit(_,_,damage)self.hits=self.hits+1;self.health=self.health-damage;self.floor=true;self.knock=true;self.stagger=true end
instanceof=function(o,name)return o==z and name=='IsoZombie'or o==p and name=='IsoPlayer'end
PY.TigerDrop={tracked={}}
PY.MultiHit={origin=function()return {}end,targets=function()return {{victim=z}}end,clearPath=function()return true end}
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
 if not squares[key]then squares[key]={isWallTo=function(_,other)return wall and other and y==1 and other.y==0 end,isWindowTo=function()return window end,isDoorTo=function()return door end,y=y}end
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
 p.vars.ProjectYakuzaDefenseMarker='enter_ready';z.vars.ProjectYakuzaGrabMarker='enter_ready';clock=clock+500;a:update()
 check(a.phaseName=='hold'and a.paired,'paired source markers reach hold')
 return a
end
local a=startGrab()
check(z.locked and z.useless and z.ignore and not z.deferred,'native reaction is latched while held')
check(not p.blocked and not p.ignore and p.deferred,'walking remains available with native movement during hold')
clock=clock+12000;a:update();check(not a.cleaned and a.phaseName=='hold','hold survives the obsolete 3.5-second timeout')
p.x=.6;p.y=.3;clock=clock+50;a:update();check(math.abs(z.x-.6)<.001 and math.abs(z.y-1)<.001,'held victim follows actor translation')
p.x=.5;p.y=.2;z.y=.9
for i=1,4 do
 check(G.input(p,a,true,false),'LMB starts grab strike '..i)
 local m=a.strikeMove;check(a.phaseName=='strike'..i and p.blocked and p.ignore and not p.deferred,'strike locks movement and selects correct paired phase')
 local before=z.hits;track=math.max(0,m.contactMs/1000-.02);clock=clock+10;a:update();check(z.hits==before,'strike cannot hit before source contact')
 track=m.contactMs/1000+.001;clock=clock+20;a:update();a:update();check(z.hits==before+1,'one source contact causes exactly one hit')
 check(z.locked and not z.floor and not z.knock and not z.stagger and z:getHitReaction()=='ProjectYakuzaGrabbed'and z.force==0,'strike does not eject or knock back held victim')
 track=m.duration;clock=clock+30;a:update();check(a.phaseName=='hold'and not p.blocked and p.deferred,'full source strike returns to walking hold')
end
PY.cancelAction(p,'released');check(not z.locked and not z.useless and not z.ignore and z.deferred and not p.blocked and p.deferred,'release restores every owned native flag')
local saved=R.capture(z);z.locked=true;R.keep(z);R.restore(z,saved);check(z.locked,'cleanup preserves a pre-existing state-machine lock');z.locked=false
local pose=R.wall(p,z,style.actions.grabHeat);check(pose and pose.fx==0 and pose.fy==1,'wall action faces its solid wall along the original forward motion')
do
 local originalCell=getCell;local oldX,oldY,oldZX,oldZY=p.x,p.y,z.x,z.y
 for _,v in ipairs({{0,1,.5,.2,.5,.9},{0,-1,.5,1.8,.5,1.1},{1,0,.2,.5,.9,.5},{-1,0,1.8,.5,1.1,.5}})do
  local nx,ny=v[1],v[2];p.x,p.y,z.x,z.y=v[3],v[4],v[5],v[6]
  getCell=function()return {getGridSquare=function(_,x,y)return {x=x,y=y,isWallTo=function(a,b)return nx==0 and a.y==1 and b.y==0 or ny==0 and a.x==1 and b.x==0 end,isWindowTo=function()return false end,isDoorTo=function()return false end}end}end
  local aligned=R.wall(p,z,style.actions.grabHeat)
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
window=true;check(not R.wall(p,z,style.actions.grabHeat),'windows never count as solid heat-action walls');window=false
door=true;check(not R.wall(p,z,style.actions.grabHeat),'doors never count as solid heat-action walls');door=false
blocked=true;check(not R.wall(p,z,style.actions.grabHeat),'blocked source pair paths reject the heat action');blocked=false
wall=false;check(not R.wall(p,z,style.actions.grabHeat),'no wall means no heat action');wall=true
p.data.ProjectYakuzaHeat=100;a=startGrab();local target,move=G.candidate(p,true);check(target==z and move==style.actions.grabHeat,'eligible held target exposes the heat-action prompt')
check(G.input(p,a,false,true),'heat-action input takes priority near a wall')
check(G.updatePending(p),'wall action consumes the held-target ticket')
local c=PY.activeActions[p];check(c and c.kind=='grabHeat'and c.target.fromGrab,'grab transfers into the paired heat-action framework')
check(a.cleaned and not z.locked,'handoff releases the old grab lock before the new victim lock')
local action=c.timedAction;action:start();check(p.invincible and p.ghost and p.blocked,'wall action uses full-duration protection and movement lock')
action:cleanup(false);check(not p.invincible and p.ghost,'ending restores invulnerability immediately while target grace remains')
clock=clock+600;PY.HeatActions.tick();check(not p.ghost and not z.locked,'target grace and victim lock clean up')
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
 local pose=PY.HeatRushRules.placement(p,z,move);check(pose~=nil,'ground pair has a bounded safe placement')
 local ticket={z=z,pose=pose,ground=true,pressed=true,expires=clock+600}
 check(PY.requestAction(p,'groundHeat',nil,ticket),'ground heat is registered in the shared paired framework')
 local action=PY.activeActions[p].timedAction;action:start();check(p.invincible and not z.floor and not z.knock,'ground action protects actor and suspends native downed overrides')
 local before=z.hits;track=1;clock=clock+1000;action:update();check(z.hits==before,'ground damage is deferred to preserve the original victim clip')
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
return 'PASS '..checks..' reliable grab lifecycle, four source-timed strikes, following, cleanup, wall geometry, handoff and action protection checks'
