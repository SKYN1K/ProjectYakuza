require=function()end
local checks=0
local function check(v,s)checks=checks+1;assert(v,s)end
local function near(a,b)return math.abs(a-b)<.000001 end
local clock,paused,text=1000,false,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
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
-- BINDINGS
-- REGISTRY
local ProjectYakuza=ProjectYakuza
-- STYLE
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
function p:getPrimaryHandItem()return {}end
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
-- TAUNTS
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
check(not p.block and not p.ignore and p.deferred and not ProjectYakuza.activeActions[p],'flags and ownership restored')
a:perform();a:cleanup(true);check(near(ProjectYakuza.getHeat(p),100/6) and ends==1,'completion cannot double reward')
p.aim=true;a=begin();p.hit='Bite';a:update();p.hit=''
check(a.stopped and near(ProjectYakuza.getHeat(p),100/6),'damage interrupts without reward')
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
-- AURA STUBS
local loads,draws,pooled,attached=0,0,0,0
local drawLog={}
local additive=false
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(self,v)additive=v end}}
Core={getTileScale=function()return 2 end};IsoDirections={N='N'};ColorInfo={new=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end}
instanceof=function()return true end
IsoSprite={CreateSprite=function()
 local s={};function s:LoadFramesNoDirPageDirect(path,kind,count)self.kind=kind;self.path=path;self.frameCount=count;check((path=='media/textures/ProjectYakuza/HeatWisp' and count==32) or (path=='media/textures/ProjectYakuza/TauntBurst' and count==1) or (path=='media/textures/ProjectYakuza/ExtremeHeat' and ((kind=='flame' and count==64) or ((kind=='wispL' or kind=='wispR') and count==1))),'only supplied normal, taunt or original Lost Judgment texture frames');loads=loads+1 end
 function s:setAnimate(v)self.animate=v end
 function s:update(i)i.frames=i.frames+1 end
 return s
end}
IsoSpriteInstance={add=function()pooled=pooled+1 end}
ProjectYakuza.WorldEffects={attach=function(p,s,height,scale,anchor,loop,speed,x)
 attached=attached+1
 local i={frames=0,scale=scale,height=anchor,speed=speed,x=x}
 function i:getParentSprite()return s end
 function i:SetAlpha(v)self.alpha=v end
 function i:SetTargetAlpha(v)end
 function i:Dispose()self.disposed=true end
 function i:render(owner,x,y,z,dir,ox,oy,color)draws=draws+1;self.additive=additive;drawLog[#drawLog+1]={instance=self,kind=s.kind,additive=additive,alpha=self.alpha,color=color,dir=dir,ox=ox,oy=oy};if self.fail and additive then error('render failure')end end
 return i
end}
function p:getAttachedAnimSprite()return {remove=function()end}end
-- CATALOG
-- PROTOCOL
-- AURA
local A=ProjectYakuza.HeatAura
ProjectYakuza.setHeat(p,0);A.update(p);check(not A.states[p],'zero heat has no ordinary aura')
a=begin();check(not A.states[p],'taunt animation itself has no aura boost at zero heat')
p:setVariable('ProjectYakuzaTaunt','started');a:update();p:setVariable('ProjectYakuzaTaunt','done');a:update()
local s=A.states[p];check(s and #s.emitters==4 and s.flashing,'completion flash reuses only the four ordinary aura sprites')
clock=clock+130;A.render()
check(s.opacity>0 and s.profile=='normal' and not s.extreme,'brief flash keeps the normal aura profile')
check(s.emitters[1].instance.additive and not additive,'same normal aura frame receives the subtle additive pass')
check(near(s.emitters[1].instance.alpha,s.opacity*.035) and s.emitters[1].instance.frames==1,'brief ordinary glow stays subtle and never advances the animation twice')
check(#A.flashes[p].emitters==5,'completion creates only five upper-body particles')
local count,alloc=loads,attached
for i=1,1000 do A.update(p);A.render()end
check(loads==count and attached==alloc,'stable aura never reallocates per frame')
local frames=s.emitters[1].instance.frames;local pulse=s.clock
paused=true;clock=clock+5000;A.render();check(s.clock==pulse and s.emitters[1].instance.frames==frames,'pause holds glow and sprites');paused=false
s.emitters[1].instance.fail=true;local ok=pcall(A.render);check(not ok and not additive,'flash render failure restores additive state');s.emitters[1].instance.fail=false
ProjectYakuza.setHeat(p,0);clock=clock+131;A.render()
check(not A.flashes[p] and not s.emitters[1].instance,'completion flash expires and zero-heat aura clears')
a=begin();a:stop();check(not A.flashes[p] and not s.emitters[1].instance,'interrupted taunt never flashes')
ProjectYakuza.setHeat(p,100/6);A.update(p);clock=clock+350;A.render();check(s.emitters[1].instance.scale==.5175,'normal aura original dimensions preserved')
local normalInstances={};local normalSprites={}
for i,e in ipairs(s.emitters) do normalInstances[i]=e.instance;normalSprites[i]=e.sprite end
local oldOpacity=s.opacity
extreme=true;A.update(p);drawLog={};clock=clock+350;A.render()
check(s.extreme and s.profile=='extreme' and #s.emitters==4,'Extreme Heat exclusively selects four original Y6 flame patches')
check(s.opacity==oldOpacity,'switching aura profile preserves completed fade without blinking')
for i,e in ipairs(s.emitters) do
 local point=A.extremeLayout[i];local normal=A.layout[i]
 check(normalInstances[i].disposed and e.instance~=normalInstances[i],'normal emitter is released before Extreme Heat replacement')
 local width=point.kind=='flame' and 32 or 64
 check(point.frameHeight*point.scale<=256*normal.scale and width*point.scale<=128*normal.scale and point.height>=38,'new original particles fit within former upper-body patch size')
 check(e.sprite.path=='media/textures/ProjectYakuza/ExtremeHeat' and e.sprite~=normalSprites[i],'replacement never uses the old blurred HeatWisp sequences')
 check(point.kind=='flame' and e.frames==64 and e.instance.frames==1,'all four patches animate original flame frames exactly once')
 check(64/(point.speed*60)<.85 and 64/(point.speed*60)>.55,'flame loops are substantially faster at roughly .6-.8 seconds')
end
check(#drawLog==4,'Extreme Heat renders four base flame particles without a second bloom/cloud pass')
for _,draw in ipairs(drawLog) do
 for _,normal in ipairs(normalInstances) do check(draw.instance~=normal,'no normal-heat instance is drawn during Extreme Heat') end
 check(draw.additive and draw.alpha<=.48 and draw.alpha>0,'black-backed original Y6 flames use scoped additive rendering at bounded opacity')
 check(draw.color==A.extremeColor and draw.color.r==.08 and draw.color.g==.38 and draw.color.b==1,'flames use a saturated blue tint instead of near-white exposure')
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
check(loads==count,'returning to normal reloads no supplied texture sequences')
p.data.ProjectYakuzaHeatAuraDisabled=true;A.flash(p);check(not A.flashes[p] and not s.emitters[1].instance and not A.rendering,'disabled aura cannot retain a delayed flash');p.data.ProjectYakuzaHeatAuraDisabled=nil
p.localPlayer=false;p:setVariable('ProjectYakuzaRemoteClip','ProjectYakuza_DD_Taunt01');ProjectYakuza.setHeat(p,0);A.update(p)
check(not s.emitters[1].instance,'remote taunt playback alone has no flash')
A.flash(p);check(s.flashing and s.emitters[1].instance,'replicated completion triggers observer flash')
clock=clock+261;A.render();check(not s.emitters[1].instance,'remote completion glow expires at zero heat')
p.localPlayer=true
return 'PASS '..checks..' taunt lifecycle, input, heat, world aura and MP checks'
