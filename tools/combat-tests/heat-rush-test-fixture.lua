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
PY.Defense={snapActor=function(actor,x,y)actor.x=x;actor.y=y end,update=function()return false end}
PY.HitEffects={spawn=function()end}
token.data={};token.min=.3;token.max=.5
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
local creates=0;instanceItem=function(name)check(name==PY.TOKEN,'canonical damage item uses B42 factory');creates=creates+1;return {getMinDamage=function()return .3 end,getMaxDamage=function()return .5 end}end
function p:StopTimedActionAnim()self.stoppedAnim=(self.stoppedAnim or 0)+1 end
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
function z:isFallOnFront()return self.front==true end
function z:getHealth()return self.health end;function z:setHealth(v)self.health=v end;function z:setAttackedBy(v)self.attacker=v end
function z:hitConsequences(item,who,skip,amount)check(skip and amount==0 and who==p and self:isDead(),"terminal native consequences only after paired completion");self.deathFinalizations=(self.deathFinalizations or 0)+1 end
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
check(#style.actions.heatAction.contacts==13 and R.duration==326/30,'retail source duration and finishing contact')
check(R.amount(style.actions.heatAction,13,token,{qte={[1]=true,[6]=true}})==.75,'missed QTEs reduce final payoff without applying early damage')
check(style.actions.grab.enabled==true,'ordinary grabs are enabled independently of the QTE grab binding')
local playback=PY.QTEPlayback;local paced=R.qte(style.actions.heatAction)
for i,prompt in ipairs(paced.prompts)do
 check(prompt.windowMs==1000 and style.actions.heatAction.qte.prompts[i].countdownMs==nil,'each two-hit section has one full original-speed one-second countdown')
 check(math.abs(prompt.atMs-(40+i*30)/30*1000)<.00001,'one QTE closes after each original-speed two-hit section')
end
for source=0,7466,13 do check(math.abs(playback.source(style.actions.heatAction.qte,playback.time(style.actions.heatAction.qte,source))-source)<.000001,'paced source and wall clocks round trip throughout the original clip')end
local authored={prompts={{atMs=500,windowMs=400,countdownMs=700,binding='light'},{atMs=900,windowMs=400,countdownMs=1200,binding='grab'}}}
check(Q.valid(authored,1000),'developers author different full countdowns per cue')
local authoredRuntime=playback.definition(authored);check(authoredRuntime.prompts[1].windowMs==700 and authoredRuntime.prompts[2].windowMs==1200,'per-cue countdown values survive runtime compilation')
local late=Q.create(style.actions.heatAction.qte,function()return false end)
for _,prompt in ipairs(late.definition.prompts)do
 Q.update(late,prompt.atMs-1,function(binding)return binding==prompt.binding end)
 Q.update(late,prompt.atMs,function()return false end)
end
check(late.successes==6,'late valid presses pass without changing any original collision deadline')
local legacy=def(2);check(playback.definition(legacy)==legacy and playback.time(legacy,900)==900 and playback.source(legacy,900)==900 and playback.speed(legacy,300)==1,'other unpaced moves keep their existing clocks and speed')
for _,bad in ipairs({{atMs=500,windowMs=400,countdownMs=50,binding='light'},{atMs=500,windowMs=400,countdownMs=1000,sourceStartMs=500,binding='light'},{atMs=500,windowMs=400,sourceStartMs=100,binding='light'}})do check(not Q.valid({prompts={bad}}),'invalid paced timing is rejected')end
for _,age in ipairs({1334,1800,2332})do
 local sample=Q.create(style.actions.heatAction.qte,function()return false end);Q.update(sample,age,function(binding)return binding=='light'end)
 check(sample.accepted[1]==true,'any fresh press from visible ring start until its last moment passes')
end
local expired=Q.create(style.actions.heatAction.qte,function()return false end);Q.update(expired,R.qte(style.actions.heatAction).prompts[1].atMs,function(binding)return binding=='light'end);check(expired.failed and not expired.accepted[1],'input at or after radial expiry cannot pass')
local function shallow(v)local out={};for k,x in pairs(v)do out[k]=x end;return out end
local authored=shallow(style);authored.actions=shallow(style.actions);authored.actions.heatAction=shallow(style.actions.heatAction)
local function invalidContact(index,key,value)
 local contacts={};for i,v in ipairs(style.actions.heatAction.contacts)do contacts[i]=shallow(v)end
 contacts[index][key]=value;authored.actions.heatAction.contacts=contacts
 check(not PY.validateStyle(authored),'invalid mapped contact rejected: '..key)
end
invalidContact(1,'qteIndex',8);invalidContact(2,'qteIndex',1);invalidContact(1,'atMs',-1)
invalidContact(13,'sumQTE','yes');invalidContact(1,'sumQTE',true);invalidContact(1,'strong',2)
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
local currentStyle=PY.getPlayerStyle(p);local hitBefore=p.vars.ProjectYakuzaHitMarker;local chainBefore=p.vars.ProjectYakuzaChainReady
p.vars.ProjectYakuzaHitMarker='';p.vars.ProjectYakuzaChainReady='';state.queued=0;state.recoveryReleased=false
check(not PY.tryRecoveryCancel(p,currentStyle,state),'Rush cannot cancel before the eighth source hit')
p.vars.ProjectYakuzaHitMarker=state.activeLightMove.nodeValue
check(PY.tryRecoveryCancel(p,currentStyle,state)and state.recoveryReleased,'confirmed eighth source hit can hand off before the late chain marker')
state.recoveryReleased=false;p.vars.ProjectYakuzaHitMarker=hitBefore;p.vars.ProjectYakuzaChainReady=chainBefore

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
local a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start();phase=0;a:update()
check(p.blocked and p.ignore and z.useless and z.ignore,'paired action owns movement/AI locks')
check(committed==1,'paired action publishes one exertion commitment when its motion starts')
for _,binding in ipairs({'light','finisher','grab'})do press(binding,false)end
phase=0;a:update()
for i,prompt in ipairs(c.action.qte.prompts)do
 phase=(prompt.atMs-100)/1000;press(prompt.binding,true);a:update();check(z.hits==0,'QTE input alone never deals early damage')
 phase=prompt.atMs/1000+(i==6 and .25 or 0);press(prompt.binding,false);a:update();check(z.hits==0 and a.success.qte[i],'successful prompt is presentation-only until final kick')
 a:update();check(z.hits==0,'repeated update cannot duplicate contact')
end
phase=(c.action.contacts[#c.action.contacts].atMs+1)/1000;a:update();a:update();check(z.hits==0 and not a.pendingDamage and math.abs(z.health-7.75)<.000001,'nonlethal final kick deals earned damage without resetting paired animation')
check(committed==1,'QTE hit count does not publish repeated exertion commitments')
check(z.total==0 and creates==1,'paired victim takes no native hit while its original animation is playing')
p:setVariable('PerformingAction','');function p:getCharacterActions()return {size=function()return 0 end}end
phase=R.duration;a:update()
check(p.vars.IsPerformingAnAction==false,'completed heat action clears native busy flag after selector disappearance')
check(z.hits==0 and math.abs(z.health-7.75)<.000001,'completion cannot duplicate damage already applied at its contact')
check(a.cleaned and not p.blocked and not p.ignore and not z.useless and not z.ignore and z.deferred and z.target==p and z.knock,'full source recovery restores actor/victim state')
check(not PY.activeActions[p]and not H.active[p],'completed paired action releases context')
check(z.nativeFloor==true and math.abs(z.facingX+1)<.000001 and math.abs(z.facingY)<.000001,'paired ending settles a surviving zombie on the ground with its original opposite facing')
p.x=0;p.y=0;z.x=1.1;z.y=0;z.knock=false;mouse[0]=false
local ticket={z=z};check(PY.requestAction(p,'heatAction',nil,ticket),'second paired action can start')
c=PY.activeActions[p];a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};a:start();phase=0
local before=z.hits
phase=c.action.qte.prompts[1].atMs/1000;a:update()
check(a.failed and a.qte.failed and a.animation=='ProjectYakuza_DD_HeatRushFail'and z.useless and z.ignore and p.blocked and a.failurePose,'a missed two-hit section retains the paired victim for the original automatic kick')
check(z.hits==before and not a.pendingDamage,'a missed cue cannot auto-complete or earn the final hit')
paused=true;phase=.3;a:update();check(not a.cleaned,'pause does not consume the failure recovery');paused=false
local kicks=0;local originalPresent=H.present;H.present=function(actor,target,move,index,effects)if index==13 then kicks=kicks+1 end;return originalPresent(actor,target,move,index,effects)end
phase=.3;a:update();phase=c.action.qteFailure.contactMs/1000+.001;a:update();a:update()
check(kicks==1,'failed QTE still plays the source kick contact automatically, exactly once')
H.present=originalPresent;phase=c.action.qteFailure.duration;a:update()
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
pose.age=R.duration+1;H.receive('ProjectYakuza','heatRushPose',pose);check(H.remote[2].age==6.5,'observer rejects poses beyond registered source duration')
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
PY.HitEffects={spawn=function(_,_,_,charged)visualHits=visualHits+1;if visualHits==13 then check(charged,'finishing kick uses supplied stronger sparks')end end}
PY.Feedback={sound=function(_,cue)return cue end,play=function(_,cue)sounds[#sounds+1]=cue end}
for i=1,13 do H.present(p,z,style.actions.heatAction,i)end
check(visualHits==13 and #sounds==13 and sounds[13]=='kickImpact','twelve punches and automatic kick retain bounded fallback contacts without extra invented sound layers')
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
function victim:getHealth()return self.health end;function victim:setHealth(v)self.health=v end;function victim:setAttackedBy(v)self.attacker=v end
function victim:hitConsequences(_,who,skip,amount)check(who==p and skip and amount==0 and self:isDead(),"player terminal consequences after paired completion")end
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
check(H.input(p,state,PY.getPlayerStyle(p))and H.tickets[p]and H.tickets[p].z==victim,'bounded settlement retains the last confirmed victim while waiting briefly')
clock=clock+81;H.input(p,state,PY.getPlayerStyle(p))
local settled=PY.activeActions[p];check(settled and settled.target.z==victim,'bounded settlement starts with the last confirmed target without waiting for an unrelated timeout')
PY.cancelAction(p,'test_settlement');H.tickets[p]=nil
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
phase=(playerContext.action.contacts[#playerContext.action.contacts].atMs+1)/1000;playerAction:update()
check(victim.total==0 and not playerAction.pendingDamage and math.abs(victim.health-7.75)<.000001,'player receives nonlethal damage without native Hit resetting paired animation')
phase=R.duration;playerAction:update();check(victim.total==0 and math.abs(victim.health-7.75)<.000001,'player completion cannot duplicate contact damage')
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
check(PY.getHeat(p)==beforeHeat,'accepted Heat Action reserves its cost without spending before playback')
local ka=kc.timedAction;ka.action={setOverrideHandModelsObject=function()end};phase=0;ka:start()
check(p.invincible and p.ghost and z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_KatanaHeatVictim','framework protects actor and selects the correct original victim clip')
check(ka.animation==p.vars.PerformingAction and p.vars.IsPerformingAnAction==true,'Heat Action owns native animation variables without a cancellable queue item')
local queued=ISTimedActionQueue.add({character=p});check(queued==nil and not ka.cleaned,'native inventory actions cannot replace a running Heat Action')
check(ISTimedActionQueue.add({character={}})~=nil,'unrelated actors keep their normal action queues')
local clip=p.vars.PerformingAction;local oldPhase=phase;fire('OnPlayerUpdate',p);check(ka.seen and not ka.cleaned and p.vars.PerformingAction==clip,'real Runtime drives queue-free paired playback')
check(math.abs(beforeHeat-PY.getHeat(p)-PY.Heat.stockSize(p))<.000001,'visible weapon Heat Action consumes one stock once')

PY.HeatActions.zombie(z);check(z.target==nil,'protected attacker is cleared as a zombie target')
local pairedCues={};PY.on('heatRushHit',function(_,_,index)pairedCues[#pairedCues+1]=index end)
for i,contact in ipairs(kc.action.contacts)do
 phase=contact.atMs/1000+(i==2 and .25 or 0);ka:update();ka:update()
 check(#pairedCues==i and pairedCues[i]==i,'katana emits each of its three impact cues once '..i)
 check(z.hits==beforeHits and math.abs(z.health-(10-({.375,.75,1.5})[i]))<.000001,'each katana strike deals damage without native Hit restarting the victim '..i)
end
check(math.abs(z.health-8.5)<.000001,'weapon action damage uses canonical held weapon without repeated bonus')
phase=kc.action.duration;ka:update()
check(ka.cleaned and not p.invincible and p.ghost,'invulnerability ends with the action while targeting grace remains')
clock=clock+499;PY.HeatActions.tick();check(p.ghost and not p.invincible,'targeting grace grants no extra invulnerability')
clock=clock+1;PY.HeatActions.tick();check(not p.ghost and not PY.HeatActions.active[p],'targeting grace ends after exactly half a second')
do
 PY.resetPlayer(p,'low_health_katana');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=.75;z.useless=false;z.knock=false;z.reaction='';phase=0;PY.setHeat(p,100)
 local prior=z.hits;local deaths=z.deathFinalizations or 0
 check(H.weaponInput(p,PY.stateFor(p),PY.getPlayerStyle(p),true),'low-health target can start the complete katana sequence')
 local context=PY.activeActions[p];local action=context.timedAction;action.action={setOverrideHandModelsObject=function()end};action:start()
 for i,contact in ipairs(context.action.contacts)do
  phase=contact.atMs/1000;action:update();action:update()
  check(math.abs(z.health-.375)<.000001 and not z:isDead(),'nonlethal first hit lands and lethal later contacts preserve positive health '..i)
  check(z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_KatanaHeatVictim'and z.hits==prior,'no native Hit resets the paired victim track '..i)
 end
 check(math.abs(action.pendingDamage-1.125)<.000001,'each withheld katana contact accumulates once')
 phase=context.action.duration-.13;action:update();check(not action.cleaned and not z:isDead(),'victim stays alive through the original recovery')
 phase=context.action.duration;action:update();action:update()
 check(action.cleaned and z:isDead()and z.deathFinalizations==deaths+1,'full completion finalizes death once through native consequences')
 clock=clock+500;PY.HeatActions.tick();z.health=10;z.knock=false;z.useless=false
end
local protect=PY.HeatActions;local key={};p.ghost=true;p.invincible=true
do
 local clips={'KatanaHeat','BottleHeat','HeatRush','WallHeat','GroundHeat','CrateHeat'};local native=z.nativeState
 for _,name in ipairs(clips)do
  z.nativeState='idle';local old=R.lock(z,'ProjectYakuza_DD_'..name..'Victim');z.nativeState='ZombieHitReactionState';R.hold(z)
  check(z.stateLocked and PY.GrabRules.locks[z],'every paired action retains its native hitreaction state '..name)
  R.restore(z,old);check(not z.stateLocked and not PY.GrabRules.locks[z],'paired state lock restores after cleanup '..name)
  z.nativeState='ZombieHitReactionState';old=R.lock(z,'ProjectYakuza_DD_'..name..'Victim');R.hold(z)
  check(z.stateLocked,'paired action also latches a victim that was already reacting '..name)
  R.restore(z,old);check(not z.stateLocked,'already-reacting target restores its original unlocked state '..name)
 end
 z.nativeState=native
end
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
 check(z.hits==before and math.abs(z.health-8.8)<.000001,'bottle contacts apply exactly one canonical final hit')
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
local crateStyle=PY.getPlayerStyle(p);check(crateStyle.weaponProfile=='crate'and R.weaponAllowed(p,crateStyle,crateStyle.actions.heatAction),'crate exposes only its original weapon-specific Heat Action');p.held=nil
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
check(heard==1 and shown==1 and packets==1 and z.hits==health,'legacy damage contact sends one request and presentation without predicting authoritative damage')
check(H.localContacts[p].action==901 and H.localContacts[p].seen[1],'owner records its presented action/contact identity')
local echo={player=2,session=44,action=901,index=1,zombie=25,targetKind='zombie',node=context.action.nodeValue,presentation=true,health=9.5}
H.remoteSessions[2]=nil;H.receive('ProjectYakuza','heatRushContact',echo);H.receive('ProjectYakuza','heatRushContact',echo)
check(heard==1 and shown==1,'first-session server confirmation and duplicate echo cannot replay owner feedback')
check(z.health==9.5,'owner accepts authoritative health even when presentation was predicted')
z.health=10;H.receive('ProjectYakuza','heatRushContact',echo);check(z.health==10,'duplicate old health cannot damage a healed target again')
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

do
 local move=PY.CrateHeatMove
 check(move and move.weaponHeat and move.qteStages and #move.qte.prompts==3 and move.qteFailure.paired,'crate uses a finite three-stage paired mash action')
 check(Q.valid(move.qte,move.duration*1000),'crate mash definition fits original-speed animation')
 local button=false;local taps=0;local q=Q.create(move.qte,function()return button end)
 for i,prompt in ipairs(move.qte.prompts)do
  local start=prompt.atMs-prompt.windowMs
  button=false;Q.update(q,start,function()return button end)
  button=true;Q.update(q,start+100,function()return button end,function(kind)if kind=='tap'then taps=taps+1 end end)
  Q.update(q,start+300,function()return button end)
  check(q.pressCounts[i]==1 and not q.accepted[i],'holding does not spam mash or auto-pass')
  button=false;Q.update(q,start+350,function()return button end)
  button=true;Q.update(q,start+600,function()return button end,function(kind)if kind=='tap'then taps=taps+1 end end)
  check(q.accepted[i]and q.pressCounts[i]==2,'two fresh presses finish an easy mash window')
  button=false;Q.update(q,prompt.atMs,function()return button end)
 end
 check(q.successes==3 and q.closed and taps==6,'mash completes once after six total fresh presses')
 local missed=Q.create(move.qte,function()return false end);Q.update(missed,move.qte.prompts[1].atMs,function()return false end)
 check(missed.failed and missed.failedIndex==1,'no mash immediately selects the authored finite ending')
 local bad={prompts={{atMs=1000,windowMs=1000,binding='heatAction',presses=10,minPressIntervalMs=120}}}
 check(not Q.valid(bad),'impossible mash counts rejected')
 local quick={prompts={{atMs=1000,windowMs=1000,binding='heatAction',presses=2,minPressIntervalMs=200}}};button=false;q=Q.create(quick,function()return button end)
 button=true;Q.update(q,100,function()return button end);button=false;Q.update(q,120,function()return button end);button=true;Q.update(q,150,function()return button end)
 check(q.pressCounts[1]==1 and not q.accepted[1],'too-fast taps cannot bypass minimum mash interval')
 check(move.contacts[#move.contacts].baseDamageMultiplier==1.5,'crate retains base impact damage on an early ending')
end

do
 local oldInstance,oldPlacement,oldCell,oldSafe=instanceof,R.placement,getCell,PY.Defense.safe
 local oldTargets=PY.MultiHit.targets
 local crowd={};for i=1,18 do crowd[i]=setmetatable({x=.4+i*.06,y=0,health=10,vars={},useless=false},{__index=z})end
 instanceof=function(obj,kind)if kind=='IsoZombie'then for _,v in ipairs(crowd)do if obj==v then return true end end end;return oldInstance(obj,kind)end
 PY.resetPlayer(p,'crowd_targets');p.held=katana;p.x=0;p.y=0;p.attacking=false;mouse[1]=true;PY.setHeat(p,100);H.tickets[p]=nil
 local state=PY.stateFor(p);local view=PY.getPlayerStyle(p);local placements=0
 R.placement=function(_,victim)placements=placements+1;if victim==crowd[18]then return {x=0,y=0,fx=1,fy=0}end end
 PY.MultiHit.targets=function(_,_,_,_,limit)local out={};for i=1,math.min(#crowd,limit)do out[i]={victim=crowd[i]}end;return out end
 local target=H.weaponCandidate(p,state,view,true)
 check(target==crowd[18],'blocked nearby zombies cannot hide a placeable Heat Action target beyond the first sixteen')
 check(placements==18,'placement follows nearest-first candidate order until a viable pair is found')
 crowd[18].health=0;placements=0;local repeated=H.weaponCandidate(p,state,view,false)
 check(not repeated,'preview cannot retain a dead target');crowd[18].health=10
 H.previews[p]={style=view,item=katana,z=crowd[1],next=clock+200}
 check(H.weaponCandidate(p,state,view,true)==crowd[18],'fresh input bypasses a stale preview and repeats placement selection')
 local stamp={};H.tickets[p]=nil;H.select(p,crowd[18],style,stamp);local ticket=H.tickets[p]
 check(ticket and ticket.z==crowd[18],'combo contact reserves its feasible victim')
 H.select(p,crowd[1],style,stamp);check(H.tickets[p]==ticket,'later blocked crowd contact cannot overwrite a feasible combo victim')
 H.select(p,nil,style,stamp);check(H.tickets[p]==ticket,'later ineligible contact cannot erase a valid same-swing ticket')
 H.tickets[p]=nil
 local groundMove={enabled=true,groundHeat=true,heatStocks=0}
 local groundStyle={actions={groundHeat=groundMove},comboResetMs=1000}
 for _,v in ipairs(crowd)do v.isOnFloor=function()return true end end
 PY.Defense.safe=function()return true end
 getCell=function()return {getGridSquare=function(_,gx,gy)if gx~=0 or gy~=0 then return end;return {getMovingObjects=function()return {size=function()return #crowd+100 end,get=function(_,i)if i<100 then return p end;return crowd[i-99]end}end}end}end
 placements=0;target=H.groundCandidate(p,state,groundStyle,true)
 check(target==crowd[18]and placements==18,'ground Heat Action scans past unrelated objects and tries farther valid placements')
 H.groundPreviews[p]=nil;H.previews[p]=nil;H.tickets[p]=nil;p.held=nil
 instanceof=oldInstance;R.placement=oldPlacement;getCell=oldCell;PY.Defense.safe=oldSafe;PY.MultiHit.targets=oldTargets
end
do
 PY.resetPlayer(p,'runtime_heat_start');PY.Heat.stop(p,'test');p.x=0;p.y=0;p.held=katana;p.attacking=false;z.x=1.1;z.y=0;z.health=10;z.useless=false;z.knock=false;mouse[1]=true;phase=nil;weight=1
 local before=100;PY.setHeat(p,before);H.tickets[p]=nil
 check(PY.requestAction(p,'heatAction',nil,{z=z}),'runtime fixture accepts a normal weapon Heat Action')
 local context=PY.activeActions[p];local action=context.timedAction
 fire('OnPlayerUpdate',p)
 check(action.started and H.active[p]==action and p.vars.PerformingAction==context.action.animation,'normal player update starts the paired actor and victim without a manual start')
 check(PY.getHeat(p)==before,'missing native playback cannot consume a stock')
 clock=clock+651;fire('OnPlayerUpdate',p)
 check(action.cleaned and not PY.activeActions[p]and PY.getHeat(p)==before and not p.blocked and not z.useless,'missing animation cleans up through Runtime without losing Heat')
 clock=clock+500;PY.HeatActions.tick();p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;phase=nil;PY.setHeat(p,before)
 check(PY.requestAction(p,'heatAction',nil,{z=z}),'action can retry after a failed playback start')
 context=PY.activeActions[p];action=context.timedAction;fire('OnPlayerUpdate',p);phase=.01;fire('OnPlayerUpdate',p)
 local paid=PY.getHeat(p)
 check(action.seen and math.abs(before-paid-PY.Heat.stockSize(p))<.000001,'Runtime confirms visible playback and pays exactly one stock')
 fire('OnPlayerUpdate',p);check(PY.getHeat(p)==paid,'repeated real player updates cannot charge again')
 PY.cancelAction(p,'test_end');check(PY.getHeat(p)==paid,'cancellation after real playback keeps the committed cost')
 clock=clock+500;PY.HeatActions.tick();p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;phase=nil;PY.setHeat(p,before)
 check(PY.requestAction(p,'heatAction',nil,{z=z}),'complete Runtime sequence starts from neutral input')
 context=PY.activeActions[p];action=context.timedAction;fire('OnPlayerUpdate',p);phase=.01;fire('OnPlayerUpdate',p)
 for _,contact in ipairs(context.action.contacts)do phase=contact.atMs/1000;fire('OnPlayerUpdate',p)end
 phase=context.action.duration;fire('OnPlayerUpdate',p)
 check(action.cleaned and not PY.activeActions[p]and z.health<10 and not p.blocked and not z.useless,'real player updates deliver every contact and finish the paired sequence')
 check(math.abs(before-PY.getHeat(p)-PY.Heat.stockSize(p))<.000001,'full Runtime sequence retains exactly one stock payment')
 clock=clock+500;PY.HeatActions.tick();p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;phase=nil;PY.setHeat(p,before)
 check(PY.requestAction(p,'heatAction',nil,{z=z}),'pending playback can be paused')
 context=PY.activeActions[p];action=context.timedAction;paused=true;clock=clock+2000;fire('OnPlayerUpdate',p)
 check(not action.started and PY.getHeat(p)==before,'pause cannot start or charge a pending Heat Action')
 paused=false;fire('OnPlayerUpdate',p);clock=clock+100;fire('OnPlayerUpdate',p)
 paused=true;clock=clock+2000;fire('OnPlayerUpdate',p);paused=false;clock=clock+10;fire('OnPlayerUpdate',p)
 check(not action.cleaned and not action.seen,'paused time cannot exhaust the native startup grace')
 phase=.01;fire('OnPlayerUpdate',p);check(action.seen and context.heatPaid,'playback resumes and commits after a paused startup')
 PY.cancelAction(p,'test_end');clock=clock+500;PY.HeatActions.tick();p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;phase=nil;PY.setHeat(p,before)
 check(PY.requestAction(p,'heatAction',nil,{z=z}),'startup rechecks resources at playback')
 context=PY.activeActions[p];action=context.timedAction;fire('OnPlayerUpdate',p);PY.setHeat(p,0);phase=.01;fire('OnPlayerUpdate',p)
 check(action.cleaned and not context.heatPaid and PY.getHeat(p)==0,'resource loss before playback cancels without a negative or duplicate debit')
 clock=clock+500;PY.HeatActions.tick();p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.knock=false;phase=nil;PY.setHeat(p,PY.Heat.stockSize(p))
 check(PY.Heat.start(p),'last-stock fixture enters Extreme Heat')
 local fuel=PY.Heat.display(p);check(PY.requestAction(p,'heatAction',nil,{z=z}),'one remaining fuel stock can reserve the weapon action')
 context=PY.activeActions[p];action=context.timedAction;fire('OnPlayerUpdate',p)
 check(PY.Heat.isExtreme(p)and PY.Heat.display(p)==fuel,'pending playback cannot deplete the final fuel stock')
 phase=.01;fire('OnPlayerUpdate',p)
 check(action.seen and context.heatPaid and not PY.Heat.isExtreme(p),'confirmed playback pays the last fuel stock and safely ends the mode')
 PY.cancelAction(p,'test_end');clock=clock+500;PY.HeatActions.tick();p.held=nil;PY.Weapons.sync(p)
 local oldFloor=z.isOnFloor
 for _,kind in ipairs({'groundHeat','grabHeat'})do
  PY.resetPlayer(p,'runtime_alias');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=10;z.useless=false;z.knock=false;phase=nil;PY.setHeat(p,before)
  z.isOnFloor=kind=='groundHeat'and function()return true end or oldFloor
  local move=style.actions[kind];local pose=R.placement(p,z,move)
  check(PY.requestAction(p,kind,nil,{z=z,fromGrab=kind=='grabHeat',pose=pose}),'native '..kind..' accepts its own action definition')
  context=PY.activeActions[p];action=context.timedAction
  check(action:isValid()and R.validFor(p,z,move),'pending '..kind..' remains eligible before Runtime startup: '..tostring(action:isValid())..'/'..tostring(R.validFor(p,z,move)))
  fire('OnPlayerUpdate',p);phase=.01;fire('OnPlayerUpdate',p)
  check(action.started and action.seen and context.heatPaid,'real Runtime starts and commits '..kind..' through the shared paired handler')
  PY.cancelAction(p,'test_end');clock=clock+500;PY.HeatActions.tick()
 end
 z.isOnFloor=oldFloor
 PY.HeatActions.clear();p.held=nil;H.tickets[p]=nil
end
do
 local savedTargets=PY.MultiHit.targets
 local function batItem(id)
  local item={data={},condition=10}
  function item:getFullType()return id end;function item:getCondition()return self.condition end
  function item:getMinDamage()return 1 end;function item:getMaxDamage()return 1 end;function item:getModData()return self.data end
  function item:setMinDamage()end;function item:setMaxDamage()end
  return item
 end
 for _,id in ipairs({'Base.BaseballBat','Base.BaseballBat_Crafted','Base.BaseballBat_Metal','Base.BaseballBat_Nails','Base.ShortBat','Base.ShortBat_Nails'})do
  PY.resetPlayer(p,'bat_heat');p.held=batItem(id);p.x=0;p.y=0;p.attacking=false;z.x=1.1;z.y=0;z.health=10;z.useless=false;z.knock=false;mouse[1]=true;phase=nil;PY.setHeat(p,100)
  PY.MultiHit.targets=function()return {{victim=z}}end
  PY.Weapons.sync(p);local view=PY.getPlayerStyle(p);local move=view.actions.heatAction
  check(view.weaponProfile=='bat'and move.motionId=='dod_bat'and not move.qte,'real bat selects its own automatic original scene '..id)
  check(#move.contacts==2 and math.abs(move.contacts[1].atMs-14/30*1000)<.00001 and math.abs(move.contacts[2].atMs-50/30*1000)<.00001,'bat uses both original CMN damage frames')
  check(move.contacts[1].damageMultiplier==.375 and move.contacts[2].damageMultiplier==1.125,'bat preserves original 1:3 victim damage weights')
  check(move.heatStocks==1 and move.useExtremeFuel and move.noCombo,'bat uses existing stock/fuel and neutral-combo rules')
  check(H.weaponInput(p,PY.stateFor(p),view,true),'bat action starts through normal weapon input '..id)
  local context=PY.activeActions[p];local action=context.timedAction;local hits=z.hits
  fire('OnPlayerUpdate',p);check(action.started and not action.seen and PY.getHeat(p)==100,'bat startup without a native track cannot consume Heat')
  phase=.01;fire('OnPlayerUpdate',p);local paid=PY.getHeat(p)
  check(action.seen and math.abs(100-paid-PY.Heat.stockSize(p))<.000001,'confirmed bat playback pays one stock')
  fire('OnPlayerUpdate',p);check(PY.getHeat(p)==paid,'bat payment cannot repeat')
  check(z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_BatHeatVictim'and p.invincible,'bat uses isolated victim motion and shared protection')
  for i,contact in ipairs(move.contacts)do
   phase=(contact.atMs+.001)/1000;fire('OnPlayerUpdate',p);fire('OnPlayerUpdate',p)
   check(z.hits==hits and math.abs(z.health-({9.625,8.5})[i])<.000001,'bat contacts apply canonical damage once without native Hit '..i)
  end
  phase=move.duration;fire('OnPlayerUpdate',p)
  check(action.cleaned and not PY.activeActions[p]and not p.invincible and p.ghost,'bat retains full original recovery and restores control')
  clock=clock+500;PY.HeatActions.tick();check(not p.ghost,'bat targeting grace expires')
  p.held.condition=0;check(not R.weaponAllowed(p,view,move),'broken bat cannot start a Heat Action')
 end
 for _,id in ipairs({'Base.MetalPipe','Base.Nightstick','Base.MetalBar','Base.Katana'})do
  p.held=batItem(id);local view=PY.getPlayerStyle(p)
  check(not R.weaponAllowed(p,view,PY.Weapons.views.dragon_of_dojima.bat.actions.heatAction),'other weapon cannot borrow the bat scene '..id)
 end
 for _,complete in ipairs({false,true})do
  PY.resetPlayer(p,'bat_lethal');p.held=batItem('Base.BaseballBat');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=.2;z.useless=false;z.knock=false;phase=0;PY.setHeat(p,100)
  PY.Weapons.sync(p);check(H.weaponInput(p,PY.stateFor(p),PY.getPlayerStyle(p),true),'low-health victim accepts bat scene')
  local context=PY.activeActions[p];local action=context.timedAction;fire('OnPlayerUpdate',p)
  for _,contact in ipairs(context.action.contacts)do phase=(contact.atMs+.001)/1000;fire('OnPlayerUpdate',p)end
  check(z.health==.2 and math.abs(action.pendingDamage-1.5)<.000001,'both lethal bat hits are reserved through recovery')
  if complete then phase=context.action.duration;fire('OnPlayerUpdate',p);check(z:isDead(),'full bat ending settles earned lethal damage')
  else PY.cancelAction(p,'bat_interrupt');check(z.health==.2,'interrupted bat scene discards reserved lethal damage')end
  clock=clock+500;PY.HeatActions.tick()
 end
 PY.MultiHit.targets=savedTargets;p.held=nil;z.health=10;z.knock=false;PY.HeatActions.clear()
end
do
 local savedTargets=PY.MultiHit.targets
 local function bicycleItem(id)
  local item={data={},condition=10}
  function item:getFullType()return id end;function item:getCondition()return self.condition end
  function item:getMinDamage()return 1 end;function item:getMaxDamage()return 1 end;function item:getModData()return self.data end
  function item:setMinDamage()end;function item:setMaxDamage()end
  return item
 end
 for _,id in ipairs({'ProjectYakuza.Bicycle'})do
  PY.resetPlayer(p,'bicycle_heat');p.held=bicycleItem(id);p.x=0;p.y=0;p.attacking=false;z.x=1.1;z.y=0;z.health=10;z.useless=false;z.knock=false;mouse[1]=true;phase=nil;PY.setHeat(p,100)
  PY.MultiHit.targets=function()return {{victim=z}}end
  PY.Weapons.sync(p);local view=PY.getPlayerStyle(p);local move=view.actions.heatAction
  check(view.weaponProfile=='bicycle'and move.motionId=='dod_bicycle'and not move.qte,'real bicycle selects its own automatic original scene '..id)
  check(#move.contacts==1 and math.abs(move.contacts[1].atMs-58/30*1000)<.00001,'bicycle uses both original CMN damage frames')
  check(move.contacts[1].damageMultiplier==1.5,'bicycle preserves original full Y6 heavy-object damage')
  check(move.heatStocks==1 and move.useExtremeFuel and move.noCombo,'bicycle uses existing stock/fuel and neutral-combo rules')
  check(H.weaponInput(p,PY.stateFor(p),view,true),'bicycle action starts through normal weapon input '..id)
  local context=PY.activeActions[p];local action=context.timedAction;local hits=z.hits
  fire('OnPlayerUpdate',p);check(action.started and not action.seen and PY.getHeat(p)==100,'bicycle startup without a native track cannot consume Heat')
  phase=.01;fire('OnPlayerUpdate',p);local paid=PY.getHeat(p)
  check(action.seen and math.abs(100-paid-PY.Heat.stockSize(p))<.000001,'confirmed bicycle playback pays one stock')
  fire('OnPlayerUpdate',p);check(PY.getHeat(p)==paid,'bicycle payment cannot repeat')
  check(z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_BicycleHeatVictim'and p.invincible,'bicycle uses isolated victim motion and shared protection')
  for i,contact in ipairs(move.contacts)do
   phase=(contact.atMs+.001)/1000;fire('OnPlayerUpdate',p);fire('OnPlayerUpdate',p)
   check(z.hits==hits and math.abs(z.health-({8.5})[i])<.000001,'bicycle contacts apply canonical damage once without native Hit '..i)
  end
  phase=move.duration;fire('OnPlayerUpdate',p)
  check(action.cleaned and not PY.activeActions[p]and not p.invincible and p.ghost,'bicycle retains full original recovery and restores control')
  clock=clock+500;PY.HeatActions.tick();check(not p.ghost,'bicycle targeting grace expires')
  p.held.condition=0;check(not R.weaponAllowed(p,view,move),'broken bicycle cannot start a Heat Action')
 end
 for _,id in ipairs({'Base.MetalPipe','Base.Nightstick','Base.MetalBar','Base.Katana'})do
  p.held=bicycleItem(id);local view=PY.getPlayerStyle(p)
  check(not R.weaponAllowed(p,view,PY.Weapons.views.dragon_of_dojima.bicycle.actions.heatAction),'other weapon cannot borrow the bicycle scene '..id)
 end
 for _,complete in ipairs({false,true})do
  PY.resetPlayer(p,'bicycle_lethal');p.held=bicycleItem('ProjectYakuza.Bicycle');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=.2;z.useless=false;z.knock=false;phase=0;PY.setHeat(p,100)
  PY.Weapons.sync(p);check(H.weaponInput(p,PY.stateFor(p),PY.getPlayerStyle(p),true),'low-health victim accepts bicycle scene')
  local context=PY.activeActions[p];local action=context.timedAction;fire('OnPlayerUpdate',p)
  for _,contact in ipairs(context.action.contacts)do phase=(contact.atMs+.001)/1000;fire('OnPlayerUpdate',p)end
  check(z.health==.2 and math.abs(action.pendingDamage-1.5)<.000001,'lethal bicycle hit are reserved through recovery')
  if complete then phase=context.action.duration;fire('OnPlayerUpdate',p);check(z:isDead(),'full bicycle ending settles earned lethal damage')
  else PY.cancelAction(p,'bicycle_interrupt');check(z.health==.2,'interrupted bicycle scene discards reserved lethal damage')end
  clock=clock+500;PY.HeatActions.tick()
 end
 PY.MultiHit.targets=savedTargets;p.held=nil;z.health=10;z.knock=false;PY.HeatActions.clear()
end
do
 local savedTargets=PY.MultiHit.targets
 local function knifeItem(id)
  local item={data={},condition=10}
  function item:getFullType()return id end;function item:getCondition()return self.condition end
  function item:getMinDamage()return 1 end;function item:getMaxDamage()return 1 end;function item:getModData()return self.data end
  function item:setMinDamage()end;function item:setMaxDamage()end
  return item
 end
 for _,id in ipairs(PY.Weapons.profiles.dragon_of_dojima.knife.items)do
  PY.resetPlayer(p,'knife_heat');p.held=knifeItem(id);p.x=0;p.y=0;p.attacking=false;z.x=1.1;z.y=0;z.health=10;z.useless=false;z.knock=false;mouse[1]=true;phase=nil;PY.setHeat(p,100)
  PY.MultiHit.targets=function()return {{victim=z}}end
  PY.Weapons.sync(p);local view=PY.getPlayerStyle(p);local move=view.actions.heatAction
  check(view.weaponProfile=='knife'and move.motionId=='dod_knife'and not move.qte,'real knife selects its own automatic original scene '..id)
  check(#move.contacts==2 and math.abs(move.contacts[1].atMs-40/30*1000)<.00001 and math.abs(move.contacts[2].atMs-90/30*1000)<.00001,'knife uses both original CMN damage frames')
  check(move.contacts[1].damageMultiplier==.375 and move.contacts[2].damageMultiplier==1.125,'knife preserves original 1:3 victim damage weights')
  check(move.heatStocks==1 and move.useExtremeFuel and move.noCombo,'knife uses existing stock/fuel and neutral-combo rules')
  check(H.weaponInput(p,PY.stateFor(p),view,true),'knife action starts through normal weapon input '..id)
  local context=PY.activeActions[p];local action=context.timedAction;local hits=z.hits
  fire('OnPlayerUpdate',p);check(action.started and not action.seen and PY.getHeat(p)==100,'knife startup without a native track cannot consume Heat')
  phase=.01;fire('OnPlayerUpdate',p);local paid=PY.getHeat(p)
  check(action.seen and math.abs(100-paid-PY.Heat.stockSize(p))<.000001,'confirmed knife playback pays one stock')
  fire('OnPlayerUpdate',p);check(PY.getHeat(p)==paid,'knife payment cannot repeat')
  check(z.vars.ProjectYakuzaPairedVictimClip=='ProjectYakuza_DD_KnifeHeatVictim'and p.invincible,'knife uses isolated victim motion and shared protection')
  for i,contact in ipairs(move.contacts)do
   phase=(contact.atMs+.001)/1000;fire('OnPlayerUpdate',p);fire('OnPlayerUpdate',p)
   check(z.hits==hits and math.abs(z.health-({9.625,8.5})[i])<.000001,'knife contacts apply canonical damage once without native Hit '..i)
  end
  phase=move.duration;fire('OnPlayerUpdate',p)
  check(action.cleaned and not PY.activeActions[p]and not p.invincible and p.ghost,'knife retains full original recovery and restores control')
  clock=clock+500;PY.HeatActions.tick();check(not p.ghost,'knife targeting grace expires')
  p.held.condition=0;check(not R.weaponAllowed(p,view,move),'broken knife cannot start a Heat Action')
 end
 for _,id in ipairs({'Base.MetalPipe','Base.Nightstick','Base.MetalBar','Base.Katana'})do
  p.held=knifeItem(id);local view=PY.getPlayerStyle(p)
  check(not R.weaponAllowed(p,view,PY.Weapons.views.dragon_of_dojima.knife.actions.heatAction),'other weapon cannot borrow the knife scene '..id)
 end
 for _,complete in ipairs({false,true})do
  PY.resetPlayer(p,'knife_lethal');p.held=knifeItem('Base.HuntingKnife');p.x=0;p.y=0;z.x=1.1;z.y=0;z.health=.2;z.useless=false;z.knock=false;phase=0;PY.setHeat(p,100)
  PY.Weapons.sync(p);check(H.weaponInput(p,PY.stateFor(p),PY.getPlayerStyle(p),true),'low-health victim accepts knife scene')
  local context=PY.activeActions[p];local action=context.timedAction;fire('OnPlayerUpdate',p)
  for _,contact in ipairs(context.action.contacts)do phase=(contact.atMs+.001)/1000;fire('OnPlayerUpdate',p)end
  check(z.health==.2 and math.abs(action.pendingDamage-1.5)<.000001,'both lethal knife hits are reserved through recovery')
  if complete then phase=context.action.duration;fire('OnPlayerUpdate',p);check(z:isDead(),'full knife ending settles earned lethal damage')
  else PY.cancelAction(p,'knife_interrupt');check(z.health==.2,'interrupted knife scene discards reserved lethal damage')end
  clock=clock+500;PY.HeatActions.tick()
 end
 PY.MultiHit.targets=savedTargets;p.held=nil;z.health=10;z.knock=false;PY.HeatActions.clear()
end
do
 local savedTargets=PY.MultiHit.targets
 local function held(id)
  return {getFullType=function()return id end,getCondition=function()return 10 end,getMinDamage=function()return 1 end,getMaxDamage=function()return 1 end,getModData=function(self)self.data=self.data or {};return self.data end,setMinDamage=function()end,setMaxDamage=function()end}
 end
 for _,id in ipairs({'Base.Katana','Base.BaseballBat','Base.HuntingKnife','ProjectYakuza.IntactBeerBottle','ProjectYakuza.BeerCrate','ProjectYakuza.Bicycle'})do
  for _,rounded in ipairs({100/6,16.666666030883789})do
   PY.resetPlayer(p,'one_stock');clock=clock+1000;p.held=held(id);p.x=0;p.y=0;p.attacking=false;z.x=1.1;z.y=0;z.health=10;z.useless=false;z.knock=false;mouse[1]=true;phase=nil;PY.MultiHit.targets=function()return {{victim=z}}end;PY.Weapons.sync(p)
   local view=PY.getPlayerStyle(p);PY.setHeat(p,100/6-.0001);check(not H.weaponCandidate(p,PY.stateFor(p),view),'genuinely underfilled stock cannot preview '..id)
   PY.setHeat(p,rounded);check(PY.Heat.stocks(p)==1 and H.weaponCandidate(p,PY.stateFor(p),view)~=nil,'one full or native-rounded orb previews '..id)
   check(H.weaponInput(p,PY.stateFor(p),view,true),'one full or native-rounded orb starts '..id)
   local context=PY.activeActions[p];local action=context.timedAction;fire('OnPlayerUpdate',p);check(not context.heatPaid and PY.getHeat(p)==rounded,'one stock remains until visible playback '..id)
   phase=.01;fire('OnPlayerUpdate',p);check(action.seen and context.heatPaid and PY.getHeat(p)==0,'one stock pays once and reaches zero without cancellation '..id)
   fire('OnPlayerUpdate',p);check(PY.getHeat(p)==0 and not action.cleaned,'paid last-stock action continues '..id)
   PY.cancelAction(p,'one_stock_done');clock=clock+500;PY.HeatActions.tick()
  end
 end
 check(not PY.HeatRules.canAfford(0,100/6)and not PY.HeatRules.canAfford(0/0,100/6)and not PY.HeatRules.canAfford(100/6-.0001,100/6),'shared price tolerance rejects missing, invalid and underfilled resources')
 PY.MultiHit.targets=savedTargets;p.held=nil;PY.Weapons.sync(p)
end
do
 local priorBusy=p.hasTimedActions;local queued
 function p:getCharacterActions()return {size=function()return queued and 1 or 0 end,contains=function(_,v)return queued==v end}end
 function p:hasTimedActions()return queued~=nil or self.vars.IsPerformingAnAction==true end
 local context={player=p,action=PY.getStyle('dragon_of_dojima').actions.heatAction,target={z=z}}
 local owner=H.Action:new(context);PY.activeActions[p]=context
 owner:setActionAnim(context.action.animation);p:setVariable('PerformingAction','')
 check(p:hasTimedActions(),'heat action busy flag survives a native selector reset')
 check(PY.releaseActionAnimation(p,owner,true)and not p:hasTimedActions(),'owned heat animation releases stale native busy state')
 owner.animation=context.action.qteFailure.animation;p:setVariable('PerformingAction',owner.animation);p:setVariable('IsPerformingAnAction',true)
 check(PY.releaseActionAnimation(p,owner,true)and not p:hasTimedActions(),'paired failure clip releases its own native action flag')
 p:setVariable('IsPerformingAnAction',true);queued={}
 check(not PY.releaseActionAnimation(p,owner,true)and p:hasTimedActions(),'heat cleanup preserves foreign queued work after the selector resets')
 queued=nil;p:setVariable('IsPerformingAnAction',false);PY.activeActions[p]=nil;p.hasTimedActions=priorBusy
end
return true,'PASS '..checks..' generic QTE validation, custom bindings, fresh presses, replay safety, native-phase contacts, canonical damage, paired cleanup and interruption checks'
