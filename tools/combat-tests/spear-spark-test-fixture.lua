local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function event()return {Add=function()end,Remove=function()end}end
Events={OnTick=event(),OnPostRender=event(),OnGameStart=event(),OnMainMenuEnter=event()}
require=function()end
local now=0
local paused=false
getTimestampMs=function()return now end
isGamePaused=function()return paused end
Core={getTileScale=function()return 2 end}
IsoDirections={N=0}
ColorInfo={new=function(...)return {...}end}
local disposed,returned,draws=0,0,0
IsoSprite={CreateSprite=function()return {LoadFramesNoDirPageSimple=function(self,path)self.path=path end}end}
IsoSpriteInstance={get=function(sprite)return {setFrameSpeedPerFrame=function()end,setScale=function()end,SetAlpha=function()end,SetTargetAlpha=function()end,Dispose=function()disposed=disposed+1 end,render=function(self,owner,x,y,z)draws=draws+1;self.position={x,y,z}end}end,add=function()returned=returned+1 end}
SpriteRenderer={instance={additive=true,getDoAdditive=function(self)return self.additive end,setDoAdditive=function(self,value)self.additive=value end}}
local localPlayers={}
local remotePlayers={}
getNumActivePlayers=function()return #localPlayers end
getSpecificPlayer=function(i)return localPlayers[i+1]end
getOnlinePlayers=function()return {size=function()return #remotePlayers end,get=function(self,i)return remotePlayers[i+1]end}end
local function player(id,clip)
 local p={id=id,clip=clip,time=0,x=10,y=20,z=0,angle=0,emoting=true,weight=1}
 function p:getVariableBoolean()return self.emoting end
 function p:isDead()return self.dead end
 function p:isHideWeaponModel()return self.hidden end
 function p:isHideEquippedHandR()return self.hidden end
 function p:getPrimaryHandItem()return self.item end
 p.item={getFullType=function()return id end}
 function p:dbgGetAnimTrackName(layer,slot)if layer==0 and slot==0 then return self.clip end end
 function p:dbgGetAnimTrackWeight()return self.weight end
 function p:dbgGetAnimTrackTime()return self.time end
 function p:getAnimAngleRadians()return self.angle end
 function p:getOnlineID()return 12 end
 function p:getX()return self.x end
 function p:getY()return self.y end
 function p:getZ()return self.z end
 return p
end
"ProjectYakuzaFixture:SPARK_SOURCE"
local F=ProjectYakuzaEmotes.SpearSparks
local impact=2.5
check(ProjectYakuzaEmotes.SpearSparkTime==impact,'last floor hit is source frame seventy-five')
local p=player('ProjectYakuza.LauKaLongSpear','main12_007_9')
localPlayers={p};remotePlayers={p};F.tick();check(#F.bursts==0,'no early effect')
for _,time in ipairs({.3,1,2,impact-.001})do p.time=time;F.tick();check(#F.bursts==0,'earlier motion and opening floor strike emit no sparks')end
p.time=impact;F.tick();check(#F.bursts==1 and #F.bursts[1].points==9,'exact contact emits one nine-spark ground burst')
check(F.sprite.path=='media/textures/ProjectYakuzaEmotes/e_f_0006_spark01.png','standalone source texture has no combat dependency')
F.tick();check(#F.bursts==1,'same player enumerated locally and online cannot duplicate')
p.time=impact-.1;F.tick();p.time=impact+.01;F.tick();check(#F.bursts==1,'animation-clock correction does not replay impact')
local b=F.bursts[1];local x,y,z=b.x,b.y,b.z;local contact=ProjectYakuzaEmotes.SpearContacts.main12_007_9
check(math.abs(x-(10-contact[3]*1.5))<.00001 and math.abs(y-(20-contact[1]*1.5))<.00001 and z==0,'actual contact point uses native facing and floor height')
p.x=50;p.y=60;F.render();check(b.x==x and b.y==y and draws==9 and SpriteRenderer.instance.additive,'sparks stay at original ground point and renderer state is restored')
ISWorldMap_instance={isVisible=function()return true end};local before=draws;F.render();check(draws==before,'map hides world sparks');ISWorldMap_instance=nil
now=100;paused=true;F.tick();check(b.age==0,'pause freezes burst age');paused=false;now=110;F.tick();check(b.age==10,'resume excludes paused interval')
now=400;F.tick();check(#F.bursts==0 and disposed==9 and returned==9 and not F.rendering,'expired particles return every instance and unhook render')
F.clear();p.time=0;F.observe(p);p.emoting=false;F.observe(p);p.time=impact+.1;F.observe(p);check(#F.bursts==0,'cancelled emote cannot produce a deferred timer burst');p.emoting=true
p.time=impact+1;F.observe(p);check(#F.bursts==0,'late remote observation does not play stale impact')
F.clear();p.time=impact+.01;F.observe(p);check(#F.bursts==1,'slightly late remote observation accepts current contact once')
F.clear();localPlayers={};local q=player('Base.SpearCrafted','ProjectYakuza_LauSpearGround');remotePlayers={q};F.tick();q.time=impact;F.tick();check(#F.bursts==1 and F.bursts[1].owner==q,'remote native spear uses its own contact and actual native track')
for id,clip in pairs(ProjectYakuzaEmotes.SpearClips)do
 F.clear();local actor=player(id,clip);actor.time=impact-.01;F.observe(actor);actor.time=impact;F.observe(actor);check(#F.bursts==1,'every calibrated spear contact is supported '..id)
end
F.clear();q.time=impact;q.clip='ProjectYakuza_MajimaBatPoint';F.observe(q);check(#F.bursts==0,'other emotes do not emit spear sparks')
q.clip='ProjectYakuza_LauSpearGround';q.hidden=true;F.observe(q);check(#F.bursts==0,'hidden weapon does not emit');q.hidden=false;q.weight=.01;F.observe(q);check(#F.bursts==0,'faded-out native tracks do not emit');q.weight=1
for i=1,10 do F.spawn(q,ProjectYakuzaEmotes.SpearContacts[q.clip])end
check(#F.bursts==8,'particle bursts are bounded')
q.dead=true;now=now+1;F.tick();check(#F.bursts==0,'dead actor releases particles')
F.clear();check(disposed==returned,'all acquired instances are returned')
return true,'PASS '..checks..' standalone spear spark checks: native contact clock, once-only local/remote playback, all source contacts, anchor projection, map, pause, cancellation, limits and disposal'
