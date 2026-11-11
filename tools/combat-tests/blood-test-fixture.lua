require=function()end
local checks=0
local function check(v,message)checks=checks+1;assert(v,message)end
local clock,paused=1000,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
Core={getTileScale=function()return 2 end}
IsoDirections={N=0}
ColorInfo={new=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end}
local function event()local e={};e.Add=function(fn)e[fn]=true end;e.Remove=function(fn)e[fn]=nil end;return e end
Events={OnTick=event(),OnPostRender=event(),OnSave=event(),OnMainMenuEnter=event(),OnGameStart=event()}
local additive=true
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end}}
local sprites,allocated,disposed,renders,attaches=0,0,0,{},0
IsoSprite={CreateSprite=function()
 sprites=sprites+1
 return {LoadFramesNoDirPageSimple=function(self,path)self.path=path end}
end}
local function instance(sprite)
 allocated=allocated+1
 local i={sprite=sprite}
 function i:setScale(x,y)self.scaleX=x;self.scaleY=y end
 function i:setFrameSpeedPerFrame(v)self.speed=v end
 function i:SetAlpha(v)self.alpha=v end
 function i:SetTargetAlpha(v)self.targetAlpha=v end
 function i:Dispose()check(not self.disposed,'instance released once');self.disposed=true;disposed=disposed+1 end
 function i:render(v,x,y,z,d,dx,dy,color)
  check(not self.disposed,'only live world instances render')
  if v.fail then error('intentional world render failure')end
  renders[#renders+1]={path=self.sprite.path,actor=v,x=x,y=y,z=z,dx=dx,dy=dy,scale=self.scaleX,alpha=self.alpha,color=color,additive=additive}
 end
 return i
end
IsoSpriteInstance={get=instance,add=function()end}
local function actor(kind)
 local a={kind=kind or 'IsoPlayer',md={},x=10,y=12,z=0,active=true,localPlayer=true,style={hitEffects='yakuza6',bloodEffects='yakuza6'},state={active=true},attached={}}
 function a:getModData()return self.md end
 function a:getX()return self.x end;function a:getY()return self.y end;function a:getZ()return self.z end
 function a:isDead()return self.dead==true end
 function a:isOnFloor()return self.floor==true end
 function a:isLocalPlayer()return self.localPlayer end
 function a:getOffsetX()return self.offsetX or 0 end;function a:getOffsetY()return self.offsetY or 0 end
 function a:AttachExistingAnim(sprite)attaches=attaches+1;self.attached[#self.attached+1]=instance(sprite)end
 function a:getAttachedAnimSprite()
  local items=self.attached
  return {size=function()return #items end,get=function(_,i)return items[i+1]end,remove=function(_,item)for i=#items,1,-1 do if items[i]==item then table.remove(items,i)end end end}
 end
 return a
end
local listeners={}
ProjectYakuza={getPlayerStyle=function(p)return p.style end,isEquipped=function(p)return p.active end,stateFor=function(p)return p.state end,
 isStyleToken=function(w)return w and w.token==true end,on=function(name,fn)listeners[name]=fn end}
instanceof=function(v,kind)return v.kind==kind end
do local _="ProjectYakuzaFixture:WORLD" end
do local _="ProjectYakuzaFixture:BLOOD" end
do local _="ProjectYakuzaFixture:HITS" end
local PY=ProjectYakuza;local B=PY.BloodEffects;local F=PY.HitEffects
local p,z=actor(),actor('IsoZombie');local weapon={token=true}
F.onHit(p,z,weapon,0)
check(#B.bursts==0,'no blood on non-damaging hit')
F.onHit(p,z,{token=false},1)
check(#B.bursts==0,'unrelated weapon cannot create blood')
F.onHit(p,z,weapon,1)
check(#B.bursts==1 and #F.bursts==1,'actual confirmed-hit path produces sparks and blood')
F.onHit(p,z,weapon,1)
check(#B.bursts==1,'same victim and swing is deduplicated')
F.clear(p)
check(#B.bursts==0 and #F.bursts==0 and not B.hooked,'shared visual cleanup releases blood')
local initialAttaches=attaches
B.spawn(p,z,false,false);B.render()
local b=B.bursts[1];local first=b.instance;local before=allocated
check(b.frame==0 and renders[#renders].path:find('Blood_splash_0.png',1,true),'first atlas frame selected')
check(attaches==initialAttaches and b.instance.speed==0,'blood uses detached world render without native attachments')
check(not renders[#renders].additive and additive,'blood uses normal transparency and restores blending')
B.render();check(allocated==before and b.instance==first,'same timestamp never reallocates a frame')
for frame=1,15 do
 clock=1000+frame*25;B.render()
 check(b.frame==frame and renders[#renders].path:find('Blood_splash_'..frame..'.png',1,true),'clock selects source frame '..frame)
end
clock=1400;B.update()
check(#B.bursts==0 and not B.hooked and not Events.OnTick[B.update] and not Events.OnPostRender[B.render],'complete one-shot removes both hooks')
B.spawn(p,z,false,false);paused=true;clock=2400;B.update()
check(B.bursts[1].age==0 and B.bursts[1].frame==0,'pause does not advance blood')
paused=false;clock=2425;B.update();check(B.bursts[1].frame==1,'resume advances only unpaused time')
B.clear()
z.floor=true;B.spawn(p,z,true,true);B.render();b=B.bursts[1]
check(b.height==10 and math.abs(b.scale-.486)<.00001,'grounded blood uses low anchor and charged scale')
B.clear();z.floor=false
for facing=1,8 do
 z.offsetX=facing*19;z.offsetY=-facing*13;z.x=10+facing;z.y=12-facing
 B.spawn(p,z,false,false);B.render();local draw=renders[#renders]
 check(draw.x==z.x and draw.y==z.y and draw.dx==0,'world centre tracks victim in facing '..facing)
 check(math.abs(draw.dy-(52-128*.36/2))<.00001,'world height remains consistent in facing '..facing)
 B.clear()
end
p.localPlayer=false;F.spawn(p,z,true)
check(#B.bursts==1,'MP confirmed observer presentation produces blood')
F.clear()
p.style={hitEffects='yakuza6'};B.spawn(p,z,false,false)
check(#B.bursts==0,'other styles require explicit blood opt-in')
p.style={hitEffects='yakuza6',bloodEffects='yakuza6'};p.md.ProjectYakuzaHitEffectsDisabled=true;B.spawn(p,z,false,false)
check(#B.bursts==0,'existing hit effect toggle suppresses blood')
p.md.ProjectYakuzaHitEffectsDisabled=nil
for i=1,20 do B.spawn(p,z,false,false)end
check(#B.bursts==4,'per-player effects remain bounded')
B.clear()
for i=1,40 do B.spawn(actor(),z,false,false)end
check(#B.bursts==16,'global multiplayer effects remain bounded')
B.clear();check(sprites<=32,'original frame sprites are cached')
B.spawn(p,z,false,false);p.active=false;B.update()
check(#B.bursts==0,'style unequip removes blood')
p.active=true;B.spawn(p,z,false,false);p.dead=true;B.update()
check(#B.bursts==0,'owner death removes blood')
p.dead=false;B.spawn(p,z,false,false);z.fail=true
local ok=pcall(B.render)
check(not ok and additive and #B.bursts==0 and not B.hooked,'render failure restores blend and disposes instances')
z.fail=false
check(allocated==disposed,'every allocated instance was released')
F.clear();p.active=true;p.localPlayer=true;p.md.ProjectYakuzaHitEffectsDisabled=nil;p.style={hitEffects='yakuza6',bloodEffects='yakuza6'}
p.x=10;p.y=12;z.x=11;z.y=12;z.floor=false
local attachedBefore=attaches
F.spawn(p,z,true,false)
check(#F.bursts==1 and #F.bursts[1].emitters==6,'strong hit adds one bounded supplied shock ring')
check(attaches==attachedBefore,'spark and shock sprites never mutate native attachment offsets')
clock=clock+100;renders={};F.render()
local foundRing=false
for _,r in ipairs(renders)do
 if r.path:find('EncounterShock',1,true) then foundRing=true;check(r.alpha<=.20 and not r.additive,'heavy ring stays subtle with normal alpha') end
end
check(foundRing and additive,'strong ring uses supplied texture and restores additive state')
F.clear();local bloodBefore=#B.bursts
F.guard(p,z)
check(#F.bursts==1 and F.bursts[1].victim==p and F.bursts[1].guard,'guard sparks follow defender instead of attacker')
check(#B.bursts==bloodBefore,'successful guard never emits blood')
check(#F.bursts[1].emitters==5 and F.bursts[1].life==180,'guard flash is small and short-lived')
clock=clock+90;F.render();check(additive,'guard drawing restores renderer state')
clock=clock+91;F.update();check(#F.bursts==0 and not F.ticking,'guard burst expires and removes idle hooks')
F.spawn(p,z,true,true);z.fail=true
local renderOK=pcall(F.render);check(not renderOK and additive and #F.bursts==0,'impact render failure cleans sprites and restores global blend state');z.fail=false
F.clear()

local baselineScale=.18*Core.getTileScale()
for _,family in ipairs({'unarmed','blunt','blade'})do
 p.style.impactFeedback=family
 F.spawn(p,z,false,false)
 local burst=F.bursts[1];local blood=B.bursts[1]
 check(burst.family==family,'impact captures family '..family)
 check(#burst.emitters==({unarmed=5,blunt=7,blade=3})[family],'family particle budget '..family)
 check(math.abs(blood.scale-baselineScale*({unarmed=1,blunt=.85,blade=1.15})[family])<.000001,'family blood size '..family)
 check(blood.life==(family=='blade'and 360 or 400),'blood timing '..family)
 p.style.impactFeedback='unarmed'
 clock=clock+50;renders={};F.render()
 check(burst.family==family,'active effect does not switch family after equipment change')
 local color=renders[#renders].color
 check(color.a==1 and not renders[#renders].additive,'family uses ordinary alpha and complete tint '..family)
 F.clear()
end
p.style.impactFeedback='blade';F.spawn(p,z,true,false)
check(#F.bursts[1].emitters==3 and F.bursts[1].life==240,'heavy blade avoids a blunt shock ring')
clock=clock+180;F.update();B.update();check(#F.bursts==1 and B.bursts[1].frame==8,'blade blood and strong sparks animate independently')
clock=clock+180;F.update();B.update();check(#B.bursts==0 and #F.bursts==0,'blade one-shots expire and detach')
p.style.impactFeedback='blunt';F.spawn(p,z,true,false)
check(#F.bursts[1].emitters==8,'heavy blunt adds one shock ring');F.clear()
p.style.impactFeedback='unarmed';F.spawn(p,z,false,false,false,'blade')
check(F.bursts[1].family=='blade'and B.bursts[1].life==360,'authoritative MP family overrides current equipment');F.clear()
p.style.impactFeedback='blade';F.spawn(p,z,false,false,false,false)
check(F.bursts[1].family=='unarmed','explicit legacy override remains unarmed');F.clear()
p.style.impactFeedback='blunt';F.guard(p,z)
check(#F.bursts[1].emitters==5 and #B.bursts==0,'weapon family does not change guard feedback');F.clear()
for facing=1,8 do
 p.x=10+math.cos(facing*math.pi/4);p.y=12+math.sin(facing*math.pi/4)
 z.offsetX=facing*13;z.offsetY=-facing*17;F.spawn(p,z,false,false)
 clock=clock+50;renders={};F.render()
 for _,r in ipairs(renders)do check(r.actor==z and r.x==z.x and r.y==z.y,'weapon impacts stay on victim in every facing')end
 F.clear()
end
check(not F.ticking and not B.hooked and allocated==disposed,'all family effects release their instances and idle hooks')
for facing=1,8 do
 local anchor={x=15+facing/10,y=19-facing/10,z=.63};F.spawn(p,z,true,false,false,'unarmed',anchor)
 anchor.x=-999;anchor.y=-999;anchor.z=-999
 clock=clock+50;renders={};F.render();B.render()
 check(#renders>1,'anchored Heat Action renders impact and blood')
 for _,r in ipairs(renders)do check(r.x==15+facing/10 and r.y==19-facing/10 and r.z==.63,'impact and blood use copied physical contact without root offsets')end
 F.clear()
end
check(allocated==disposed,'anchored instances release on interruption')


do
 p.style.impactFeedback='unarmed';local signatures={};local randomCalls=0;local previousRandom=ZombRand
 ZombRand=function()randomCalls=randomCalls+1;error('visual variation must not consume gameplay randomness')end
 for i=1,4 do
  F.spawn(p,z,false,false);local burst=F.bursts[1];local particle=burst.emitters[2]
  signatures[i]={particle.point.dx,particle.point.dy,particle.scale,particle.life}
  check(math.abs(particle.point.dx)<30 and math.abs(particle.point.dy)<30 and particle.life>=.78 and particle.life<=1,'varied sparks keep bounded spread and lifetime')
  clock=clock+60;renders={};F.render();local before={}
  for j,r in ipairs(renders)do before[j]={r.dx,r.dy,r.alpha}end
  paused=true;clock=clock+1000;renders={};F.render();paused=false
  for j,r in ipairs(renders)do check(r.dx==before[j][1]and r.dy==before[j][2]and r.alpha==before[j][3],'varied trajectories freeze completely while paused')end
  F.clear()
 end
 for i=2,#signatures do check(signatures[i][1]~=signatures[i-1][1]and signatures[i][3]~=signatures[i-1][3],'repeated same-place hits choose distinct trajectories and scale')end
 check(randomCalls==0,'visual noise leaves gameplay RNG untouched');ZombRand=previousRandom
 check(allocated==disposed and not F.ticking,'varied hit effects retain bounded cleanup')
end
return true,'PASS '..checks..' source-frame blood animation, confirmed hit, world anchor, MP budgets and cleanup checks'
