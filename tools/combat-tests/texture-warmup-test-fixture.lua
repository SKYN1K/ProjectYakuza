require=function()end
ProjectYakuza={}
local hooks={};local ticks={};local requests=0;local textures={}
local function event()return {Add=function(fn)hooks[#hooks+1]=fn end}end
Events={OnCreatePlayer=event(),OnGameStart=event(),OnTick={Add=function(fn)ticks[fn]=true end,Remove=function(fn)ticks[fn]=nil end}}
getTexture=function(path)requests=requests+1;local t={ready=false,isReady=function(self)return self.ready end};textures[path]=t;return t end
do local _="ProjectYakuzaFixture:WARMUP" end
do local _="ProjectYakuzaFixture:WORLD" end
local T=ProjectYakuza.TextureWarmup;local W=ProjectYakuza.WorldEffects
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
check(requests==0,'texture queue waits for the player creation phase')
for _,fn in ipairs(hooks)do fn()end
check(requests==0 and T.hooked,'startup schedules work without blocking player creation')
local jobs=0;T.add('probe',function()jobs=jobs+1 end);T.add('probe',function()jobs=jobs+100 end)
for tick=1,45 do local before=requests;T.tick();check(requests-before<=6,'texture requests per tick are bounded');check(jobs==0,'sprite jobs wait until texture requests finish')end
check(requests==270 and T.hooked,'all supplied textures requested across 45 ticks')
T.tick();check(jobs==1 and not T.hooked and ticks[T.tick]==nil,'unique sprite setup runs once and removes the idle tick callback')
for _,path in ipairs(T.paths)do check(T.textures[path]==textures[path],'warm cache retains each native texture request')end
T.start();check(requests==270 and not T.hooked,'loading another player cannot enqueue duplicate textures')
T.add('late',function()jobs=jobs+1 end);check(T.hooked,'a module loaded after warm-up can schedule one job');T.tick();check(jobs==2 and not T.hooked,'late work also returns to an idle state')
T.add('broken',function()error('expected warm-up failure')end);T.add('after broken',function()jobs=jobs+1 end);T.tick();T.tick();check(jobs==3 and not T.hooked,'failed optional setup does not strand the remaining queue')
local draws=0;Core={getTileScale=function()return 2 end};IsoDirections={N=0}
local tex={ready=false,isReady=function(self)return self.ready end}
local sprite={getTextureForFrame=function()return tex end}
IsoSpriteInstance={get=function()return {setScale=function()end,setFrameSpeedPerFrame=function()end,render=function()draws=draws+1 end}end}
local instance=W.detached(sprite,.2,0);local p={getX=function()return 0 end,getY=function()return 0 end,getZ=function()return 0 end}
W.renderCentered(p,instance,64,.2,0,0,{});check(draws==0 and not W.ready(instance),'loading sprites cannot draw a red/white placeholder')
tex.ready=true;W.renderCentered(p,instance,64,.2,0,0,{});check(draws==1 and W.ready(instance),'ready sprites render normally without a permanent visibility lock')
local phaseUpdates,phaseSpeed=0,0
sprite.update=function()phaseUpdates=phaseUpdates+1 end
instance.setFrameSpeedPerFrame=function(_,v)phaseSpeed=v end
isGamePaused=function()return false end;W.phase(instance,21,.7)
check(phaseUpdates==1 and phaseSpeed==.7,'a staggered smoke start uses one native update and restores playback rate')
isGamePaused=function()return true end;W.phase(instance,17,.8)
check(phaseUpdates==1 and phaseSpeed==.8,'phase seeding never advances a paused effect')
return 'PASS '..checks..' texture warm-up, idempotence, readiness and first-use rendering assertions'
