require "ProjectYakuza/Runtime"
require "ProjectYakuza/Defense"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local PY=ProjectYakuza
local H={gestures=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"})}
PY.ChargedHeavy=H
local function now()return getTimestampMs()end
local A=ISBaseTimedAction:derive("ProjectYakuzaHeavyChargeAction")
H.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:isValid()
    local p=self.character
    return PY.isEquipped(p) and PY.getPlayerStyle(p)==self.context.style and p:isAiming()
        and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and not p:isAsleep()
        and not p:isDraggingCorpse() and (p:getHitReaction() or "")==""
end
function A:holdPosition()
    local p=self.character
    if math.abs(p:getX()-self.anchorX)>.0001 or math.abs(p:getY()-self.anchorY)>.0001 then
        PY.Defense.snapActor(p,self.anchorX,self.anchorY)
    end
    p:getMovementLastFrame():set(0,0);p:setMoving(false);p:setRunning(false);p:setSprinting(false)
end
function A:start()
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    local p=self.character
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement();self.oldDeferred=p:isDeferredMovementEnabled()
    self.anchorX,self.anchorY=p:getX(),p:getY()
    p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false);self:holdPosition()
    p:setVariable("ProjectYakuzaChargeClip","")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    PY.emit("heavyChargeStarted",p,self.context.style,self.context.action,self.context)
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true;local p=self.character
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setDeferredMovementEnabled(self.oldDeferred);p:setVariable("ProjectYakuzaChargeClip","")
    end
    if PY.activeActions[p]==self.context then
        if completed then PY.completeAction(p,self.context) else PY.cancelAction(p,"charge_interrupted",self.context) end
    end
    H.gestures[p]=nil
    if completed and self.started and self:isValid() then H.pending[p]={expiresAt=now()+600,consumed=false,variant=self.context.variant,branch=self.context.action.chargeBranch,power=self.power or 0} end
    if self.started then PY.emit("heavyChargeStopped",p,completed==true) end
end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:cancel()
    if self.cleaned then return end
    self:cleanup(false)
    if self.action then self:forceStop()
    elseif self.context.queue and self.context.queue.removeFromQueue then self.context.queue:removeFromQueue(self) end
end
function A:update()
    if self.cleaned then return end
    local t=now();local dt=math.max(0,t-self.lastAt);self.lastAt=t
    if isGamePaused() then
        self.startedAt=self.startedAt+dt
        if self.holdRequestedAt then self.holdRequestedAt=self.holdRequestedAt+dt end
        return
    end
    if not self:isValid() then self:forceStop();return end
    self:holdPosition()
    local age=t-self.startedAt
    local clip=self.character:GetVariable("ProjectYakuzaChargeClip") or ""
    if clip=="started" or clip=="handoff" or clip=="done" or clip=="holding" then self.seenClip=true end
    if self.seenClip and self.context.action.holdAnimation and not self.holding
        and (clip=="handoff" or clip=="done") then
        self.holding=true;self.holdRequestedAt=t
        self:setActionAnim(self.context.action.holdAnimation)
    end
    if clip=="holding" then self.holdSeen=true end
    if self.holding and not self.holdSeen and t-self.holdRequestedAt>600 then self:forceStop();return end
    local minimum=self.context.action.minChargeMs or 350
    local maximum=self.context.action.maxHoldMs or self.context.action.duration*1000
    self.power=PY.ChargeRules.power(age,minimum,maximum>0 and maximum or minimum+1000)
    if self.seenClip and self.power>=1 and not self.ready then
        self.ready=true;PY.emit("heavyChargeReady",self.character,self.context.style,self.context.action)
    end
    if age>600 and not self.seenClip then self:forceStop();return end
    if self.context.action.holdAnimation and not self.holding and age>(self.context.action.windupMs or minimum)+600 then self:forceStop();return end
    if self.seenClip and age>=(self.context.action.minChargeMs or 350)
        and (not self.context.action.holdAnimation or self.holding)
        and (not PY.Bindings.down("finisher") or (maximum>0 and age>=maximum)) then self:forceComplete() end
end
function A:new(c)
    local o=ISBaseTimedAction.new(self,c.player);o.context=c;o.maxTime=-1
    o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false;o.ignoreHandsWounds=true
    return o
