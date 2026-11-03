require "ProjectYakuza/Runtime"
require "ProjectYakuza/NetworkProtocol"
require "ProjectYakuza/HeatRushRules"
require "ProjectYakuza/HeatActions"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/Defense"
require "ProjectYakuza/QTEFeedback"
require "ProjectYakuza/Feedback"
require "ProjectYakuza/CombatVoices"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local PY=ProjectYakuza;local R=PY.HeatRushRules
local H={chains=setmetatable({}, {__mode="k"}),tickets=setmetatable({}, {__mode="k"}),active=setmetatable({}, {__mode="k"}),localContacts=setmetatable({}, {__mode="k"})};PY.HeatRush=H
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
    if not p:isAiming()or ticket.weapon and not isMouseButtonDown(1)or not ticket.weapon and PY.Bindings.down("finisher")then H.discard(p,ticket);return false end
    local action=style.actions.heatAction
    if ticket.weapon then
        local cost=action and (action.heatStocks or 0)*PY.Heat.stockSize(p)or 0
        if not R.weaponAllowed(p,style,action)or not R.noCombo(s,style,now())or PY.actionHeat(p,action)<cost then H.discard(p,ticket);return false end
    elseif not style.heatRush or not PY.Heat.isExtreme(p)then H.discard(p,ticket);return false end
    if now()>ticket.expires+(ticket.sent and 1000 or 0)or not R.validTarget(p,ticket.z)then H.discard(p,ticket);return false end
    local down=PY.Bindings.down("light")
    if down and not s.lastDown then ticket.pressed=true end
    if not ticket.pressed then return false end
    s.queued=0
    if not ticket.weapon and PY.MultiHit then
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
            if not ticket.sent then ticket.sent=now();H.requestSerial=(H.requestSerial or 0)+1;ticket.request=H.requestSerial;PY.Network.capture(p,true);PY.Network.send(p,"heatRushBegin",{zombie=ticket.z:getOnlineID(),targetKind=R.targetKind(ticket.z),request=ticket.request,weaponHeat=ticket.weapon==true})end
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
H.previews=setmetatable({}, {__mode="k"})
function H.weaponReady(p,s,style)
    if not p or not style or not PY.isEquipped(p)or not isMouseButtonDown(1)or not p:isAiming()or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:getVehicle()or p:isClimbing()or (p:getHitReaction()or"")~=""or PY.activeActions[p]or H.tickets[p]or not R.noCombo(s,style,now())then return end
    local action=style.actions.heatAction
    if not R.weaponAllowed(p,style,action)or PY.actionHeat(p,action)<(action.heatStocks or 0)*PY.Heat.stockSize(p)then return end
    if p:hasTimedActions()or p:isAttackStarted()or p:isPerformingAttackAnimation()then return end
    return action
end
function H.weaponCandidate(p,s,style,force)
    local action=H.weaponReady(p,s,style)
    if not action then H.previews[p]=nil;return end
    local cached=H.previews[p];local t=now();local item=p:getPrimaryHandItem()
    if not force and cached and cached.style==style and cached.item==item and t<cached.next then
        if cached.z and R.validTarget(p,cached.z)then return cached.z,action end
        return
    end
    cached={style=style,item=item,next=t+200};H.previews[p]=cached
    local selected,distance
    local function consider(z)
        if R.validTarget(p,z)and PY.NetworkProtocol.path(p,z:getX(),z:getY())then
            local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local d=dx*dx+dy*dy
            if not distance or d<distance then selected=z;distance=d end
        end
    end
    local origin=PY.MultiHit.origin(p,R.targetRange);if not origin then return end
    for _,entry in ipairs(PY.MultiHit.targets(p,origin,false,{},16))do consider(entry.victim)end
    if isClient()then
        local players=getOnlinePlayers();for i=0,players:size()-1 do consider(players:get(i))end
    elseif getNumActivePlayers then for i=0,getNumActivePlayers()-1 do consider(getSpecificPlayer(i))end end
    if selected then
        local f=p:getForwardDirection()
        if R.space(p,{x=p:getX(),y=p:getY(),fx=f:getX(),fy=f:getY(),motion=R.motion(action),duration=R.durationFor(action)})then cached.z=selected;return selected,action end
    end
end
function H.weaponInput(p,s,style,pressed)
    if not pressed then return false end
    local selected=H.weaponCandidate(p,s,style,true)
    if not selected then return false end
    H.tickets[p]={z=selected,pressed=true,weapon=true,expires=now()+600}
    return H.input(p,s,style)
