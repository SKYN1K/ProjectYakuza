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
  draws[#draws+1]={instance=s,p=p,x=x,y=y,z=z,ox=ox,oy=oy,color=col,alpha=s.alpha,scale=s.scale,height=s.sprite.height,additive=additive,rootX=p:getX(),rootY=p:getY(),rootZ=p:getZ()}
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
do local _="ProjectYakuzaFixture:CATALOG" end
do local _="ProjectYakuzaFixture:EFFECTS" end
local F=ProjectYakuza.AttackEffects
local track=ProjectYakuza.AttackTracks.dd_light_01
local move={animation=track.animation,duration=.625,impact=.2,attackEffects={track='dd_light_01',from=2/30,to=14/30,swingFrame=3,verticalOffset=2.5}}
style.lightAttacks={move}
check(not F.hooked and not any(Events.OnTick.hooks),'idle has no tick/render effects')
local nativeProjection="ProjectYakuzaFixture:PROJECTION"
for i=0,7 do
 local x,y,wx,wy,wz=F.project(.1,.65,-.4,i*math.pi/4,2)
 check(near(x,nativeProjection[i+1][1])and near(y,nativeProjection[i+1][2]),'native eight-facing model/world/screen projection')
 check(near(wx,nativeProjection[i+1][3])and near(wy,nativeProjection[i+1][4])and near(wz,nativeProjection[i+1][5]),'native limb-height projection')
end
for i=0,30 do
 for bone=1,4 do
  local x,y,z=F.sample(track,i/30,bone);local row=bone==4 and track.upperFrames[i+1]or track.frames[i+1];local n=bone==4 and 0 or (bone-1)*3
  check(near(x,row[n+1])and near(y,row[n+2])and near(z,row[n+3]),'exact imported shoulder/elbow/hand/knuckle sample')
 end
end
local x,y,z=F.sample(track,6.5/30,4)
check(near(x,(track.upperFrames[7][1]+track.upperFrames[8][1])/2),'shoulder source is interpolated at subframes')
F.start(p,style,1,{animation='Other'});check(not F.states[p],'unconfigured moves remain unchanged')
emit('lightAttackStarted',p,style,1,move);check(F.states[p]and F.hooked and allocated==0,'allocation waits for actual clip window')
p.time=.04;F.tick();F.render();check(allocated==0 and #draws==0,'no particles before source window')
p.time=.2;F.tick();F.render()
check(allocated==30 and #F.states[p].points==30,'limb coating and lingering trails have a fixed thirty-sprite budget')
check(#draws>=14 and additive,'contiguous coat and inner arm layers draw, restoring renderer state')
check(near(F.states[p].points[1].scale,.88),'coating is wide enough for the PZ arm')
for _,d in ipairs(draws)do check(not d.additive and d.alpha<=.55,'all arm layers use restrained ordinary alpha')end
check(F.normal.r>=.6 and F.normal.g>=.8 and F.normal.b==1,'white-blue normal tint remains')
for facing=0,31 do
 p.angle=facing*math.pi/16;p.x=.13;p.y=-.17;p.z=.25;draws={};F.render()
 local ux,uy,uz=F.sample(track,.2,4);local wx,wy,wz=F.sample(track,.2,2);local kx,ky,kz=F.sample(track,.2,3)
 local sx,sy=F.project(ux,uy,uz,p.angle,2)
 local hx,hy=F.project(wx+(kx-wx)*.35,wy+(ky-wy)*.35,wz+(kz-wz)*.35,p.angle,2)
 local cx,cy=centre(draws[1]);local fx,fy=centre(draws[11])
 check(near(cx,sx)and near(cy,sy),'coating starts at native shoulder for every continuous facing')
 check(near(fx,hx)and near(fy,hy),'coating ends at native fist without an outward offset')
 for i=2,11 do
  local a,b=draws[i-1],draws[i];local ax,ay=centre(a);local bx,by=centre(b)
  check(math.sqrt((bx-ax)^2+(by-ay)^2)<math.min(a.height*a.scale,b.height*b.scale)*.6,'arm coverage stays connected in every direction')
 end
end
for frame=3,14 do for facing=0,7 do
 p.time=frame/30;F.states[p].time=p.time;p.angle=facing*math.pi/4;draws={};F.render()
 local ux,uy,uz=F.sample(track,p.time,4);local sx,sy=F.project(ux,uy,uz,p.angle,2);local x,y=centre(draws[1])
 check(near(x,sx)and near(y,sy),'deforming source shoulder stays centred throughout the configured punch')
 for point=2,11 do
  local ax,ay=centre(draws[point-1]);local bx,by=centre(draws[point])
  check(math.sqrt((bx-ax)^2+(by-ay)^2)<draws[point].height*draws[point].scale*.6,'coating has no gaps across source frames and eight facings')
 end
end end
p.time=.2;F.states[p].time=.2
local allocations,updates=allocated,updated;F.render();check(allocated==allocations and updated==updates,'repeat render at the same clock neither allocates nor advances flames')
clock=clock+10;F.render()
local state=F.states[p];local old={};for i=1,9 do old[i]=state.joints[i]end;local oldAt=state.clock
clock=clock+20;p.angle=p.angle+math.pi/2;p.x=p.x+.1;draws={};F.render()
local fresh={};for i=1,9 do fresh[i]=state.joints[i]end
local sample={};check(F.historyPose(state,oldAt,sample),'recorded earlier world pose remains available')
for i=1,9 do check(near(sample[i],old[i]),'turning does not rotate historical arm positions')end
local trail
for _,d in ipairs(draws)do if d.instance==state.points[15].instance then trail=d end end
check(trail and near(trail.x,select(1,F.armPoint(old,.5)))and near(trail.y,select(2,F.armPoint(old,.5))),'rendered history trail interpolates past world positions, not current facing')
clock=clock+20;p.x=p.x+5;draws={};F.render()
check(state.historyCount==1,'teleport clears the trail instead of drawing across the map')
for i=1,40 do clock=clock+10;p.angle=p.angle+.02;F.render()end
check(state.historyCount==24 and #state.history==24 and allocated==allocations,'world history and native instances stay bounded during repeated frames')
local ticks=state.clock;local beforeUpdate=updated;paused=true;clock=clock+1000;p.time=.3;F.tick();F.render()
check(state.time==.2 and state.clock==ticks and updated==beforeUpdate,'pause freezes source clock, pose history and flames')
paused=false;p.time=.25;p.extreme=true;clock=clock+16;F.tick();draws={};F.render()
check(draws[1].color==F.extreme and draws[1].alpha<=.34,'Extreme uses its restrained brighter tint without changing body aura')
local providerCalls=0
F.registerLimbProvider('live',function(who,animation,time)
 providerCalls=providerCalls+1
 return who.x+.05,who.y+.1,who.z+.3,who.x+.25,who.y-.15,who.z+.45
end)
for i=0,7 do
 p.angle=i*math.pi/4;draws={};F.render()
 local d=draws[11]
 check(near(d.x,p.x+.25)and near(d.y,p.y-.15)and near(d.z,p.z+.45),'existing six-coordinate provider keeps its exact hand endpoint')
end
check(providerCalls==8,'provider is queried once per actor draw')
F.removeLimbProvider('live')
F.registerLimbProvider('full',function(who)return who.x+.05,who.y+.1,who.z+.3,who.x+.25,who.y-.15,who.z+.45,who.x-.1,who.y+.1,who.z+.55 end)
state.config.limbProvider='full';draws={};F.render();check(near(draws[1].x,p.x-.1)and near(draws[1].z,p.z+.55),'optional shoulder endpoint is respected')
F.removeLimbProvider('full');state.config.limbProvider=nil
F.registerLimbProvider('broken',function()error('unavailable native pose')end);state.config.limbProvider='broken';draws={};F.render()
check(#draws>0 and state.providerRetry,'unavailable provider falls back with retry throttle')
state.config.limbProvider=nil;F.removeLimbProvider('broken')
local n=p.lookup;F.tick();check(p.lookup==n+1,'cached native clip slot avoids scanning every layer')
local duplicate=actor()
function duplicate:dbgGetAnimTrackName(layer,slot)if layer==1 and slot<2 then return move.animation end;return ''end
function duplicate:dbgGetAnimTrackTime(layer,slot)return slot==0 and .8 or .12 end
local time,weight,where=F.findTrack(duplicate,move.animation)
check(near(time,.12)and where.slot==1,'incoming native track wins over its fading copy')
p.reaction='Bite';F.tick();check(not F.states[p]and not F.hooked and allocated==disposed,'hit interruption disposes all instances');p.reaction=''
p.empty=true;F.start(p,style,1,move);clock=clock+351;F.tick();check(not F.states[p],'missing animation times out cleanly');p.empty=false
F.start(p,style,1,move);p.time=.8;F.tick();check(F.states[p]and not F.states[p].seen,'stale outgoing clip waits for replacement');clock=clock+351;F.tick();check(not F.states[p],'late incoming clip cannot produce stale burst')
p.time=.2;F.start(p,style,1,move);F.tick();F.render();p.clip='Other';F.tick();check(not F.states[p],'clip change clears coating');p.clip=nil
F.start(p,style,1,move);F.tick();p.time=.1;F.tick();check(F.states[p]and F.states[p].historyCount==0,'native restart drops previous pose history before following the new cycle')
p.time=.2;F.start(p,style,1,move);F.tick();F.render();emit('lightAttackFinished',p);check(not F.states[p],'light completion clears coating')
for _,key in ipairs({'comboCancelled','finisherStarted','runningAttackStarted','quickstepAttackStarted','chargedHeavyStarted','groundAttackStarted','styleChanged'})do
 F.start(p,style,1,move);emit(key,p);check(not F.states[p],key..' cleans up')
end
p.md.ProjectYakuzaHitEffectsDisabled=true;F.start(p,style,1,move);check(not F.states[p],'visual preference is respected');p.md.ProjectYakuzaHitEffectsDisabled=nil
p.localPlayer=false;F.remote(p,style,{clip=move.animation});check(F.states[p],'MP observer starts configured trail');F.remote(p,style,{clip='Other'});check(not F.states[p],'MP clip transition clears trail');p.localPlayer=true
local actors={};for i=1,10 do local who=actor();actors[i]=who;F.start(who,style,1,move)end
local total=0;for _ in pairs(F.states)do total=total+1 end;check(total==8,'actor budget stays eight under MP load');F.clearAll()
F.start(p,style,1,move);F.tick();failRender=true;local ok=pcall(F.render);check(not ok and additive and not any(F.states)and not F.hooked,'render failure restores global blend and cleans instances');failRender=false
for _,event in ipairs({Events.OnSave,Events.OnMainMenuEnter,Events.OnGameStart})do F.start(p,style,1,move);for fn in pairs(event.hooks)do fn()end;check(not any(F.states),'world transition clears coating and history')end

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
A.clear();combo.active=true;p.clip='ProjectYakuza_DD_Heavy';p.time=.1;style.sounds.kickSwing='KickWhoosh'
local beforeHeavy=#audio;local heavy={animation=p.clip,duration=1,speed=1,impact=.6,neutralHeavy=true}
A.swing(p,style,0,heavy);clock=clock+400;A.tick();check(#audio==beforeHeavy and A.pending[p],'heavy whoosh waits past old 350ms cutoff for its source phase')
p.time=.54;A.tick();check(#audio==beforeHeavy+1 and audio[#audio]=='KickWhoosh','heavy whoosh follows actual clip phase instead of elapsed wall time')
A.tick();check(#audio==beforeHeavy+1,'heavy source-phase cue fires once');p.clip=nil
A.clear();check(not A.ticking and not F.hooked and allocated==disposed,'complete effects/audio cleanup')
local catalog=ProjectYakuza.AttackEffectCatalog.dragon_of_dojima
local clips,contacts=0,0
for animation,entry in pairs(catalog)do
 clips=clips+1
 local attack={animation=animation,duration=entry.duration,speed=1,impact=.5};local stamp={player=p}
 p.clip=animation;p.time=0;emit('attackCommitted',p,style,attack,stamp)
 local active=F.states[p];check(active and active.stamp==stamp,'committed attack starts catalogue coating '..animation)
 emit('finisherStarted',p,style,1,attack);check(F.states[p]==active,'category event preserves committed state')
 emit('actionCompleted',{player=p});check(F.states[p]==active,'unrelated completed context preserves active coating')
 for _,window in ipairs(entry.windows)do
  contacts=contacts+1;p.time=(window.from+window.to)/2
  for facing=0,7 do
   p.angle=facing*math.pi/4;clock=clock+10;F.tick();draws={};F.render()
   check(F.states[p]==active and active.track==ProjectYakuza.AttackTracks[window.track],'correct source limb selected at contact')
   check(#draws>=14 and #active.points==30,'every contact has bounded animated coating')
   for i=1,11 do
    local x,y,z=F.armPoint(active.joints,(i-1)/10);local d=draws[i]
    check(math.sqrt((d.x-x)^2+(d.y-y)^2+(d.z-z)^2)<.025,'chaos remains tightly around the attacking limb')
   end
  end
 end
 emit('actionCompleted',stamp);check(not F.states[p],'matching action completion clears coating')
 F.remote(p,style,{clip=animation});check(F.states[p],'observer catalogue covers every attack');F.clear(p)
end
check(clips==83 and contacts==103,'complete active moveset coverage with removed katana recovery trail')
p.style={id='other_style'};F.start(p,p.style,0,{animation='ProjectYakuza_DD_Heavy'});check(not F.states[p],'builtin catalogue remains style exclusive');p.style=nil
F.remote(p,nil,{clip='Unknown'});check(not F.states[p],'missing remote style is safe')

F.clearAll();p.clip=move.animation;p.time=.2;p.angle=0;p.x=0;p.y=0
F.start(p,style,1,move);F.tick();F.render()
for i=1,16 do clock=clock+10;p.time=.2+i*.005;p.angle=p.angle+.04;p.x=p.x+.004;F.tick();F.render()end
local old=F.states[p];local oldRoot={p.x,p.y};emit('lightAttackFinished',p)
check(not F.states[p]and #F.tails==1 and F.hooked,'finished attack leaves a short world-space trail')
for i,point in ipairs(old.points)do check((point.instance~=nil)==(i>=15 and i<=26),'retired state keeps only twelve historical flame instances')end
clock=clock+20;p.angle=p.angle+2;p.x=p.x+.1;draws={};F.render();check(#draws>0,'world history still renders after the source attack finishes')
for _,draw in ipairs(draws)do check(draw.x<oldRoot[1]+.7 and draw.alpha<.32,'retired trail is restrained and stays near prior world positions')end
F.start(p,style,1,move);F.tick();F.render();check(F.states[p]and #F.tails==1,'new attack does not erase the previous attack trail')
paused=true;local clocked=old.clock;clock=clock+1000;F.render();check(old.clock==clocked,'retired trail freezes during pause');paused=false
clock=clock+210;F.render();check(#F.tails==0,'retired trail expires without following the current hand')
F.clearAll()
local base='ProjectYakuza_DD_DoubleFinisher03';local linked='ProjectYakuza_DD_LinkedDoubleFinisher03'
p.clip=linked;local cfg=catalog[linked];p.time=(cfg.windows[1].from+cfg.windows[1].to)/2
local linkedMove={animation=base};F.start(p,style,0,linkedMove,901);F.tick();draws={};F.render()
check(F.states[p]and F.states[p].track.animation==linked and F.states[p].track.limb=='leftLeg','base double-finisher request follows the actual playing linked kick and its native leg')
for facing=0,15 do p.angle=facing*math.pi/8;clock=clock+5;draws={};F.render();local a=F.states[p];local x,y,z=F.armPoint(a.joints,1);check(near(draws[11].x,x)and near(draws[11].y,y)and near(draws[11].z,z),'kicking foot endpoint matches current clip in every facing')end
F.clearAll();p.clip='ProjectYakuza_DD_Light01';F.start(p,style,0,linkedMove);clock=clock+351;F.tick();check(not F.states[p],'unrelated visible punch cannot substitute for a committed kick')
check(ProjectYakuza.AttackTracks[catalog.ProjectYakuza_DD_Finisher03.track].limb=='rightArm','normal finisher uses its own striking arm rather than the charge-up arm')
check(ProjectYakuza.AttackTracks[catalog.ProjectYakuza_DD_Finisher02.track].limb=='rightLeg','high-kick finisher retains the striking leg when recovering arms move faster')
check(#catalog.ProjectYakuza_DD_HeatRush.windows==13 and ProjectYakuza.AttackTracks[catalog.ProjectYakuza_DD_HeatRush.windows[13].track].limb=='rightLeg','current Rush has twelve original punch contacts followed by its actual kick')
do
 local name='ProjectYakuza_DD_KatanaHeat';local config=catalog[name];local limbs={'rightArm','leftArm','rightArm'}
 check(#config.windows==3,'katana has exactly three source strike windows')
 for i,window in ipairs(config.windows)do
  F.clearAll();p.clip=name;p.time=(window.from+window.to)/2;F.start(p,style,0,{animation=name},1000+i);F.tick();draws={};F.render()
  check(F.states[p]and F.states[p].track.limb==limbs[i]and #draws>0,'katana tracks its actual striking limb '..i)
 end
 F.clearAll();p.time=97/30;F.start(p,style,0,{animation=name},1004);clock=clock+351;F.tick()
 check(not F.states[p],'katana recovery cannot emit the removed fourth hit trail')
end
p.clip=linked;p.time=(cfg.windows[1].from+cfg.windows[1].to)/2;p.localPlayer=false
F.remote(p,style,{clip=linked,action=77,swing=12});F.tick();F.render();local remote=F.states[p];F.remote(p,style,{clip=linked,action=77,swing=12});check(F.states[p]==remote,'repeated MP snapshots cannot reset current limb phase/history')
F.clear(p);p.localPlayer=true

p.clip=nil;F.clearAll();check(allocated==disposed and not F.hooked,'expanded effects release all sprites and hooks')
return 'PASS '..count..' original-punch tracking, world projection, lifecycle, bounded MP and source-clock audio checks'