end
PY.registerActionHandler("heavyCharge",{
    canStart=function(c)
        local p=c.player
        local s=PY.stateFor(p)
        if s.finisherMove or s.pendingFinisher or s.queuedFinisher or s.queuedDouble
            or (s.finisherBranch and s.finisherFinishedAt and now()-s.finisherFinishedAt<=c.style.comboResetMs) then return false,"second_finisher_only" end
        local gesture=H.gestures[p]
        if c.action.chargeBranch and (not gesture or c.target~=gesture or gesture.branch~=c.action.chargeBranch) then return false,"light_branch_required" end
        return p:isLocalPlayer() and p:isAiming() and not isGamePaused() and not p:hasTimedActions()
            and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown() and not p:isClimbing()
            and not p:getVehicle() and not p:isAsleep() and not p:isDraggingCorpse()
            and not p:isBlockMovement() and not p:getIgnoreMovement()
            and not p:isAttackStarted() and not p:isPerformingAttackAnimation()
            and (p:getHitReaction() or "")=="","not_ready"
    end,
    start=function(c)
        PY.resetPlayer(c.player,"heavy_charge_started",true)
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        c.queue=q;return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
})
function H.watch(p,c)
    if not c.timedAction.started and now()-c.requestedAt>600 then PY.cancelAction(p,"charge_start_timeout",c) end
    if c.timedAction.started and not c.timedAction.cleaned then c.timedAction:holdPosition() end
    return PY.activeActions[p]==c
end
function H.wantsRecovery(p,s,style)
    local gesture=H.gestures[p]
    if not gesture or not PY.Bindings.down("finisher") or not p:isAiming() or isGamePaused()
        or not s.active or s.finisherMove or s.groundMove or s.queued>0 or PY.activeActions[p] then return false end
    local slot=style.actions.heavyCharge
    if not slot or not slot.enabled then return false end
    local branch=slot.variants and slot.variants["after_"..s.step]
    return gesture.branch==s.step and now()-gesture.at>=((branch and branch.holdMs) or slot.holdMs or 350)
end
function H.input(p,down,pressed,s,style)
    local slot=style.actions.heavyCharge
    if not slot or not slot.enabled then return false end
    if not p:isAiming() or isGamePaused() then H.gestures[p]=nil;H.pending[p]=nil;return true end
    local move=s.finisherMove or s.pendingFinisher
    if move and (move.runningAttack or move.quickstepAttack or (move.chargedHeavy and not move.chargedFinisher)) then H.gestures[p]=nil;return true end
    local ticket=H.pending[p]
    if ticket then
        if now()>ticket.expiresAt or ticket.consumed then H.pending[p]=nil;return true end
        local ok,reason=PY.requestAction(p,"chargedHeavy",ticket.variant,ticket)
        if ok or (reason~="native_attack_busy" and reason~="busy" and reason~="native_attack_rejected") then H.pending[p]=nil end
        return true
    end
    if pressed then
        -- Second finishers never enter the hold gesture, even if MMB stays held.
        if move or s.queuedFinisher or s.queuedDouble or (s.finisherBranch and s.finisherFinishedAt and now()-s.finisherFinishedAt<=style.comboResetMs) then
            H.gestures[p]=nil;PY.queueFinisher(p);return true
        end
        local branch=(s.active or (s.finishedAt and now()-s.finishedAt<=style.comboResetMs)) and s.step or 0
        H.gestures[p]={at=now(),branch=branch}
    end
    local gesture=H.gestures[p]
    if not gesture then return true end
    -- Preserve a valid initial press past combo expiry, but follow any light
    -- that was already buffered and actually executes before charging starts.
    if s.active and not s.finisherMove and not s.groundMove and s.step>0 then gesture.branch=s.step end
    if not down then
        H.gestures[p]=nil;PY.queueFinisher(p);return true
    end
    local branchSlot=slot.variants and slot.variants["after_"..(gesture.branch or 0)]
    if now()-gesture.at>=((branchSlot and branchSlot.holdMs) or slot.holdMs or 350) and not s.active and not s.starting and s.queued==0 and not PY.activeActions[p] then
        local branch=gesture.branch or 0
        local variant=slot.variants and slot.variants["after_"..branch] and ("after_"..branch) or nil
        PY.requestAction(p,"heavyCharge",variant,gesture)
    end
    return true
end
function H.clearPlayer(p)
    H.gestures[p]=nil;H.pending[p]=nil
end
PY.on("comboCancelled",function(p,reason)if reason~="heavy_charge_started" then H.clearPlayer(p) end end)
function H.clear()
    local players={};for p,c in pairs(PY.activeActions) do if c.kind=="heavyCharge" then players[#players+1]=p end end
    for _,p in ipairs(players) do PY.cancelAction(p,"world_exit") end
    H.gestures=setmetatable({}, {__mode="k"});H.pending=setmetatable({}, {__mode="k"})
end
Events.OnSave.Add(H.clear)
Events.OnMainMenuEnter.Add(H.clear)
