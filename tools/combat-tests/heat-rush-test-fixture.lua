local Q=PY.QTE;local held={};local function down(k)return held[k]==true end
local function def(n)local out={prompts={}};for i=1,n do out.prompts[i]={atMs=i*500,windowMs=250,binding=i%2==0 and 'light'or'finisher'}end;return out end
check(Q.valid(def(32))and not Q.valid(def(33)),'framework bounds prompt arrays')
for _,bad in ipairs({{prompts={}}, {prompts={{atMs=0/0,windowMs=100,binding='light'}}},{prompts={{atMs=50,windowMs=100,binding='light'}}},{prompts={{atMs=500,windowMs=100,binding=''}}}})do check(not Q.valid(bad),'invalid QTE definitions rejected')end
check(not Q.valid(def(2),500),'prompt cannot outlive its animation')
local results=0;local session=Q.create(def(32),down,{style='addon'})
for i,v in ipairs(session.definition.prompts)do
 held[v.binding]=false;Q.update(session,v.atMs-200,down)
 held[v.binding]=true;Q.update(session,v.atMs-100,down)
 Q.update(session,v.atMs-50,down)
 Q.update(session,v.atMs,down,function(kind,index,success)if kind=='result'then check(index==i and success,'custom binding QTE succeeds once');results=results+1 end end)
