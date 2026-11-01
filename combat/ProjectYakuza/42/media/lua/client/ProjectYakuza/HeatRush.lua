require "ProjectYakuza/Runtime"
require "ProjectYakuza/NetworkProtocol"
require "ProjectYakuza/HeatRushRules"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/Defense"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local PY=ProjectYakuza;local R=PY.HeatRushRules
local H={chains=setmetatable({}, {__mode="k"}),tickets=setmetatable({}, {__mode="k"}),active=setmetatable({}, {__mode="k"})};PY.HeatRush=H
local function now()return getTimestampMs()end
function H.inputStarted(p,style,step,move)
    if style and style.extremeView and style.heatRush and move.extremeHeat then
        H.chains[p]={count=step,at=now(),stamp=PY.stateFor(p).multiHitToken}
    else H.chains[p]=nil end
end
function H.select(p,z,style,stamp)
    H.discard(p,H.tickets[p])
    if R.validTarget(p,z)then H.tickets[p]={z=z,pressed=true,stamp=stamp,expires=now()+style.heatRush.windowMs};PY.stateFor(p).queued=0 end
end
function H.confirmedSupplement(p,z,damage,stamp)
    local style=PY.getPlayerStyle(p);local s=PY.stateFor(p)
    if style and style.heatRush and style.extremeView and s.step==style.heatRush.hits and s.multiHitToken==stamp
        and not s.finisherMove and not PY.activeActions[p]and damage>0 then H.select(p,z,style,stamp)end
end
function H.hit(p,z,weapon,damage)
    if not p or not p:isLocalPlayer()or type(damage)~="number"or damage<=0 then return end
    local s=PY.stateFor(p);local style=PY.getPlayerStyle(p);local move=s.activeLightMove
    if not style or not style.heatRush or not style.extremeView or not s.active or not move or s.finisherMove or s.groundMove or s.directionalLight or s.queuedFinisher or PY.ChargedHeavy and PY.ChargedHeavy.gestures[p]then return end
    if s.step==style.heatRush.hits then
        H.select(p,z,style,s.multiHitToken)
    end
end
function H.discard(p,ticket)
    if ticket and ticket.granted and PY.Network then PY.Network.send(p,"heatRushEnd",{action=ticket.granted.action})end
    H.tickets[p]=nil
end
function H.input(p,s,style)
    local ticket=H.tickets[p];if not ticket then return false end
    if not p:isAiming()or PY.Bindings.down("finisher")then H.discard(p,ticket);return false end
    if not style.heatRush or not PY.Heat.isExtreme(p)or now()>ticket.expires+(ticket.sent and 1000 or 0) or not R.validTarget(p,ticket.z)then H.discard(p,ticket);return false end
    local down=PY.Bindings.down("light")
    if down and not s.lastDown then ticket.pressed=true end
    if not ticket.pressed then return false end
    s.queued=0
    if PY.MultiHit then
        local waiting=PY.MultiHit.waiting(p,ticket.stamp)
        if waiting=="timeout"then H.discard(p,ticket);return false end
        if waiting then return true end
    end
    if s.active or s.starting or p:isAttackStarted()or p:isPerformingAttackAnimation()then PY.tryRecoveryCancel(p,style,s);return true end
    if isClient()and PY.Network then
        local answer=H.answer
        if answer and answer.p==p then
            H.answer=nil
            if answer.z~=ticket.z:getOnlineID()or (answer.targetKind or "zombie")~=R.targetKind(ticket.z)or answer.request~=ticket.request then return true end
            ticket.granted=answer
        end
        if not ticket.granted then
            if not ticket.sent then ticket.sent=now();H.requestSerial=(H.requestSerial or 0)+1;ticket.request=H.requestSerial;PY.Network.capture(p,true);PY.Network.send(p,"heatRushBegin",{zombie=ticket.z:getOnlineID(),targetKind=R.targetKind(ticket.z),request=ticket.request})end
            if now()-ticket.sent>1000 then H.tickets[p]=nil end
            return true
        end
    end
    H.tickets[p]=nil
    local ok,reason=PY.requestAction(p,"heatAction",nil,ticket)
    if not ok and (reason=="native_attack_busy"or reason=="busy")then H.tickets[p]=ticket;return true end
    H.tickets[p]=nil
    if not ok and ticket.granted then PY.Network.send(p,"heatRushEnd",{action=ticket.granted.action})end
    return true
