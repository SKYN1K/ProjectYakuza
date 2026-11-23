require=function()end
local checks=0;local function check(v,message)checks=checks+1;assert(v,message)end
local function near(a,b)return math.abs(a-b)<.001 end
local clock=1000;getTimestampMs=function()return clock end
local function event()local e={hooks={}};function e.Add(fn)e.hooks[fn]=true end;function e.Remove(fn)e.hooks[fn]=nil end;return e end
Events={OnTick=event(),OnPreUIDraw=event(),OnRenderTick=event(),OnSave=event(),OnMainMenuEnter=event()}
local callback
ProjectYakuza={on=function(name,fn)check(name=='heatRushHit','only confirmed Heat Action contacts drive the screen treatment');callback=fn end}
local PY=ProjectYakuza
local style={hitEffects='yakuza6'};local equipped=true;local paused=false;local players=1;local zoom=1
PY.getPlayerStyle=function()return style end;PY.isEquipped=function()return equipped end
getNumActivePlayers=function()return players end;isGamePaused=function()return paused end;getCore=function()return {getZoom=function()return zoom end}end
local p={localPlayer=true,index=0,dead=false,md={}}
function p:isLocalPlayer()return self.localPlayer end;function p:getPlayerNum()return self.index end;function p:isDead()return self.dead end;function p:getModData()return self.md end
PY.HeatActionPresentation={states={[p]={}}}
local x,y,rightX,rightY=125,-270,13.5,-7.25
IsoCamera={getOffX=function()return x+rightX end,getOffY=function()return y+rightY end,getRightClickOffX=function()return rightX end,getRightClickOffY=function()return rightY end,setOffX=function(v)x=v end,setOffY=function(v)y=v end}
local draws={};local additive=true;local failed=false
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end,renderRect=function(_,sx,sy,w,h,r,g,b,a)if failed then error('injected renderer failure')end;draws[#draws+1]={x=sx,y=sy,w=w,h=h,r=r,g=g,b=b,a=a,additive=additive}end}}
local width,height=1920,1080
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end;getPlayerScreenWidth=function()return width end;getPlayerScreenHeight=function()return height end
getTexture=function()error('screen treatment must never load a texture or spawn a glint')end
do local _="ProjectYakuzaFixture:HEATSCREEN" end
local F=PY.HeatScreenEffects;local victim={}
for _,size in ipairs({{1024,768},{1280,720},{1920,1080},{3440,1440}})do
 width,height=size[1],size[2]
 for _,scale in ipairs({.5,1,1.5,2.5})do
  zoom=scale
  for _,contact in ipairs({{strong=false},{strong=true},{strong=true,charged=true},{sumQTE=true}})do
   F.stop();clock=clock+1000;callback(p,victim,2,contact)
   check(F.state and Events.OnTick.hooks[F.update]and Events.OnPreUIDraw.hooks[F.draw]and Events.OnRenderTick.hooks[F.restoreCamera],'registered callbacks apply before the world and restore after it')
   local peak=F.state.strength
   for age=0,650,10 do
    local baseX,baseY=x,y;local count=#draws;clock=F.state and F.state.at+age or clock+10
    F.update()
    check(math.abs(x-baseX)<=peak*5*zoom+.51 and math.abs(y-baseY)<=peak*3.5*zoom+.51,'shake is bounded by zoom and contact strength')
    F.draw()
    check(near(x,baseX)and near(y,baseY),'pre-UI drawing restores the original camera including aiming offset')
    check(additive,'renderer blend mode is restored after tint')
    if #draws>count then local draw=draws[#draws];check(#draws==count+1 and draw.w==width and draw.h==height and draw.x==0 and draw.y==0 and not draw.additive,'one non-additive rectangle covers the current viewport');check(draw.a>0 and draw.a<=.12 and draw.b>draw.r,'tint is cool, translucent and bounded')end
   end
   check(not F.state and not F.hooked and not Events.OnTick.hooks[F.update],'completed contact removes its per-frame hooks')
  end
 end
end
zoom=1;callback(p,victim,1,{sumQTE=true});F.update();x=900;F.restoreCamera();check(x==900,'restoration preserves another camera writer instead of replacing its new position');F.stop()
local originalX,originalY=x,y
callback(p,victim,1,{sumQTE=true});F.update();F.restoreCamera();check(near(x,originalX)and near(y,originalY),'after-world fallback restores the camera when the UI is hidden');F.stop()
for _,set in ipairs({function(v)p.localPlayer=not v end,function(v)p.index=v and 1 or 0 end,function(v)p.dead=v end,function(v)equipped=not v end,function(v)paused=v end,function(v)players=v and 2 or 1 end,function(v)p.md.ProjectYakuzaHitEffectsDisabled=v end,function(v)ISWorldMap_instance=v and {isVisible=function()return true end}or nil end,function(v)PY.StyleSelector={setup=v and {}or nil}end})do
 set(true);callback(p,victim,1,{strong=true});check(not F.state,'remote actors, split screen, pause, death, map, menu and disabled effects do not shake or tint');set(false)
 callback(p,victim,1,{strong=true});check(F.state,'eligible local contact starts again');set(true);F.update();check(not F.state and not F.hooked,'losing eligibility stops and cleans up the screen effect');set(false)
end
callback(p,victim,1,{bloodOnly=true});check(not F.state,'blood-only secondary events cannot repeatedly flash the screen')
PY.HeatActionPresentation.states[p]=nil;callback(p,victim,1,{strong=true});check(not F.state,'ordinary grab strikes cannot trigger cinematic screen effects');PY.HeatActionPresentation.states[p]={}
callback(p,victim,1,{sumQTE=true});F.update();F.stop();check(not F.state and near(x,originalX)and near(y,originalY),'saving clears state and restores the camera')
callback(p,victim,1,{sumQTE=true});F.update();failed=true;local ok=pcall(F.draw);failed=false;check(not ok and additive and not F.state and not F.camera,'draw failure restores blending, camera and hooks')
do
 PY.HeatActionPresentation.states[p]={source={}};clock=clock+1000
 check(F.prepare(p,victim,1,{strong=true},120),'contact anticipation starts within its 120ms lead')
 local state=F.state;clock=clock+60;local _,envelope=F.sample();check(envelope>0 and envelope<.55,'tint and shake ramp before the impact')
 F.prepare(p,victim,1,{strong=true},60);check(state.hitAt==clock+60,'anticipation follows the current source track without restarting its state')
 F.hit(p,victim,1,{bloodOnly=true});check(not state.confirmed,'blood-only events cannot confirm an anticipating contact')
 clock=clock+60;F.hit(p,victim,1,{strong=true});check(F.state==state and state.confirmed and state.hitAt==clock,'actual contact confirms the existing lead-in without restarting it')
 clock=clock+300;check(F.sample()~=nil,'impact remains visible longer than the previous 250ms maximum')
 local _,old=F.sample();F.prepare(p,victim,2,{strong=true},80);local _,continuity=F.sample();check(continuity>=old-.001,'closely spaced contacts preserve the previous tail while the next lead-in starts')
 F.cancel(p,PY.HeatActionPresentation.states[p].source);check(not F.state,'cancelled unconfirmed contacts clear anticipation')
 F.hit(p,victim,2,{strong=true});F.cancel(p,PY.HeatActionPresentation.states[p].source);check(F.state and F.state.confirmed,'completed presentation keeps an already confirmed contact tail');F.stop()
end
return 'PASS '..checks..' tint coverage, bounded pre-world shake, aiming offsets, hook cleanup, local ownership and no-spark assertions'
