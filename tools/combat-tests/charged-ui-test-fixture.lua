Events.OnTick=event();Events.OnPostRender=event();Events.OnGameStart=event()
local paused=false
isGamePaused=function()return paused end
PY.Defense={snapActor=function(p,x,y)p.x=x;p.y=y end,update=function()return false end}
function p:isBlockMovement()return self.blocked==true end
function p:getIgnoreMovement()return self.ignored==true end
function p:setIgnoreMovement(v)self.ignored=v end
function p:isDeferredMovementEnabled()return self.deferred~=false end
function p:setDeferredMovementEnabled(v)self.deferred=v end
function p:getX()return self.x or 10 end
function p:getY()return self.y or 12 end
function p:getMovementLastFrame()return {set=function()end}end
function p:setMoving(v)self.moving=v end
function p:setRunning(v)self.running=v end
function p:setSprinting(v)self.sprinting=v end
function p:isOnFloor()return false end
function p:isKnockedDown()return false end
function p:isClimbing()return false end
function p:isAsleep()return false end
function p:isDraggingCorpse()return false end
function p:getVehicle()return nil end
function p:getHitReaction()return self.hit or '' end
function p:hasTimedActions()return self.nativeAction~=nil end
function p:isAimAtFloor()return false end
function p:getCurrentStateName()return self.attacking and 'SwipeStatePlayer' or 'IdleState' end
function p:isAiming()return self.aim~=false end
function base:setActionAnim(v)self.character:setVariable('PerformingAction',v)end
function base:forceStop()self:stop()end
function base:forceComplete()self:perform()end
function base.perform(a)a.character.nativeAction=nil;a.character:setVariable('PerformingAction','')end
function base.stop(a)a.character.nativeAction=nil;a.character:setVariable('PerformingAction','')end
local queueFail=false
ISTimedActionQueue.add=function(a)if queueFail then return nil end;return {removeFromQueue=function()end}end
-- CHARGE
local H=PY.ChargedHeavy
local function state()return PY.stateFor(p)end
local function charge(branch)
 p.aim=true;p.hit='';p.attacking=false;p.nativeAction=nil
 if branch then state().step=branch;state().finishedAt=clock end
 H.input(p,true,true,state(),style);clock=clock+351;H.input(p,true,false,state(),style)
 local c=PY.activeActions[p];check(c and c.kind=='heavyCharge','hold enters native charge action')
 local a=c.timedAction;a.action={setOverrideHandModelsObject=function()end};p.nativeAction=a.action;a:start()
 p:setVariable('ProjectYakuzaChargeClip','started');mouse[2]=true
 return a,c
