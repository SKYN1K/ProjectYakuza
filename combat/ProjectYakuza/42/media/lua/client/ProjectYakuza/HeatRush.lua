require "ProjectYakuza/ActionAnimation"
require "ProjectYakuza/Runtime"
require "TimedActions/ISTimedActionQueue"
require "ProjectYakuza/NetworkProtocol"
require "ProjectYakuza/HeatRushRules"
require "ProjectYakuza/HeatActions"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/Defense"
require "ProjectYakuza/QTEFeedback"
require "ProjectYakuza/Feedback"
require "ProjectYakuza/CombatVoices"
require "ProjectYakuza/HeatActionPresentation"
require "TimedActions/ISBaseTimedAction"
local PY=ProjectYakuza;local R=PY.HeatRushRules
local H={chains=setmetatable({}, {__mode="k"}),tickets=setmetatable({}, {__mode="k"}),active=setmetatable({}, {__mode="k"}),localContacts=setmetatable({}, {__mode="k"})};PY.HeatRush=H
local function now()return getTimestampMs()end
function H.inputStarted(p,style,step,move)
    if style and style.extremeView and style.heatRush and move.extremeHeat then
        H.chains[p]={count=step,at=now(),stamp=PY.stateFor(p).multiHitToken}
    else H.chains[p]=nil end
end
function H.select(p,z,style,stamp)
    local ticket=H.tickets[p];local action=style.actions.heatAction
    local valid=R.validTarget(p,z)and R.placement(p,z,action)
    if ticket and ticket.stamp==stamp and now()<=ticket.expires and R.validFor(p,ticket.z,action)and R.placement(p,ticket.z,action)
        and (not valid or ticket.sent or ticket.granted)then return end
    H.discard(p,ticket)
    if valid then H.tickets[p]={z=z,pressed=true,stamp=stamp,created=now(),expires=now()+style.heatRush.windowMs};PY.stateFor(p).queued=0 end
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
    if not p:isAiming()or (ticket.weapon or ticket.ground)and not isMouseButtonDown(1)or not ticket.weapon and not ticket.ground and PY.Bindings.down("finisher")then H.discard(p,ticket);return false end
    local action=ticket.ground and style.actions.groundHeat or style.actions.heatAction
    if ticket.ground then
        if not action or not action.enabled or not R.noCombo(s,style,now())or not PY.HeatRules.canAfford(PY.actionHeat(p,action),(action.heatStocks or 0)*PY.Heat.stockSize(p))then H.discard(p,ticket);return false end
    elseif ticket.weapon then
        local cost=action and (action.heatStocks or 0)*PY.Heat.stockSize(p)or 0
        if not R.weaponAllowed(p,style,action)or not R.noCombo(s,style,now())or not PY.HeatRules.canAfford(PY.actionHeat(p,action),cost) then H.discard(p,ticket);return false end
    elseif not style.heatRush or not PY.Heat.isExtreme(p)then H.discard(p,ticket);return false end
    if now()>ticket.expires+(ticket.sent and 1000 or 0)or not R.validFor(p,ticket.z,action)then H.discard(p,ticket);return false end
    local down=PY.Bindings.down("light")
    if down and not s.lastDown then ticket.pressed=true end
    if not ticket.pressed then return false end
    s.queued=0
    if isClient()and PY.Network then
        local answer=H.answer
        if answer and answer.p==p then
            H.answer=nil
            if answer.z~=ticket.z:getOnlineID()or (answer.targetKind or "zombie")~=R.targetKind(ticket.z)or answer.request~=ticket.request then return true end
            ticket.granted=answer
        end
        if not ticket.granted then
            if not ticket.sent and now()>=(ticket.retryAt or 0)then ticket.sent=now();H.requestSerial=(H.requestSerial or 0)+1;ticket.request=H.requestSerial;PY.Network.capture(p,true);PY.Network.send(p,"heatRushBegin",{zombie=ticket.z:getOnlineID(),targetKind=R.targetKind(ticket.z),request=ticket.request,weaponHeat=ticket.weapon==true,groundHeat=ticket.ground==true})end
            if ticket.sent and now()-ticket.sent>1000 then H.tickets[p]=nil end
            return true
        end
    end
    if not ticket.weapon and not ticket.ground and PY.MultiHit then
        local waiting=PY.MultiHit.waiting(p,ticket.stamp)
        local budget=style.heatRush and style.heatRush.handoffWaitMs
        if waiting=="timeout"and budget==nil then H.discard(p,ticket);return false end
        if waiting and (budget==nil or now()-(ticket.created or now())<budget)then return true end
    end
    if s.active or s.starting or p:isAttackStarted()or p:isPerformingAttackAnimation()then PY.tryRecoveryCancel(p,style,s);return true end
    H.tickets[p]=nil
    local ok,reason=PY.requestAction(p,ticket.ground and "groundHeat"or "heatAction",nil,ticket)
    if not ok and (reason=="native_attack_busy"or reason=="busy")then H.tickets[p]=ticket;return true end
    H.tickets[p]=nil
    if not ok and ticket.granted then PY.Network.send(p,"heatRushEnd",{action=ticket.granted.action})end
    return true