end
local A=ISBaseTimedAction:derive("ProjectYakuzaHeatRushAction");H.Action=A
function A:isUsingTimeout()return false end
function A:adjustMaxTime(v)return v end
function A:isValid()
    local p=self.character;local z=self.context.target.z;local style=PY.getPlayerStyle(p)
    return style and style.id==self.context.style.id and PY.isEquipped(p)and p:getPrimaryHandItem()==self.held and not p:isDead()and not p:isOnFloor()and not p:isKnockedDown()and not p:getVehicle()and not p:isClimbing()and (p:getHitReaction()or"")==""and (self.failed or z and (not z:isDead()or self.finalRequested)and (R.targetKind(z)~="player"or R.playerAllowed(p,z)))
end
function H.align(job,time)
    local paths=job.motion or PY.HeatRushPaths;local p,z=job.p,job.z
    local x,y=R.point(job,paths.actor,time);local zx,zy=R.point(job,paths.victim,time)
    if not PY.NetworkProtocol.path(p,x,y)or not z:isDead()and not PY.NetworkProtocol.path(z,zx,zy)then return false end
    PY.Defense.snapActor(p,x,y);p:setTargetAndCurrentDirection(job.fx,job.fy)
    if not z:isDead()then PY.Defense.snapActor(z,zx,zy);z:setTargetAndCurrentDirection(job.fx,job.fy)end
    p:getMovementLastFrame():set(0,0);p:setMoving(false);p:setRunning(false);p:setSprinting(false);return true
end
function A:start()
    local p,z=self.character,self.context.target.z;self.started=true;self.last=now();self.elapsed=0;self.index=1;self.success={};self.autoSeen={};self.qte=self.context.action.qte and PY.QTE.create(self.context.action.qte,PY.Bindings.down,self.context)
    self.old={block=p:isBlockMovement(),ignore=p:getIgnoreMovement(),deferred=p:isDeferredMovementEnabled()};p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false)
    local granted=self.context.target.granted;local f=p:getForwardDirection()
    self.pose={p=p,z=z,x=granted and granted.x or p:getX(),y=granted and granted.y or p:getY(),fx=granted and granted.fx or f:getX(),fy=granted and granted.fy or f:getY()}
    self.pose.motion=R.motion(self.context.action);self.pose.duration=R.durationFor(self.context.action)
    self.victim=R.lock(z,self.context.action.targetAnimation)
    PY.setVisual(p,true,self.context.action.nodeValue);p:setVariable("ProjectYakuzaStyle",self.context.style.id);p:setVariable("ProjectYakuzaWeaponProfile",self.context.style.weaponProfile or "");p:setVariable("ProjectYakuzaHeatRush","")
    self:setActionAnim(self.context.action.animation);self.action:setOverrideHandModelsObject(self.held,nil,false)
    H.active[p]=self;PY.HeatActions.begin(p,self,self.context.action);PY.Heat.onSwing(p,{damageMultiplier=1})
    if not H.align(self.pose,0)then self:forceStop()end
    if not self.cleaned then PY.emit("attackCommitted",p,self.context.style,self.context.action,self.context,"heatAction")end
    if granted then PY.Network.send(p,"heatRushReady",{action=granted.action})end
end
function H.present(p,z,move,index,effects)
    local contact=R.contacts(move)[index];if not contact then return end
    if effects~=false and PY.HitEffects then PY.HitEffects.spawn(p,z,contact.strong~=false,contact.charged==true)end
    if p:isLocalPlayer()and PY.Feedback then
        PY.Feedback.play(p,PY.Feedback.sound(p,contact.cue or "heavyImpact")or PY.Feedback.sound(p,"heavyImpact")or PY.Feedback.sound(p,"finisher"),.55)
        for _,cue in ipairs(contact.layers or {})do PY.Feedback.play(p,PY.Feedback.sound(p,cue),.3)end
    end
    PY.emit("heatRushHit",p,z,index,contact)
end
function A:contact(index)
    if not self.success[index]then return end
    local p,z=self.character,self.context.target.z;local granted=self.context.target.granted
    if index==#R.contacts(self.context.action)then self.finalRequested=true end
    if granted then
        local previous=H.localContacts[p]
        if not previous or previous.action~=granted.action or previous.session~=granted.session then previous={action=granted.action,session=granted.session,seen={}};H.localContacts[p]=previous end
        if not previous.seen[index]then
            previous.seen[index]=true
            local amount=R.amount(self.context.action,index,self.held,self.success)
            H.present(p,z,self.context.action,index,self.context.action.deferFinalDamage==true or amount==0 or R.targetKind(z)=="player")
        end
        PY.Network.send(p,"heatRushHit",{action=granted.action,index=index});return
    end
    local amount=R.amount(self.context.action,index,self.held,self.success);if not amount then return end
    if R.targetKind(z)=="player"and not R.playerAllowed(p,z)then return end
    if amount>0 then if self.context.action.deferFinalDamage then self.pendingDamage=amount else z:Hit(self.held,p,amount,false,1)end end
    H.present(p,z,self.context.action,index)