end
-- The normal input path is release-triggered, and light/double branch queuing survives.
state().step=1;state().finishedAt=clock
H.input(p,true,true,state(),style);check(not state().queuedFinisher,'press does not fire a finisher')
H.input(p,false,false,state(),style);check(state().queuedFinisher==1,'tap release queues ordinary finisher')
PY.Combo.reset(state());state().finisherMove=style.actions.finisher.variants.after_1
H.input(p,true,true,state(),style);H.input(p,false,false,state(),style)
check(state().queuedDouble==true,'tap release retains double finisher input')
PY.Combo.reset(state())
local a,c=charge();check(p.blocked and p.ignored and not p.deferred,'charge locks movement, without invulnerability')
check(PY.blocksNativeAttacks(p) and not PY.attemptAttack(p),'charge blocks native LMB attacks')
p.x=18;p.y=19;a:update();check(p.x==10 and p.y==12 and not p.moving,'charge anchors player while movement is pressed')
local started=a.startedAt;paused=true;clock=clock+1000;a:update();paused=false
check(a.startedAt==started+1000 and not a.cleaned,'pause does not advance charge')
mouse[2]=false;clock=clock+100;a:update();check(not a.cleaned,'early release waits for minimum charge pose')
clock=clock+251;a:update();check(a.cleaned and H.pending[p] and not PY.activeActions[p],'release produces one native attack ticket')
check(not p.blocked and not p.ignored and p.deferred,'charge completion restores previous movement state')
local ticket=H.pending[p];a:perform();check(H.pending[p]==ticket,'duplicate charge completion cannot mint another strike')
local before=p.submissions;H.input(p,false,false,state(),style)
check(p.submissions==before+1 and state().finisherMove.chargedHeavy and ticket.consumed,'release submits one native charged strike')
check(not H.pending[p] and PY.blocksNativeAttacks(p),'accepted strike consumes ticket and locks repeated attacks')
check(not PY.attemptAttack(p),'repeated LMB cannot replay charged hit')
local tokenStamp=state().multiHitToken;fire('OnWeaponSwing',p,token)
check(state().multiHitToken==tokenStamp,'duplicate native swing callback cannot duplicate collision state')
finish();check(not state().finisherBranch and not PY.activeActions[p],'charged hit does not open a double finisher branch')
-- Rejection must not consume entitlement; async native callbacks retain kind.
H.pending[p]={expiresAt=clock+600};p.reject=true
local retry=H.pending[p];H.input(p,false,false,state(),style)
check(H.pending[p]==retry and not retry.consumed and not PY.activeActions[p],'rejected native charge submission can retry inside its window')
p.reject=false;p.async=true;H.input(p,false,false,state(),style)
check(not H.pending[p] and retry.consumed and state().pendingFinisher.chargedHeavy,'async submission consumes ticket before callback')
fire('OnWeaponSwing',p,token);check(state().finisherMove.chargedHeavy,'first asynchronous native swing retains charged classification')
finish();p.async=false
H.pending[p]=ticket;local ok,why=PY.requestAction(p,'chargedHeavy',nil,ticket)
check(not ok and why=='charge_required','consumed strike ticket cannot be reused');H.pending[p]=nil
a,c=charge();p.hit='Bite';a:update()
check(a.cleaned and not H.pending[p] and not p.blocked and not p.ignored,'getting hit cancels charge without damage or lingering locks');p.hit=''
a,c=charge();p.aim=false;a:update();check(a.cleaned and not H.pending[p],'losing aim cancels charge');p.aim=true
a,c=charge();clock=clock+3501;a:update();check(a.cleaned and H.pending[p],'maximum hold auto releases rather than locking player forever')
clock=clock+601;H.input(p,false,false,state(),style);check(not H.pending[p],'expired native handover is dropped')
queueFail=true;H.input(p,true,true,state(),style);clock=clock+351;H.input(p,true,false,state(),style)
check(not PY.activeActions[p] and not p.blocked,'queue rejection restores the player');queueFail=false;H.clearPlayer(p)
-- Validate the production event path's initial-press Tiger Drop priority.
local counters=0;PY.TigerDrop={track=function()end,tryCounter=function()counters=counters+1;return true end}
mouse[2]=false;fire('OnPlayerUpdate',p);mouse[2]=true;fire('OnPlayerUpdate',p)
check(counters==1 and not H.gestures[p] and not PY.activeActions[p],'Tiger Drop on initial press takes priority over charge')
PY.TigerDrop=nil;mouse[2]=false;fire('OnPlayerUpdate',p)
-- Every first finisher has an independent source-derived wind-up and release.
for branch=1,4 do
 local a,c=charge(branch)
 check(c.variant=='after_'..branch and c.action.animation=='ProjectYakuza_DD_ChargeWindup0'..branch,'light branch selects its unique native wind-up')
 check(c.action.minChargeMs>=350,'minimum charge waits for the source wind-up endpoint')
 clock=clock+c.action.minChargeMs+1;mouse[2]=false;a:update()
 local entitlement=H.pending[p]
 check(entitlement and entitlement.branch==branch and entitlement.variant==c.variant,'charge completion preserves selected branch')
 local wrong=branch%4+1
 local accepted,reason=PY.requestAction(p,'chargedHeavy','after_'..wrong,entitlement)
 check(not accepted and reason=='charge_required' and not entitlement.consumed,'ticket cannot be substituted for a different finisher branch')
 H.input(p,false,false,state(),style)
 local move=state().finisherMove
 check(move.chargedFinisher and move.chargeBranch==branch and state().step==branch,'release plays the matching first finisher and restores combo branch')
 H.input(p,true,true,state(),style)
 check(state().queuedDouble and not H.gestures[p],'second finisher queues immediately on press and cannot start charging')
 clock=clock+1000;H.input(p,true,false,state(),style)
 check(PY.activeActions[p].kind=='chargedHeavy' and not H.gestures[p],'holding second-finisher input cannot replace the current action with a charge')
 finish()
 check(state().finisherBranch==branch,'charged first finisher opens the matching ordinary second-finisher branch')
 check(PY.requestAction(p,'finisher','double_after_'..branch),'ordinary second finisher follows charged first finisher')
 H.input(p,true,true,state(),style);clock=clock+1000;H.input(p,true,false,state(),style)
 check(not H.gestures[p] and state().finisherMove.double,'second-finisher playback never grants another charge gesture')
 finish();H.clearPlayer(p)
