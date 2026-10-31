require=function()end
local checks=0
local function check(v,message)checks=checks+1;assert(v,message)end
local clock,paused=1000,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
local function event()local e={};e.Add=function(fn)e[fn]=true end;e.Remove=function(fn)e[fn]=nil end;return e end
Events={OnWeaponHitCharacter=event(),OnTick=event(),OnPlayerUpdate=event(),OnGameStart=event(),OnSave=event(),OnMainMenuEnter=event()}
getPlayerScreenLeft=function(n)return n*1280 end
getPlayerScreenTop=function()return 0 end
getPlayerScreenWidth=function()return 1280 end
getPlayerScreenHeight=function()return 720 end
local additive=true
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end}}
local draws={};local removed,created=0,0
ISPanel={}
function ISPanel:derive()local t={};t.__index=t;setmetatable(t,{__index=self});return t end
function ISPanel:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h},self)end
function ISPanel:initialise()end
function ISPanel:setWantMouseEvents(v)self.mouseEvents=v end
function ISPanel:addToUIManager()self.inUI=true;created=created+1 end
function ISPanel:removeFromUIManager()self.inUI=false;removed=removed+1 end
function ISPanel:setX(v)self.x=v end;function ISPanel:setY(v)self.y=v end
function ISPanel:setWidth(v)self.width=v end;function ISPanel:setHeight(v)self.height=v end
function ISPanel:drawSubTexture(t,x,y,w,h,dx,dy,dw,dh,alpha,r,g,b)
 check(x>=0 and y>=0 and x+w<=t.width and y+h<=t.height,'glyph crop within converted source font atlas')
 check(dw>0 and dh>0 and alpha>=0 and alpha<=1,'valid glyph destination and transparency')
 draws[#draws+1]={path=t.path,x=dx,y=dy,width=dw,height=dh,alpha=alpha}
end
function ISPanel:drawRect(x,y,w,h,alpha)check(alpha>=0 and alpha<=1,'bounded screen tint')end
function ISPanel:drawTextureScaled(t,x,y,w,h,alpha,r,g,b)
 check(alpha>=0 and alpha<=1,'original flare transparency bounded')
 draws[#draws+1]={path=t.path,alpha=alpha}
end
getTexture=function(path)return {path=path,width=path:find('EdoSZ') and 2048 or path:find('Explosion') and 1024 or 512,height=path:find('Explosion') and 1024 or 512}end
do local _="ProjectYakuzaFixture:REGISTRY" end
do local _="ProjectYakuzaFixture:STYLE" end
local PY=ProjectYakuza
PY.isEquipped=function(p)return p.active end
PY.getPlayerStyle=function(p)return PY.getStyle(p.styleId)end
instanceof=function(x,name)return x.kind==name end
do local _="ProjectYakuzaFixture:UI" end
do local _="ProjectYakuzaFixture:ENCOUNTER" end
do local _="ProjectYakuzaFixture:FONT" end
do local _="ProjectYakuzaFixture:Y6" end
local E=PY.EncounterIntro;local style=PY.getStyle('dragon_of_dojima');local cfg=style.encounterIntro
local statReads,zombieReads=0,0
local p={kind='IsoPlayer',active=true,styleId=style.id,chasing=0,visible=0,close=0,number=0}
function p:isLocalPlayer()return self.localPlayer~=false end
function p:isDead()return self.dead==true end
function p:getVehicle()return self.vehicle end
function p:getPlayerNum()return self.number end
function p:getX()return 10 end;function p:getY()return 12 end;function p:getZ()return 0 end
function p:getStats()
 statReads=statReads+1
 return {getNumChasingZombies=function()return self.chasing end,getNumVisibleZombies=function()return self.visible end,getNumVeryCloseZombies=function()return self.close end}
end
local zombies={}
local list={size=function()return #zombies end,get=function(_,i)zombieReads=zombieReads+1;return zombies[i+1]end}
local squareReads=0
getCell=function()
 local cells={}
 for _,v in ipairs(zombies)do local key=math.floor(v:getX())..':'..math.floor(v:getY())..':'..math.floor(v:getZ());cells[key]=cells[key] or {};table.insert(cells[key],v)end
 return {getGridSquare=function(_,x,y,z)
  squareReads=squareReads+1;local items=cells[x..':'..y..':'..z] or {}
  return {getMovingObjects=function()return {size=function()return #items end,get=function(_,i)zombieReads=zombieReads+1;return items[i+1]end}end}
 end}
end
local function zombie(x,y,z,dead)
 return {kind='IsoZombie',getX=function()return x end,getY=function()return y end,getZ=function()return z or 0 end,isDead=function()return dead==true end}
end
local function crowd(n)
 zombies={};for i=1,n do zombies[#zombies+1]=zombie(11,12)end
 zombies[#zombies+1]=zombie(23,12);zombies[#zombies+1]=zombie(10,12,1);zombies[#zombies+1]=zombie(10,12,0,true)
end
local function finishCount()
 local ticks=0
 for i=1,100 do if E.states[p] and E.states[p].job then
  ticks=ticks+1
  local reads=zombieReads;local squares=squareReads;E.tick();check(squareReads-squares<=256,'bounded nearby grid queries per tick');check(zombieReads-reads<=192,'at most 192 nearby moving objects read per tick')
 end end
 check(E.states[p] and E.states[p].panel,'count finishes into intro panel');check(ticks<=3,'ordinary 12-tile count completes within three bounded ticks')
 return E.states[p]
end
for _,case in ipairs({{0,'A bunch of brain eaters'},{10,'A bunch of brain eaters'},{11,'Zombies'},{39,'Zombies'},{40,'The Horde'},{100,'The Horde'}})do
 check(E.title(cfg,case[1])==case[2],'requested title boundary '..case[1])
 E.clear();crowd(case[1]);check(E.request(p),'style-owned manual encounter starts')
 local s=finishCount();check(s.context.title==case[2],'radius count selects correct title '..case[1])
 check(s.context.count==math.min(40,case[1]),'count stops at highest title threshold')
 check(s.panel.mouseEvents==false and s.panel.inUI,'intro panel never captures mouse input')
 clock=clock+150;E.tick();s.panel:prerender();clock=clock+220;E.tick();s.panel:prerender();check(additive,'style UI restores incoming blend state')
end
check(#draws>0,'real Edo glyph and original flare provider draws')
E.clear();crowd(10)
for i=1,5000 do zombies[#zombies+1]=zombie(500+i,500)end
local beforeReads=zombieReads;E.request(p);finishCount();check(zombieReads-beforeReads==11,'five thousand distant zombies are never read by nearby counting')
local current=E.states[p];current.age=370;draws={};current.panel:prerender();local explosions=0
for _,draw in ipairs(draws)do if draw.path:find('EncounterExplosion',1,true)then explosions=explosions+1;check(draw.width>=500,'landing explosion is enlarged')end end
check(explosions==1,'landing renders one burst without staggered repeats')
current.age=1100;draws={};current.panel:prerender()
for _,draw in ipairs(draws)do check(not draw.path:find('EncounterExplosion',1,true),'explosion does not restart after completion')end

E.clear();crowd(10);zombies[#zombies+1]=zombie(22,12)
check(E.request(p),'exact radius case starts');local s=finishCount()
check(s.context.count==11 and s.context.title=='Zombies','12-tile boundary included; outside/dead/other floor excluded')
E.clear();crowd(100);p.chasing=0;p.close=0;p.visible=0
local initialStats=statReads;E.update(p)
for i=1,100 do E.update(p)end
check(statReads==initialStats+1 and not E.hooked,'idle detector throttles native stats and installs no tick hook')
local reads=zombieReads;clock=clock+400;p.chasing=1;E.update(p)
check(E.states[p].job and zombieReads==reads,'threat schedules count instead of scanning in player update')
paused=true;clock=clock+1000;E.tick();check(zombieReads==reads,'count pauses without scanning')
paused=false;s=finishCount();clock=clock+100;E.tick();local age=s.age
paused=true;clock=clock+5000;E.tick();s.panel:prerender()
check(s.age==age,'intro timing freezes while paused')
paused=false;clock=clock+2500;E.tick()
check(not s.panel and s.inEncounter and not E.hooked,'intro closes, encounter stays latched and idle hook removed')
local panels=created;clock=clock+400;E.update(p)
check(created==panels and not s.job,'continuous threat cannot replay intro')
E.onHit(p,zombie(11,12),nil,1);check(not s.job,'continued confirmed hits do not restart intro')
p.chasing=0;clock=clock+cfg.quietMs+401;E.update(p)
check(not s.inEncounter,'quiet interval ends encounter')
E.onHit(p,zombie(11,12),nil,0);check(not s.job,'non-damaging hit does not trigger')
E.onHit(p,zombie(11,12),nil,1);check(s.job~=nil,'new confirmed hit starts next encounter')
finishCount();p.active=false;E.update(p)
check(not E.states[p] and not E.hooked,'unequip disposes intro and session')
p.active=true;p.number=1;E.request(p);s=finishCount();s.panel:prerender()
check(s.panel.x==1280 and s.panel.width==1280,'panel follows local player viewport without input capture')
E.clear();p.number=0
local other={id='tests.no_intro',name='No intro',lightAttacks={{animation='Existing',nodeValue='own',duration=1}}}
PY.registerStyle(other);p.styleId=other.id;reads=zombieReads;initialStats=statReads;E.update(p)
check(not E.request(p) and zombieReads==reads and statReads==initialStats,'other styles inherit no DoD intro, scan or assets')
local custom={id='tests.custom_intro',name='Custom intro',lightAttacks=other.lightAttacks,ui={encounter='tests.provider'},encounterIntro={enabled=true,radius=5,durationMs=200,quietMs=1000,pollMs=100,titles={{max=2,text='Few'},{text='Many'}},soundKey='intro'}}
local made,painted,destroyed,sounded=0,0,0,0
PY.registerStyleUI('tests.provider',{create=function(c,state)made=made+1;check(c.style.id==custom.id and c.extra.title=='Many' and c.extra.radius==5,'custom provider gets style-owned encounter context')end,render=function()painted=painted+1;return true end,destroy=function()destroyed=destroyed+1 end})
PY.Feedback={sound=function(_,key)return key=='intro' and 'ExistingIntroSound' end,play=function()sounded=sounded+1 end}
PY.registerStyle(custom);p.styleId=custom.id;crowd(4);E.request(p);s=finishCount();s.panel:prerender()
check(made==1 and painted==1 and sounded==1,'custom intro provider and supplied sound are independent of DoD')
p.styleId=style.id;E.update(p)
check(destroyed==1 and not s.panel,'style change releases custom provider lifecycle')
E.clear();p.styleId=custom.id;E.request(p);s=finishCount();s.panel:prerender();PY.unregisterStyleUI('tests.provider');E.update(p)
check(not E.states[p] and destroyed==2,'provider removal cancels intro without falling back to DoD')
p.styleId=style.id
local function invalid(config)
 local candidate={id='tests.invalid_intro',name='Invalid',lightAttacks=other.lightAttacks,encounterIntro=config}
 check(not PY.validateStyle(candidate),'invalid intro config rejected')
end
invalid({titles={{max=10,text='Low'}}})
invalid({radius=0,titles={{text='All'}}})
invalid({titles={{max=10,text='Low'},{max=5,text='Bad'},{text='All'}}})
invalid({titles={{text='Early fallback'},{text='All'}}})

local short=E.layoutText(PY.EncounterFont,'Zombies');local long=E.layoutText(PY.EncounterFont,string.rep('Zombies ',40))
local smallScale=E.textScale(short,PY.EncounterFont,1280,720,{},1)
local longScale=E.textScale(long,PY.EncounterFont,1280,720,{},1.08)
check(smallScale>.72 and smallScale<=1,'short title is larger without upscaling its source font')
check(longScale<smallScale and long.width*longScale<=1280*.88,'long titles shrink to viewport width including landing pulse')
check(E.textScale(short,PY.EncounterFont,320,180,{},1)<=180*.22/PY.EncounterFont.lineHeight,'small viewports limit title height')
local detectorStyle={id='tests.detect',name='Detector',lightAttacks=other.lightAttacks,ui={encounter='ProjectYakuza.y6Encounter'},encounterIntro={enabled=true,countZombies=false,playerRadius=15,playerFov=140,pollMs=100,quietMs=1000,triggers={visiblePlayer=true},titles={{text='A rival'}}}}
PY.registerStyle(detectorStyle);E.clear();p.styleId=detectorStyle.id;p.chasing=100
p.getForwardDirection=function()return {getX=function()return 1 end,getY=function()return 0 end}end
p.CanSee=function(_,target)return not target.hidden end
local rival={kind='IsoPlayer',x=11,y=12,dead=false,hidden=false}
function rival:getX()return self.x end;function rival:getY()return self.y end;function rival:getZ()return 0 end
function rival:isDead()return self.dead end
function rival:getForwardDirection()return {getX=function()return -1 end,getY=function()return 0 end}end
function rival:CanSee(target)return not self.blocked end
local playerReads=0;local online={rival,p}
getOnlinePlayers=function()return {size=function()return #online end,get=function(_,i)playerReads=playerReads+1;return online[i+1]end}end
local cellsBefore=squareReads;local statsBefore=statReads;clock=clock+100;E.update(p)
check(E.states[p].panel and E.states[p].context.target==rival and E.states[p].context.reason=='player_seen','visible player triggers own style and exposes target context')
check(squareReads==cellsBefore and statReads==statsBefore,'player-only intro performs no zombie count or native threat reads')
E.clear();rival.hidden=true;clock=clock+100;E.update(p);check(not E.states[p].panel,'occluded player cannot trigger intro')
rival.hidden=false;rival.x=9;clock=clock+100;E.update(p);check(not E.states[p].panel,'player behind viewer fails configured field of view')
rival.x=100;clock=clock+100;E.update(p);check(not E.states[p].panel,'distant player cannot trigger intro')
rival.x=11;rival.dead=true;clock=clock+100;E.update(p);check(not E.states[p].panel,'dead players cannot trigger intro');rival.dead=false
E.clear();detectorStyle.encounterIntro.triggers={seenByPlayer=true};p.CanSee=function()return false end;clock=clock+100;E.update(p)
check(E.states[p].panel and E.states[p].context.target==rival,'seen-by-player uses the other actor visibility direction')
E.clear();detectorStyle.encounterIntro.triggers={visiblePlayer=true};p.CanSee=function()return true end
online={};for i=1,40 do online[i]=p end;online[36]=rival
for i=1,3 do local reads=playerReads;clock=clock+100;E.update(p);check(playerReads-reads<=16,'player candidate scan has a bounded per-poll budget')end
check(E.states[p].panel,'bounded cursor eventually detects a later visible player')
local reads=playerReads;clock=clock+100;E.update(p);check(playerReads==reads,'visible target is cached without rescanning the player list')
online={rival,p}
E.clear();detectorStyle.encounterIntro.triggers={};detectorStyle.encounterIntro.detector='tests.detector'
local detectorCalls=0;PY.registerEncounterDetector('tests.detector',function(who,style,ctx)detectorCalls=detectorCalls+1;check(who==p and style==detectorStyle and ctx.inEncounter==false,'detector receives its style and local state');return true,rival end)
clock=clock+100;E.update(p);check(E.states[p].panel and E.states[p].context.reason=='custom','registered detector can independently request its own intro')
E.update(p);check(detectorCalls==1,'custom detector obeys poll throttle')
PY.unregisterEncounterDetector('tests.detector');E.clear();clock=clock+100;E.update(p);check(not E.states[p].panel,'removed detector causes no DoD fallback')
PY.registerEncounterDetector('tests.detector',function()error('bad addon')end);clock=clock+100;E.update(p);clock=clock+100;E.update(p);check(not E.states[p].panel,'failing detector is quarantined without an intro');PY.unregisterEncounterDetector('tests.detector')
E.clear();detectorStyle.encounterIntro.detector=nil;detectorStyle.encounterIntro.triggers={playerHit=true}
for fn,enabled in pairs(Events.OnWeaponHitCharacter)do if type(fn)=="function" and enabled then fn(p,rival,nil,1)end end
check(E.states[p] and E.states[p].panel and E.states[p].context.reason=='hit','native player-hit event can trigger an opted-in player style')
E.clear();p.styleId=style.id;p.CanSee=nil;crowd(2);local originalMin=cfg.minZombies;cfg.minZombies=3;E.request(p)
for i=1,4 do E.tick()end
check(not E.states[p].panel and not E.states[p].inEncounter,'style minimum rejects insufficient zombie count without latching encounter')
E.onHit(p,zombie(11,12),nil,1);check(not E.states[p].job,'automatic hits respect rejected-count backoff')
crowd(3);E.request(p);finishCount();check(E.states[p].panel,'minimum allows the exact threshold');cfg.minZombies=originalMin
invalid({minZombies='wrong',titles={{text='All'}}})
invalid({countZombies=false,minZombies=1,titles={{text='All'}}})
invalid({textScale=2,titles={{text='All'}}})
invalid({triggers={unknown=true},titles={{text='All'}}})
invalid({triggers={visiblePlayer='yes'},titles={{text='All'}}})
getOnlinePlayers=nil
E.clear();check(removed==created,'all created panels removed')
return true,'PASS '..checks..' encounter thresholds, bounded radius counts, native-font UI, style providers, lifecycle and mouse isolation checks'