end
local A=ISBaseTimedAction:derive("ProjectYakuzaHeatRushAction");H.Action=A
function A:isUsingTimeout()return false end
function A:adjustMaxTime(v)return v end
function A:isValid()
    local p=self.character;local z=self.context.target.z;local style=PY.getPlayerStyle(p)
    return style and style.id==self.context.style.id and PY.isEquipped(p)and p:getPrimaryHandItem()==self.held and not p:isDead()and not p:isOnFloor()and not p:isKnockedDown()and not p:getVehicle()and not p:isClimbing()and (p:getHitReaction()or"")==""and z and not z:isDead()and (R.targetKind(z)~="player"or R.playerAllowed(p,z))
end
function H.align(job,time)
    local paths=PY.HeatRushPaths;local p,z=job.p,job.z
    local x,y=R.point(job,paths.actor,time);local zx,zy=R.point(job,paths.victim,time)
    if not PY.NetworkProtocol.path(p,x,y)or not PY.NetworkProtocol.path(z,zx,zy)then return false end
    PY.Defense.snapActor(p,x,y);PY.Defense.snapActor(z,zx,zy);p:setTargetAndCurrentDirection(job.fx,job.fy);z:setTargetAndCurrentDirection(job.fx,job.fy)
    p:getMovementLastFrame():set(0,0);p:setMoving(false);p:setRunning(false);p:setSprinting(false);return true
end
function A:start()
    local p,z=self.character,self.context.target.z;self.started=true;self.last=now();self.elapsed=0;self.index=1;self.success={};self.qte=PY.QTE.create(self.context.action.qte,PY.Bindings.down,self.context)
    self.old={block=p:isBlockMovement(),ignore=p:getIgnoreMovement(),deferred=p:isDeferredMovementEnabled()};p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false)
    local granted=self.context.target.granted;local f=p:getForwardDirection()
    self.pose={p=p,z=z,x=granted and granted.x or p:getX(),y=granted and granted.y or p:getY(),fx=granted and granted.fx or f:getX(),fy=granted and granted.fy or f:getY()}
    self.victim=R.lock(z)
    PY.setVisual(p,true,self.context.action.nodeValue);p:setVariable("ProjectYakuzaStyle",self.context.style.id);p:setVariable("ProjectYakuzaWeaponProfile","");p:setVariable("ProjectYakuzaHeatRush","")
    self:setActionAnim(self.context.action.animation);self.action:setOverrideHandModelsObject(self.held,nil,false)
    H.active[p]=self;PY.Heat.onSwing(p,{damageMultiplier=1})
    if not H.align(self.pose,0)then self:forceStop()end
    if not self.cleaned then PY.emit("attackCommitted",p,self.context.style,self.context.action,self.context,"heatAction")end
    if granted then PY.Network.send(p,"heatRushReady",{action=granted.action})end
end
function A:contact(index)
    if not self.success[index]then return end
    local p,z=self.character,self.context.target.z;local granted=self.context.target.granted
    if granted then PY.Network.send(p,"heatRushHit",{action=granted.action,index=index});return end
    local amount=R.amount(self.context.action,index);if not amount then return end
    if R.targetKind(z)=="player"and not R.playerAllowed(p,z)then return end
    z:Hit(self.held,p,amount,false,1)
    if PY.HitEffects then PY.HitEffects.spawn(p,z,true)end
    if PY.Feedback then PY.Feedback.play(p,PY.Feedback.sound(p,"heavyImpact"),.55)end
    PY.emit("heatRushHit",p,z,index)
end
function A:update()
    if self.cleaned then return end
    local t=now();local dt=math.max(0,t-self.last);self.last=t
    if isGamePaused()then return end
    if not self:isValid()then self:forceStop();return end
    local phase,weight,slot=PY.AttackEffects.findTrack(self.character,self.context.action.animation,self.slot);self.slot=slot
    if phase and weight>=.35 then
        if self.seen and phase+.02<self.elapsed then self:forceStop();return end
        self.seen=true;self.elapsed=phase;self.wait=0
    else self.wait=(self.wait or 0)+dt;if self.seen or self.wait>650 then self:forceStop()end;return end
    if not H.align(self.pose,self.elapsed)then self:forceStop();return end
    PY.QTE.update(self.qte,self.elapsed*1000,PY.Bindings.down,function(kind,index,success,prompt)
        self.index=self.qte.index
        local grant=self.context.target.granted
        if kind=="input"and grant then PY.Network.send(self.character,"heatRushPress",{action=grant.action,index=index})end
        if kind=="result"then self.success[index]=success;if success and self.elapsed*1000-prompt.atMs<=120 then self:contact(index)end end
    end)
    if self.elapsed>=R.duration-.025 or self.character:GetVariable("ProjectYakuzaHeatRush")=="done"then self:forceComplete()end