end
-- A retained first-finisher window cannot be charged through the public API.
state().step=1;state().finishedAt=clock
check(PY.requestAction(p,'finisher','after_1'),'ordinary first finisher can still start')
finish();local allowed,why=PY.requestAction(p,'heavyCharge')
check(not allowed and why=='second_finisher_only','only an ordinary second finisher is allowed in the follow-up window')
PY.Combo.reset(state())
state().step=2;state().finishedAt=clock-300
H.input(p,true,true,state(),style);clock=clock+351
PY.Combo.reset(state()) -- native combo expiry while a valid heavy press is held
H.input(p,true,false,state(),style)
check(PY.activeActions[p] and PY.activeActions[p].variant=='after_2','valid initial charge press retains its branch after combo expiry')
PY.cancelAction(p,'fixture_reset');H.clearPlayer(p)
state().step=1;state().finishedAt=clock
H.input(p,true,true,state(),style);state().active=true;state().step=2
H.input(p,true,false,state(),style)
check(H.gestures[p].branch==2,'a buffered light that really executes updates the charged branch')
H.clearPlayer(p);PY.Combo.reset(state())
-- UI callbacks: isolation, live replacement, styles, channels, pause, cleanup.
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end
getPlayerScreenWidth=function()return 1920 end;getPlayerScreenHeight=function()return 1080 end
getTexture=function(path)return {path=path}end
PY.Heat.display=function()return 50 end;PY.Heat.stocks=function()return 3 end
PY.Heat.isExtreme=function()return false end;PY.Heat.config={maxStocks=6}
local additive=false;SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end}}
-- UI
local U=PY.StyleUI;local host={};local created,updated,destroyed,drawn=0,0,0,0
local provider={create=function(c,s)created=created+1;s.asset=c.texture('supplied.png')end,
 update=function(c,s)updated=updated+1;check(c.heat==50 and c.maxStocks==6 and c.viewport.width==1920,'provider receives live heat and viewport state')end,
 render=function(c,s)drawn=drawn+1;check(s.asset.path=='supplied.png','provider can cache supplied assets');return true end,
 destroy=function()destroyed=destroyed+1 end}
