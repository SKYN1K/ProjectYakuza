require=function()end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local clock=1000;getTimestampMs=function()return clock end
local paused=false;isGamePaused=function()return paused end
local function event()local e={hooks={}};e.Add=function(fn)e.hooks[fn]=true end;e.Remove=function(fn)e.hooks[fn]=nil end;return e end
Events={OnRenderTick=event(),OnPreUIDraw=event(),OnPostUIDraw=event(),OnSave=event(),OnMainMenuEnter=event()}
ProjectYakuza={listeners={},on=function(name,fn)ProjectYakuza.listeners[name]=fn end,isEquipped=function(p)return p.equipped end}
ProjectYakuza.getPlayerStyle=function()return {hitEffects="yakuza6"}end
local p={data={},equipped=true,localPlayer=true}
function p:isLocalPlayer()return self.localPlayer end;function p:getPlayerNum()return 0 end;function p:isDead()return self.dead end;function p:getModData()return self.data end
local z={getX=function()return 1 end,getY=function()return 2 end,getZ=function()return 0 end}
local rawX,rawY,rightX,rightY=100.2,200.3,23.5,-10.4
local function trunc(v)return v<0 and math.ceil(v)or math.floor(v)end
IsoCamera={getOffX=function()return trunc(rawX+rightX)end,getOffY=function()return trunc(rawY+rightY)end,getRightClickOffX=function()return rightX end,getRightClickOffY=function()return rightY end,setOffX=function(v)rawX=v end,setOffY=function(v)rawY=v end}
local zoom=1;getCore=function()return {getZoom=function()return zoom end}end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end;getPlayerScreenWidth=function()return 1280 end;getPlayerScreenHeight=function()return 720 end
IsoUtils={XToScreenExact=function(x,y,z)return(x-y)*64-IsoCamera.getOffX()end,YToScreenExact=function(x,y,z)return(x+y)*32-z*192-IsoCamera.getOffY()end}
local additive=true;local calls=0;local fail=false
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end,renderRect=function(_,x,y,w,h,r,g,b,a)check(a>=0 and a<=.035,'grade pulse is restrained');calls=calls+1 end,renderPoly=function()if fail then error('expected overlay error')end;calls=calls+1 end}}
getTexture=function()return {isReady=function()return true end}end

do local _="ProjectYakuzaFixture:SCREENFX" end
local F=ProjectYakuza.HeatScreenEffects;local hit=ProjectYakuza.listeners.heatRushHit
hit(p,z,13,{sumQTE=true});check(F.state and F.hooked,'confirmed impactful Heat Action contact owns a short local effect')
check(Events.OnPreRender==nil and Events.OnRenderTick.hooks[F.pre]and Events.OnPreUIDraw.hooks[F.draw],'Heat Action uses the registered render-tick hook when OnPreRender is absent')
hit(p,z,13,{sumQTE=true},{x=6,y=7,z=.2});check(F.state.x==6 and F.state.y==7 and F.state.z==.2,'RGB fringing uses the confirmed victim contact anchor, including floor contacts')
local baseX,baseY=IsoCamera.getOffX(),IsoCamera.getOffY();F.pre()
check(math.abs(IsoCamera.getOffX()-baseX)<=5 and math.abs(IsoCamera.getOffY()-baseY)<=4,'shake remains bounded with existing aim-pan offsets')
F.draw();check(calls==4 and additive,'one grade pulse and two source-image RGB fringes restore blend state')
F.restoreCamera();check(IsoCamera.getOffX()==baseX and IsoCamera.getOffY()==baseY,'visible camera offsets restore without adding aim-pan twice')
for i=1,50 do F.pre();F.restoreCamera()end
check(IsoCamera.getOffX()==baseX and IsoCamera.getOffY()==baseY,'repeated frames cannot accumulate camera drift')
F.pre();rawX=999;F.restoreCamera();check(rawX==999,'a foreign camera update is never overwritten')
paused=true;F.pre();check(not F.state and not F.camera and not F.hooked,'pause clears camera ownership and render hooks');paused=false
check(not Events.OnRenderTick.hooks[F.pre]and not Events.OnPreUIDraw.hooks[F.draw]and not Events.OnPostUIDraw.hooks[F.restoreCamera],'all supported event hooks release together')
hit(p,z,2,{charged=true,strong=false});clock=clock+201;F.pre();check(not F.hooked,'short impacts remove idle hooks after expiry')
p.localPlayer=false;hit(p,z,1,{strong=true});check(not F.state,'remote players cannot shake the local camera');p.localPlayer=true
p.data.ProjectYakuzaHitEffectsDisabled=true;hit(p,z,1,{strong=true});check(not F.state,'existing effect toggle disables screen impacts');p.data.ProjectYakuzaHitEffectsDisabled=nil
hit(p,z,1,{strong=true});ISWorldMap_instance={isVisible=function()return true end};F.draw();check(not F.state and not F.camera,'map opening releases impact effects');ISWorldMap_instance=nil
hit(p,z,1,{strong=true});F.pre();fail=true;local ok=pcall(F.draw);check(not ok and additive and not F.state and not F.camera,'overlay errors restore camera, blend and hooks');fail=false
return 'PASS '..checks..' local Heat Action grading/fringing, bounded shake, aim-pan restoration, ownership, pause, map, expiry and error cleanup checks'
