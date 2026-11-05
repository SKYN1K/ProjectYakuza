require=function()end
local checks=0
local function check(v,s)checks=checks+1;assert(v,s)end
local function near(a,b)return math.abs(a-b)<.000001 end
local clock,paused,text=1000,false,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
isClient=function()return false end
local function event()return {Add=function()end,Remove=function()end}end
Events={OnPlayerUpdate=event(),OnTick=event(),OnGameStart=event(),OnSave=event(),OnMainMenuEnter=event(),OnKeyStartPressed=event(),OnKeyKeepPressed=event(),OnKeyPressed=event(),OnPostRender=event()}
local keys={}
isKeyDown=function(k)return keys[k]==true end
isMouseButtonDown=function()return false end
KeybindId={SHOUT='Shout'}
getCore=function()return {isDoingTextEntry=function()return text end,isKey=function(self,id,key)return id=='Shout' and key==16 end}end
local base={}
function base:derive()local c={};c.__index=c;setmetatable(c,{__index=self});return c end
function base.new(class,p)return setmetatable({character=p},class)end
function base:setActionAnim(anim)self.character:setVariable('PerformingAction',anim)end
function base:forceStop()self.stopped=true;self:stop()end
function base:forceComplete()self.completed=true;self:perform()end
function base.perform()end
function base.stop()end
ISBaseTimedAction=base
local queueFail=false
ISTimedActionQueue={add=function(a)if queueFail then return nil end;return {current=a}end}
do local _="ProjectYakuzaFixture:BINDINGS" end
do local _="ProjectYakuzaFixture:REGISTRY" end
local ProjectYakuza=ProjectYakuza
do local _="ProjectYakuzaFixture:STYLE" end
local p={vars={},data={ProjectYakuzaStyle='dragon_of_dojima',ProjectYakuzaHeat=0},block=false,ignore=false,deferred=true,aim=true,x=10,y=12,localPlayer=true}
function p:getModData()return self.data end
function p:GetVariable(k)return self.vars[k]end
function p:setVariable(k,v)self.vars[k]=v end
function p:isDead()return self.dead or false end
function p:isOnFloor()return false end
function p:isKnockedDown()return false end
function p:isClimbing()return false end
function p:isAsleep()return false end
function p:isDraggingCorpse()return false end
function p:getHitReaction()return self.hit or '' end
function p:getVehicle()return self.vehicle end
function p:isAiming()return self.aim end
function p:isBlockMovement()return self.block end
function p:setBlockMovement(v)self.block=v end
function p:getIgnoreMovement()return self.ignore end
function p:setIgnoreMovement(v)self.ignore=v end
function p:isDeferredMovementEnabled()return self.deferred end
function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:getX()return self.x end
function p:getY()return self.y end
function p:getZ()return 0 end
function p:getMovementLastFrame()return {set=function()end}end
function p:setMoving(v)self.moving=v end
function p:setRunning(v)self.running=v end
function p:setSprinting(v)self.sprinting=v end
local heldItem={}
function p:getPrimaryHandItem()return self.held or heldItem end
function p:isLocalPlayer()return self.localPlayer end
function p:getOffsetX()return 0 end
function p:getOffsetY()return 0 end
local equipped,extreme=true,false
ProjectYakuza.isEquipped=function()return equipped end
ProjectYakuza.isBusy=function(p)return ProjectYakuza.activeActions[p]~=nil end
ProjectYakuza.resetPlayer=function()end
ProjectYakuza.Defense={ready=function(p)return p.aim and equipped and not paused and not ProjectYakuza.isBusy(p) and not p.vehicle and not p.dead end,
 snapActor=function(p,x,y)p.x=x;p.y=y end}
ProjectYakuza.Heat={stockSize=function()return 100/6 end,isExtreme=function()return extreme end,enabled=function()return true end,
 stocks=function(p)return math.floor(ProjectYakuza.getHeat(p)/(100/6))end,display=function(p)return extreme and 80 or ProjectYakuza.getHeat(p)end}
