require=function()end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local clock=1000;local paused=false
getTimestampMs=function()return clock end;isGamePaused=function()return paused end
local function event()local e={};e.Add=function(f)e[f]=true end;e.Remove=function(f)e[f]=nil end;return e end
Events={OnTick=event(),OnTickEvenPaused=event(),OnPlayerUpdate=event(),OnPlayerGetDamage=event(),OnSave=event(),OnMainMenuEnter=event(),OnGameStart=event()}
do local _="ProjectYakuzaFixture:REGISTRY" end
do local _="ProjectYakuzaFixture:WEAPONS" end
do local _="ProjectYakuzaFixture:STYLE" end
local PY=ProjectYakuza;local rules=PY.LowHealthRules;local style=PY.getStyle('dragon_of_dojima')
check(PY.validateStyle(style)and rules.forStyle(style).threshold==30,'DoD opts into validated low-health defaults')
for _,cfg in ipairs({{threshold=0},{recover=30},{critical=30},{volume=2},{quietMs=20},{soundKey=''},{hud=1},{unknown=true},{threshold=0/0}})do check(not rules.valid(cfg),'invalid low-health configuration rejected')end
check(rules.valid(false)and rules.valid(nil)and rules.valid({enabled=false})and rules.valid({soundKey=false,volume=0}),'explicitly disabled/HUD-only authoring is valid')
local owner={playerType=true,health=100,localPlayer=true,equipped=true,style=style,reads=0,chasing=0,near=0,visible=0}
instanceof=function(p,name)return type(p)=='table'and p.playerType==true and name=='IsoPlayer'end
function owner:isLocalPlayer()return self.localPlayer end;function owner:isDead()return self.dead==true end
function owner:getVehicle()return self.vehicle end;function owner:isAsleep()return self.asleep==true end
function owner:getBodyDamage()local p=self;return {getOverallBodyHealth=function()p.reads=p.reads+1;return p.health end}end
function owner:getStats()local p=self;return {get=function()return p.panic or 0 end,getNumChasingZombies=function()return p.chasing end,getNumVeryCloseZombies=function()return p.near end,getNumVisibleZombies=function()return p.visible end}end
function owner:getEmitter()local p=self;return {isPlaying=function(_,name)return name=='HeartBeat'and p.nativeHeartbeat==true end}end
CharacterStat={PANIC=1};GameSounds={getSound=function()return {getUserVolume=function()return 1 end}end}
PY.isEquipped=function(p)return p.equipped end;PY.getPlayerStyle=function(p)return p.style end
local allocated,played,stopped,ticked=0,0,0,0;local failed=false
FMODSoundEmitter={new=function()
 allocated=allocated+1;local e={handles={}}
 function e:setPlayRemoteEvents(v)self.remote=v end
 function e:playSoundImpl(name,_,target)played=played+1;self.name=name;self.target=target;if failed then return 0 end;self.handles[played]=true;return played end
 function e:set3D(id,value)self.spatial=value end
 function e:setVolume(id,value)self.volume=value end
 function e:stopSoundLocal(id)self.handles[id]=nil;stopped=stopped+1 end
 function e:isPlaying(id)return self.handles[id]==true end
 function e:tick()ticked=ticked+1 end
 return e
end}
getSoundManager=function()return {unregisterEmitter=function(_,e)e.unregistered=true end}end
do local _="ProjectYakuzaFixture:LOW" end
local L=PY.LowHealthFeedback
local function step(ms)clock=clock+ms;L.update(owner);L.tick()end
L.update(owner);for i=1,1000 do L.update(owner)end
check(owner.reads==1 and not L.hooked and not L.states[owner]and allocated==0,'healthy updates are throttled without a tick hook or audio allocation')
local zombie=setmetatable({playerType=false},{__index=function(_,key)error('player-only member accessed on zombie: '..tostring(key))end})
L.markCombat(zombie);L.update(zombie,true)
for i=1,512 do for callback in pairs(Events.OnPlayerGetDamage)do if type(callback)=='function'then callback(zombie,'WEAPONHIT',.4)end end end
check(not L.combat[zombie]and not L.polls[zombie]and not L.states[zombie]and allocated==0,'native zombie weapon-damage callbacks never call player methods, poll health or allocate feedback')
L.markCombat(nil);L.update(nil,true);L.markCombat(false);L.update('WEAPONHIT',true)
check(owner.reads==1 and not L.hooked,'non-player callback payloads cannot enter the local-player feedback path')
for callback in pairs(Events.OnPlayerGetDamage)do if type(callback)=='function'then callback(owner,'WEAPONHIT',.4)end end
check(L.combat[owner]==clock and owner.reads==2,'native local-player victim still records combat and refreshes health immediately')
L.combat[owner]=nil
owner.health=30;step(250);check(L.states[owner]and L.states[owner].fade==0,'warning enters at thirty percent with a fade')
step(250);check(L.sample(owner)>0 and allocated==0,'low health has a quiet HUD warning outside combat')
owner.health=15;step(250);step(250);local strength,critical=L.sample(owner)
check(critical and strength>0 and strength<=1 and L.states[owner].period==850,'critical health increases restrained pulse strength and speed')
PY.emit('combatHit',owner,{},nil,1);step(16);local state=L.states[owner];local emitter=state.emitter
check(emitter and emitter.unregistered and emitter.remote==false and emitter.spatial==false and emitter.target==nil,'heartbeat is private 2D audio rather than a world/MP sound')
check(emitter.name=='ProjectYakuza_LowHealthHeartbeat'and emitter.volume>0 and emitter.volume<=.18,'heartbeat uses the style sound at a quiet bounded gain')
local sounds=played;for i=1,100 do step(16)end;check(played==sounds,'playing heartbeat cannot overlap or restart each update')
state.emitter.handles[state.sound]=nil;state.nextBeat=clock+800;local beforeBeat=played;step(16);check(played==beforeBeat and not state.sound,'short native event cannot restart before the next heartbeat interval');step(800);check(played==beforeBeat+1,'ended heartbeat can repeat after its bounded interval')
owner.nativeHeartbeat=true;owner.panic=50;step(250);check(not state.sound,'audible vanilla heartbeat takes precedence without a second overlapping heartbeat');owner.nativeHeartbeat=false;owner.panic=0;step(1000);check(state.sound,'private heartbeat can resume after native heartbeat stops')
owner.nativeHeartbeat=true;step(250);check(state.sound,'retained but muted native heartbeat with zero panic cannot suppress mod feedback');owner.nativeHeartbeat=false
local remote={playerType=true,localPlayer=false};function remote:isLocalPlayer()return false end
L.update(remote,true);L.markCombat(remote);check(not L.states[remote]and not L.combat[remote],'remote players never allocate local warnings or sounds')
local before=state.clock;paused=true;clock=clock+1000;L.tick();check(state.clock==before and not state.sound,'pause freezes animation and stops the private heartbeat')
clock=clock+1000;L.sample(owner);check(state.clock==before,'HUD sampling also stays frozen during pause')
paused=false;L.tick();step(32);check(state.sound and state.clock>before,'unpause resumes through the owned audio path')
owner.chasing=0;L.combat[owner]=clock-7000;step(250);check(not state.sound and L.states[owner],'combat quiet timeout stops audio while retaining the health warning')
owner.health=32;step(250);check(L.states[owner]and not state.recovering,'hysteresis prevents flickering immediately above entry threshold')
owner.health=35;step(250);step(250);check(not L.states[owner]and not L.hooked,'healing past recovery clears the state and tick hook')
owner.health=10;owner.chasing=1;step(250);step(250);check(L.states[owner].sound,'native chasing counters activate heartbeat without any square scan')
owner.dead=true;L.tick();check(not L.states[owner]and not L.hooked,'death immediately restores the owned audio lifecycle');owner.dead=false
owner.health=20;step(250);step(250);owner.equipped=false;L.tick();check(not L.states[owner],'unequipping the style stops feedback');owner.equipped=true
step(250);step(250);owner.asleep=true;L.tick();check(not L.states[owner],'sleep never retains combat heartbeat');owner.asleep=false
step(250);step(250);owner.vehicle={};L.tick();check(not L.states[owner],'entering a vehicle clears combat feedback');owner.vehicle=nil
local future={id='other',sounds={}};owner.style=future;step(250);check(not L.states[owner],'future styles do not inherit DoD low-health feedback')
future.lowHealthFeedback={threshold=50,recover=60,critical=25,soundKey=false,volume=0,hud=false};check(rules.valid(future.lowHealthFeedback),'custom thresholds and silent custom UI are supported')
local before=allocated;step(250);step(250);check(L.states[owner]and L.sample(owner)==0 and allocated==before,'HUD-only/no-audio options allocate no emitter or stock HUD warning')
owner.style=style;step(250);step(250);failed=true;L.clear(owner);L.update(owner,true);L.markCombat(owner);step(250)
local failedCount=played;for i=1,20 do step(250)end;check(played==failedCount,'missing audio event retries are throttled rather than spammed');failed=false
L.clearAll();owner.style=style;owner.health=10;owner.chasing=1;L.update(owner,true);step(250)
local uiDraws={};ISPanel={}
function ISPanel:derive()local c={};c.__index=c;return setmetatable(c,{__index=self})end
function ISPanel:new(x,y,w,h)return setmetatable({width=w,height=h},self)end
function ISPanel:initialise()end;function ISPanel:setWantMouseEvents(v)self.mouse=v end;function ISPanel:addToUIManager()end
function ISPanel:drawTextureScaled(texture,x,y,w,h,alpha,r,g,b)uiDraws[#uiDraws+1]={texture=texture,alpha=alpha,r=r,g=g,b=b}end
function ISPanel:drawSubTexture()end;function ISPanel:drawRect()end;function ISPanel:drawText(text)self.lastText=text end
getSpecificPlayer=function()return owner end;getPlayerScreenWidth=function()return 1280 end
getTexture=function(name)return name end;UIFont={Small=1}
SpriteRenderer={instance={getDoAdditive=function()return false end,setDoAdditive=function()end}}
PY.StyleUI={releaseAll=function()end,render=function()return false end}
PY.Heat={display=function()return 50 end,isExtreme=function()return false end,stocks=function()return 3 end,enabled=function()return true end,config={maxStocks=6}}
PY.Bindings={label=function()return 'N'end};PY.TigerDrop=nil
do local _="ProjectYakuzaFixture:HUD" end
local HUD=PY.HeatUI;HUD.create();HUD.instance:prerender()
local red=false;for _,draw in ipairs(uiDraws)do if draw.texture:find('BarFrame.png',1,true)and draw.g==.12 then red=true;check(draw.alpha>0 and draw.alpha<=.28,'health warning overlays the original frame at restrained alpha')end end
check(red and HUD.instance.mouse==false,'stock HUD uses original health frame without intercepting mouse input')
owner.health=100;step(250);step(250);uiDraws={};HUD.instance:prerender();local warned=false
for _,draw in ipairs(uiDraws)do if draw.g==.12 then warned=true end end
check(not warned,'healed character does not retain a pulsing health-frame overlay')
L.clearAll();local remaining=0;for _ in pairs(L.states)do remaining=remaining+1 end;check(not L.hooked and remaining==0,'save/world cleanup drops all local state')
return 'PASS '..checks..' style-specific low-health thresholds, private audio, pause, recovery, HUD and bounded polling checks'
