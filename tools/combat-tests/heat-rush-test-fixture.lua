getCell=function()return {getGridSquare=function()return {getMovingObjects=function()return {size=function()return 0 end}end}end}end
local Q=PY.QTE;local held={};local function down(k)return held[k]==true end
local function def(n)local out={prompts={}};for i=1,n do out.prompts[i]={atMs=i*500,windowMs=250,binding=i%2==0 and 'light'or'finisher'}end;return out end
check(Q.valid(def(32))and not Q.valid(def(33)),'framework bounds prompt arrays')
for _,bad in ipairs({{prompts={}}, {prompts={{atMs=0/0,windowMs=100,binding='light'}}},{prompts={{atMs=50,windowMs=100,binding='light'}}},{prompts={{atMs=500,windowMs=100,binding=''}}}})do check(not Q.valid(bad),'invalid QTE definitions rejected')end
check(not Q.valid(def(2),500),'prompt cannot outlive its animation')
local remapped={light=false,finisher=false,grab=false};local inputOrder={'light','finisher','grab','light','finisher','grab'}
local sequence={prompts={}};for i,b in ipairs(inputOrder)do sequence.prompts[i]={atMs=i*500,windowMs=250,binding=b}end
local rebound=Q.create(sequence,function(b)return remapped[b]end)
for i,b in ipairs(inputOrder)do remapped[b]=true;Q.update(rebound,i*500-100,function(k)return remapped[k]end);remapped[b]=false;Q.update(rebound,i*500,function(k)return remapped[k]end)end
check(rebound.successes==6,'six distinct action roles work through an arbitrary binding provider')

local function policy(mode)
 local definition=def(5);definition.failureLimit=2;definition.failureMode=mode
 local held={};local session=Q.create(definition,function(b)return held[b]end)
 for i,prompt in ipairs(definition.prompts)do
  if session.closed then break end
  if i==1 or i==3 then held[prompt.binding]=true;Q.update(session,prompt.atMs-100,function(b)return held[b]end);held[prompt.binding]=false end
  Q.update(session,prompt.atMs,function(b)return held[b]end)
 end
 return session
end
local consecutive=policy('consecutive');local total=policy('total')
check(consecutive.failed and consecutive.failedIndex==5 and consecutive.failures==3 and consecutive.consecutiveFailures==2,'consecutive failure policy resets after a correct press')
check(total.failed and total.failedIndex==4 and total.failures==2,'total failure policy retains separated misses')
for _,change in ipairs({{failureLimit=0},{failureLimit=1.5},{failureMode='anything'},{feedback={gain=2}},{feedback={success=2}}})do
 local bad=def(2);for k,v in pairs(change)do bad[k]=v end;check(not Q.valid(bad),'invalid failure/feedback authoring rejected')
end
local wrong=def(1);wrong.failureLimit=1;local wrongHeld={light=true};local wrongSession=Q.create(wrong,down)
Q.update(wrongSession,400,function(b)return wrongHeld[b]end);Q.update(wrongSession,500,function(b)return wrongHeld[b]end)
check(wrongSession.failed and not wrongSession.results[1],'wrong control cannot count as a successful press')
local overlap={allowOverlap=true,prompts={{atMs=1000,windowMs=400,binding='light'},{atMs=1250,windowMs=400,binding='finisher'}}}
check(Q.valid(overlap),'explicit consistent windows may overlap')
local buttons={};local early=Q.create(overlap,function(b)return buttons[b]end)
buttons.light=true;Q.update(early,700,function(b)return buttons[b]end);buttons.light=false;Q.update(early,710,function(b)return buttons[b]end)
check(Q.promptIndex(early)==2 and early.index==1,'next input is visible before the prior source contact')
buttons.finisher=true;Q.update(early,900,function(b)return buttons[b]end)
check(early.accepted[2]and not early.results[1]and not early.results[2],'next correct press is accepted during its full window without an early impact')
Q.update(early,950,function(b)return buttons[b]end);check(early.promptedIndex==2,'fully accepted prompts do not re-emit an earlier cue before impact')
Q.update(early,1000,function(b)return buttons[b]end);check(early.results[1]and not early.results[2],'first contact retains its source timing')
Q.update(early,1250,function(b)return buttons[b]end);check(early.successes==2 and early.closed,'consistent overlapping windows complete in source order')
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
local keys={};isKeyDown=function(k)return keys[k]==true end
local function press(binding,value)
 local mode=PY.Bindings.mode(binding)
 if mode<4 then mouse[mode-1]=value else keys[PY.Bindings.key(binding)]=value end