getSpecificPlayer=function()return p end
local vanilla={0,0,0}
ISEmoteRadialMenu={onKeyPressed=function()vanilla[1]=vanilla[1]+1 end,onKeyRepeat=function()vanilla[2]=vanilla[2]+1 end,onKeyReleased=function()vanilla[3]=vanilla[3]+1 end}
local reactionCalls=0
ProjectYakuza.TauntReactions={react=function()reactionCalls=reactionCalls+1 end}
do local _="ProjectYakuzaFixture:TAUNTS" end
local T=ProjectYakuza.Taunts
local starts,ends=0,0
ProjectYakuza.on('tauntStarted',function()starts=starts+1 end)
ProjectYakuza.on('tauntStopped',function()ends=ends+1 end)
local function begin()
 check(T.request(p),'taunt request accepted')
 local a=ProjectYakuza.activeActions[p].timedAction
 a.action={setOverrideHandModelsObject=function()end};a:start()
 return a
end
local a=begin()
check(p.block and p.ignore and not p.deferred,'movement flags locked')
check(a.stopOnWalk==false and a.stopOnRun==false and a.stopOnAim==false,'movement and aim release cannot interrupt')
check(starts==1 and ProjectYakuza.getHeat(p)==0,'one start event; no early heat')
check(not T.request(p),'cannot queue while busy')
p.x=20;p.y=22;p.moving=true;p.running=true;p.sprinting=true;T.holdPositions()
check(p.x==10 and p.y==12 and not p.moving and not p.running and not p.sprinting,'anchor clears sliding')
p.aim=false;p:setVariable('ProjectYakuzaTaunt','started');a:update();check(a:isValid(),'aim release preserves committed taunt')
clock=clock+2000;a:update();check(ProjectYakuza.getHeat(p)==0,'incomplete playback grants nothing')
p:setVariable('ProjectYakuzaTaunt','done');a:update()
check(near(ProjectYakuza.getHeat(p),100/6),'full playback grants exactly one orb')
check(reactionCalls==1,'SP taunt draws attention only after native completion')
check(not p.block and not p.ignore and p.deferred and not ProjectYakuza.activeActions[p],'flags and ownership restored')
a:perform();a:cleanup(true);check(near(ProjectYakuza.getHeat(p),100/6) and ends==1,'completion cannot double reward')
p.aim=true;a=begin();p.hit='Bite';a:update();p.hit=''
check(a.stopped and near(ProjectYakuza.getHeat(p),100/6),'damage interrupts without reward')
check(reactionCalls==1,'interrupted taunt cannot draw attention')
local reward=ProjectYakuza.getHeat(p);a=begin();p.held={};a:update();p.held=nil
check(a.stopped and ProjectYakuza.getHeat(p)==reward and reactionCalls==1,'changing held equipment interrupts taunt before heat/attention')
a=begin();p.block=true;p.ignore=true;p.deferred=false;a:stop();check(not p.block and not p.ignore and p.deferred,'cancel restores captured flags')
local heat=ProjectYakuza.getHeat(p);a=begin();clock=clock+601;a:update();check(a.stopped and ProjectYakuza.getHeat(p)==heat,'missing animation marker fails closed')
a=begin();p:setVariable('ProjectYakuzaTaunt','started');a:update();local start=a.startedAt
paused=true;clock=clock+20000;a:update();check(a.startedAt==start+20000 and not a.stopped,'pause does not timeout');paused=false
clock=clock+6000;a:update();check(a.stopped and ProjectYakuza.getHeat(p)==heat,'clip timeout never rewards')
extreme=true;a=begin();p:setVariable('ProjectYakuzaTaunt','started');a:update();p:setVariable('ProjectYakuzaTaunt','done');a:update()
check(ProjectYakuza.getHeat(p)==heat,'Extreme Heat taunt grants no heat');extreme=false
ProjectYakuza.setHeat(p,99);a=begin();p:setVariable('ProjectYakuzaTaunt','started');a:update();p:setVariable('ProjectYakuzaTaunt','done');a:update();check(ProjectYakuza.getHeat(p)==100,'orb reward clamps at maximum')
a=begin();equipped=false;a:update();equipped=true;check(a.stopped,'unequipping cancels')
a=begin();T.clear();check(a.cleaned and not ProjectYakuza.activeActions[p] and not p.block,'world exit cleans up')
queueFail=true;check(not T.request(p) and not ProjectYakuza.activeActions[p],'rejected queue has no ownership');queueFail=false
T.bindInput();T.bindInput()
p.aim=false;ISEmoteRadialMenu.onKeyPressed(16);ISEmoteRadialMenu.onKeyRepeat(16);ISEmoteRadialMenu.onKeyReleased(16)
check(vanilla[1]==1 and vanilla[2]==1 and vanilla[3]==1,'un-aimed shout remains vanilla')
p.aim=true;keys[16]=true;ISEmoteRadialMenu.onKeyPressed(16);T.poll(p);check(ProjectYakuza.activeActions[p]~=nil,'aim + rebound shout key starts taunt')
p.aim=false;keys[16]=false;ISEmoteRadialMenu.onKeyRepeat(16);ISEmoteRadialMenu.onKeyReleased(16);T.poll(p)
check(vanilla[1]==1 and vanilla[2]==1 and vanilla[3]==1 and not T.consumed[16],'aim release cannot leak shout')
T.clear();p.aim=true;text=true;ISEmoteRadialMenu.onKeyPressed(16);check(not ProjectYakuza.activeActions[p] and vanilla[1]==2,'text entry does not trigger taunt');text=false
ISEmoteRadialMenu.onKeyPressed(99);check(vanilla[1]==3,'unrelated keys pass through')

