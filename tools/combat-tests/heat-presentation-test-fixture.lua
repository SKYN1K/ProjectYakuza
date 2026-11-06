local C=PY.HeatActionPresentation;local D=PY.HeatPresentationData
Events.OnPostRender=event()
local activeStyle={id='presentation',sounds={heavyImpact='impact',punchImpact='punch',kickImpact='kick',throwImpact='fall'}}
PY.getPlayerStyle=function()return activeStyle end;PY.getStyle=function()return activeStyle end
PY.isEquipped=function(a)return a.equipped~=false end
local plays,fx,emitted={},{},0
local file;for name in pairs(D.leads)do file=name;break end
local lead=D.leads[file]
GameSounds={getSound=function(name)return {getRandomClip=function()return {name=name,getFile=function()return file end}end}end}
getWorld=function()return {getFreeEmitter=function(_,x,y,z)
 local emitter={x=x,y=y,z=z}
 function emitter:playClip(clip,a)local id=#plays+1;plays[id]={time=phase*1000,name=clip.name,actor=a,emitter=self};return id end
 function emitter:setVolume(id,gain)plays[id].gain=gain end
 function emitter:isPlaying(id)return not plays[id].stopped end
 function emitter:stopSound(id)plays[id].stopped=true end
 return emitter
end}end
PY.AttackEffects.project=function(x,y,z,angle,tile)return 0,0,x*math.cos(angle)-z*math.sin(angle),x*math.sin(angle)+z*math.cos(angle),y end
PY.HitEffects.spawn=function(a,v,strong,charged,ground,feedback,anchor)fx[#fx+1]={time=phase*1000,anchor=anchor,feedback=feedback}end
PY.emit=function(name)if name=='heatRushHit'then emitted=emitted+1 end end
function p:getAnimAngleRadians()return self.angle or 0 end
p.dead=false;p.equipped=true;z.dead=false;paused=false;weight=1
local function step(ms)phase=ms/1000;clock=clock+16;C.tick()end
local total=0;local move,source
for animation,data in pairs(D.moves)do
 move={animation=animation,contacts={}}
 for i,meta in ipairs(data.contacts)do move.contacts[meta.index]={atMs=meta.atMs,cue=meta.cue,layers={'heavyImpact'}}end
 for _,meta in ipairs(data.contacts)do
  C.clearAll();plays={};fx={};source={};phase=0;C.start(p,z,move,source);C.tick()
  C.start(p,z,move,source);check(C.states[p].source==source,'MP snapshots preserve presentation session')
  local at=meta.atMs
  step(math.max(0,at-160))
  step(math.max(0,at-lead));local matched=false;for _,play in ipairs(plays)do if math.abs(play.time-math.max(0,at-lead))<.001 then matched=true end end
  check(matched,'source transient preroll follows live phase at its measured lead')
  local fbefore=#fx;step(at);check(#fx==fbefore+1,'one effect at physical contact')
  check(fx[#fx].anchor~=nil,'all built-in contacts have a sampled native victim anchor')
  local count=#fx;step(at+1);check(#fx==count,'contact cannot duplicate on next render')
  H.present(p,z,move,meta.index,true);check(#fx==count,'damage/network echo cannot replay presentation')
  total=total+1
 end
end
check(total==30,'all enabled main and failure-ending physical impacts covered')
C.clearAll();move={animation='Custom',contacts={{atMs=500,cue='punchImpact',layers={'kickImpact'}}}};source={};plays={};fx={};phase=0;C.start(p,z,move,source);step(500-lead)
check(#plays==2 and plays[1].gain==.55 and plays[2].gain==.3,'custom styles retain primary and layered sound gains')
step(500);check(#fx==1 and fx[1].anchor==nil,'custom action without numeric sample retains legacy placement')
local count=#plays;paused=true;step(600);check(#plays==count,'pause cannot emit sound');paused=false
C.stop(p,{});check(C.states[p]~=nil,'stale remote cleanup cannot end active action')
C.stop(p,source);check(not C.states[p]and plays[1].stopped and plays[2].stopped,'interruption stops session sounds and drops hooks')
phase=0;plays={};fx={};source={};C.start(p,z,move,source);step(850)
check(#plays==0 and #fx==0,'late render drops stale impacts instead of catch-up bursts')
C.stop(p,source,true)
phase=0;source={};C.start(p,z,move,source);step(400);clock=clock+2000;step(401);weight=0;clock=clock+100;C.tick()
check(C.states[p]~=nil,'missing-track grace starts from last observed track');weight=1
p.equipped=false;C.tick();check(not C.states[p],'unequip cleans controller');p.equipped=true
phase=0;source={};C.start(p,z,move,source);source.cleaned=true;C.tick();check(not C.states[p],'action cleanup cancels presentation')
for i=0,7 do p.angle=i*math.pi/4;local a=C.anchor(p,z,{.2,.7,-.3});check(math.abs(a.z-z:getZ()-.7)<.00001,'native height remains constant in all rotations');check(math.abs((a.x-z:getX())^2+(a.y-z:getY())^2-.13)<.00001,'world anchor rotates around victim')end
p.angle=0;C.clearAll();check(not C.hooked,'no idle render hook remains')
move={animation='Custom',contacts={{atMs=500,cue='punchImpact',qteIndex=1}}};source={qte={accepted={}}};phase=0;plays={};fx={};C.start(p,z,move,source);step(500)
check(#plays==0 and #fx==0,'unaccepted custom QTE contact cannot present')
C.clearAll();source.qte.accepted[1]=true;phase=0;C.start(p,z,move,source);step(500-lead);step(500)
check(#plays==1 and #fx==1,'accepted custom QTE keeps its authored contact')
C.clearAll();local ending;for name in pairs(D.moves)do if name:find('Fail')then ending=name;break end end
check(ending~=nil,'original paired failure data present')
move={animation='Custom',contacts={{atMs=500,cue='kickImpact'}},qteFailure={paired=true,animation=ending,contactMs=D.moves[ending].contacts[1].atMs}};source={failed=true};phase=0;plays={};fx={};C.start(p,z,move,source);step(0)
check(C.states[p].clip==ending,'paired failure switches to its own animation clock')
C.clearAll();move={animation='Custom',contacts={{atMs=500,cue='punchImpact'}}};source={};phase=0;plays={};fx={}
local localMethod=p.isLocalPlayer;p.isLocalPlayer=function()return false end;C.start(p,z,move,source);step(500-lead);step(500)
check(#plays==1 and #fx==1,'observer reconstructs presentation without owner-only sound packets');p.isLocalPlayer=localMethod
C.stop(p,source,true);check(not plays[1].stopped,'natural completion preserves current impact tail')
local katana=PY.Weapons.views.dragon_of_dojima.blade.actions.heatAction
check(#katana.contacts==3 and katana.contacts[4]==nil,'katana has exactly three damaging contacts')
for i=1,3 do check(katana.contacts[i].damageMultiplier==.5,'katana splits unchanged total damage evenly across three hits')end
check(#D.moves[katana.animation].contacts==3,'katana numeric timeline contains only three presented contacts')
plays={};fx={};local eventCount=emitted;H.present(p,z,katana,4,true,true,{x=0,y=0,z=1})
check(#plays==0 and #fx==0 and emitted==eventCount,'removed fourth katana contact cannot present sounds, effects or voices')
C.clearAll()
return true,'PASS '..checks..' paired Heat Action timing, 30 native contact anchors, three damaging katana strikes, clip lead-ins, custom layers, replay suppression, rotation and lifecycle checks'
