require=function()end
local function any(t)for _ in pairs(t)do return true end;return false end
local count=0
local function check(v,m)count=count+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<.00002 end
local clock,paused=1000,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
local function event()local e={hooks={}};function e.Add(f)e.hooks[f]=true end;function e.Remove(f)e.hooks[f]=nil end;return e end
Events={OnPlayerUpdate=event(),OnTick=event(),OnPostRender=event(),OnSave=event(),OnMainMenuEnter=event(),OnGameStart=event()}
Core={getTileScale=function()return 2 end}
IsoDirections={N=0}
ColorInfo={new=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end}
local additive=true
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end}}
local allocated,disposed,updated,draws=0,0,0,{}
local failRender=false
local function centre(d)
 local x,y,z=d.x-d.rootX,d.y-d.rootY,d.z-d.rootZ
 return (x-y)*64-d.ox,(x+y)*32-z*192-d.oy-d.height*d.scale/2
end

local function instance()
 allocated=allocated+1
 return {setScale=function(s,x,y)s.scale=x end,setFrameSpeedPerFrame=function()end,SetAlpha=function(s,v)s.alpha=v end,SetTargetAlpha=function()end,
 Dispose=function(s)check(not s.disposed,'no double disposal');s.disposed=true;disposed=disposed+1 end,
 render=function(s,p,x,y,z,d,ox,oy,col)
  if failRender then error('injected render failure')end
  draws[#draws+1]={p=p,x=x,y=y,z=z,ox=ox,oy=oy,color=col,alpha=s.alpha,scale=s.scale,height=s.sprite.height,additive=additive,rootX=p:getX(),rootY=p:getY(),rootZ=p:getZ()}
 end}
end
IsoSprite={CreateSprite=function()return {height=64,LoadFramesNoDirPageSimple=function(s,path)s.height=string.find(path,'ChargeSpark') and 32 or 64 end,LoadFramesNoDirPageDirect=function(s)s.height=32 end,setAnimate=function()end,update=function()updated=updated+1 end}end}
IsoSpriteInstance={add=function()end,get=function(sprite)local i=instance();i.sprite=sprite;return i end}
local function actor()
 local a={dead=false,equipped=true,reaction='',floor=false,md={},angle=0,time=0,weight=1,localPlayer=true,lookup=0,empty=false,x=0,y=0,z=0}
 function a:isDead()return self.dead end
 function a:isLocalPlayer()return self.localPlayer end
 function a:isOnFloor()return self.floor end
 function a:getHitReaction()return self.reaction end
 function a:getModData()return self.md end
 function a:getAnimAngleRadians()return self.angle end
 function a:getShoulderTwist()return self.twist or 0 end
 function a:getX()return self.x end;function a:getY()return self.y end;function a:getZ()return self.z end
 function a:getOffsetX()return 0 end;function a:getOffsetY()return 0 end
 function a:getAttachedAnimSprite()return {remove=function()end}end
 function a:dbgGetAnimTrackName(layer,slot)
  self.lookup=self.lookup+1
  if self.empty then return '' end
  if layer==1 and slot==0 then return 'Idle' end
  if layer==1 and slot==1 then return self.clip or 'ProjectYakuza_DD_Light01' end
  return ''
 end
 function a:dbgGetAnimTrackTime()return self.time end
 function a:dbgGetAnimTrackWeight()return self.weight end
 return a
end
local style={id='dragon_of_dojima',sounds={punchSwing='OriginalWhoosh'}}
local combo={active=true,multiHitToken={}}
local p=actor()
ProjectYakuza={listeners={},WorldEffects={attach=function()return instance()end},
 getPlayerStyle=function(who)return who.style or style end,isEquipped=function(who)return who.equipped end,stateFor=function()return combo end,
 isStyleToken=function()return false end,Heat={isExtreme=function(who)return who.extreme or false end,config={extremeSpeed=1.15}},HeatActivation={active={}}}
function ProjectYakuza.on(name,fn)local listeners=ProjectYakuza.listeners;listeners[name]=listeners[name] or {};table.insert(listeners[name],fn)end
local function emit(name,...)for _,f in ipairs(ProjectYakuza.listeners[name] or {})do f(...)end end
do local _="ProjectYakuzaFixture:WORLD" end
do local _="ProjectYakuzaFixture:TRACKS" end
do local _="ProjectYakuzaFixture:EFFECTS" end
local F=ProjectYakuza.AttackEffects
local track=ProjectYakuza.AttackTracks.dd_light_01
local move={animation=track.animation,duration=.625,impact=.2,attackEffects={track='dd_light_01',from=2/30,to=14/30,swingFrame=3,verticalOffset=2.5}}
style.lightAttacks={move}
check(not F.hooked and not any(Events.OnTick.hooks),'idle has no tick/render effects')
local nativeProjection="ProjectYakuzaFixture:PROJECTION"
for i=0,7 do
 local x,y,wx,wy,wz=F.project(.1,.65,-.4,i*math.pi/4,2)
 check(near(x,nativeProjection[i+1][1]) and near(y,nativeProjection[i+1][2]),'native eight-facing model/world/screen projection '..i)
 check(near(wx,nativeProjection[i+1][3]) and near(wy,nativeProjection[i+1][4]) and near(wz,nativeProjection[i+1][5]),'native limb-height world depth anchor '..i)
end
for i=0,30 do
 for bone=1,3 do
  local x,y,z=F.sample(track,i/30,bone);local row=track.frames[i+1];local n=(bone-1)*3
  check(near(x,row[n+1]) and near(y,row[n+2]) and near(z,row[n+3]),'exact native source sample')
 end
end
local x,y,z=F.sample(track,6.5/30,2)
check(near(x,(track.frames[7][4]+track.frames[8][4])/2),'subframe position interpolation')
F.start(p,style,1,{animation='Other'});check(not F.states[p],'unconfigured moves remain unchanged')
emit('lightAttackStarted',p,style,1,move);check(F.states[p] and F.hooked and allocated==0,'begin waits for actual native clip before allocating')
p.time=.04;F.tick();F.render();check(allocated==0 and #draws==0,'windup before configured window has no particles')
p.time=.2;F.tick();F.render();check(allocated==18 and #F.states[p].points==18,'bounded eighteen sprites for first punch')
check(additive,'render restores original additive state')
for _,d in ipairs(draws)do check(not d.additive,'every punch layer uses normal transparency without brightness boost')end
check(near(F.states[p].points[6].scale,.16*2*1.25) and near(F.states[p].points[7].scale,.30*2*1.25),'all punch particles are exactly 25 percent larger')
check(draws[1].alpha>.5 and draws[1].scale>.2,'punch glow is larger and more visible')
check(F.normal.r>=.6 and F.normal.g>=.8 and F.normal.b==1,'punch glow has a white-bluish tint')
for j=1,6 do
 local d=draws[j];local x,y,z
 if j==6 then
  local ax,ay,az=F.sample(track,.2,1);local wx,wy,wz=F.sample(track,.2,2)
  x,y,z=ax+(wx-ax)*.78,ay+(wy-ay)*.78,az+(wz-az)*.78
 else
  local ax,ay,az=F.sample(track,.2,1);local wx,wy,wz=F.sample(track,.2,2);local t=.08+j*.12
  x,y,z=ax+(wx-ax)*t,ay+(wy-ay)*t,az+(wz-az)*t
 end
 local px,py=F.project(x,y,z,p.angle,2)
 local cx,cy=centre(d)
 check(near(cx,px) and near(cy,py+5) and d.z>d.rootZ,'lowered punch centre retains native limb-height depth')
end
check(#draws>=14,'forearm glow, two flames, trails and several sparks are visible together')

local n=p.lookup;F.tick();check(p.lookup==n+1,'native slot cached after bounded initial lookup')
local duplicate=actor()
function duplicate:dbgGetAnimTrackName(layer,slot)if layer==1 and slot<2 then return move.animation end;return '' end
function duplicate:dbgGetAnimTrackTime(layer,slot)return slot==0 and .8 or .12 end
local time,weight,where=F.findTrack(duplicate,move.animation)
check(near(time,.12) and where.slot==1,'new native track wins over fading copy of same clip')

local last=draws[#draws];check(last.p==p and math.abs(last.x-p:getX())<1 and math.abs(last.y-p:getY())<1 and last.z>p:getZ(),'world renderer anchors particles at the nearby limb height')
local a=allocated;F.render();check(allocated==a,'no sprite allocation on repeated frames')
local ticks=F.states[p].clock;local beforeUpdate=updated;paused=true;clock=clock+1000;p.time=.3;F.tick();F.render()
check(F.states[p].time==.2 and F.states[p].clock==ticks and updated==beforeUpdate,'pause freezes clock, source position and flame')
paused=false;p.time=.25;p.extreme=true;F.tick();draws={};F.render();check(draws[1].color==F.extreme and draws[1].alpha>.5,'extreme tint and stronger glow without touching body aura')
for i=0,15 do
 p.angle=i*math.pi/8;p.twist=(i%3-1)*30;draws={};F.render()
 local ax,ay,az=F.sample(track,p.time,1);local wx,wy,wz=F.sample(track,p.time,2)
 local x,y,z=ax+(wx-ax)*.78,ay+(wy-ay)*.78,az+(wz-az)*.78
 local px,py=F.project(x,y,z,p.angle,2)
 local cx,cy=centre(draws[6]);check(near(cx,px) and near(cy,py+5),'sampled fallback avoids rotating the arm twice '..i)
end
p.twist=0
local providerCalls=0
F.registerLimbProvider('live',function(who,animation,time)
 providerCalls=providerCalls+1
 check(who==p and animation==move.animation,'live adapter receives actor and exact attack clip')
 return who.x+.10,who.y-.05,who.z+.4,who.x+.25,who.y+.15,who.z+.45
end)
for i=0,7 do
 p.angle=i*math.pi/4;draws={};F.render()
 local cx,cy=centre(draws[6]);local tx=(.25-.15)*64;local ty=(.25+.15)*32-.45*192
 check(near(cx,tx) and near(cy,ty),'live hand coordinates bypass sampled yaw and pixel inset for facing '..i)
end
check(providerCalls==8,'live provider is read once per actor draw, not per particle')
F.removeLimbProvider('live');check(not F.limbProviders.live,'addon can remove its limb provider')
F.registerLimbProvider('broken',function()error('unavailable native pose')end);F.states[p].config.limbProvider='broken'
draws={};F.render();check(#draws>0 and F.states[p].providerRetry,'broken provider safely falls back with a retry throttle')
F.states[p].config.limbProvider=nil;F.removeLimbProvider('broken')
p.reaction='Bite';F.tick();check(not F.states[p] and not F.hooked and allocated==disposed,'hit interruption disposes everything and removes hooks');p.reaction=''
p.empty=true;F.start(p,style,1,move);clock=clock+351;F.tick();check(not F.states[p],'missing animation times out without offset fallback');p.empty=false
F.start(p,style,1,move);p.time=.8;F.tick();check(F.states[p] and not F.states[p].seen,'stale outgoing clip waits for replacement');clock=clock+351;F.tick();check(not F.states[p],'late clip observation skips stale burst')
p.time=.2;F.start(p,style,1,move);F.tick();F.render();p.clip='Other';F.tick();check(not F.states[p],'changing native clip clears effect');p.clip=nil
F.start(p,style,1,move);F.tick();p.time=.1;F.tick();check(not F.states[p],'native restart clears old trail')
p.time=.2;F.start(p,style,1,move);F.tick();F.render();emit('lightAttackFinished',p);check(not F.states[p],'native light completion clears effect')
for _,key in ipairs({'comboCancelled','finisherStarted','runningAttackStarted','quickstepAttackStarted','chargedHeavyStarted','groundAttackStarted','styleChanged'})do
 F.start(p,style,1,move);emit(key,p);check(not F.states[p],key..' ends trail')
end
p.md.ProjectYakuzaHitEffectsDisabled=true;F.start(p,style,1,move);check(not F.states[p],'existing visual preference respected');p.md.ProjectYakuzaHitEffectsDisabled=nil
p.localPlayer=false;F.remote(p,style,{clip=move.animation});check(F.states[p],'MP observer uses same configured clip');F.remote(p,style,{clip='Other'});check(not F.states[p],'observer clip transition cleans up');p.localPlayer=true
local actors={};for i=1,10 do local who=actor();actors[i]=who;F.start(who,style,1,move)end
local total=0;for _ in pairs(F.states)do total=total+1 end;check(total==8,'actor effect count bounded under MP load');F.clearAll();check(not any(F.states),'all bounded actors cleaned')
F.start(p,style,1,move);F.tick();failRender=true;local ok=pcall(F.render);check(not ok and additive and not any(F.states) and not F.hooked,'render error restores graphics flags and disposes state');failRender=false
for _,event in ipairs({Events.OnSave,Events.OnMainMenuEnter,Events.OnGameStart})do F.start(p,style,1,move);for fn in pairs(event.hooks)do fn()end;check(not any(F.states),'world transition clears state')end
do local _="ProjectYakuzaFixture:CHARGELIMBTRACKS" end
do local _="ProjectYakuzaFixture:CHARGELIMBEFFECTS" end
local C=ProjectYakuza.ChargeEffects
ProjectYakuza.activeActions={};style.hitEffects='yakuza6';instanceof=function()return true end
function p:GetVariable(k)return self.vars and self.vars[k] end
local chargeAllocation=allocated
for branch=1,4 do
 local animation='ProjectYakuza_DD_ChargeWindup0'..branch
 ProjectYakuza.activeActions[p]={kind='heavyCharge',action={animation=animation,holdAnimation='ProjectYakuza_DD_ChargeHold0'..branch},timedAction={started=true,holding=true,power=.5}}
 p.time=0;C.update(p);clock=clock+120;C.update(p);draws={};C.render()
 local state=C.states[p];check(state and #state.instances==6,'branch has only six limb-bound charging particles')
 local row=state.track.frames[1];local ax,ay,az=row[1],row[2],row[3];local bx,by,bz=row[4],row[5],row[6]
 local x,y=F.project(ax+(bx-ax)*.31,ay+(by-ay)*.31,az+(bz-az)*.31,p.angle,2)
 local d=draws[1];local cx,cy=centre(d);check(near(cx,x) and near(cy,y+4) and d.z>d.rootZ,'charge particle centres and depth follow the branch-specific limb')
 check(d.color.r>=.6 and d.color.g>=.8,'limb charge glow is white-blue')
 local n=allocated;C.update(p);C.render();check(allocated==n,'stable charge never rebuilds particles')
 C.clear(p)
end
ProjectYakuza.activeActions[p]=nil;C.update(p);check(not C.hooked and not C.states[p],'charge stop removes render callback')
local startingContext={kind='heavyCharge',action={animation='ProjectYakuza_DD_ChargeLoop'},timedAction={started=true,power=.5}}
p.empty=true
C.begin(p,style,startingContext.action,startingContext)
check(C.states[p] and C.owners[p]==startingContext,'synchronous action start creates effects before registry publishes its context')
clock=clock+120;draws={};C.render()
check(#draws==12 and draws[1].additive and not draws[4].additive,'missing debug track still draws bounded charging limbs with scoped core glow')
local lookups=p.lookup;clock=clock+10;C.render();check(p.lookup==lookups,'missing debug track retries are throttled')
check(draws[1].alpha>.4 and draws[1].scale>=.3,'charge cores are visible before full power')
C.clear(p);p.empty=false
check(not C.owners[p] and not C.states[p],'stopping charge clears early-start ownership too')

p.localPlayer=false;p.vars={ProjectYakuzaRemoteClip='ProjectYakuza_DD_ChargeHold02',ProjectYakuzaRemoteChargePower='.7'}
C.update(p);check(C.states[p] and near(C.states[p].power,.7),'remote limb charge follows bounded replicated power')
C.clear(p);p.localPlayer=true;p.vars=nil
local chargeActors={}
for i=1,10 do
 local who=actor();chargeActors[i]=who
 ProjectYakuza.activeActions[who]={kind='heavyCharge',action={animation='ProjectYakuza_DD_ChargeLoop'},timedAction={started=true,power=.4}}
 C.update(who)
end
local chargeCount=0;for _ in pairs(C.states)do chargeCount=chargeCount+1 end
check(chargeCount==8,'charge effect bounds active actors to eight');C.clearAll();ProjectYakuza.activeActions={}
check(not C.hooked and allocated==disposed,'all arm/leg charge instances return to the pool')
do local _="ProjectYakuzaFixture:FEEDBACK" end
local audio={}
function p:getPrimaryHandItem()return nil end
function p:playSound(name)audio[#audio+1]=name;return #audio end
function p:getEmitter()return {setVolume=function()end}end
local A=ProjectYakuza.Feedback
p.time=.02;clock=clock+1000;A.swing(p,style,1,move);A.tick();check(#audio==0,'whoosh waits for live source frame')
p.time=3/30;A.tick();check(#audio==1 and audio[1]=='OriginalWhoosh','single existing Y6 whoosh at source frame three')
A.tick();check(#audio==1,'no duplicate whoosh next tick')
p.time=.02;A.swing(p,style,1,move);paused=true;p.time=.2;clock=clock+1000;A.tick();check(#audio==1,'pause suppresses scheduled sound');paused=false;A.tick();check(#audio==2,'unpause resumes native timing')
p.time=.02;A.swing(p,style,1,move);combo.active=false;p.time=.2;A.tick();check(#audio==2,'interrupted swing has no whoosh');combo.active=true
p.time=.02;A.swing(p,style,1,move);p.clip='Other';clock=clock+351;A.tick();check(not A.pending[p] and #audio==2,'missing native clip discards stale whoosh');p.clip=nil
p.time=.02;A.swing(p,style,1,move);p.time=.6;A.tick();check(#audio==2,'late frame never plays delayed whoosh')
p.time=.2;p.localPlayer=false;A.swing(p,style,1,move);A.tick();check(#audio==2,'remote visuals do not duplicate local-only swing audio');p.localPlayer=true
A.clear();check(not A.ticking and not F.hooked and allocated==disposed,'complete effects/audio cleanup')
return 'PASS '..count..' original-punch tracking, world projection, lifecycle, bounded MP and source-clock audio checks'