end
function A:cleanup(done)
    if self.cleaned then return end;self.cleaned=true;local p,z=self.character,self.context.target.z;H.active[p]=nil
    if self.started then
        PY.QTE.cancel(self.qte,done and "complete"or"interrupted")
        p:setBlockMovement(self.old.block==true);p:setIgnoreMovement(self.old.ignore==true);p:setDeferredMovementEnabled(self.old.deferred);p:setVariable("ProjectYakuzaHeatRush","")
        R.restore(z,self.victim)
        if not isClient()and done and self.success[#self.context.action.qte.prompts]and not z:isDead()then z:setKnockedDown(true);z:setFallOnFront(false)end
    end
    local granted=self.context.target.granted;if granted then PY.Network.send(p,"heatRushEnd",{action=granted.action,completed=done==true})end
    if PY.activeActions[p]==self.context then if done then PY.completeAction(p)else PY.cancelAction(p,"heat_rush_interrupted")end end
    PY.resetPlayer(p,"heat_rush_finished")
end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:cancel()self:cleanup(false);if self.action then self:forceStop()end end
function A:new(c)local a=ISBaseTimedAction.new(self,c.player);a.context=c;a.held=c.player:getPrimaryHandItem();a.maxTime=-1;a.stopOnWalk=false;a.stopOnRun=false;a.stopOnAim=false;a.ignoreHandsWounds=true;return a end
PY.registerStyleActionHandler("dragon_of_dojima","heatAction",{
    canStart=function(c)
        local p=c.player;local ticket=c.target;local cfg=c.style.heatRush
        if not p:isAiming()or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:getVehicle()or p:isClimbing()or (p:getHitReaction()or"")~=""or not cfg or not c.action.heatRush or not ticket or isClient()and not ticket.granted or not PY.Heat.isExtreme(p)or not R.validTarget(p,ticket.z)then return false,"not_ready"end
        if p:hasTimedActions()or p:isAttackStarted()or p:isPerformingAttackAnimation()then return false,"native_attack_busy"end
        local f=p:getForwardDirection();return R.space(p,{x=p:getX(),y=p:getY(),fx=f:getX(),fy=f:getY()}),"blocked_space"
    end,
    start=function(c)
        PY.resetPlayer(c.player,"heat_rush_started");local a=A:new(c);c.timedAction=a;c.requestedAt=now();local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cleanup(false);return false,"queue_rejected"end
        return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel()end end,
})
function H.clear(p)
    if p then H.chains[p]=nil;H.discard(p,H.tickets[p]);if H.answer and H.answer.p==p then H.answer=nil end;return end
    local players={};for player in pairs(H.active)do players[#players+1]=player end
    for _,player in ipairs(players)do PY.cancelAction(player,"world_exit")end
    if H.remote then for id,job in pairs(H.remote)do H.remoteEnd(id,job.action)end;H.updateRemote()end
    for player,ticket in pairs(H.tickets)do H.discard(player,ticket)end
    H.chains=setmetatable({}, {__mode="k"});H.tickets=setmetatable({}, {__mode="k"});H.answer=nil
end
PY.on("lightAttackStarted",H.inputStarted)
PY.on("combatHit",H.hit)
PY.on("comboCancelled",function(p,reason)if reason~="recovery_cancel"then H.clear(p)end end)
PY.on("styleChanged",function(p)H.clear(p)end)
Events.OnSave.Add(function()H.clear()end)
Events.OnMainMenuEnter.Add(function()H.clear()end)
H.remote={};H.ended={};H.remoteSessions={}
function H.remoteEnd(id,action,packet)
    if type(action)~="number"then return end;H.ended[id]=math.max(H.ended[id]or 0,action)
    local job=H.remote[id];if not job or job.action~=action then return end;H.remote[id]=nil
    local z=job.z;local saved=R.targetKind(z)=="zombie"and packet or job.old
    if saved and saved~=job.old then saved={useless=saved.useless,ignore=saved.ignore,deferred=saved.deferred,target=job.old.target}end
    R.restore(z,saved or job.old)
end
function H.session(id,session)
    if PY.Network and not PY.Network.acceptSession(id,session)then return false end
    if H.remoteSessions[id]~=session then
        local old=H.remote[id];if old then H.remoteEnd(id,old.action)end
        H.remoteSessions[id]=session;H.ended[id]=nil;H.contacts=H.contacts or {};H.contacts[id]=nil
    end
    return true
end
function H.receive(module,command,a)
    if module~=PY.NetworkProtocol.module or type(a)~="table"or not PY.NetworkProtocol.integer(a.player,0,32767)then return end
    local p=getPlayerByOnlineID(a.player);if not p then return end
    if command=="heatRushGranted"and p:isLocalPlayer()then
        local ticket=H.tickets[p];if not ticket or ticket.request~=a.request then
            if PY.NetworkProtocol.integer(a.action,1,1000000000)and PY.Network then PY.Network.send(p,"heatRushEnd",{action=a.action})end
            return
        end
        if PY.NetworkProtocol.integer(a.action,1,1000000000)and PY.NetworkProtocol.integer(a.zombie,-32768,32767)and PY.NetworkProtocol.number(a.x,-1000000,1000000)and PY.NetworkProtocol.number(a.y,-1000000,1000000)and PY.NetworkProtocol.number(a.fx,-1,1)and PY.NetworkProtocol.number(a.fy,-1,1)then a.p=p;a.z=a.zombie;H.answer=a end;return
    end
    if command=="heatRushDenied"and p:isLocalPlayer()then local ticket=H.tickets[p];if ticket and ticket.request==a.request then H.tickets[p]=nil end;return end
    if command=="heatRushEnd"then if not H.session(a.player,a.session)then return end;H.remoteEnd(a.player,a.action,a);return end
    if command=="heatRushContact"then
        if not H.session(a.player,a.session)or not PY.NetworkProtocol.integer(a.action,1,1000000000)or not PY.NetworkProtocol.integer(a.index,1,32)then return end
        H.contacts=H.contacts or {};local previous=H.contacts[a.player]
        if previous and previous.action>a.action then return end
        if not previous or previous.action~=a.action then previous={action=a.action,seen={}};H.contacts[a.player]=previous end
        if previous.seen[a.index]then return end;previous.seen[a.index]=true;previous.at=now()
        if p:isLocalPlayer()and PY.Feedback then PY.Feedback.play(p,PY.Feedback.sound(p,"heavyImpact"),.55)end
        return
    end
    if command~="heatRushPose"or p:isLocalPlayer()or not PY.NetworkProtocol.integer(a.action,1,1000000000)or not PY.NetworkProtocol.number(a.age,0,R.duration)or not PY.NetworkProtocol.number(a.x,-1000000,1000000)or not PY.NetworkProtocol.number(a.y,-1000000,1000000)or not PY.NetworkProtocol.number(a.fx,-1,1)or not PY.NetworkProtocol.number(a.fy,-1,1)then return end
    if not H.session(a.player,a.session)then return end
    if a.action<=(H.ended[a.player]or 0)then return end
    local z=R.target(p,a.zombie,a.targetKind);if not z then return end
    local old=H.remote[a.player]
    if old and old.action>a.action then return end
    if old and old.action~=a.action then H.remoteEnd(a.player,old.action);old=nil end
    local job=old or {p=p,z=z,action=a.action,old=R.capture(z)}
    job.x,job.y,job.fx,job.fy,job.age,job.at=a.x,a.y,a.fx,a.fy,a.age,now();H.remote[a.player]=job
    if not old then job.old=R.lock(z)end
    if not H.remoteHook then Events.OnTick.Add(H.updateRemote);H.remoteHook=true end
end
function H.updateRemote()
    local t=now();local active=false
    for id,job in pairs(H.remote)do
        if t-job.at>1000 or job.p:isDead()or job.z:isDead()then H.remoteEnd(id,job.action)
        else active=true;if not isGamePaused()then H.align(job,math.min(R.duration,job.age+(t-job.at)/1000))end end
    end
    for key,job in pairs(H.contacts or {})do if t-job.at>6000 then H.contacts[key]=nil end end
    if not active and H.remoteHook then Events.OnTick.Remove(H.updateRemote);H.remoteHook=false end
end
Events.OnServerCommand.Add(H.receive)
Events.OnMainMenuEnter.Add(function()for id,job in pairs(H.remote)do H.remoteEnd(id,job.action)end;H.updateRemote();H.contacts={};H.ended={};H.remoteSessions={}end)
