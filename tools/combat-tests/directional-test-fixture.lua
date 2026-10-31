token.min=.3;token.max=.5;token.data={}
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
local D=PY.DirectionalAttacks;local style=PY.getStyle('dragon_of_dojima');local H=PY.Heat
for degrees=-180,180 do
 local a=degrees*math.pi/180;local direction=D.direction(1,0,math.cos(a),math.sin(a))
 local expected
 if math.abs(degrees)>=145 then expected='rear'elseif math.abs(degrees)>=65 then expected=degrees>=0 and'right'or'left'end
 if math.abs(degrees)~=65 and math.abs(degrees)~=145 then check(direction==expected,'manual turn sector '..degrees)end
end
check(not D.direction(0,0,1,0)and not D.direction(1,0,0/0,1),'invalid facing cannot select a directional strike')
local fx,fy=1,0
function p:isBlockMovement()return self.blocked==true end
function p:getForwardDirection()return {getX=function()return fx end,getY=function()return fy end}end
local function state()return PY.stateFor(p)end
local function finish()p.attacking=false;fire('OnPlayerAttackFinished',p,token);clock=clock+30 end
local function reset()p.attacking=false;p.held=nil;mouse[0]=false;H.stop(p,'test');PY.resetPlayer(p,'test');PY.Bindings.update(p);fx,fy=1,0;clock=clock+100 end
for _,entry in ipairs({{'left',0,-1},{'right',0,1},{'rear',-1,0}})do
 reset();p:AttemptAttack();check(state().activeLightMove==style.lightAttacks[1],'chain starts with ordinary light');finish()
 fx,fy=entry[2],entry[3];PY.Combo.press(state(),4,1);p:AttemptAttack()
 local selected=style.directionalAttacks.moves[entry[1]]
 check(state().activeLightMove==selected and state().directionalLight,'manual turn selects native '..entry[1]..' move')
 check(p.vars.ProjectYakuzaMove==selected.nodeValue and not state().finisherMove,'directional owner uses native light hit path')
 check(math.abs(token.max-.375)<.000001,'directional light retains x0.75 damage')
 check(not PY.queueFinisher(p),'directional ender cannot chain a mismatched finisher')
 p.blocked=true;local oldPath=PY.Quicksteps.canMove;PY.Quicksteps.canMove=function()return true end
 check(PY.Quicksteps.cancelReady(p,{style=style.id,direction='forward',dx=1,dy=0,stamp=state().multiHitToken}),'owned directional movement lock permits a quota-checked quickstep cancel')
 PY.Quicksteps.canMove=oldPath
 local f=p:getForwardDirection();check(f:getX()==fx and f:getY()==fy,'directional logic never turns player automatically')
 finish();check(state().step==0 and not state().directionalLight,'directional completion ends chain')
 p:AttemptAttack();check(state().activeLightMove==style.lightAttacks[1],'next press starts fresh normal chain');finish()
end
reset();p:AttemptAttack();finish();fx,fy=math.cos(.4),math.sin(.4);PY.Combo.press(state(),4,1);p:AttemptAttack()
check(state().step==2 and state().activeLightMove==style.lightAttacks[2],'small aiming changes preserve ordinary combo');finish()
reset();p:AttemptAttack();finish();clock=clock+style.comboResetMs+1;fx,fy=-1,0;PY.Combo.press(state(),4,1);p:AttemptAttack()
check(not state().directionalLight and state().step==1,'expired combo cannot trigger rear strike');finish()
reset();PY.setHeat(p,100);H.start(p);p:AttemptAttack();finish();fx,fy=0,1;PY.Combo.press(state(),4,1);p:AttemptAttack()
check(state().activeLightMove==style.directionalAttacks.moves.right,'Extreme mode permits an explicitly redirected light')
check(math.abs(token.max-.5625)<.000001,'existing Extreme bonus applies once to directional light');p.blocked=true;PY.resetPlayer(p,'interrupted')
check(not p.blocked and not state().directionalLight,'interruption restores directional movement lock')
for _,profile in ipairs({'bat','knife','blade'})do check(not PY.Weapons.views[style.id][profile].directionalAttacks,'weapon profile excludes unarmed directional motion '..profile)end
reset();local bat=weapon('Base.BaseballBat');p.held=bat;PY.Weapons.sync(p);state().lightFacing={x=1,y=0};state().step=1;state().finishedAt=clock;fx,fy=0,1
check(not D.select(p,state(),PY.getPlayerStyle(p)),'armed input stays with weapon profile')
local other={id='tests.no_directional',name='No automatic opt-in',lightAttacks=style.lightAttacks,actions={}}
PY.registerStyle(other);check(not D.select(p,state(),other),'other styles do not inherit directional moves')
local invalid={id='tests.bad_directional',name='Invalid',lightAttacks=style.lightAttacks,actions={},directionalAttacks={minimumDegrees=160,rearDegrees=80,moves={}}}
check(not PY.validateStyle(invalid),'invalid turn thresholds and empty move maps rejected')
for branch=1,4 do
 reset()
 for i=1,branch do PY.Combo.press(state(),4,1);p:AttemptAttack();finish()end
 fx,fy=-1,0;check(PY.queueFinisher(p),'rear finisher input accepted '..branch)
 check(state().queuedFinisherVariant=='reverse_after_'..branch,'rear first source branch selected '..branch)
 fire('OnPlayerUpdate',p)
 check(state().finisherMove==style.actions.finisher.variants['reverse_after_'..branch],'native rear finisher starts '..branch)
 check(PY.queueFinisher(p),'rear double input accepted '..branch)
 check(state().queuedDoubleVariant=='reverse_double_after_'..branch,'matching reverse double queued during first '..branch)
 finish();fire('OnPlayerUpdate',p)
 check(state().finisherMove==style.actions.finisher.variants['reverse_double_after_'..branch],'matching reverse double starts '..branch)
 finish()
end
reset();p:AttemptAttack();finish();fx,fy=0,1;check(PY.queueFinisher(p),'side-facing ordinary finisher input accepted')
check(state().queuedFinisherVariant=='after_1','unverified side finisher motion is not invented')
return true,'PASS '..checks..' directional sectors, actual Runtime routing, damage, enders, interruption and style/weapon isolation checks'