end
check(results==32 and session.closed and session.successes==32,'generic QTE sequence completes once')
Q.update(session,999999,down);check(results==32,'closed QTE cannot replay results')
held={finisher=true};session=Q.create({prompts={{atMs=1000,windowMs=300,binding='finisher'}}},down)
Q.update(session,800,down);Q.update(session,1000,down);check(session.results[1]==false,'holding before prompt is not a fresh input')
held={};session=Q.create(def(1),down);Q.update(session,100,down);check(not Q.update(session,99,down),'time rewind cannot replay a QTE');Q.cancel(session,'test');check(session.closed,'QTE interruption closes it')
local phase,weight,paused=0,1,false
isGamePaused=function()return paused end
Events.OnServerCommand=event()
PY.AttackEffects={findTrack=function()return phase,weight end}
PY.NetworkProtocol={module='ProjectYakuza',path=function()return true end}
PY.Defense={snapActor=function(actor,x,y)actor.x=x;actor.y=y end}
PY.HitEffects={spawn=function()end}
token.data={};token.min=.3;token.max=.5
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
local creates=0;instanceItem=function(name)check(name==PY.TOKEN,'canonical damage item uses B42 factory');creates=creates+1;return {getMinDamage=function()return .3 end,getMaxDamage=function()return .5 end}end
function p:getX()return self.x or 0 end;function p:getY()return self.y or 0 end
function p:getIgnoreMovement()return self.ignore==true end;function p:setIgnoreMovement(v)self.ignore=v end
function p:isBlockMovement()return self.blocked==true end
function p:isDeferredMovementEnabled()return self.deferred~=false end;function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:setTargetAndCurrentDirection()end;function p:getMovementLastFrame()return {set=function()end}end
function p:setMoving()end;function p:setRunning()end;function p:setSprinting()end
function base:setActionAnim(v)self.animation=v end
function base:forceComplete()self:perform()end;function base:forceStop()self:stop()end
local z={x=1.1,y=0,health=10,hits=0,total=0,vars={},useless=false,ignore=false,deferred=true,target=p}
function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return 0 end
function z:isDead()return self.health<=0 end;function z:isOnFloor()return false end;function z:isKnockedDown()return false end
function z:isUseless()return self.useless end;function z:setUseless(v)self.useless=v end
function z:isAttacking()return false end;function z:getIgnoreMovement()return self.ignore end;function z:setIgnoreMovement(v)self.ignore=v end
function z:isDeferredMovementEnabled()return self.deferred end;function z:setDeferredMovementEnabled(v)self.deferred=v end
function z:getTarget()return self.target end;function z:setTarget(v)self.target=v end
function z:setVariable(k,v)self.vars[k]=v end;function z:setHitReaction(v)self.reaction=v end;function z:getHitReaction()return self.reaction or ''end
function z:setAttackOutcome(v)self.outcome=v end
function z:reportEvent(v)self.report=v end;function z:setTargetAndCurrentDirection()end
function z:Hit(item,who,amount)check(item==token and who==p,'paired source contact uses native item/actor');self.hits=self.hits+1;self.total=self.total+amount;self.health=self.health-amount end
function z:setKnockedDown(v)self.knock=v end;function z:setFallOnFront()end
function z:getOnlineID()return 25 end
instanceof=function(obj,kind)return kind=='IsoZombie'and obj==z or kind=='IsoPlayer'and obj==p end
do local _="ProjectYakuzaFixture:PATHS" end
do local _="ProjectYakuzaFixture:RUSH_RULES" end
do local _="ProjectYakuzaFixture:RUSH" end
local committed=0;PY.on("attackCommitted",function(_,_,_,_,kind)if kind=="heatAction"then committed=committed+1 end end)
local H=PY.HeatRush;local style=PY.getStyle('dragon_of_dojima');local R=PY.HeatRushRules
PY.setHeat(p,100);check(PY.Heat.start(p),'Extreme Heat starts for paired action')
local state=PY.stateFor(p);state.active=true
for i=1,7 do state.step=i;state.activeLightMove=style.extremeLightAttacks[i];state.multiHitToken={};H.inputStarted(p,PY.getPlayerStyle(p),i,state.activeLightMove);clock=clock+100 end
check(not H.tickets[p]and H.chains[p].count==7,'seven missed inputs progress without requiring a target')
z.x=1.65;check(R.validTarget(p,z),'native-hit knockback margin permits a nearby standing victim');z.x=2.01;check(not R.validTarget(p,z),'paired handoff cannot reach beyond two tiles');z.x=1.65
state.step=8;state.activeLightMove=style.extremeLightAttacks[8];state.multiHitToken={};H.hit(p,z,token,.1);check(H.tickets[p]and H.tickets[p].z==z,'eighth confirmed hit stores existing target without search/steering')
local second=setmetatable({}, {__index=z});function second:getOnlineID()return 26 end
local oldInstanceof=instanceof;instanceof=function(obj,kind)return obj==second and kind=='IsoZombie'or oldInstanceof(obj,kind)end
H.hit(p,second,token,.1);check(H.tickets[p].z==second,'eighth multi-hit selects the last target hit');H.hit(p,z,token,.1);check(H.tickets[p].z==z,'later eighth-strike contact replaces the prior target');instanceof=oldInstanceof
state.active=false;p.attacking=false;state.lastDown=false;mouse[0]=true
local busy=true;function p:hasTimedActions()return busy end
local savedTicket=H.tickets[p]
check(H.input(p,state,PY.getPlayerStyle(p))and H.tickets[p]==savedTicket and not PY.activeActions[p],'native recovery retains the ready ticket instead of consuming it')
local oldClient=isClient;local oldNetwork=PY.Network;isClient=function()return true end;PY.Network={send=function()error('granted recovery must not cancel or request a second lease')end};savedTicket.granted={action=44}
check(H.input(p,state,PY.getPlayerStyle(p))and H.tickets[p]==savedTicket,'MP granted handoff also survives busy recovery')
savedTicket.granted=nil;PY.Network=oldNetwork;isClient=oldClient
busy=false
check(H.input(p,state,PY.getPlayerStyle(p)),'cleared recovery requests paired finish without another light')
local c=PY.activeActions[p];check(c and c.kind=='heatAction','registered heat action handler starts')
local a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start()
check(p.blocked and p.ignore and z.useless and z.ignore,'paired action owns movement/AI locks')
check(committed==1,'paired action publishes one exertion commitment when its motion starts')
for i,prompt in ipairs(c.action.qte.prompts)do
 phase=(prompt.atMs-100)/1000;mouse[2]=true;a:update();check(z.hits==i-1,'QTE input alone never deals early damage')
 phase=prompt.atMs/1000;mouse[2]=false;a:update();check(z.hits==i,'one hit on source contact after successful prompt')
 a:update();check(z.hits==i,'repeated update cannot duplicate contact')