end
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
function p:isInvincible()return self.invincible==true end;function p:setInvincible(v)self.invincible=v end
function p:isGhostMode()return self.ghost==true end;function p:setGhostMode(v)self.ghost=v end
function p:getX()return self.x or 0 end;function p:getY()return self.y or 0 end
function p:getIgnoreMovement()return self.ignore==true end;function p:setIgnoreMovement(v)self.ignore=v end
function p:isBlockMovement()return self.blocked==true end
function p:isDeferredMovementEnabled()return self.deferred~=false end;function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:setTargetAndCurrentDirection()end;function p:getMovementLastFrame()return {set=function()end}end
function p:setMoving()end;function p:setRunning()end;function p:setSprinting()end
function base:setActionAnim(v)self.animation=v end
function base:forceComplete()self:perform()end;function base:forceStop()self:stop()end
local z={x=1.1,y=0,health=10,hits=0,total=0,vars={},useless=false,ignore=false,deferred=true,target=p}
function z:getStateMachine()local z=self;return {isLocked=function()return z.stateLocked==true end}end
function z:setStateMachineLocked(v)self.stateLocked=v end;function z:getCurrentStateName()return self.state or "idle"end
function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return 0 end
function z:isDead()return self.health<=0 end;function z:isOnFloor()return false end;function z:isKnockedDown()return false end
function z:isUseless()return self.useless end;function z:setUseless(v)self.useless=v end
function z:isAttacking()return false end;function z:getIgnoreMovement()return self.ignore end;function z:setIgnoreMovement(v)self.ignore=v end
function z:isDeferredMovementEnabled()return self.deferred end;function z:setDeferredMovementEnabled(v)self.deferred=v end
function z:getTarget()return self.target end;function z:setTarget(v)self.target=v end
function z:GetVariable(k)local v=self.vars[k];return type(v)=="boolean"and tostring(v)or v or ""end
function z:setVariable(k,v)self.vars[k]=v end;function z:setHitReaction(v)self.reaction=v end;function z:getHitReaction()return self.reaction or ''end
function z:setAttackOutcome(v)self.outcome=v end
function z:reportEvent(v)self.report=v end;function z:setTargetAndCurrentDirection(x,y)self.facingX=x;self.facingY=y end
function z:Hit(item,who,amount)check(item==token and who==p,'paired source contact uses native item/actor');self.hits=self.hits+1;self.total=self.total+amount;self.health=self.health-amount end
function z:setOnFloor(v)self.nativeFloor=v end;function z:setKnockedDown(v)self.knock=v end;function z:setFallOnFront()end
function z:getOnlineID()return 25 end
instanceof=function(obj,kind)return kind=='IsoZombie'and obj==z or kind=='IsoPlayer'and obj==p end
do local _="ProjectYakuzaFixture:PATHS" end
do local _="ProjectYakuzaFixture:KATANA_PATHS" end
do local _="ProjectYakuzaFixture:BOTTLE_PATHS" end
do local _="ProjectYakuzaFixture:RUSH_RULES" end
do local _="ProjectYakuzaFixture:HEAT_ACTIONS" end
do local _="ProjectYakuzaFixture:QTE_FEEDBACK" end
do local _="ProjectYakuzaFixture:RUSH" end
local committed=0;PY.on("attackCommitted",function(_,_,_,_,kind)if kind=="heatAction"then committed=committed+1 end end)
local H=PY.HeatRush;local style=PY.getStyle('dragon_of_dojima');local R=PY.HeatRushRules
local savedFeedback=PY.Feedback;local heard={}
PY.Feedback={sound=function(_,key)return key end,play=function(_,cue,gain)heard[#heard+1]={cue=cue,gain=gain}end}
local feedbackDefinition=def(3);feedbackDefinition.failureLimit=2;feedbackDefinition.feedback={success='good',miss='miss',failure='fail',gain=.3}
local feedbackHeld={};local feedbackSession=Q.create(feedbackDefinition,function(b)return feedbackHeld[b]end,{player=p,action={qte=feedbackDefinition}})
feedbackHeld.finisher=true;Q.update(feedbackSession,400,function(b)return feedbackHeld[b]end);feedbackHeld.finisher=false;Q.update(feedbackSession,500,function(b)return feedbackHeld[b]end)
Q.update(feedbackSession,1000,function(b)return feedbackHeld[b]end);Q.update(feedbackSession,1500,function(b)return feedbackHeld[b]end);Q.update(feedbackSession,1600,function(b)return feedbackHeld[b]end)
check(#heard==3 and heard[1].cue=='good'and heard[2].cue=='miss'and heard[3].cue=='fail'and heard[1].gain==.3,'framework plays distinct configured success/miss/failure sounds once at the selected gain')
PY.Feedback=savedFeedback

for i,binding in ipairs({'light','finisher','grab','light','finisher','grab'})do check(style.actions.heatAction.qte.prompts[i].binding==binding,'requested six-role QTE order')end
check(#style.actions.heatAction.contacts==7 and R.duration==224/30,'retail source duration and finishing contact')
check(R.amount(style.actions.heatAction,7,token,{[1]=true,[6]=true})==.75,'missed QTEs reduce final payoff without applying early damage')
check(style.actions.grab.enabled==true,'ordinary grabs are enabled independently of the QTE grab binding')
for _,prompt in ipairs(style.actions.heatAction.qte.prompts)do check(prompt.windowMs==600,'all six DoD inputs have a consistent 600 ms visible/accepted window')end
for _,age in ipairs({1267,1500,1866})do
 local sample=Q.create(style.actions.heatAction.qte,function()return false end);Q.update(sample,age,function(binding)return binding=='light'end)
 check(sample.accepted[1]==true,'any fresh press from visible ring start until its last moment passes')
end
local expired=Q.create(style.actions.heatAction.qte,function()return false end);Q.update(expired,56/30*1000,function(binding)return binding=='light'end);check(expired.failed and not expired.accepted[1],'input at or after radial expiry cannot pass')
local function shallow(v)local out={};for k,x in pairs(v)do out[k]=x end;return out end
local authored=shallow(style);authored.actions=shallow(style.actions);authored.actions.heatAction=shallow(style.actions.heatAction)
local function invalidContact(index,key,value)
 local contacts={};for i,v in ipairs(style.actions.heatAction.contacts)do contacts[i]=shallow(v)end
 contacts[index][key]=value;authored.actions.heatAction.contacts=contacts
 check(not PY.validateStyle(authored),'invalid mapped contact rejected: '..key)
end
invalidContact(1,'qteIndex',8);invalidContact(2,'qteIndex',1);invalidContact(1,'atMs',1)
invalidContact(1,'qteIndex',nil);invalidContact(7,'sumQTE','yes');invalidContact(1,'sumQTE',true);invalidContact(1,'strong',2)
local codes={light=20,finisher=21,grab=22}
PY.Bindings.options={getOption=function(_,id)
 local role=id:match('^input_(.+)$');if codes[role]then return {getValue=function()return 4 end}end
 role=id:match('^key_(.+)$');if codes[role]then local code=codes[role];return {getValue=function()return code end}end
end}
local configured=Q.create(style.actions.heatAction.qte,PY.Bindings.down)
for _,v in ipairs(configured.definition.prompts)do
 press(v.binding,true);Q.update(configured,v.atMs-100,PY.Bindings.down)
 press(v.binding,false);Q.update(configured,v.atMs,PY.Bindings.down)
end
check(configured.successes==6,'all six cues use actual remapped keyboard action bindings')
PY.Bindings.options=nil

PY.setHeat(p,100);check(PY.Heat.start(p),'Extreme Heat starts for paired action')
local state=PY.stateFor(p);state.active=true
for i=1,7 do state.step=i;state.activeLightMove=style.extremeLightAttacks[i];state.multiHitToken={};H.inputStarted(p,PY.getPlayerStyle(p),i,state.activeLightMove);clock=clock+100 end
check(not H.tickets[p]and H.chains[p].count==7,'seven missed inputs progress without requiring a target')
z.x=1.65;check(R.validTarget(p,z),'native-hit knockback margin permits a nearby standing victim');z.x=2.01;check(not R.validTarget(p,z),'paired handoff cannot reach beyond two tiles');z.x=1.65
state.step=8;state.activeLightMove=style.extremeLightAttacks[8];state.multiHitToken={};H.hit(p,z,token,.1);check(H.tickets[p]and H.tickets[p].z==z,'eighth confirmed hit stores existing target without search/steering')
check(not PY.blocksNativeAttacks(p),'restored handoff retains the earlier recovery-cancel transition')
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
for _,binding in ipairs({'light','finisher','grab'})do press(binding,false)end
phase=0;a:update()
for i,prompt in ipairs(c.action.qte.prompts)do
 phase=(prompt.atMs-100)/1000;press(prompt.binding,true);a:update();check(z.hits==0,'QTE input alone never deals early damage')
 phase=prompt.atMs/1000+(i==6 and .25 or 0);press(prompt.binding,false);a:update();check(z.hits==0 and a.success[i],'successful prompt is presentation-only until final kick')
 a:update();check(z.hits==0,'repeated update cannot duplicate contact')
end
phase=143/30;a:update();a:update();check(z.hits==0 and math.abs(a.pendingDamage-2.25)<.000001,'final kick queues earned damage without resetting the paired victim track')
check(committed==1,'QTE hit count does not publish repeated exertion commitments')
check(z.total==0 and creates==1,'paired victim takes no native hit while its original animation is playing')
phase=R.duration;a:update()
check(z.hits==1 and math.abs(z.total-2.25)<.000001,'completion applies canonical earned damage once after the paired animation')
check(a.cleaned and not p.blocked and not p.ignore and not z.useless and not z.ignore and z.deferred and z.target==p and z.knock,'full source recovery restores actor/victim state')
check(not PY.activeActions[p]and not H.active[p],'completed paired action releases context')
check(z.nativeFloor==true and math.abs(z.facingX+1)<.000001 and math.abs(z.facingY)<.000001,'paired ending settles a surviving zombie on the ground with its original opposite facing')
p.x=0;p.y=0;z.x=1.1;z.y=0;z.knock=false;mouse[0]=false
local ticket={z=z};check(PY.requestAction(p,'heatAction',nil,ticket),'second paired action can start')
c=PY.activeActions[p];a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start();phase=0
local before=z.hits
phase=c.action.qte.prompts[1].atMs/1000;a:update()
check(a.failed and a.qte.failed and a.animation=='ProjectYakuza_DD_HeatRushFail'and not z.useless and not z.ignore and p.blocked,'first missed prompt releases the victim and plays the original short abort recovery')
check(z.hits==before and not a.pendingDamage,'a missed cue cannot auto-complete or earn the final hit')
paused=true;phase=.3;a:update();check(not a.cleaned,'pause does not consume the failure recovery');paused=false
phase=.3;a:update();phase=20/30;a:update()
check(a.cleaned and not p.blocked and not p.ignore and not z.useless,'failure recovery restores actor movement and protection')

PY.NetworkProtocol.number=function(v,lo,hi)return type(v)=='number'and v==v and v>=lo and v<=hi end
PY.NetworkProtocol.integer=function(v,lo,hi)return PY.NetworkProtocol.number(v,lo,hi)and v==math.floor(v)end
PY.NetworkProtocol.zombie=function()return z end
local currentSession=1;PY.Network={acceptSession=function(_,session)return session==currentSession end}
function p:isLocalPlayer()return false end;function p:getOnlineID()return 2 end
getPlayerByOnlineID=function(id)return id==2 and p end
local pose={player=2,action=10,zombie=25,session=1,age=0,x=0,y=0,fx=1,fy=0}
H.receive('ProjectYakuza','heatRushPose',pose);check(H.remote[2]and z.useless,'remote paired pose enters native victim state')
pose.age=6.5;H.receive('ProjectYakuza','heatRushPose',pose);check(H.remote[2]and H.remote[2].age==6.5,'retail observer accepts poses after the old five-second cutoff')
pose.age=8;H.receive('ProjectYakuza','heatRushPose',pose);check(H.remote[2].age==6.5,'observer rejects poses beyond registered source duration')
pose.age=0

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
H.receive('ProjectYakuza','heatRushFailed',{player=2,action=21,index=1,session=2});pose.action=21;H.receive('ProjectYakuza','heatRushPose',pose)
check(not H.remote[2]and not z.useless,'failure arriving before a late pose cannot re-lock the released victim')

local draws=0
ISPanel={derive=function(self)local cls={};cls.__index=cls;setmetatable(cls,{__index=self});return cls end}
function ISPanel:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h,background=true},{__index=self})end
function ISPanel:getAbsoluteX()return self.x end;function ISPanel:getAbsoluteY()return self.y end
function ISPanel:initialise()end;function ISPanel:setWantMouseEvents(v)self.mouse=v end;function ISPanel:addToUIManager()self.added=true end
function ISPanel:drawSubTexture(texture)if texture.path and texture.path:find('/Input',1,true)then self.inputDraws=(self.inputDraws or 0)+1;self.lastInputIcon=texture.path end end
function ISPanel:drawTextCentre(text,x,y,r,g,b,a)draws=draws+1;self.lastText=text;self.textAlpha=a end
Events.OnGameStart=event();Events.OnCreatePlayer=event();getSpecificPlayer=function()return p end;getNumActivePlayers=function()return 1 end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end;getPlayerScreenWidth=function()return 1920 end;getPlayerScreenHeight=function()return 1080 end
UIFont={Large=1}
do local _="ProjectYakuzaFixture:INPUT_PROMPTS" end
do local _="ProjectYakuzaFixture:RUSH_UI" end
function p:isLocalPlayer()return true end
local U=PY.HeatRushUI;U.create();local panel=U.instances[0]
check(panel.added and panel.background==false and panel.mouse==false,'QTE overlay has no fullscreen panel background and cannot capture mouse')
local qte=Q.create(style.actions.heatAction.qte,down)
getKeyName=function(k)return k==34 and 'G'or tostring(k)end
local polygons={};getTexture=function(path)return {path=path}end
SpriteRenderer={instance={renderPoly=function(_,texture,...)polygons[#polygons+1]={...}end}}
H.active[p]={seen=true,qte=qte,elapsed=1.5};panel:render()
check(draws==0 and panel.inputDraws==1 and panel.lastInputIcon:find('InputMouseLeft',1,true)and #polygons>4 and #polygons<=52,'QTE draws the Y6 left-mouse icon and a bounded radial countdown without extra cues')
check(polygons[5][9]>=.15 and polygons[5][12]>0 and #polygons[5]==20,'radial sectors use native textured UV geometry and bounded blue RGBA')
local firstCount=#polygons;polygons={};H.active[p].elapsed=1.55;panel:render();check(#polygons<firstCount,'blue radial timer loses arc coverage as the source time advances')

H.active[p].elapsed=0;panel:render();check(panel.inputDraws==2 and draws==0,'QTE overlay is empty outside cue lead-in');H.active[p]=nil
H.chains[p]={count=7,at=clock};panel:render();check(panel.inputDraws==2 and draws==0,'punch transition adds no preparatory input cue')
H.chains[p]=nil;H.tickets[p]={expires=clock+700};panel:render();check(panel.inputDraws==2 and draws==0,'paired handoff has no extra ready text')
H.tickets[p].expires=clock-1;panel:render();check(panel.inputDraws==2 and draws==0,'expired handoff has no stale UI');H.tickets[p]=nil

local ended=0;PY.Network={send=function(_,command)if command=='heatRushEnd'then ended=ended+1 end end}
H.tickets[p]={z=z,pressed=true,expires=clock-1001,sent=clock-1100,granted={action=22}}
check(not H.input(p,state,PY.getPlayerStyle(p))and not H.tickets[p]and ended==1,'expired MP recovery ticket releases its server reservation')
H.tickets[p]={granted={action=23}};H.clear(p);check(not H.tickets[p]and ended==2,'style cancellation releases an unstarted granted lease')
H.receive('ProjectYakuza','heatRushGranted',{player=2,request=999,action=24});check(ended==3,'obsolete grant is released rather than holding an abandoned target')
local oldEffects,oldFeedback=PY.HitEffects,PY.Feedback;local visualHits,sounds=0,{}
PY.HitEffects={spawn=function(_,_,_,charged)visualHits=visualHits+1;if visualHits==7 then check(charged,'finishing kick uses supplied stronger sparks')end end}
PY.Feedback={sound=function(_,cue)return cue end,play=function(_,cue)sounds[#sounds+1]=cue end}
for i=1,7 do H.present(p,z,style.actions.heatAction,i)end
check(visualHits==7 and #sounds==9 and sounds[7]=='kickImpact'and sounds[8]=='heavyImpact'and sounds[9]=='heatImpact','seven original contacts carry varied timed effects and finishing sound layers')
PY.HitEffects=oldEffects;PY.Feedback=oldFeedback
local responses=PY.HitResponses


function z:setStaggerBack(v)self.stagger=v end;function z:setHitForce(v)self.force=v end;function z:setAttackOutcome(v)self.outcome=v end
local oldIdle=ZombieIdleState;ZombieIdleState={instance=function()return 'idle'end}
function z:isIgnoreStaggerBack()return self.ignoreStagger==true end;function z:setIgnoreStaggerBack(v)self.ignoreStagger=v end
function z:getCurrentStateName()return self.nativeState or 'ZombieHitReactionState'end;function z:changeState(v)self.nativeState=v end
z.nativeState='StaggerBackState';responses.stun(z)
check(z.ignoreStagger and z.nativeState=='idle'and z:getHitReaction()=='','boost stun suppresses native stagger animation as well as force')
responses.releaseStun(z);check(not z.ignoreStagger,'stun release restores the original native stagger policy');ZombieIdleState=oldIdle
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
p.x=0;p.y=0;z.x=1.1;z.y=0
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
for _,binding in ipairs({'light','finisher','grab'})do press(binding,false)end
phase=0;playerAction:update()
for i,prompt in ipairs(playerContext.action.qte.prompts)do phase=(prompt.atMs-100)/1000;press(prompt.binding,true);playerAction:update();phase=prompt.atMs/1000;press(prompt.binding,false);playerAction:update()end
phase=143/30;playerAction:update()
check(victim.total==0 and math.abs(playerAction.pendingDamage-2.25)<.000001,'player victim animation is preserved until completion')
phase=R.duration;playerAction:update();check(math.abs(victim.total-2.25)<.000001,'player completed rush applies canonical native Hit damage')
check(not victim.blocked and victim.authorize and not victim.ignore,'player interruption restores movement and attack authorization')
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
PY.HeatActions.clear();PY.Network=nil;mouse[0]=false;mouse[1]=false;mouse[2]=false
PY.resetPlayer(p,'katana_test');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;z.reaction=''
PY.Heat.stop(p);PY.setHeat(p,100)
local katana={data={},getFullType=function()return 'Base.Katana'end,getCondition=function()return 10 end,getMinDamage=function()return .8 end,getMaxDamage=function()return 1.2 end}
function katana:getModData()return self.data end;function katana:setMinDamage()end;function katana:setMaxDamage()end
p.held=katana;local blade=PY.getPlayerStyle(p);state=PY.stateFor(p)
check(blade.weaponProfile=='blade'and blade.actions.heatAction.weaponHeat,'katana heat action belongs to the equipped DoD blade view')
local baseBinding=PY.Bindings.byId.heatAction
check(baseBinding and baseBinding.mode==3,'dedicated Heat Action binding defaults to MMB')
local mode=4;local keyDown=false
PY.Bindings.options={getOption=function(_,id)if id=='input_heatAction'then return {getValue=function()return mode end}elseif id=='key_heatAction'then return {getValue=function()return 37 end}end end}
isKeyDown=function(key)return key==37 and keyDown end
check(not PY.Bindings.pressed(p,'heatAction'),'remapped action starts released');keyDown=true
check(PY.Bindings.pressed(p,'heatAction')and not PY.Bindings.pressed(p,'heatAction'),'remapped keyboard binding has one fresh edge')
check(not H.weaponInput(p,state,blade,true)and not H.tickets[p],'keyboard aim alone cannot bypass literal RMB')
mouse[1]=true;state.active=true;check(not H.weaponInput(p,state,blade,true),'active combo blocks weapon heat action')
state.active=false;state.step=1;state.finishedAt=clock
check(not H.weaponInput(p,state,blade,true),'combo follow-up window keeps normal finishers available')
clock=clock+blade.comboResetMs+1
check(R.noCombo(state,blade,clock),'expired neutral combo permits heat actions')
state.step=0;state.finishedAt=nil
local oldTargets=PY.MultiHit.targets;PY.MultiHit.targets=function()return {{victim=z}}end
PY.setHeat(p,0);check(not H.weaponInput(p,state,blade,true),'no stock cannot start weapon heat action');PY.setHeat(p,100)
local oldHit=z.Hit;function z:Hit(item,who,amount)check(item==katana and who==p,'katana action preserves actual weapon');self.hits=self.hits+1;self.health=self.health-amount end
local beforeHeat=PY.getHeat(p);local beforeHits=z.hits
check(H.weaponInput(p,state,blade,true),'remapped action starts only with physical RMB and neutral combo')
local kc=PY.activeActions[p];check(kc and kc.action.weaponHeat and not kc.action.qte,'weapon action uses automatic source contacts')
check(math.abs(beforeHeat-PY.getHeat(p)-PY.Heat.stockSize(p))<.000001,'weapon heat action consumes one stock once')
local ka=kc.timedAction;ka.action={setOverrideHandModelsObject=function()end};phase=0;ka:start()
check(p.invincible and p.ghost and z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_KatanaHeatVictim','framework protects actor and selects the correct original victim clip')
PY.HeatActions.zombie(z);check(z.target==nil,'protected attacker is cleared as a zombie target')
local pairedCues={};PY.on('heatRushHit',function(_,_,index)pairedCues[#pairedCues+1]=index end)
for i,contact in ipairs(kc.action.contacts)do
 phase=contact.atMs/1000+(i==2 and .25 or 0);ka:update();ka:update()
 check(#pairedCues==i and pairedCues[i]==i,'late frame still emits each automatic contact exactly once '..i)
 check(z.hits==beforeHits+(i==4 and 1 or 0),'automatic contact timing is presentation-only until final damage '..i)
end
check(math.abs(z.health-8.5)<.000001,'weapon action damage uses canonical held weapon without repeated bonus')
phase=kc.action.duration;ka:update()
check(ka.cleaned and not p.invincible and p.ghost,'invulnerability ends with the action while targeting grace remains')
clock=clock+499;PY.HeatActions.tick();check(p.ghost and not p.invincible,'targeting grace grants no extra invulnerability')
clock=clock+1;PY.HeatActions.tick();check(not p.ghost and not PY.HeatActions.active[p],'targeting grace ends after exactly half a second')
local protect=PY.HeatActions;local key={};p.ghost=true;p.invincible=true
check(protect.begin(p,key,{duration=1}),'framework API accepts custom action owner');protect.finish(p,key);clock=clock+500;protect.tick()
check(p.ghost and p.invincible,'framework preserves pre-existing native protection flags');p.ghost=false;p.invincible=false
protect.begin(p,key,{duration=1});protect.finish(p,{});check(protect.active[p].playing,'stale action cleanup cannot unlock a newer owner');protect.clear()
check(not p.ghost and not p.invincible and not protect.hooked,'world cleanup cannot leak protection')
check(not protect.begin(p,key,{duration=0})and not protect.begin(p,key,{duration=1,targetGraceMs=2001}),'raw helper bounds protection durations')
protect.begin(p,key,{duration=1});paused=true;clock=clock+5000;protect.tick();paused=false;protect.tick()
check(p.invincible and p.ghost,'pausing does not consume live-action protection')
protect.finish(p,key);clock=clock+500;protect.tick();check(not p.invincible and not p.ghost,'paused action still restores protection on finish')
p.held=nil;z.Hit=oldHit;PY.MultiHit.targets=oldTargets;PY.Bindings.options=nil
for _,id in ipairs({'ProjectYakuza.IntactBeerBottle','ProjectYakuza.IntactWineBottle','ProjectYakuza.IntactWhiskeyBottle'})do
 PY.resetPlayer(p,'bottle_test');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;mouse[1]=true;phase=0;PY.setHeat(p,100)
 local bottle={data={}};function bottle:getFullType()return id end;function bottle:getCondition()return self.condition or 4 end
 function bottle:getMinDamage()return .6 end;function bottle:getMaxDamage()return 1 end;function bottle:getModData()return self.data end
 function bottle:setMinDamage()end;function bottle:setMaxDamage()end
 p.held=bottle;local view=PY.getPlayerStyle(p);local state=PY.stateFor(p)
 check(view.weaponProfile=='bottle'and view.actions.heatAction.motionId=='dod_bottle','spawned bottle uses Short Blunt profile and original paired action')
 local before=z.hits;function z:Hit(item,who,amount)check(item==bottle and who==p,'bottle native contact uses actual weapon');self.hits=self.hits+1;self.health=self.health-amount end
 PY.MultiHit.targets=function()return {{victim=z}}end
 check(H.weaponInput(p,state,view,true),'intact bottle starts eligible Heat Action '..id)
 local context=PY.activeActions[p];local action=context.timedAction;action.action={setOverrideHandModelsObject=function()end};action:start()
 check(z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_BottleHeatVictim','bottle victim clip cannot select the katana motion')
 for _,contact in ipairs(context.action.contacts)do phase=contact.atMs/1000;action:update();action:update()end
 check(z.hits==before+1 and math.abs(z.health-8.8)<.000001,'bottle contacts apply exactly one canonical final hit')
 phase=5;action:update();check(action.cleaned and not p.invincible and p.ghost,'bottle preserves full recovery and action-only invulnerability')
 clock=clock+500;PY.HeatActions.tick();check(not p.ghost,'bottle targeting grace cleans up')
 bottle.condition=0;check(not R.weaponAllowed(p,view,view.actions.heatAction),'broken bottle cannot start the intact-bottle action')
end
p.held=katana;local blade=PY.getPlayerStyle(p);check(not R.weaponAllowed(p,blade,PY.Weapons.views.dragon_of_dojima.bottle.actions.heatAction),'katana cannot borrow bottle Heat Action')
p.held=nil;z.Hit=oldHit;PY.MultiHit.targets=oldTargets;PY.HeatActions.clear()
PY.resetPlayer(p,'prompt_test');p.held=katana;PY.setHeat(p,100);p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.useless=false;mouse[1]=true
local scans=0;PY.MultiHit.targets=function()scans=scans+1;return {{victim=z}}end
getTexture=function(path)return {path=path}end;U.heatIcon=nil
local regions={};function panel:drawSubTexture(texture,sx,sy,sw,sh,x,y,w,h,alpha)if texture.path and texture.path:find('HeatActionIconAtlas',1,true)then regions[#regions+1]={sx=sx,sy=sy,sw=sw,sh=sh,w=w,h=h,alpha=alpha}elseif texture.path and texture.path:find('/Input',1,true)then self.inputDraws=(self.inputDraws or 0)+1;self.lastInputIcon=texture.path end end
panel.promptAt=clock;panel.promptAlpha=0;H.previews[p]=nil
panel:render();check(scans==1 and panel.promptAlpha==0,'eligible prompt starts a bounded preview search with zero initial alpha')
clock=clock+60;panel:render();check(panel.promptAlpha==.5 and scans==1,'prompt fades in fast without repeating target search')
clock=clock+60;panel:render();check(panel.promptAlpha==1 and scans==1 and panel.lastInputIcon:find('InputMouseMiddle',1,true),'fully visible prompt displays the current mouse binding')
check(#regions==4 and regions[1].w==64 and regions[1].h==80 and regions[2].sx==64 and regions[2].sw==64,'prompt reuses the original Y6 flame and glow at native resolution')
PY.Bindings.options={getOption=function(_,id)if id=='input_heatAction'then return {getValue=function()return 4 end}elseif id=='key_heatAction'then return {getValue=function()return 37 end}end end}
getKeyName=function()return 'K'end
clock=clock+1;panel:render();check(panel.lastText=='K'and panel.lastInputIcon:find('InputKeycap',1,true),'prompt draws the rebound keyboard name over the original game keycap')
mouse[1]=false;clock=clock+80;panel:render();check(panel.promptAlpha==0 and scans==1,'losing RMB eligibility fades the prompt out and stops searching')
PY.Bindings.options=nil;p.held=nil;PY.MultiHit.targets=oldTargets;H.previews[p]=nil
p.held={getFullType=function()return 'ProjectYakuza.BeerCrate'end,getCondition=function()return 8 end}
local crateStyle=PY.getPlayerStyle(p);check(crateStyle.weaponProfile=='crate'and not R.weaponAllowed(p,crateStyle,crateStyle.actions.heatAction),'original crate uses DoD Short Blunt combat without borrowing the bottle Heat Action');p.held=nil
PY.resetPlayer(p,'network_feedback');p.held=katana;p.attacking=false;p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;mouse[1]=true;clock=clock+2000;PY.setHeat(p,100)
PY.MultiHit.targets=function()return {{victim=z}}end
check(H.weaponInput(p,PY.stateFor(p),PY.getPlayerStyle(p),true),'network feedback fixture starts the actual paired action')
local context=PY.activeActions[p];local action=context.timedAction;action.action={setOverrideHandModelsObject=function()end};phase=0;action:start()
local client,network,feedback,effects=isClient,PY.Network,PY.Feedback,PY.HitEffects;local heard,shown,packets=0,0,0
isClient=function()return true end
PY.Network={send=function(_,command)if command=='heatRushHit'then packets=packets+1 end end,capture=function()end,acceptSession=function(_,session)return session==44 end}
PY.Feedback={sound=function(_,cue)return cue end,play=function()heard=heard+1 end};PY.HitEffects={spawn=function()shown=shown+1 end}
context.target.granted={action=901,session=44};local health=z.hits
phase=context.action.contacts[1].atMs/1000+.25;action:update();action:update()
check(heard==1 and shown==1 and packets==1 and z.hits==health,'owner source contact presents audio/FX without predicting authoritative damage or repeating')
check(H.localContacts[p].action==901 and H.localContacts[p].seen[1],'owner records its presented action/contact identity')
local echo={player=2,session=44,action=901,index=1,zombie=25,targetKind='zombie',node=context.action.nodeValue,presentation=true}
H.remoteSessions[2]=nil;H.receive('ProjectYakuza','heatRushContact',echo);H.receive('ProjectYakuza','heatRushContact',echo)
check(heard==1 and shown==1,'first-session server confirmation and duplicate echo cannot replay owner feedback')
action:cleanup(false);H.receive('ProjectYakuza','heatRushContact',echo)
check(heard==1 and shown==1,'late confirmation after cleanup cannot replay a locally presented contact')
echo.session=43;H.receive('ProjectYakuza','heatRushContact',echo);check(heard==1,'stale session remains rejected before feedback')
isClient=client;PY.Network=network;PY.Feedback=feedback;PY.HitEffects=effects;p.held=nil;PY.MultiHit.targets=oldTargets;PY.HeatActions.clear()
do
 local old=R.capture(z);old.locked=false;z.stateLocked=true;PY.GrabRules.locks[z]=true;z:setVariable('ProjectYakuzaPairedVictimClip','ProjectYakuza_DD_WallHeatVictim');z:setVariable('ProjectYakuzaHeatRushVictim',true)
 H.remote[99]={p=p,z=z,old=old,action=998}
 H.remoteEnd(99,998,{locked=false,useless=false,ignore=false,deferred=true,completed=false})
 check(not z.stateLocked,'observer wall cleanup restores the authoritative AI-lock state')
 local oldNetwork,oldLookup,oldTarget=PY.Network,getPlayerByOnlineID,R.target
 function p:isLocalPlayer()return false end
 z.health=10;z.stateLocked=true;PY.GrabRules.locks[z]=true;z.useless=true;z.ignore=true;z.deferred=false
 PY.Network={acceptSession=function()return true end,remote={[2]={grab=z,grabRestore={locked=false,useless=false,ignore=false,deferred=true}}}}
 getPlayerByOnlineID=function()return p end;R.target=function()return z end
 H.receive('ProjectYakuza','heatRushPose',{player=2,session=44,action=998,motionId='dod_wall',age=0,x=0,y=0,fx=1,fy=0,zombie=3})
 check(H.remote[2]and not H.remote[2].old.locked and not H.remote[2].old.useless and not PY.Network.remote[2].grab,'wall observer captures originals after releasing its grab ownership')
 H.remoteEnd(2,998);check(not z.stateLocked and not z.useless and not z.ignore and z.deferred,'observer timeout cannot leave old grab flags or lock behind')
 function p:isLocalPlayer()return true end
 PY.Network=oldNetwork;getPlayerByOnlineID=oldLookup;R.target=oldTarget
 local savedNetwork,savedLookup=PY.Network,getPlayerByOnlineID;PY.Network=nil;getPlayerByOnlineID=function()return p end
 local cancelled=0;H.active[p]={context={target={granted={action=999}}},cancel=function()cancelled=cancelled+1;H.active[p]=nil end}
 H.receive('ProjectYakuza','heatRushEnd',{player=2,session=45,action=999,completed=false})
 H.receive('ProjectYakuza','heatRushEnd',{player=2,session=45,action=999,completed=false})
 check(cancelled==1,'server abort cancels the matching owner action once')
 PY.Network=savedNetwork;getPlayerByOnlineID=savedLookup
end
return true,'PASS '..checks..' generic QTE validation, custom bindings, fresh presses, replay safety, native-phase contacts, canonical damage, paired cleanup and interruption checks'