end
function A:fail(index,remote)
    if self.failed or self.cleaned then return end
    local recovery=self.context.action.qteFailure
    if not recovery then self:forceStop();return end
    self.failed=true;self.failedIndex=index;self.failureStarted=now();self.failureElapsed=0;self.failureSeen=false;self.slot=nil;self.pendingDamage=nil
    if remote and not self.qte.failed and PY.QTEFeedback then PY.QTEFeedback.play(self.context,"failure")end
    PY.QTE.cancel(self.qte,"failed")
    if not self.victimRestored then R.restore(self.context.target.z,self.victim);self.victimRestored=true end
    local p=self.character;PY.setVisual(p,true,recovery.nodeValue);p:setVariable("ProjectYakuzaHeatRush","");self:setActionAnim(recovery.animation)
    if not remote and self.context.target.granted then PY.Network.send(p,"heatRushFail",{action=self.context.target.granted.action,index=index})end
    if PY.Network then PY.Network.capture(p,true,true)end
end
function A:update()
    if self.cleaned then return end
    local t=now();local dt=math.max(0,t-self.last);self.last=t
    if isGamePaused()then return end
    if not self:isValid()then self:forceStop();return end
    if self.failed then
        local recovery=self.context.action.qteFailure
        local phase,weight,slot=PY.AttackEffects.findTrack(self.character,recovery.animation,self.slot);self.slot=slot
        if phase and weight>=.35 then self.failureSeen=true;self.failureElapsed=phase
        elseif self.failureSeen and self.failureElapsed>=recovery.duration-.12 then self:forceComplete();return
        elseif self.failureSeen or now()-self.failureStarted>650 then self:forceStop();return end
        if self.failureElapsed>=recovery.duration-.005 or now()-self.failureStarted>(recovery.duration+1)*1000 then self:forceComplete()end
        return
    end
    R.hold(self.context.target.z)
    local phase,weight,slot=PY.AttackEffects.findTrack(self.character,self.context.action.animation,self.slot);self.slot=slot
    if phase and weight>=.35 then
        if self.seen and phase+.02<self.elapsed then if self.elapsed>=self.pose.duration-.12 then self:forceComplete()else self:forceStop()end;return end
        self.seen=true;self.elapsed=phase;self.wait=0
    else self.wait=(self.wait or 0)+dt;if self.seen and self.elapsed>=self.pose.duration-.12 then self:forceComplete()elseif self.seen or self.wait>650 then self:forceStop()end;return end
    if not H.align(self.pose,self.elapsed)then self:forceStop();return end
    if self.qte then PY.QTE.update(self.qte,self.elapsed*1000,PY.Bindings.down,function(kind,index,success,prompt)
        self.index=self.qte.index
        local grant=self.context.target.granted
        if kind=="input"and grant then PY.Network.send(self.character,"heatRushPress",{action=grant.action,index=index})end
        if kind=="result"then
            local contact=R.promptContact(self.context.action,index)
            if contact then self.success[contact]=success and self.elapsed*1000-prompt.atMs<=R.contactGraceMs;if self.success[contact]then self:contact(contact)end end
        elseif kind=="failure"then self:fail(index)
        end
    end)
        if self.failed or self.cleaned then return end
        for i,contact in ipairs(self.context.action.contacts or {})do
            if not contact.qteIndex and not self.autoSeen[i]and self.elapsed*1000>=contact.atMs then
                self.autoSeen[i]=true
                if self.elapsed*1000-contact.atMs<=R.contactGraceMs then self.success[i]=true;self:contact(i)end
            end
        end
    else
        local contacts=R.contacts(self.context.action)
        while contacts[self.index]and self.elapsed*1000>=contacts[self.index].atMs do
            local i=self.index;self.index=i+1
            if self.elapsed*1000-contacts[i].atMs<=R.contactGraceMs then self.success[i]=true;self:contact(i)end
        end
    end
    if self.elapsed>=self.pose.duration-.005 or self.character:GetVariable("ProjectYakuzaHeatRush")=="done"then self:forceComplete()end