end
check(committed==1,'QTE hit count does not publish repeated exertion commitments')
check(math.abs(z.total-2.25)<.000001 and creates==1,'canonical base damage gets one Extreme bonus and one cached factory item')
phase=R.duration;a:update()
check(a.cleaned and not p.blocked and not p.ignore and not z.useless and not z.ignore and z.deferred and z.target==p and z.knock,'full source recovery restores actor/victim state')
check(not PY.activeActions[p]and not H.active[p],'completed paired action releases context')
p.x=0;p.y=0;z.x=1.1;z.y=0;z.knock=false;mouse[0]=false
local ticket={z=z};check(PY.requestAction(p,'heatAction',nil,ticket),'second paired action can start')
c=PY.activeActions[p];a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start();phase=0
local before=z.hits
for _,prompt in ipairs(c.action.qte.prompts)do phase=prompt.atMs/1000;a:update()end
check(z.hits==before,'missing every QTE grants no bonus hits')
paused=true;phase=R.duration;a:update();check(not a.cleaned,'pause does not finish or damage the sequence');paused=false
a:forceStop();check(not z.useless and not p.blocked and a.cleaned,'interruption releases paired locks')
PY.NetworkProtocol.number=function(v,lo,hi)return type(v)=='number'and v==v and v>=lo and v<=hi end
PY.NetworkProtocol.integer=function(v,lo,hi)return PY.NetworkProtocol.number(v,lo,hi)and v==math.floor(v)end
PY.NetworkProtocol.zombie=function()return z end
local currentSession=1;PY.Network={acceptSession=function(_,session)return session==currentSession end}
function p:isLocalPlayer()return false end;function p:getOnlineID()return 2 end
getPlayerByOnlineID=function(id)return id==2 and p end
local pose={player=2,action=10,zombie=25,session=1,age=0,x=0,y=0,fx=1,fy=0}
H.receive('ProjectYakuza','heatRushPose',pose);check(H.remote[2]and z.useless,'remote paired pose enters native victim state')
H.receive('ProjectYakuza','heatRushEnd',{player=2,action=10,session=1,useless=false,ignore=false,deferred=true})
check(not H.remote[2]and not z.useless and not z.ignore and z.deferred,'remote completion restores explicit false flags')
H.receive('ProjectYakuza','heatRushPose',pose);check(not H.remote[2],'late pose cannot resurrect an ended sequence')
currentSession=2;pose.session=2;pose.action=1;H.receive('ProjectYakuza','heatRushPose',pose)
check(H.remote[2]and H.remote[2].action==1,'new session can start with fresh action serial')
H.receive('ProjectYakuza','heatRushEnd',{player=2,action=99,session=1,useless=false,ignore=false,deferred=true})
check(H.remote[2]~=nil,'stale-session end cannot cancel current paired action')
H.clear();check(not H.remote[2]and not z.useless and not H.remoteHook,'world cleanup releases remote locks and callback')
H.receive('ProjectYakuza','heatRushEnd',{player=2,action=20,session=2,useless=false,ignore=false,deferred=true});pose.action=20
H.receive('ProjectYakuza','heatRushPose',pose);check(not H.remote[2],'end arriving before first pose still prevents revival')
local draws=0
ISPanel={derive=function(self)local cls={};cls.__index=cls;setmetatable(cls,{__index=self});return cls end}
function ISPanel:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h,background=true},{__index=self})end
function ISPanel:initialise()end;function ISPanel:setWantMouseEvents(v)self.mouse=v end;function ISPanel:addToUIManager()self.added=true end
function ISPanel:drawTextCentre(text)draws=draws+1;self.lastText=text end
Events.OnGameStart=event();Events.OnCreatePlayer=event();getSpecificPlayer=function()return p end;getNumActivePlayers=function()return 1 end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end;getPlayerScreenWidth=function()return 1920 end;getPlayerScreenHeight=function()return 1080 end
UIFont={Large=1}
do local _="ProjectYakuzaFixture:RUSH_UI" end
function p:isLocalPlayer()return true end
local U=PY.HeatRushUI;U.create();local panel=U.instances[0]
check(panel.added and panel.background==false and panel.mouse==false,'QTE overlay has no fullscreen panel background and cannot capture mouse')
local qte=Q.create(style.actions.heatAction.qte,down)
H.active[p]={seen=true,qte=qte,elapsed=.8};panel:render();check(draws==1 and panel.lastText:find('MMB'),'QTE prompt uses current configurable binding label')
H.active[p].elapsed=0;panel:render();check(draws==1,'QTE overlay is empty outside prompt windows');H.active[p]=nil
H.chains[p]={count=7,at=clock};panel:render();check(draws==2 and panel.lastText:find('7 / 8'),'connected-light progress explains when prompts become available')
H.chains[p]=nil;H.tickets[p]={expires=clock+700};panel:render();check(draws==3 and panel.lastText=='Heat Rush','ready handoff is visible during recovery')
H.tickets[p].expires=clock-1;panel:render();check(draws==3,'expired handoff has no stale UI');H.tickets[p]=nil
local ended=0;PY.Network={send=function(_,command)if command=='heatRushEnd'then ended=ended+1 end end}
H.tickets[p]={z=z,pressed=true,expires=clock-1001,sent=clock-1100,granted={action=22}}
check(not H.input(p,state,PY.getPlayerStyle(p))and not H.tickets[p]and ended==1,'expired MP recovery ticket releases its server reservation')
H.tickets[p]={granted={action=23}};H.clear(p);check(not H.tickets[p]and ended==2,'style cancellation releases an unstarted granted lease')
H.receive('ProjectYakuza','heatRushGranted',{player=2,request=999,action=24});check(ended==3,'obsolete grant is released rather than holding an abandoned target')
local responses=PY.HitResponses
function z:setStaggerBack(v)self.stagger=v end;function z:setHitForce(v)self.force=v end;function z:setAttackOutcome(v)self.outcome=v end
z.health=10;z.ignore=false;z.deferred=true;z.useless=false
check(responses.apply(p,z,{kind='stun',force=0})and z.ignore and z.useless and not z.deferred and z.force==0 and not z.stagger,'boost stun stops AI and root movement without push')
clock=clock+100;responses.tickStuns();check(responses.stuns[z]~=nil,'stun remains briefly active')
responses.stun(z);clock=clock+249;responses.tickStuns();check(z.useless,'repeated hits refresh the same stun lease')
clock=clock+2;responses.tickStuns();check(not z.useless and not z.ignore and z.deferred and not responses.stunHooked,'stun restores original AI and movement flags')
responses.stun(z);local previous=R.lock(z);check(not responses.stuns[z]and not previous.useless,'paired finisher takes over a stunned zombie without retaining the temporary stun');R.restore(z,previous)
local victim={x=1.1,y=0,health=10,vars={},ignore=false,deferred=true,blocked=false,authorize=true,total=0}
function victim:getOnlineID()return 26 end;function victim:getX()return self.x end;function victim:getY()return self.y end;function victim:getZ()return 0 end
function victim:isDead()return self.health<=0 end;function victim:isOnFloor()return false end;function victim:isKnockedDown()return false end
function victim:isGodMod()return self.god==true end;function victim:isInvincible()return self.invincible==true end;function victim:isGhostMode()return self.ghost==true end
function victim:isClimbing()return false end;function victim:getVehicle()return nil end;function victim:isFactionPvp()return false end
function victim:getSafety()return {isEnabled=function()return self.safe==true end}end
function victim:isLocalPlayer()return true end;function victim:getPrimaryHandItem()return nil end;function victim:getModData()return {}end
function victim:getIgnoreMovement()return self.ignore end;function victim:setIgnoreMovement(v)self.ignore=v end
function victim:isDeferredMovementEnabled()return self.deferred end;function victim:setDeferredMovementEnabled(v)self.deferred=v end
function victim:isBlockMovement()return self.blocked end;function victim:setBlockMovement(v)self.blocked=v end
function victim:isAuthorizeMeleeAction()return self.authorize end;function victim:setAuthorizeMeleeAction(v)self.authorize=v end
function victim:GetVariable(k)local v=self.vars[k];return type(v)=='boolean'and tostring(v)or v or''end;function victim:setVariable(k,v)self.vars[k]=v end
function victim:getHitReaction()return self.reaction or''end;function victim:setHitReaction(v)self.reaction=v end
function victim:reportEvent(v)self.event=v end;function victim:setTargetAndCurrentDirection()end
function victim:isUseless()error('player target must not call zombie AI APIs')end;function victim:getTarget()error('player target must not call zombie AI APIs')end
function victim:Hit(_,who,amount)check(who==p,'player contact preserves native attacker');self.total=self.total+amount;self.health=self.health-amount end
function victim:setKnockedDown(v)self.knock=v end;function victim:setFallOnFront()end
local originalInstanceof=instanceof;instanceof=function(obj,kind)return obj==victim and kind=='IsoPlayer'or obj~=victim and originalInstanceof(obj,kind)end
local serverFlag=isServer;isServer=function()return true end
local pvp,safety,zone,faction=true,true,false,false
getServerOptions=function()return {getBoolean=function(_,k)return k=='PVP'and pvp or k=='SafetySystem'and safety end}end
NonPvpZone={getNonPvpZone=function()return zone and {}or nil end};local group={};Faction={getPlayerFaction=function()return faction and group or nil end}
function p:getSafety()return {isEnabled=function()return true end}end;function p:isFactionPvp()return false end
p.x=0;p.y=0
check(R.playerAllowed(p,victim),'eligible PvP target is supported')
pvp=false;check(not R.playerAllowed(p,victim),'PvP-off server rejects paired player control');pvp=true
victim.safe=true;check(not R.playerAllowed(p,victim),'both safety flags reject paired player control');victim.safe=false
zone=true;check(not R.playerAllowed(p,victim),'non-PvP zone rejects paired player control');zone=false
faction=true;check(not R.playerAllowed(p,victim),'same-faction protection is retained');faction=false
victim.god=true;check(not R.playerAllowed(p,victim),'god mode rejects paired player control');victim.god=false
victim.invincible=true;check(not R.playerAllowed(p,victim),'invincibility rejects paired player control');victim.invincible=false
victim.ghost=true;check(not R.playerAllowed(p,victim),'ghost protection rejects paired player control');victim.ghost=false
local saved=R.lock(victim);check(victim.ignore and victim.blocked and not victim.authorize and not victim.deferred,'paired PvP victim owns movement and attack locks')
R.restore(victim,saved);check(not victim.ignore and not victim.blocked and victim.authorize and victim.deferred and victim:GetVariable('PerformingAction')=='','player cleanup restores native flags without zombie APIs')
state.active=false;state.step=8;state.activeLightMove=nil;state.multiHitToken={}
local multi=PY.MultiHit;local stamp=state.multiHitToken
H.select(p,z,PY.getPlayerStyle(p),stamp)
multi.swings[p]={stamp=stamp,networkSwing=456,awaiting={[26]=true},awaitUntil=clock+500}
check(multi.waiting(p,stamp)==true,'paired handoff waits for outstanding MP supplemental contacts')
multi.confirm(p,victim,455,.1);check(H.tickets[p].z==z and multi.waiting(p,stamp),'old-swing reply cannot retarget the current finisher')
multi.confirm(p,victim,456,.1);check(H.tickets[p].z==victim and not multi.waiting(p,stamp),'confirmed last supplemental victim wins even after source recovery')
multi.swings[p]={stamp=stamp,networkSwing=456,awaiting={[26]=true},awaitUntil=clock-1}
check(not H.input(p,state,PY.getPlayerStyle(p))and not H.tickets[p],'unconfirmed MP contacts time out without finishing the wrong target')
multi.swings[p]=nil
state.active=true;state.step=8;state.activeLightMove=style.extremeLightAttacks[8];state.multiHitToken={};H.hit(p,victim,token,.1)
check(H.tickets[p]and H.tickets[p].z==victim,'eighth input can select the actual player hit')
state.active=false;p.attacking=false;H.input(p,state,PY.getPlayerStyle(p))
local playerContext=PY.activeActions[p];check(playerContext and playerContext.target.z==victim,'player target enters the same registered paired action')
local playerAction=playerContext.timedAction;playerAction.action={setOverrideHandModelsObject=function()end};playerAction:start()
check(victim.blocked and not victim.authorize,'player paired action locks the correct victim')
for i,prompt in ipairs(playerContext.action.qte.prompts)do phase=(prompt.atMs-100)/1000;mouse[2]=true;playerAction:update();phase=prompt.atMs/1000;mouse[2]=false;playerAction:update()end
check(math.abs(victim.total-2.25)<.000001,'player QTE contacts use canonical native Hit damage')
playerAction:forceStop();check(not victim.blocked and victim.authorize and not victim.ignore,'player interruption restores movement and attack authorization')
PY.Network={acceptSession=function()return true end};getPlayerByOnlineID=function(id)return id==2 and p or id==26 and victim or nil end
function p:isLocalPlayer()return false end
victim.x=1.1;victim.y=0;p.x=0;p.y=0
local playerPose={player=2,action=101,zombie=26,targetKind='player',session=3,age=0,x=0,y=0,fx=1,fy=0}
H.receive('ProjectYakuza','heatRushPose',playerPose)
check(H.remote[2]and H.remote[2].z==victim and victim.blocked and not victim.authorize,'typed remote pose locks the actual local PvP victim')
H.receive('ProjectYakuza','heatRushEnd',{player=2,action=100,session=3})
check(H.remote[2]and victim.blocked,'stale remote end cannot unlock a newer player pairing')
H.receive('ProjectYakuza','heatRushEnd',{player=2,action=101,session=3})
H.updateRemote();check(not H.remote[2]and not victim.blocked and victim.authorize and not H.remoteHook,'remote player completion restores native input and drops the callback')
function p:isLocalPlayer()return true end
instanceof=originalInstanceof;isServer=serverFlag
return true,'PASS '..checks..' generic QTE validation, custom bindings, fresh presses, replay safety, native-phase contacts, canonical damage, paired cleanup and interruption checks'
