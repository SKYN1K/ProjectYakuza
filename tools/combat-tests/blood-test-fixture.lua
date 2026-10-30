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
return true,'PASS '..checks..' source-frame blood animation, confirmed hit, world anchor, MP budgets and cleanup checks'
