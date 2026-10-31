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
function z:reportEvent(v)self.report=v end;function z:setTargetAndCurrentDirection()end
function z:Hit(item,who,amount)check(item==token and who==p,'paired source contact uses native item/actor');self.hits=self.hits+1;self.total=self.total+amount;self.health=self.health-amount end
function z:setKnockedDown(v)self.knock=v end;function z:setFallOnFront()end
function z:getOnlineID()return 25 end
instanceof=function(obj,kind)return kind=='IsoZombie'and obj==z or kind=='IsoPlayer'and obj==p end
do local _="ProjectYakuzaFixture:PATHS" end
do local _="ProjectYakuzaFixture:RUSH_RULES" end
do local _="ProjectYakuzaFixture:RUSH" end
local H=PY.HeatRush;local style=PY.getStyle('dragon_of_dojima');local R=PY.HeatRushRules
PY.setHeat(p,100);check(PY.Heat.start(p),'Extreme Heat starts for paired action')
local state=PY.stateFor(p);state.active=true
for i=1,7 do state.step=i;state.activeLightMove=style.extremeLightAttacks[i];state.multiHitToken={};H.hit(p,z,token,.1);clock=clock+100 end
check(not H.tickets[p],'paired finish never begins before eighth connected light')
state.step=8;state.activeLightMove=style.extremeLightAttacks[8];state.multiHitToken={};H.hit(p,z,token,.1);check(H.tickets[p]and H.tickets[p].z==z,'eighth confirmed hit stores existing target without search/steering')
state.active=false;p.attacking=false;state.lastDown=false;mouse[0]=true
check(H.input(p,state,PY.getPlayerStyle(p)),'fresh extra light requests paired finish')
local c=PY.activeActions[p];check(c and c.kind=='heatAction','registered heat action handler starts')
local a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start()
check(p.blocked and p.ignore and z.useless and z.ignore,'paired action owns movement/AI locks')
for i,prompt in ipairs(c.action.qte.prompts)do
 phase=(prompt.atMs-100)/1000;mouse[2]=true;a:update();check(z.hits==i-1,'QTE input alone never deals early damage')
 phase=prompt.atMs/1000;mouse[2]=false;a:update();check(z.hits==i,'one hit on source contact after successful prompt')
 a:update();check(z.hits==i,'repeated update cannot duplicate contact')
end
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
local U=PY.HeatRushUI;U.create();local panel=U.instances[0]
check(panel.added and panel.background==false and panel.mouse==false,'QTE overlay has no fullscreen panel background and cannot capture mouse')
local qte=Q.create(style.actions.heatAction.qte,down)
H.active[p]={seen=true,qte=qte,elapsed=.8};panel:render();check(draws==1 and panel.lastText:find('MMB'),'QTE prompt uses current configurable binding label')
H.active[p].elapsed=0;panel:render();check(draws==1,'QTE overlay is empty outside prompt windows');H.active[p]=nil
return true,'PASS '..checks..' generic QTE validation, custom bindings, fresh presses, replay safety, native-phase contacts, canonical damage, paired cleanup and interruption checks'
