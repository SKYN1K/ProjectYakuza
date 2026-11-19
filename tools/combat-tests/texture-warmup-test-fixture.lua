require=function()end
ProjectYakuza={}
local hooks={};local requests=0;local textures={}
local function event()return {Add=function(fn)hooks[#hooks+1]=fn end}end
Events={OnCreatePlayer=event(),OnGameStart=event()}
getTexture=function(path)requests=requests+1;local t={ready=false,isReady=function(self)return self.ready end};textures[path]=t;return t end
do local _="ProjectYakuzaFixture:WARMUP" end
do local _="ProjectYakuzaFixture:WORLD" end
local T=ProjectYakuza.TextureWarmup;local W=ProjectYakuza.WorldEffects
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
check(requests==0,'texture queue waits for the player creation phase')
for _,fn in ipairs(hooks)do fn()end
check(requests==270,'all supplied combat textures preload once before first use')
for _,path in ipairs(T.paths)do check(T.textures[path]==textures[path],'warm cache retains each native texture request')end
T.start();check(requests==270,'loading another player cannot enqueue duplicate textures')
local draws=0;Core={getTileScale=function()return 2 end};IsoDirections={N=0}
local tex={ready=false,isReady=function(self)return self.ready end}
local sprite={getTextureForFrame=function()return tex end}
IsoSpriteInstance={get=function()return {setScale=function()end,setFrameSpeedPerFrame=function()end,render=function()draws=draws+1 end}end}
local instance=W.detached(sprite,.2,0);local p={getX=function()return 0 end,getY=function()return 0 end,getZ=function()return 0 end}
W.renderCentered(p,instance,64,.2,0,0,{});check(draws==0 and not W.ready(instance),'loading sprites cannot draw a red/white placeholder')
tex.ready=true;W.renderCentered(p,instance,64,.2,0,0,{});check(draws==1 and W.ready(instance),'ready sprites render normally without a permanent visibility lock')
return 'PASS '..checks..' texture warm-up, idempotence, readiness and first-use rendering assertions'