end
H.previews=setmetatable({}, {__mode="k"});H.groundPreviews=setmetatable({}, {__mode="k"})
function H.weaponReady(p,s,style)
    if not p or not style or not PY.isEquipped(p)or not isMouseButtonDown(1)or not p:isAiming()or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:getVehicle()or p:isClimbing()or (p:getHitReaction()or"")~=""or PY.activeActions[p]or H.tickets[p]or not R.noCombo(s,style,now())then return end
    local action=style.actions.heatAction
    if not R.weaponAllowed(p,style,action)or not PY.HeatRules.canAfford(PY.actionHeat(p,action),(action.heatStocks or 0)*PY.Heat.stockSize(p))then return end
    if p:hasTimedActions()or p:isAttackStarted()or p:isPerformingAttackAnimation()then return end
    return action
end
function H.groundCandidate(p,s,style,force)
    local move=style and style.actions.groundHeat
    if not move or not move.enabled or not isMouseButtonDown(1)or not PY.Defense.safe(p)or PY.activeActions[p]or H.tickets[p]or not R.noCombo(s,style,now())or not PY.HeatRules.canAfford(PY.actionHeat(p,move),(move.heatStocks or 0)*PY.Heat.stockSize(p))then return end
    local cached=H.groundPreviews[p]
    if not force and cached and cached.style==style and now()<cached.next then
        if cached.z and R.validFor(p,cached.z,move)then return cached.z,move end
        if not cached.z then return end
    end
    local candidates,seen={},{};local cell=getCell();if not cell then return end
    local gx,gy,level=math.floor(p:getX()),math.floor(p:getY()),math.floor(p:getZ())
    for ox=-2,2 do for oy=-2,2 do local sq=cell:getGridSquare(gx+ox,gy+oy,level);local objects=sq and sq:getMovingObjects()
        if objects then for i=0,objects:size()-1 do
            local z=objects:get(i)
            if not seen[z]and R.validFor(p,z,move)then candidates[#candidates+1]={z=z,distance=(z:getX()-p:getX())^2+(z:getY()-p:getY())^2}end
            seen[z]=true
        end end
    end end
    table.sort(candidates,function(a,b)return a.distance<b.distance end)
    H.groundPreviews[p]={style=style,next=now()+200}
    for _,entry in ipairs(candidates)do
        if R.placement(p,entry.z,move)then H.groundPreviews[p].z=entry.z;return entry.z,move end
    end
end
function H.weaponCandidate(p,s,style,force)
    local ground,groundMove=H.groundCandidate(p,s,style,force);if ground then return ground,groundMove end
    local action=H.weaponReady(p,s,style)
    if not action then H.previews[p]=nil;return end
    local cached=H.previews[p];local t=now();local item=p:getPrimaryHandItem()
    if not force and cached and cached.style==style and cached.item==item and t<cached.next then
        if cached.z and R.validFor(p,cached.z,action)and PY.NetworkProtocol.path(p,cached.z:getX(),cached.z:getY())then return cached.z,action end
        if not cached.z then return end
    end
    cached={style=style,item=item,next=t+200};H.previews[p]=cached
    local candidates,seen={},{}
    local function consider(z)
        if not seen[z]and R.validFor(p,z,action)and PY.NetworkProtocol.path(p,z:getX(),z:getY())then
            local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local d=dx*dx+dy*dy
            candidates[#candidates+1]={z=z,distance=d}
        end
        if z then seen[z]=true end
    end
    local origin=PY.MultiHit.origin(p,R.targetRange);if not origin then return end
    for _,entry in ipairs(PY.MultiHit.targets(p,origin,false,{},math.huge))do consider(entry.victim)end
    if isClient()then
        local players=getOnlinePlayers();for i=0,players:size()-1 do consider(players:get(i))end
    elseif getNumActivePlayers then for i=0,getNumActivePlayers()-1 do consider(getSpecificPlayer(i))end end
    table.sort(candidates,function(a,b)return a.distance<b.distance end)
    for _,entry in ipairs(candidates)do
        if R.placement(p,entry.z,action)then cached.z=entry.z;return entry.z,action end
    end
end
function H.weaponInput(p,s,style,pressed)
    if not pressed then return false end
    local selected,action=H.weaponCandidate(p,s,style,true)
    if not selected then return false end
    H.tickets[p]={z=selected,pressed=true,weapon=not action.groundHeat,ground=action.groundHeat==true,expires=now()+600}
    return H.input(p,s,style)
end
local A=ISBaseTimedAction:derive("ProjectYakuzaHeatRushAction");H.Action=A
function A:setActionAnim(clip)
    self.animation=clip;self.character:setVariable("PerformingAction",clip);self.character:setVariable("IsPerformingAnAction",true)
end
function A:forceStop()self:stop()end
function A:forceComplete()self:perform()end
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
    if self.started or self.cleaned then return end
    if not self:isValid()then self:cleanup(false);return end
    local p,z=self.character,self.context.target.z
    if self.context.action.groundHeat and not R.validFor(p,z,self.context.action)then self:forceStop();return end
    self.started=true;self.last=now();self.elapsed=0;self.index=1;self.success={};self.autoSeen={};self.qte=self.context.action.qte and PY.QTE.create(R.qte(self.context.action),PY.Bindings.down,self.context)
    if self.qte and self.context.action.qteStages then self.success.qte=self.qte.accepted end
    self.old={block=p:isBlockMovement(),ignore=p:getIgnoreMovement(),deferred=p:isDeferredMovementEnabled()};p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false)
    local granted=self.context.target.granted;local f=p:getForwardDirection()
    local origin=granted or self.context.target.pose or {x=p:getX(),y=p:getY(),fx=f:getX(),fy=f:getY()}
    self.pose={p=p,z=z,x=origin.x,y=origin.y,fx=origin.fx,fy=origin.fy}
    self.pose.move=self.context.action;self.pose.motion=R.motion(self.context.action);self.pose.duration=R.durationFor(self.context.action)
    self.victim=R.lock(z,self.context.action.targetAnimation)
    PY.setVisual(p,true,self.context.action.nodeValue);p:setVariable("ProjectYakuzaStyle",self.context.style.id);p:setVariable("ProjectYakuzaWeaponProfile",self.context.style.weaponProfile or "");p:setVariable("ProjectYakuzaHeatRush","")
    self:setActionAnim(self.context.action.animation)
    H.active[p]=self;PY.HeatActions.begin(p,self,R.protection(self.context.action))
    if not H.align(self.pose,0)then self:forceStop()end
    if not self.cleaned and PY.HeatActionPresentation then PY.HeatActionPresentation.start(p,z,self.context.action,self)end
end
function H.present(p,z,move,index,effects,scheduled,anchor,feedback,bloodOnly)
    local contact=R.contacts(move)[index];if not contact then return end
    if PY.HeatActionPresentation and not scheduled then return end
    if effects~=false then
        if bloodOnly and PY.BloodEffects then PY.BloodEffects.spawn(p,z,contact.strong~=false,contact.charged==true,feedback,anchor)
        elseif PY.HitEffects then PY.HitEffects.spawn(p,z,contact.strong~=false,contact.charged==true,nil,feedback,anchor)end
    end
    if not scheduled and p:isLocalPlayer()and PY.Feedback then
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
            H.present(p,z,self.context.action,index,true)
        end
        PY.Network.send(p,"heatRushHit",{action=granted.action,index=index});return
    end
    local amount=R.amount(self.context.action,index,self.held,self.success);if not amount then return end
    if R.targetKind(z)=="player"and not R.playerAllowed(p,z)then return end
    PY.HeatActions.strike(self,p,z,self.held,amount,index)
    H.present(p,z,self.context.action,index)
end
function A:fail(index,remote)
    if self.failed or self.cleaned then return end
    local recovery=self.context.action.qteFailure
    if not recovery then self:forceStop();return end
    self.failed=true;self.failedIndex=index;self.failureStarted=now();self.failureElapsed=0;self.failureSeen=false;self.slot=nil
    if remote and not self.qte.failed and PY.QTEFeedback then PY.QTEFeedback.play(self.context,"failure")end
    PY.QTE.cancel(self.qte,"failed")
    if R.pairedFailure(self.context.action)then
        self.failurePose=R.failurePose(self.pose,self.elapsed);self.context.target.z:setVariable("ProjectYakuzaPairedVictimClip",recovery.targetAnimation);R.hold(self.context.target.z)
    elseif not self.victimRestored then R.restore(self.context.target.z,self.victim);self.victimRestored=true end
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
        if phase and weight>=.35 then
            self.failureSeen=true;self.failureElapsed=phase
            if self.failurePose then
                R.hold(self.context.target.z);if not H.align(self.failurePose,phase)then self:forceStop();return end
                if not self.failureContact and phase*1000>=recovery.contactMs then self.failureContact=true;local index=#R.contacts(self.context.action);self.success[index]=true;self:contact(index)end
            end
        elseif self.failureSeen and self.failureElapsed>=recovery.duration-.12 then self:forceComplete();return
        elseif self.failureSeen or now()-self.failureStarted>650 then self:forceStop();return end
        if self.failureElapsed>=recovery.duration-.005 or now()-self.failureStarted>(recovery.duration+1)*1000 then self:forceComplete()end
        return
    end
    R.hold(self.context.target.z)
    local phase,weight,slot=PY.AttackEffects.findTrack(self.character,self.context.action.animation,self.slot);self.slot=slot
    if phase and weight>=.35 then
        if not self.seen then
            if not PY.payActionHeat(self.context)then self:forceStop();return end
            PY.Heat.onSwing(self.character,{damageMultiplier=1})
            PY.emit("attackCommitted",self.character,self.context.style,self.context.action,self.context,"heatAction")
            local granted=self.context.target.granted
            if granted then PY.Network.send(self.character,"heatRushReady",{action=granted.action})end
        end
        local sourcePhase=self.context.action.pacedAnimation and R.sourceTime(self.context.action,phase)or phase
        if self.seen and sourcePhase+.02<self.elapsed then if self.elapsed>=self.pose.duration-.12 then self:forceComplete()else self:forceStop()end;return end
        self.seen=true;self.elapsed=self.context.action.pacedAnimation and R.sourceTime(self.context.action,phase)or phase;self.wait=0
    else self.wait=(self.wait or 0)+dt;if self.seen and self.elapsed>=self.pose.duration-.12 then self:forceComplete()elseif self.seen or self.wait>650 then self:forceStop()end;return end
    if not H.align(self.pose,self.elapsed)then self:forceStop();return end
    if self.qte then PY.QTE.update(self.qte,R.time(self.context.action,self.elapsed)*1000,PY.Bindings.down,function(kind,index,success,prompt)
        self.index=self.qte.index
        local grant=self.context.target.granted
        if kind=="tap"and grant then PY.Network.send(self.character,"heatRushPress",{action=grant.action,index=index,tap=self.qte.pressCounts[index],tapAt=self.qte.lastPressAt[index]})end
        if kind=="input"and grant and not prompt.presses then PY.Network.send(self.character,"heatRushPress",{action=grant.action,index=index})end
        if kind=="result"then
            local contact=R.promptContact(self.context.action,index)
            if contact then self.success[contact]=success and self.elapsed*1000-R.contacts(self.context.action)[contact].atMs<=R.contactGraceMs;if self.success[contact]then self:contact(contact)end end
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
    if PY.HeatActionPresentation then PY.HeatActionPresentation.stop(p,self,done)end
    if self.started then
        PY.HeatActions.finish(p,self)
        if self.qte then PY.QTE.cancel(self.qte,done and "complete"or"interrupted")end
        p:setBlockMovement(self.old.block==true);p:setIgnoreMovement(self.old.ignore==true);p:setDeferredMovementEnabled(self.old.deferred);p:setVariable("ProjectYakuzaHeatRush","")
        local settled=done and(not self.failed or R.pairedFailure(self.context.action))and self.success[#R.contacts(self.context.action)]
        if settled then R.ground(z,R.endFacing(self.pose))end
        if not self.victimRestored then R.restore(z,self.victim);self.victimRestored=true end
        PY.releaseActionAnimation(p,self,true)
        if not isClient()then PY.HeatActions.settle(self,p,z,self.held,done and(not self.failed or R.pairedFailure(self.context.action)))end
        if not isClient()and done and(not self.failed or R.pairedFailure(self.context.action))and self.success[#R.contacts(self.context.action)]and not z:isDead()then R.ground(z,R.endFacing(self.pose))end
    end
    local granted=self.context.target.granted;if granted then PY.Network.send(p,"heatRushEnd",{action=granted.action,completed=done==true and(not self.failed or R.pairedFailure(self.context.action))})end
    if PY.activeActions[p]==self.context then if done then PY.completeAction(p)else PY.cancelAction(p,"heat_rush_interrupted")end end
    PY.resetPlayer(p,"heat_rush_finished")
end
function A:perform()self:cleanup(true)end
function A:stop()self:cleanup(false)end
function A:cancel()self:cleanup(false)end
function A:new(c)local a=ISBaseTimedAction.new(self,c.player);a.context=c;a.held=c.player:getPrimaryHandItem();return a end
local gate=PY.HeatActionQueueGate or {add=ISTimedActionQueue.add,addAfter=ISTimedActionQueue.addAfter}
PY.HeatActionQueueGate=gate
local function protectedAction(action)
    local p=action and action.character;local c=p and PY.activeActions[p]
    return c and(c.kind=="heatAction"or c.kind=="groundHeat"or c.kind=="grabHeat")and c.timedAction and not c.timedAction.cleaned
end
ISTimedActionQueue.add=function(action,...)
    if protectedAction(action)then return end
    return gate.add(action,...)
end
if gate.addAfter then ISTimedActionQueue.addAfter=function(previous,action,...)
    if protectedAction(action)then return end
    return gate.addAfter(previous,action,...)
end end
PY.registerStyleActionHandler("dragon_of_dojima","heatAction",{
    canStart=function(c)
        local p=c.player;local ticket=c.target;local cfg=c.style.heatRush
        if not p:isAiming()or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:getVehicle()or p:isClimbing()or (p:getHitReaction()or"")~=""or not ticket or isClient()and not ticket.granted or not R.validFor(p,ticket.z,c.action)then return false,"not_ready"end
        if c.action.groundHeat then
            if not isMouseButtonDown(1)or not R.noCombo(PY.stateFor(p),c.style,now())then return false,"neutral_aim_required"end
        elseif c.action.weaponHeat then
            if not isMouseButtonDown(1)or not R.weaponAllowed(p,c.style,c.action)or not R.noCombo(PY.stateFor(p),c.style,now())then return false,"neutral_aim_required"end
        elseif c.action.grabHeat then
            if not ticket.fromGrab or not isMouseButtonDown(1)then return false,"grab_required"end
        elseif not cfg or not c.action.heatRush or not PY.Heat.isExtreme(p)then return false,"not_ready"end
        if p:hasTimedActions()or p:isAttackStarted()or p:isPerformingAttackAnimation()then return false,"native_attack_busy"end
        local pose=ticket.granted or ticket.pose
        if not pose and not c.action.grabHeat then pose=R.placement(p,ticket.z,c.action);ticket.pose=pose end
        if pose then pose.motion=R.motion(c.action);pose.duration=R.durationFor(c.action)end
        return pose~=nil and R.space(p,pose)and (c.action.grabHeat or R.clearance(p,{x=pose.x,y=pose.y,fx=pose.fx,fy=pose.fy,motion=R.motion(c.action),duration=R.durationFor(c.action)})),"blocked_space"
    end,
    start=function(c)
        PY.resetPlayer(c.player,"heat_rush_started");c.timedAction=A:new(c);c.requestedAt=now();return true
    end,
    update=function(c)
        local a=c.timedAction;if not a then return end
        if isGamePaused()then a.last=now();return end
        if not a.started then a:start()else a:update()end
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel()end end,
})
PY.registerActionHandler("groundHeat",PY.getActionHandler("dragon_of_dojima","heatAction"))
PY.registerActionHandler("grabHeat",PY.getActionHandler("dragon_of_dojima","heatAction"))
function H.clear(p)
    if p then H.previews[p]=nil;H.groundPreviews[p]=nil;H.chains[p]=nil;H.discard(p,H.tickets[p]);if H.answer and H.answer.p==p then H.answer=nil end;return end
    local players={};for player in pairs(H.active)do players[#players+1]=player end
    for _,player in ipairs(players)do PY.cancelAction(player,"world_exit")end
    if H.remote then for id,job in pairs(H.remote)do H.remoteEnd(id,job.action)end;H.updateRemote()end
    for player,ticket in pairs(H.tickets)do H.discard(player,ticket)end
    H.previews=setmetatable({}, {__mode="k"});H.chains=setmetatable({}, {__mode="k"});H.tickets=setmetatable({}, {__mode="k"});H.answer=nil;H.groundPreviews=setmetatable({}, {__mode="k"})
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
    if PY.HeatActionPresentation then PY.HeatActionPresentation.stop(job.p,job,packet and packet.completed)end
    local z=job.z;local saved=R.targetKind(z)=="zombie"and packet or job.old
    if saved and saved~=job.old then saved={useless=saved.useless,ignore=saved.ignore,deferred=saved.deferred,locked=saved.locked,target=job.old.target,groundAction=job.old.groundAction,floor=job.old.floor,knocked=job.old.knocked}end
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
function H.syncHealth(p,a)
    if not PY.NetworkProtocol.number(a.health,0,1000)then return end
    local active=H.active[p];local grant=active and active.context.target.granted;local remote=H.remote[a.player];local previous=H.localContacts[p]
    if not(grant and grant.action==a.action or remote and remote.action==a.action or previous and previous.action==a.action)then return end
    local z=R.target(p,a.zombie,a.targetKind)
    if not z or z:isDead()then return end
    H.contacts=H.contacts or {};local record=H.contacts[a.player]
    if record and record.action>a.action then return end
    if not record or record.action~=a.action then record={action=a.action,seen={}};H.contacts[a.player]=record end
    record.healthSeen=record.healthSeen or {};local key=a.index or "end"
    if record.healthSeen[key]then return end;record.healthSeen[key]=true;record.at=now()
    z:setHealth(math.min(z:getHealth(),a.health))
end
function H.receive(module,command,a)
    if module~=PY.NetworkProtocol.module or type(a)~="table"or not PY.NetworkProtocol.integer(a.player,0,32767)then return end
    local p=getPlayerByOnlineID(a.player);if not p then return end
    if PY.GrabCombat and PY.GrabCombat.receive(command,p,a)then return end
    if command=="heatRushGranted"and p:isLocalPlayer()then
        local ticket=H.tickets[p];if not ticket or ticket.request~=a.request then
            if PY.NetworkProtocol.integer(a.action,1,1000000000)and PY.Network then PY.Network.send(p,"heatRushEnd",{action=a.action})end
            return
        end
        if PY.NetworkProtocol.integer(a.action,1,1000000000)and PY.NetworkProtocol.integer(a.zombie,-32768,32767)and PY.NetworkProtocol.number(a.x,-1000000,1000000)and PY.NetworkProtocol.number(a.y,-1000000,1000000)and PY.NetworkProtocol.number(a.fx,-1,1)and PY.NetworkProtocol.number(a.fy,-1,1)then a.p=p;a.z=a.zombie;H.answer=a end;return
    end
    if command=="heatRushDenied"and p:isLocalPlayer()then local ticket=H.tickets[p];if ticket and ticket.request==a.request then if not ticket.weapon and not ticket.ground and now()<ticket.expires then ticket.sent=nil;ticket.retryAt=now()+100 else H.tickets[p]=nil end end;return end
    if command=="heatRushEnd"then
        if not H.session(a.player,a.session)then return end
        H.syncHealth(p,a)
        local active=p:isLocalPlayer()and H.active[p];local grant=active and active.context.target.granted
        if grant and grant.action==a.action and a.completed~=true then active:cancel()end
        H.remoteEnd(a.player,a.action,a);return
    end
    if command=="heatRushFailed"then
        if not H.session(a.player,a.session)or not PY.NetworkProtocol.integer(a.action,1,1000000000)then return end
        H.failedPackets[a.player]=math.max(H.failedPackets[a.player]or 0,a.action)
        local localAction=H.active[p]
        if p:isLocalPlayer()and localAction and localAction.context.target.granted and localAction.context.target.granted.action==a.action then localAction:fail(a.index,true);return end
        local job=H.remote[a.player]
        if job and job.action==a.action then
            if not job.failed then
                if R.pairedFailure(job.move)then job.failurePose=R.failurePose(job,job.age or 0);job.z:setVariable("ProjectYakuzaPairedVictimClip",job.move.qteFailure.targetAnimation)
                elseif not job.victimRestored then R.restore(job.z,job.old);job.victimRestored=true end
                job.failed=true;job.failureAt=now()
            end
            job.at=now()
        end
        return
    end
    if command=="heatRushContact"then
        if not H.session(a.player,a.session)or not PY.NetworkProtocol.integer(a.action,1,1000000000)or not PY.NetworkProtocol.integer(a.index,1,32)then return end
        H.syncHealth(p,a)
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
    if not old then
        local observer=PY.Network and PY.Network.remote and PY.Network.remote[a.player]
        if observer and observer.grab==z and observer.grabRestore then
            PY.GrabRules.restore(z,observer.grabRestore);observer.grab=nil;observer.grabRestore=nil
            z:setVariable("ProjectYakuzaGrabbed",false);z:setVariable("ProjectYakuzaGrabPhase","");z:setVariable("ProjectYakuzaGrabMoving",false)
        end
    end
    local style=a.node and PY.getStyle(p:getModData().ProjectYakuzaStyle or "")
    local move=style and PY.NetworkProtocol.move(style.id,a.node,p:GetVariable("ProjectYakuzaWeaponProfile"))or nil
    if a.node and(not move or move.motionId~=a.motionId)then return end
    local job=old or {p=p,z=z,action=a.action};job.move=move
    job.motion=motion;job.duration=motion and motion.duration or R.duration
    job.x,job.y,job.fx,job.fy,job.age,job.at=a.x,a.y,a.fx,a.fy,a.age,now();H.remote[a.player]=job
    if not old then job.old=R.lock(z,motion and motion.targetAnimation);PY.HeatActions.begin(p,job,{duration=move and R.wallDuration(move)or job.duration})end
    if move and PY.HeatActionPresentation then PY.HeatActionPresentation.start(p,z,move,job)end
    if not H.remoteHook then Events.OnTick.Add(H.updateRemote);H.remoteHook=true end
end
function H.updateRemote()
    local t=now();local active=false
    for id,job in pairs(H.remote)do
        if t-job.at>1000 or job.p:isDead()or job.z:isDead()and not job.motion then H.remoteEnd(id,job.action)
        else active=true;if not isGamePaused()then if job.failurePose then H.align(job.failurePose,math.min(job.failurePose.duration,(t-job.failureAt)/1000))elseif not job.failed then H.align(job,math.min(job.duration or R.duration,R.sourceTime(job.move,R.time(job.move,job.age)+(t-job.at)/1000)))end end end
    end
    for key,job in pairs(H.contacts or {})do if t-job.at>6000 then H.contacts[key]=nil end end
    if not active and H.remoteHook then Events.OnTick.Remove(H.updateRemote);H.remoteHook=false end
end
Events.OnServerCommand.Add(H.receive)
Events.OnMainMenuEnter.Add(function()for id,job in pairs(H.remote)do H.remoteEnd(id,job.action)end;H.updateRemote();H.contacts={};H.ended={};H.remoteSessions={};H.failedPackets={};H.localContacts=setmetatable({}, {__mode="k"})end)