PY.registerStyleUI('test.hud',provider);style.ui={heat='test.hud',status=false,selectorSlot='test.hud'}
check(U.render('heat',p,host),'custom heat renderer replaces built in UI')
clock=clock+16;check(U.render('heat',p,host) and created==1 and drawn==2,'UI state survives frames')
check(U.render('status',p,host),'false hides one channel explicitly')
style.ui.heat=nil;check(not U.render('heat',p,host) and destroyed==1,'omitted channel restores builtin and releases state')
style.ui.heat='missing.provider';check(not U.render('heat',p,host),'missing optional provider safely falls back')
PY.registerStyleUI('broken.hud',{render=function()additive=true;error('intentional addon failure')end,destroy=function()destroyed=destroyed+1 end})
style.ui.heat='broken.hud';check(not U.render('heat',p,host) and not additive,'addon error restores additive renderer state and builtin fallback')
local d=destroyed;check(not U.render('heat',p,host) and destroyed==d,'failed provider is quarantined without per frame errors')
style.ui.heat='test.hud';U.render('heat',p,host);paused=true;clock=clock+500;U.render('heat',p,host)
check(U.sessions[host].heat.context.dt==0,'UI animation clock freezes while paused');paused=false
U.render('selectorSlot',p,host,{style=style,side='left'});d=destroyed
U.render('selectorSlot',p,host,{side='left'});check(destroyed==d+1,'empty selector slot releases previous style presentation')
U.releaseAll(host);check(not U.sessions[host],'panel close releases all addon resources')
style.ui.heat='test.hud';U.render('heat',p,host)
check(PY.unregisterStyleUI('test.hud') and not U.sessions[host].heat,'unregister immediately releases provider resources')
check(not U.render('heat',p,host),'unregistered provider falls back to builtin UI')
style.ui={unknown='test.hud'};check(not PY.validateStyle(style),'unknown UI channels produce validation errors');style.ui=nil
-- Native outline packed ABGR preservation, no stolen target highlights.
local outline=false;local color=3432605235
function p:isOutlineHighlight()return outline end
function p:getOutlineHighlightCol()return color end
function p:setOutlineHighlight(_,v)outline=v end
function p:setOutlineHighlightCol(_,r,g,b,a)color=math.floor(r*255+.5)+math.floor(g*255+.5)*256+math.floor(b*255+.5)*65536+math.floor(a*255+.5)*16777216 end
getPlayer=function()return p end
-- OUTLINE
local O=PY.HeatOutline;local old=color
O.update(p,true);O.draw(p);check(outline and color~=old,'extreme mode applies native blue outline')
O.clear(p);check(not outline and color==old,'outline ends with original packed RGBA and flag restored')
outline=true;O.update(p,true);O.draw(p);check(color==old,'existing game or addon outline is preserved');O.clear(p)
outline=false;O.update(p,true);O.draw(p);color=12345;O.draw(p);O.clear(p)
check(color==12345,'foreign outline takeover is not overwritten on cleanup')
-- Original-texture world effects use native instances and bounded lifecycle.
Core={getTileScale=function()return 2 end};IsoDirections={N='N'}
ColorInfo={new=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end}
local disposed,rendered=0,0
IsoSpriteInstance={add=function()end}
local function instance(sprite)
 return {sprite=sprite,Dispose=function()disposed=disposed+1 end,setScale=function()end,setFrameSpeedPerFrame=function()end,
  SetAlpha=function(self,v)self.alpha=v end,SetTargetAlpha=function()end,
  render=function(self,p,x,y,z,d,dx,dy,color)rendered=rendered+1;self.direction=d;self.dx=dx;self.dy=dy;self.color=color end}