end
function A:cleanup(done)
    if self.cleaned then return end;self.cleaned=true;local p,z=self.character,self.context.target.z;H.active[p]=nil
    if self.started then
        PY.HeatActions.finish(p,self)
        if self.qte then PY.QTE.cancel(self.qte,done and "complete"or"interrupted")end
        p:setBlockMovement(self.old.block==true);p:setIgnoreMovement(self.old.ignore==true);p:setDeferredMovementEnabled(self.old.deferred);p:setVariable("ProjectYakuzaHeatRush","")
        local settled=done and not self.failed and self.success[#R.contacts(self.context.action)]
        if settled then R.ground(z,R.endFacing(self.pose))end
        if not self.victimRestored then R.restore(z,self.victim);self.victimRestored=true end
        local clip=p:GetVariable("PerformingAction")
        if clip==self.context.action.animation or self.failed and clip==self.context.action.qteFailure.animation then p:setVariable("PerformingAction","");p:setVariable("IsPerformingAnAction",false)end
        if not isClient()and done and not self.failed and self.pendingDamage and not z:isDead()then local ok,err=PY.HitResponses.nativeHit(p,z,self.held,self.pendingDamage,self.context.action);self.pendingDamage=nil;if not ok then print("[ProjectYakuza] completed paired hit failed: "..tostring(err))end end
        if not isClient()and done and not self.failed and self.success[#R.contacts(self.context.action)]and not z:isDead()then R.ground(z,R.endFacing(self.pose))end
    end
    local granted=self.context.target.granted;if granted then PY.Network.send(p,"heatRushEnd",{action=granted.action,completed=done==true and not self.failed})end
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
        if not p:isAiming()or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:getVehicle()or p:isClimbing()or (p:getHitReaction()or"")~=""or not ticket or isClient()and not ticket.granted or not R.validTarget(p,ticket.z)then return false,"not_ready"end
        if c.action.weaponHeat then
            if not isMouseButtonDown(1)or not R.weaponAllowed(p,c.style,c.action)or not R.noCombo(PY.stateFor(p),c.style,now())then return false,"neutral_aim_required"end
        elseif not cfg or not c.action.heatRush or not PY.Heat.isExtreme(p)then return false,"not_ready"end
        if p:hasTimedActions()or p:isAttackStarted()or p:isPerformingAttackAnimation()then return false,"native_attack_busy"end
        local f=p:getForwardDirection();return R.space(p,{x=p:getX(),y=p:getY(),fx=f:getX(),fy=f:getY(),motion=R.motion(c.action),duration=R.durationFor(c.action)}),"blocked_space"
    end,
    start=function(c)
        PY.resetPlayer(c.player,"heat_rush_started");local a=A:new(c);c.timedAction=a;c.requestedAt=now();local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cleanup(false);return false,"queue_rejected"end
        return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel()end end,
})
function H.clear(p)
    if p then H.previews[p]=nil;H.chains[p]=nil;H.discard(p,H.tickets[p]);if H.answer and H.answer.p==p then H.answer=nil end;return end
    local players={};for player in pairs(H.active)do players[#players+1]=player end
    for _,player in ipairs(players)do PY.cancelAction(player,"world_exit")end
    if H.remote then for id,job in pairs(H.remote)do H.remoteEnd(id,job.action)end;H.updateRemote()end
    for player,ticket in pairs(H.tickets)do H.discard(player,ticket)end
    H.previews=setmetatable({}, {__mode="k"});H.chains=setmetatable({}, {__mode="k"});H.tickets=setmetatable({}, {__mode="k"});H.answer=nil
end
PY.on("lightAttackStarted",H.inputStarted)
PY.on("combatHit",H.hit)
PY.on("comboCancelled",function(p,reason)if reason~="recovery_cancel"then H.clear(p)end end)
PY.on("styleChanged",function(p)H.clear(p)end)
Events.OnSave.Add(function()H.clear()end)
Events.OnMainMenuEnter.Add(function()H.clear()end)
H.remote={};H.ended={};H.remoteSessions={};H.failedPackets={}
function H.remoteEnd(id,action,packet)
    if type(action)~="number"then return end;H.ended[id]=math.max(H.ended[id]or 0,action)
    local job=H.remote[id];if not job or job.action~=action then return end;H.remote[id]=nil
    local z=job.z;local saved=R.targetKind(z)=="zombie"and packet or job.old
    if saved and saved~=job.old then saved={useless=saved.useless,ignore=saved.ignore,deferred=saved.deferred,target=job.old.target}end
    if packet and packet.completed then R.ground(z,R.endFacing(job))end;PY.HeatActions.finish(job.p,job);if not job.victimRestored then R.restore(z,saved or job.old)end;if packet and packet.completed then R.ground(z,R.endFacing(job))end
end
function H.session(id,session)
    if PY.Network and not PY.Network.acceptSession(id,session)then return false end
    if H.remoteSessions[id]~=session then
        local old=H.remote[id];if old then H.remoteEnd(id,old.action)end
        H.remoteSessions[id]=session;H.ended[id]=nil;H.failedPackets[id]=nil;H.contacts=H.contacts or {};H.contacts[id]=nil
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
    if command=="heatRushFailed"then
        if not H.session(a.player,a.session)or not PY.NetworkProtocol.integer(a.action,1,1000000000)then return end
        H.failedPackets[a.player]=math.max(H.failedPackets[a.player]or 0,a.action)
        local localAction=H.active[p]
        if p:isLocalPlayer()and localAction and localAction.context.target.granted and localAction.context.target.granted.action==a.action then localAction:fail(a.index,true);return end
        local job=H.remote[a.player]
        if job and job.action==a.action then
            if not job.victimRestored then R.restore(job.z,job.old);job.victimRestored=true end
            job.failed=true;job.at=now()
        end
        return
    end
    if command=="heatRushContact"then
        if not H.session(a.player,a.session)or not PY.NetworkProtocol.integer(a.action,1,1000000000)or not PY.NetworkProtocol.integer(a.index,1,32)then return end
        local predicted=H.localContacts[p]
        if p:isLocalPlayer()and predicted and(predicted.session==nil or predicted.session==a.session)and(predicted.action>a.action or predicted.action==a.action and predicted.seen[a.index])then return end
        H.contacts=H.contacts or {};local previous=H.contacts[a.player]
        if previous and previous.action>a.action then return end
        if not previous or previous.action~=a.action then previous={action=a.action,seen={}};H.contacts[a.player]=previous end
        if previous.seen[a.index]then return end;previous.seen[a.index]=true;previous.at=now()
        local style=PY.getPlayerStyle(p)
        local move=style and (a.node and PY.NetworkProtocol.move and PY.NetworkProtocol.move(style.id,a.node)or style.actions.heatAction)
        local z=R.target(p,a.zombie,a.targetKind)
        if move and z then H.present(p,z,move,a.index,a.presentation==true)end
        return
    end
    local motion=a.motionId and PY.PairedMotions[a.motionId]
    if a.motionId and not motion then return end
    if command~="heatRushPose"or p:isLocalPlayer()or not PY.NetworkProtocol.integer(a.action,1,1000000000)or not PY.NetworkProtocol.number(a.age,0,motion and motion.duration or R.duration)or not PY.NetworkProtocol.number(a.x,-1000000,1000000)or not PY.NetworkProtocol.number(a.y,-1000000,1000000)or not PY.NetworkProtocol.number(a.fx,-1,1)or not PY.NetworkProtocol.number(a.fy,-1,1)then return end
    if not H.session(a.player,a.session)then return end
    if a.action<=(H.ended[a.player]or 0)or a.action<=(H.failedPackets[a.player]or 0)then return end
    local z=R.target(p,a.zombie,a.targetKind);if not z then return end
    local old=H.remote[a.player]
    if old and (old.action>a.action or old.failed and old.action==a.action)then return end
    if old and old.action~=a.action then H.remoteEnd(a.player,old.action);old=nil end
    local job=old or {p=p,z=z,action=a.action,old=R.capture(z)}
    job.motion=motion;job.duration=motion and motion.duration or R.duration
    job.x,job.y,job.fx,job.fy,job.age,job.at=a.x,a.y,a.fx,a.fy,a.age,now();H.remote[a.player]=job
    if not old then job.old=R.lock(z,motion and motion.targetAnimation);PY.HeatActions.begin(p,job,{duration=job.duration})end
    if not H.remoteHook then Events.OnTick.Add(H.updateRemote);H.remoteHook=true end
end
function H.updateRemote()
    local t=now();local active=false
    for id,job in pairs(H.remote)do
        if t-job.at>1000 or job.p:isDead()or job.z:isDead()and not job.motion then H.remoteEnd(id,job.action)
        else active=true;if not job.failed and not isGamePaused()then H.align(job,math.min(job.duration or R.duration,job.age+(t-job.at)/1000))end end
    end
    for key,job in pairs(H.contacts or {})do if t-job.at>6000 then H.contacts[key]=nil end end
    if not active and H.remoteHook then Events.OnTick.Remove(H.updateRemote);H.remoteHook=false end
end
Events.OnServerCommand.Add(H.receive)
Events.OnMainMenuEnter.Add(function()for id,job in pairs(H.remote)do H.remoteEnd(id,job.action)end;H.updateRemote();H.contacts={};H.ended={};H.remoteSessions={};H.failedPackets={};H.localContacts=setmetatable({}, {__mode="k"})end)