local loads,draws,pooled,attached=0,0,0,0
local drawLog={}
local additive=false
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(self,v)additive=v end}}
Core={getTileScale=function()return 2 end};IsoDirections={N='N'};ColorInfo={new=function(r,g,b,a)
 local data={r=r,g=g,b=b,a=a}
 data.set=function(self,rr,gg,bb,aa)data.r=rr;data.g=gg;data.b=bb;data.a=aa;return self end
 return setmetatable({}, {__index=data,__newindex=function()error('native colour fields are not Lua-writable; use set()')end})
end}
instanceof=function()return true end
IsoSprite={CreateSprite=function()
 local s={};function s:LoadFramesNoDirPageDirect(path,kind,count)self.kind=kind;self.path=path;self.frameCount=count;check(((path=='media/textures/ProjectYakuza/HeatWisp' or path=='media/textures/ProjectYakuza/TauntAura') and count==32) or (path=='media/textures/ProjectYakuza/ExtremeHeat' and ((kind=='flame' or kind=='smoke') and count==64)),'only supplied current normal, taunt and Extreme Heat frames');loads=loads+1 end
 function s:LoadFramesNoDirPageSimple(path)self.path=path;self.kind=path:match("([^/]+)%.png$");self.frameCount=1;loads=loads+1 end
 function s:setAnimate(v)self.animate=v end
 function s:update(i)i.frames=i.frames+1 end
 return s
end}
IsoSpriteInstance={add=function()pooled=pooled+1 end}
ProjectYakuza.WorldEffects={attach=function(p,s,height,scale,anchor,loop,speed,x)
 attached=attached+1
 local i={frames=0,scale=scale,height=anchor,speed=speed,x=x}
 function i:setScale(x,y)self.scale=x end
 function i:getParentSprite()return s end
 function i:SetAlpha(v)self.alpha=v end
 function i:SetTargetAlpha(v)end
 function i:Dispose()self.disposed=true end
 function i:render(owner,x,y,z,dir,ox,oy,color)draws=draws+1;self.additive=additive;drawLog[#drawLog+1]={instance=self,kind=s.kind,additive=additive,alpha=self.alpha,color=color,dir=dir,ox=ox,oy=oy};if self.fail then error('render failure')end end
 return i
end}
function p:getAttachedAnimSprite()return {remove=function()end}end
ProjectYakuza.WorldEffects.detached=function(s,scale,speed)return ProjectYakuza.WorldEffects.attach(p,s,s.kind=='smoke' and 64 or 32,scale,0,true,speed,0)end
ProjectYakuza.WorldEffects.renderCentered=function(owner,i,height,scale,x,y,color)i:render(owner,owner:getX(),owner:getY(),owner:getZ(),IsoDirections.N,-x,-y-height*scale/2,color)end
function p:getPlayerNum()return 0 end
function p:isOutlineHighlight()return self.outline or false end
function p:getOutlineHighlightCol()return self.outlineColor or 0 end
function p:setOutlineHighlight(_,value)self.outline=value end
function p:setOutlineHighlightCol(_,r,g,b,a)self.outlineColor=math.floor(r*255)+math.floor(g*255)*256+math.floor(b*255)*65536+math.floor(a*255)*16777216 end
getPlayer=function()return p end
do local _="ProjectYakuzaFixture:OUTLINE" end
do local _="ProjectYakuzaFixture:CATALOG" end
do local _="ProjectYakuzaFixture:PROTOCOL" end
do local _="ProjectYakuzaFixture:AURA" end
local A=ProjectYakuza.HeatAura
for i,seconds in ipairs({.65,.73,.81,.59})do
 check(near(A.extremeLayout[i].speed,.55*64/(seconds*60)),'Extreme Heat flame playback is exactly 45 percent slower')
end
ProjectYakuza.setHeat(p,0);A.update(p);check(not A.states[p],'zero heat has no ordinary aura')
a=begin();check(not A.states[p],'taunt animation itself has no aura boost at zero heat')
p:setVariable('ProjectYakuzaTaunt','started');a:update();p:setVariable('ProjectYakuzaTaunt','done');a:update()
local s=A.states[p];check(s and #s.emitters==4 and s.flashing,'completion flash reuses only the four ordinary aura sprites')
clock=clock+130;A.render()
check(s.opacity>0 and s.profile=='normal' and not s.extreme,'brief flash keeps the normal aura profile')
check(not additive,'taunt has no additive brightness pulse')
check(s.emitters[1].instance.frames>0,'taunt leaves the existing earned heat aura moving beneath its distinct burst')
check(#A.flashes[p].emitters==6,'completion uses three original animated fire clouds and three smoke clouds')
for i,e in ipairs(A.flashes[p].emitters)do
 check(e.sprite.path=='media/textures/ProjectYakuza/ExtremeHeat'and e.sprite.frameCount==64 and e.instance.alpha<.5,'taunt uses original alpha-textured animation instead of opaque black-backed streaks')
 check(e.instance.scale>0 and e.instance.scale<4,'world particle sizes remain bounded')
end
check(near(A.tauntColor.r,.28)and near(A.tauntColor.g,.62),'taunt stays soft blue instead of pulsing white')
check(A.flashes[p].duration==450,'taunt burst finishes in 0.45 unpaused seconds')
for _,layout in ipairs({A.tauntLayout,A.entryLayout,A.activationLayout})do
 check(#layout==6,'each event burst has a fixed six-particle budget')
 for _,point in ipairs(layout)do check(not point.source and (point.kind=='flame'or point.kind=='smoke')and point.scale*point.frameHeight>=32 and point.alpha<=.48,'event bursts use broad transparent source clouds at restrained alpha')end
end

local count,alloc=loads,attached
for i=1,1000 do A.update(p);A.render()end
check(loads==count and attached==alloc,'stable aura never reallocates per frame')
local frames=A.flashes[p].emitters[1].instance.frames;local pulse=s.clock
paused=true;clock=clock+5000;A.render();check(s.clock==pulse and A.flashes[p].emitters[1].instance.frames==frames,'pause holds glow and sprites');paused=false
A.flashes[p].emitters[1].instance.fail=true;local ok=pcall(A.render);check(not ok and not additive,'flash render failure restores additive state');A.flashes[p].emitters[1].instance.fail=false
ProjectYakuza.setHeat(p,0);clock=clock+621;A.render()
check(not A.flashes[p] and not s.emitters[1].instance,'completion flash expires and zero-heat aura clears')
a=begin();a:stop();check(not A.flashes[p] and not s.emitters[1].instance,'interrupted taunt never flashes')
ProjectYakuza.setHeat(p,100/6);A.update(p);clock=clock+350;A.render();check(s.emitters[1].instance.scale==.5175,'normal aura original dimensions preserved')
local normalInstances={};local normalSprites={}
for i,e in ipairs(s.emitters) do normalInstances[i]=e.instance;normalSprites[i]=e.sprite end
local oldOpacity=s.opacity
extreme=true;A.update(p);drawLog={};clock=clock+350;A.render()
check(s.extreme and s.profile=='extreme' and #s.emitters==6,'Extreme Heat exclusively selects four original Y6 flame patches')
check(s.opacity==oldOpacity,'switching aura profile preserves completed fade without blinking')
for i,e in ipairs(s.emitters) do
 local point=A.extremeLayout[i];local normal=A.layout[i] or A.layout[1]
 check((not normalInstances[i] or normalInstances[i].disposed) and e.instance~=normalInstances[i],'normal emitter is released before Extreme Heat replacement')
 local width=point.kind=='flame' and 32 or 64
 check(point.frameHeight*point.scale<=256*normal.scale and width*point.scale<=128*normal.scale and (point.smoke and point.height<=8 or not point.smoke and point.height>=38),'new original particles fit within former upper-body patch size')
 check(e.sprite.path=='media/textures/ProjectYakuza/ExtremeHeat' and e.sprite~=normalSprites[i],'replacement never uses the old blurred HeatWisp sequences')
 check((point.kind=='flame' or point.kind=='smoke') and e.frames==64 and e.instance.frames==1,'all original flame/smoke frames advance exactly once')
 check(point.smoke or (64/(point.speed*60)<1.5 and 64/(point.speed*60)>1.0),'upper flames retain fast loops; smoke has its own slower playback')
end
check(#drawLog==6,'Extreme Heat renders four upper flames and two low smoke patches')
for _,draw in ipairs(drawLog) do
 for _,normal in ipairs(normalInstances) do check(draw.instance~=normal,'no normal-heat instance is drawn during Extreme Heat') end
 check(not draw.additive and draw.alpha<=.85 and draw.alpha>0,'black-backed original Y6 flames use scoped additive rendering at bounded opacity')
 check((draw.kind=='smoke' and draw.color==A.smokeColor or draw.kind=='flame' and draw.color==A.extremeColor and draw.color.r==.25 and draw.color.g==.15 and draw.color.b==1),'flames use a saturated blue tint instead of near-white exposure')
 check(draw.dir==IsoDirections.N,'all player facings share the same world renderer path')
end
check(not additive,'Extreme Heat does not change renderer blend state')
s.emitters[1].instance.fail=true;ok=pcall(A.render)
check(not ok and not additive,'failed Extreme Heat flame rendering restores the previous blend state')
s.emitters[1].instance.fail=false
local driftX,driftY=drawLog[1].ox,drawLog[1].oy
clock=clock+160;drawLog={};A.render()
check(drawLog[1].ox~=driftX or drawLog[1].oy~=driftY,'original static wisps move gently in world space')
local frozenX,frozenY=drawLog[1].ox,drawLog[1].oy
paused=true;clock=clock+5000;drawLog={};A.render();paused=false
check(drawLog[1].ox==frozenX and drawLog[1].oy==frozenY,'pausing freezes drift and breathing motion')
count=loads;alloc=attached;for i=1,1000 do A.update(p)end
check(loads==count and attached==alloc,'Extreme Heat reuses existing sprites without per-update allocations')
local extremeInstances={};for i,e in ipairs(s.emitters) do extremeInstances[i]=e.instance end
extreme=false;A.update(p);drawLog={};clock=clock+250;A.render()
check(s.profile=='normal' and not s.extreme and #drawLog==4,'ending mode restores only normal aura without a lingering Extreme Heat overlay')
for i,e in ipairs(s.emitters) do check(extremeInstances[i].disposed and e.sprite==normalSprites[i],'mode exit releases replacement and reuses cached normal sprite') end
check(loads==count and extremeInstances[5].disposed and extremeInstances[6].disposed and #s.emitters==4,'returning to normal releases low smoke and reloads no normal sequences')
p.data.ProjectYakuzaHeatAuraDisabled=true;A.flash(p);check(not A.flashes[p] and not s.emitters[1].instance and not A.rendering,'disabled aura cannot retain a delayed flash');p.data.ProjectYakuzaHeatAuraDisabled=nil
p.localPlayer=false;p:setVariable('ProjectYakuzaRemoteClip','ProjectYakuza_DD_Taunt01');ProjectYakuza.setHeat(p,0);A.update(p)
check(not s.emitters[1].instance,'remote taunt playback alone has no flash')
A.flash(p);check(s.flashing and s.emitters[1].instance,'replicated completion triggers observer flash')
clock=clock+751;A.render();check(not s.emitters[1].instance,'remote completion glow expires at zero heat')
p.localPlayer=true
A.flash(p);local echo=A.flashes[p]
clock=clock+50;A.render();check(echo.emitters[1].instance.alpha>0 and echo.emitters[1].instance.alpha<.30,'taunt spiral fades in softly')
clock=clock+175;A.render();check(near(echo.emitters[1].instance.alpha,.46),'taunt fire cloud peaks below half opacity halfway through its brief lifetime')
clock=clock+226;A.render();check(not A.flashes[p],'taunt burst fades out and cleans up')
A.entry(p);local entry=A.states[p].entryBurst
check(entry and #entry.emitters==6 and entry.duration==380,'style switching uses three fire clouds and three fast smoke puffs')
check(entry.emitters[1].sprite.kind=='flame'and entry.emitters[4].sprite.kind=='smoke','entry uses wider animated fire and smoke instead of thin single-frame wisps')
clock=clock+190;A.render();check(entry.emitters[1].instance.alpha>0 and entry.emitters[4].instance.alpha<.3,'style effects have a restrained animated envelope')
clock=clock+191;A.render();check(not A.states[p].entryBurst and entry.emitters[1].instance.disposed,'entry particles expire once and return their instances')

ProjectYakuza.HeatActivation={active={}}
ProjectYakuza.setHeat(p,0);extreme=false
local activation={started=true,cleaned=false};ProjectYakuza.HeatActivation.active[p]=activation
ProjectYakuza.emit('heatActivationStarted',p)
check(p.outline==true,'outline starts immediately with native activation before mode fuel starts')
check(A.states[p].activating and A.states[p].extreme and #A.states[p].emitters==6,'native activation immediately selects fire/smoke even before Extreme Heat fuel starts')
clock=clock+350;drawLog={};A.render()
check(#drawLog==12 and A.states[p].opacity==1,'activation draws body aura plus three fire and three smoke clouds')
local cloud=A.states[p].activationBurst
local cloudCentres=0
for _,draw in ipairs(drawLog)do
 for _,e in ipairs(cloud.emitters)do if draw.instance==e.instance then
  local centreY=-draw.oy-e.point.frameHeight*e.instance.scale/2
  check(centreY<0 and centreY>-135,'activation fire and smoke centres cover legs through upper torso without ground clipping')
  check(draw.alpha<=.48 and not draw.additive,'activation smoke stays translucent without additive glare')
  cloudCentres=cloudCentres+1
 end end
end
check(cloudCentres==6,'three fire clouds and three smoke clouds render independently')
local savedGetters={};local bridgeReads=0;local savedLog=drawLog;drawLog={}
for _,name in ipairs({'getX','getY','getZ','getOffsetX','getOffsetY'})do
 local original=p[name];savedGetters[name]=original
 p[name]=function(self)bridgeReads=bridgeReads+1;return original(self)end
end
A.draw(p,A.states[p])
for name,original in pairs(savedGetters)do p[name]=original end
drawLog=savedLog
check(bridgeReads==5,'six-emitter body draw reads five actor coordinates/offsets once instead of thirty calls')
local matchingSmoke=true;for _,draw in ipairs(drawLog)do if draw.kind=='smoke' and draw.color~=A.extremeColor then matchingSmoke=false end end
check(matchingSmoke and A.smokeColor==A.extremeColor,'actual activation and sustained smoke renders exactly match the Extreme Heat aura tint')
local oldCloudLog=drawLog;additive=true;drawLog={};A.render()
local onlyAlpha=true;for _,draw in ipairs(drawLog)do if draw.additive then onlyAlpha=false end end
check(additive and onlyAlpha,'aura and transient particles force alpha and restore foreign additive mode');additive=false;drawLog=oldCloudLog
check(cloud and #cloud.emitters==6 and cloud.remaining==650,'activation uses six bounded particles for one second')
local beforeCloudFrames=cloud.emitters[1].instance.frames;paused=true;clock=clock+3000;A.render();paused=false
check(cloud.remaining==650 and cloud.emitters[1].instance.frames==beforeCloudFrames,'pause freezes activation smoke age and animation')
local savedHook=A.syncRenderHook;local scans=0
A.syncRenderHook=function()scans=scans+1;savedHook()end
for i=1,100 do A.update(p)end
A.syncRenderHook=savedHook
check(scans==0,'stable aura updates do not rescan all actors for render-hook ownership')
check(A.states[p].activationBurst==cloud,'repeated state updates never restart activation cloud')
clock=clock+651;A.render()
check(not A.states[p].activationBurst and cloud.emitters[1].instance.disposed,'cloud ends after one unpaused second and returns all instances')
A.update(p);check(not A.states[p].activationBurst,'cloud does not repeat during remaining activation')
local activationSprites={};for i,e in ipairs(A.states[p].emitters)do activationSprites[i]=e.instance end
extreme=true;activation.cleaned=true;ProjectYakuza.emit('extremeHeatStarted',p)
check(not A.states[p].activating and A.states[p].extreme,'activation hands over to active mode')
local reused=true;for i,e in ipairs(A.states[p].emitters)do if e.instance~=activationSprites[i]then reused=false end end
check(reused,'activation-to-mode transition reuses particles without a disappearance')
extreme=false;ProjectYakuza.emit('heatActivationStopped',p,false)
check(not A.states[p].emitters[1].instance and not p.outline,'interrupted/ended activation clears particles and outline when no heat remains')
ProjectYakuza.HeatActivation.active[p]=nil
p.localPlayer=false;p:setVariable('ProjectYakuzaRemoteClip','ProjectYakuza_DD_HeatActivate02');A.update(p)
check(A.states[p].activating and #A.states[p].emitters==6 and A.states[p].activationBurst and p.outline,'remote activation starts matching aura, cloud and outline')
p:setVariable('ProjectYakuzaRemoteClip','');A.update(p)
check(not A.states[p].emitters[1].instance and not A.states[p].activationBurst and not p.outline,'remote activation clip ending clears zero-heat aura, cloud and outline')
p.localPlayer=true
return 'PASS '..checks..' taunt lifecycle, input, heat, world aura and MP checks'