end
IsoSprite={CreateSprite=function()return {LoadFramesNoDirPageSimple=function(self,path)self.path=path end}end}
function p:getZ()return 0 end
function p:getOffsetX()return 0 end;function p:getOffsetY()return 0 end
function p:getForwardDirection()return {getX=function()return self.fx or 1 end,getY=function()return self.fy or 0 end}end
function p:AttachExistingAnim(sprite)self.attached=instance(sprite)end
function p:getAttachedAnimSprite()return {size=function()return self.attached and 1 or 0 end,get=function()return self.attached end,remove=function()self.attached=nil end}end
-- WORLD
-- SPARKS
local E=PY.ChargeEffects
E.update(p);check(not E.hooked,'idle players create no particle render hook')
PY.activeActions[p]={kind='heavyCharge',timedAction={started=true}}
E.update(p);check(#E.states[p].instances==6 and E.hooked,'charge creates six bounded original-texture world sprites')
clock=clock+100;E.update(p);E.render();local time=E.states[p].clock
paused=true;clock=clock+500;E.update(p);E.render();check(E.states[p].clock==time,'world spark animation pauses');paused=false
for _,dir in ipairs({{1,0},{0,1},{-1,0},{0,-1}})do
 p.fx,p.fy=dir[1],dir[2];clock=clock+40;E.update(p);E.render()
 check(E.states[p].instances[1].direction=='N','all character facings use the same world sprite page')
end
local before=disposed;PY.activeActions[p]=nil;E.update(p)
check(not E.states[p] and not E.hooked and disposed==before+6,'ending charge disposes particles and removes render hook')
-- HITS
PY.HitEffects.spawn(p,p,true,true)
local burst=PY.HitEffects.bursts[1]
check(#burst.emitters==9 and burst.charged,'confirmed charged impact selects bounded core and eight original sparks')
PY.HitEffects.render();check(burst.emitters[2].instance.color.b==1,'charged impact uses blue world tint')
before=disposed;PY.HitEffects.clear(p)
check(#PY.HitEffects.bursts==0 and disposed==before+9,'impact cleanup releases every world sprite')
-- Native ISPanel drawing is captured without generating an image.
local hudDraws={};ISPanel={}
function ISPanel:derive()local c={};c.__index=c;setmetatable(c,{__index=self});return c end
function ISPanel:new(x,y,width,height)return setmetatable({x=x,y=y,width=width,height=height},self)end
function ISPanel:initialise()end;function ISPanel:setWantMouseEvents()end;function ISPanel:addToUIManager()end
function ISPanel:drawSubTexture(texture,sx,sy,sw,sh,x,y,w,h,alpha,r,g,b)
 hudDraws[#hudDraws+1]={source={sx,sy,sw,sh},alpha=alpha,r=r,g=g,b=b,path=texture.path}
end
function ISPanel:drawText()end
getSpecificPlayer=function()return p end;UIFont={Small=1}
getKeyName=function(key)return tostring(key)end
local extremeHud=false;PY.Heat.enabled=function()return true end
PY.Heat.isExtreme=function()return extremeHud end
-- HEATUI
local HUD=PY.HeatUI;HUD.create();HUD.instance:prerender()
local function cropped(x,y,w,h)
 local count=0;for _,d in ipairs(hudDraws) do local q=d.source;if q[1]==x and q[2]==y and q[3]==w and q[4]==h then count=count+1 end end;return count
end
check(cropped(130,38,129,121)==1 and cropped(0,38,129,121)==0,'normal HUD keeps original white dragon')
extremeHud=true;clock=clock+101;hudDraws={};HUD.instance:prerender()
check(cropped(0,38,129,121)==1 and cropped(130,38,129,121)==0,'Extreme Heat selects original dark blue dragon head')
check(cropped(0,160,118,138)==1,'Extreme Heat selects matching original dark body')
check(cropped(38,0,37,37)==6 and cropped(114,0,37,37)==6,'all six original dark orb rings/glasses remain connected')
check(cropped(339,0,77,62)==2 and cropped(416,0,92,62)==1,'Extreme Heat uses the original matching dark connectors and tail')
local colored=false;local stockFills=0
for _,d in ipairs(hudDraws) do
 if d.source[1]==0 and d.source[2]==300 and d.r==.52 and d.g==.22 and d.b==1 then colored=true end
 if d.source[1]==266 and d.alpha==.9 then stockFills=stockFills+1 end
end
check(colored and stockFills==0,'original glow is purple-blue and six stock orbs stay dark during mode')
local phase=HUD.instance.frame;paused=true;clock=clock+1000;HUD.instance:prerender();paused=false
check(HUD.instance.frame==phase,'Extreme Heat HUD glow animation pauses')
extremeHud=false;clock=clock+101;hudDraws={};HUD.instance:prerender()
check(cropped(130,38,129,121)==1 and cropped(0,38,129,121)==0,'ending mode restores the white dragon artwork')
check(cropped(0,0,37,37)==6 and cropped(339,63,77,62)==2,'normal orb rings and connectors return after mode')
print('PASS '..checks..' charged heavy, style UI and outline checks')
return checks
